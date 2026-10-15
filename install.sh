#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

kpackagetool6 -t Plasma/Applet -u "$SCRIPT_DIR/plasmoid" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$SCRIPT_DIR/plasmoid"

echo "Done. Add the \"Zowie Mouse\" widget to your panel and press \"Grant access\" in its popup."
