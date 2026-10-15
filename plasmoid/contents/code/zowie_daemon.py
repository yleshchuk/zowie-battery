#!/usr/bin/env python3
"""Publish Zowie EC-CW battery and polling rate to $XDG_RUNTIME_DIR/zowie/status.json."""
import json
import math
import os
import select
import statistics
import sys
import time
from pathlib import Path

VENDOR_ID = "04A5"
MODES = {"8005": "wired", "8006": "receiver"}
BATTERY_QUERY = bytes([0xA5, 0x03]).ljust(64, b"\0")
QUERY_INTERVAL = 30.0
RESCAN_INTERVAL = 5.0
# ponytail: steady slow motion at 1000 Hz can still skip every other frame and read 500.
RATE_SAMPLE = 100
MAX_GAP = 0.012
SUPPORTED_RATES = (125, 500, 1000)
RATE_TOLERANCE = 0.25
# ponytail: generic single-cell LiPo resting curve, not calibrated for this mouse.
LIPO_CURVE = (
    (3270, 0), (3610, 5), (3690, 10), (3710, 15), (3730, 20), (3750, 25), (3770, 30),
    (3790, 35), (3800, 40), (3820, 45), (3840, 50), (3850, 55), (3870, 60), (3910, 65),
    (3950, 70), (3980, 75), (4020, 80), (4080, 85), (4110, 90), (4150, 95), (4200, 100),
)
SMOOTHING = 0.3
STATUS_PATH =Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "zowie" / "status.json"


def find_interfaces() -> tuple[str, str, str] | None:
    """Return (mode, mouse hidraw path, vendor hidraw path), preferring the wired mouse."""
    found: dict[str, dict[str, str]] = {}
    for node in Path("/sys/class/hidraw").iterdir():
        uevent = (node / "device" / "uevent").read_text()
        hid_id = next((line[7:] for line in uevent.splitlines() if line.startswith("HID_ID=")), "")
        _, vid, pid = hid_id.split(":")
        if vid[-4:].upper() != VENDOR_ID or pid[-4:] not in MODES:
            continue
        descriptor = (node / "device" / "report_descriptor").read_bytes()
        role = "vendor" if descriptor[:1] == b"\x06" else "mouse"
        found.setdefault(MODES[pid[-4:]], {})[role] = f"/dev/{node.name}"
    for mode in ("wired", "receiver"):
        nodes = found.get(mode, {})
        if "mouse" in nodes and "vendor" in nodes:
            return mode, nodes["mouse"], nodes["vendor"]
    return None


def parse_battery(reply: bytes) -> tuple[int, int] | None:
    """Return (millivolts, percent) from an `a5 03` reply, None when the mouse is not linked."""
    millivolts, percent = int.from_bytes(reply[0:2], "little"), reply[2]
    return None if millivolts == 0 else (millivolts, percent)


def estimate_percent(millivolts: float) -> int:
    if millivolts <= LIPO_CURVE[0][0]:
        return 0
    for (v0, p0), (v1, p1) in zip(LIPO_CURVE, LIPO_CURVE[1:]):
        if millivolts <= v1:
            return round(p0 + (p1 - p0) * (millivolts - v0) / (v1 - v0))
    return 100


def estimate_rate(gaps: list[float]) -> int | None:
    """Polling rate from report gaps; None when uneven or off-rate, i.e. slow motion skipping frames."""
    median = statistics.median(gaps)
    steady = sum(abs(gap / median - 1) < RATE_TOLERANCE for gap in gaps)
    if steady < 0.8 * len(gaps):
        return None
    hz = 1 / median
    rate = min(SUPPORTED_RATES, key=lambda rate: abs(math.log(rate / hz)))
    return rate if abs(math.log(rate / hz)) < math.log(1 + RATE_TOLERANCE) else None


def publish(status: dict[str, object]) -> None:
    STATUS_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATUS_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(status))
    os.replace(tmp, STATUS_PATH)


def serve(mode: str, mouse_path: str, vendor_path: str, status: dict[str, object]) -> None:
    mouse = os.open(mouse_path, os.O_RDONLY)
    vendor = os.open(vendor_path, os.O_RDWR)
    try:
        status.update(mode=mode, access=True)
        publish(status)
        next_query = 0.0
        last_report: float | None = None
        gaps: list[float] = []
        smoothed_mv: float | None = None
        while True:
            now = time.monotonic()
            if now >= next_query:
                os.write(vendor, BATTERY_QUERY)
                next_query = now + QUERY_INTERVAL
            for fd in select.select([mouse, vendor], [], [], next_query - now)[0]:
                data = os.read(fd, 64)
                stamp = time.monotonic()
                if fd == vendor:
                    battery = parse_battery(data)
                    if battery is None:
                        smoothed_mv = None
                    elif smoothed_mv is None:
                        smoothed_mv = battery[0]
                    else:
                        smoothed_mv += SMOOTHING * (battery[0] - smoothed_mv)
                    status.update(
                        linked=battery is not None,
                        battery_mv=battery and battery[0],
                        battery_percent=battery and battery[1],
                        battery_estimate=smoothed_mv and estimate_percent(smoothed_mv),
                        battery_updated=time.time(),
                    )
                    publish(status)
                    continue
                if last_report is not None and stamp - last_report < MAX_GAP:
                    gaps.append(stamp - last_report)
                last_report = stamp
                if len(gaps) >= RATE_SAMPLE:
                    rate = estimate_rate(gaps)
                    gaps.clear()
                    if rate is not None and rate != status.get("polling_hz"):
                        status.update(polling_hz=rate)
                        publish(status)
    finally:
        os.close(mouse)
        os.close(vendor)


def main() -> None:
    status: dict[str, object] = {"mode": None, "linked": False}
    while True:
        interfaces = find_interfaces()
        if interfaces is None:
            status.update(mode=None, linked=False)
            publish(status)
        else:
            try:
                serve(*interfaces, status)
            except PermissionError:
                status.update(mode=None, linked=False, access=False)
                publish(status)
            except OSError as error:
                print(f"{interfaces}: {error}", file=sys.stderr, flush=True)
                status.update(mode=None, linked=False)
                publish(status)
        time.sleep(RESCAN_INTERVAL)


if __name__ == "__main__":
    main()
