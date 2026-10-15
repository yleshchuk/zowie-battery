#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sudo install -m 644 "$SCRIPT_DIR/70-zowie.rules" /etc/udev/rules.d/70-zowie.rules
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=hidraw

mkdir -p "$HOME/.config/systemd/user"
sed "s|@SCRIPT_DIR@|$SCRIPT_DIR|" "$SCRIPT_DIR/zowie-daemon.service" > "$HOME/.config/systemd/user/zowie-daemon.service"
systemctl --user daemon-reload
systemctl --user enable --now zowie-daemon.service

ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
cp "$SCRIPT_DIR"/plasmoid/contents/icons/*.svg "$ICON_DIR/"

kpackagetool6 -t Plasma/Applet -u "$SCRIPT_DIR/plasmoid" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$SCRIPT_DIR/plasmoid"

echo "Done. Add the \"Zowie Mouse\" widget to your panel."
