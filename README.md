# Zowie EC-CW battery widget for KDE Plasma

> **Disclaimer:** Made with Claude AI. The vendor protocol was reverse-engineered by trial and error;
> it is unofficial and not endorsed by BenQ/Zowie. Use at your own risk.

A KDE Plasma 6 panel widget showing battery level, polling rate and connection mode of the
BenQ Zowie EC-CW wireless mouse (tested with EC1-CW and its charging dock receiver).

## How it works

- `zowie_daemon.py` runs as a systemd user service, opens the mouse's vendor hidraw interface
  (`04a5:8006` receiver or `04a5:8005` cable) and sends `a5 03` every 30 s.
  The reply is `LL HH PP ec`: battery millivolts (little-endian) and the mouse's own percent.
- The percent shown is estimated from millivolts with a generic LiPo curve and smoothing;
  the mouse's own value is shown in the popup too.
- Polling rate (125/500/1000 Hz) is measured from mouse report intervals while you move it.
- Status goes to `$XDG_RUNTIME_DIR/zowie/status.json`, which the widget reads.

DPI is not exposed over the receiver, so the widget does not show it.

## Install

```sh
./install.sh
```

It installs a udev rule (needs sudo) that gives the logged-in user access to the mouse hidraw
nodes, enables the user service, installs the icons and the plasmoid. Then add the
"Zowie Mouse" widget to a panel. Requires Python 3.10+ and Plasma 6.

## Tests

```sh
python3 -m unittest
```

## Warning

Some vendor commands are dangerous: `a5 09` reboots the receiver and unpairs the mouse
(re-pair: hold the DPI button 5 s, then replug the receiver within 30 s), and other commands may
enter firmware update mode. The daemon only sends the read-only `a5 03`.

## License

GPL-3.0-or-later
