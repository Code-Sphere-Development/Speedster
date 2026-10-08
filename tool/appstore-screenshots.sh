#!/usr/bin/env bash
#
# Erzeugt die Bilder fuer App Store Connect und die Landingpage.
#
# Der zweite Schritt ist der, den man vergisst: Flutters toImage schreibt
# immer RGBA, auch wenn jedes Pixel deckend ist. App Store Connect nimmt
# PNGs mit Alphakanal nicht an -- und meldet dabei "falsche Masse",
# obwohl die Masse stimmen. Das hat schon zweimal eine Einreichung
# gekostet.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter test test/screenshots/generate.dart

if ! command -v magick >/dev/null 2>&1; then
  echo "FEHLER: ImageMagick fehlt (brew install imagemagick)." >&2
  echo "Die Bilder in build/appstore haben noch einen Alphakanal und" >&2
  echo "werden von App Store Connect abgelehnt." >&2
  exit 1
fi

for f in build/appstore/*/*.png; do
  magick "$f" -background black -alpha remove -alpha off "$f"
done

echo
echo "App Store Connect, 6,9\":  build/appstore/6.9   (1320 x 2868)"
echo "App Store Connect, 6,3\":  build/appstore/6.3   (1206 x 2622)"
echo "Landingpage:              build/screenshots   (860 x 1864)"
echo
echo "Fuer die Cloud:"
echo "  cp build/screenshots/*.png ../Speedster_Cloud/public/screenshots/"
