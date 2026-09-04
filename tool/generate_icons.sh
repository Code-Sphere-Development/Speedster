#!/usr/bin/env bash
# Erzeugt alle App-Icons und Splash-Bilder aus tool/branding/speedster.png.
#
# Bewusst ein Skript statt einer Dependency wie flutter_launcher_icons:
# die Erzeugung laeuft einmal pro Logo-Aenderung, die Ergebnisse liegen im
# Repo, und das Projekt bleibt ohne zusaetzliches Paket.
#
# Voraussetzung: ImageMagick (brew install imagemagick)
# Aufruf:        tool/generate_icons.sh   (aus dem Projektwurzelverzeichnis)
set -euo pipefail

SRC="tool/branding/speedster.png"
CARD="#14161A"   # Kartenhintergrund des Logos
ANDROID_RES="android/app/src/main/res"
IOS_ICONS="ios/Runner/Assets.xcassets/AppIcon.appiconset"
IOS_LAUNCH="ios/Runner/Assets.xcassets/LaunchImage.imageset"

command -v magick >/dev/null || { echo "ImageMagick fehlt: brew install imagemagick"; exit 1; }
[ -f "$SRC" ] || { echo "Quelle fehlt: $SRC"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- Motive vorbereiten ---------------------------------------------------
# Der Kartenhintergrund des Logos ist ein Verlauf. Wird ein Ausschnitt einfach
# auf eine flache Farbe gelegt, bleibt seine Kante als Rechteck sichtbar.
# Deshalb wird der Hintergrund von den Ecken aus freigestellt; die dann
# transparenten dunklen Flaechen sehen vor "$CARD" aus wie das Original.
free_background() { # $1 = Eingabe, $2 = Ausgabe
  local w h
  w=$(magick "$1" -format %w info:)
  h=$(magick "$1" -format %h info:)
  magick "$1" -alpha set -fuzz 12% \
    -fill none \
    -draw "color 0,0 floodfill" \
    -draw "color $((w - 1)),0 floodfill" \
    -draw "color 0,$((h - 1)) floodfill" \
    -draw "color $((w - 1)),$((h - 1)) floodfill" \
    "$2"
}

# Motiv fuers Icon: nur Tacho und Strasse. Der Schriftzug des vollen Logos ist
# bei 48 px nicht mehr aufloesbar und wuerde die Grafik zusaetzlich verkleinern.
magick "$SRC" -crop 1254x845+0+0 +repage -fuzz 12% -trim +repage "$WORK/graphic.png"
free_background "$WORK/graphic.png" "$WORK/graphic_free.png"

# Volles Logo fuer den Splash — dort ist genug Platz, die Schrift ist lesbar.
magick "$SRC" -fuzz 12% -trim +repage "$WORK/logo.png"
free_background "$WORK/logo.png" "$WORK/logo_free.png"

# Klassisches Icon: Motiv mit etwas Luft auf der Kartenfarbe.
magick -size 1024x1024 xc:"$CARD" \
  \( "$WORK/graphic_free.png" -resize 820x820 \) \
  -gravity center -composite "$WORK/icon.png"

# Adaptive-Icon-Vordergrund: Motiv auf rund 66 % der Flaeche, der Rest ist die
# Sicherheitszone, die Android je nach Launcher-Maske wegschneidet.
magick "$WORK/graphic_free.png" -resize 660x660 \
  -background none -gravity center -extent 1024x1024 "$WORK/foreground.png"

magick -size 1254x1254 xc:"$CARD" \
  \( "$WORK/logo_free.png" -resize 1080x1080 \) \
  -gravity center -composite "$WORK/splash.png"

# --- Android: klassische Mipmaps -----------------------------------------
# "Dichte:Kantenlaenge" -- bewusst kein assoziatives Array, das kann die
# mit macOS ausgelieferte Bash 3.2 nicht.
for entry in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  d="${entry%%:*}"
  size="${entry##*:}"
  mkdir -p "$ANDROID_RES/mipmap-$d"
  magick "$WORK/icon.png" -resize "${size}x${size}" \
    "$ANDROID_RES/mipmap-$d/ic_launcher.png"
  # Adaptive-Ebenen werden mit 108/48 der Basisgroesse gerendert.
  fg=$(( size * 108 / 48 ))
  magick "$WORK/foreground.png" -resize "${fg}x${fg}" \
    "$ANDROID_RES/mipmap-$d/ic_launcher_foreground.png"
  magick "$WORK/splash.png" -resize "$(( size * 4 ))x$(( size * 4 ))" \
    "$ANDROID_RES/mipmap-$d/launch_image.png"
done

# --- iOS: AppIcon in allen vom Contents.json verlangten Groessen ----------
# iOS erlaubt keinen Alphakanal in App-Icons.
ios_icon() { # $1 = Kantenlaenge in Pixeln, $2 = Dateiname
  magick "$WORK/icon.png" -resize "${1}x${1}" -background "$CARD" -alpha remove \
    -alpha off "$IOS_ICONS/$2"
}
ios_icon 40   Icon-App-20x20@2x.png
ios_icon 60   Icon-App-20x20@3x.png
ios_icon 20   Icon-App-20x20@1x.png
ios_icon 29   Icon-App-29x29@1x.png
ios_icon 58   Icon-App-29x29@2x.png
ios_icon 87   Icon-App-29x29@3x.png
ios_icon 40   Icon-App-40x40@1x.png
ios_icon 80   Icon-App-40x40@2x.png
ios_icon 120  Icon-App-40x40@3x.png
ios_icon 120  Icon-App-60x60@2x.png
ios_icon 180  Icon-App-60x60@3x.png
ios_icon 76   Icon-App-76x76@1x.png
ios_icon 152  Icon-App-76x76@2x.png
ios_icon 167  Icon-App-83.5x83.5@2x.png
ios_icon 1024 Icon-App-1024x1024@1x.png

# --- iOS: Launch-Bilder ---------------------------------------------------
magick "$WORK/splash.png" -resize 320x320 "$IOS_LAUNCH/LaunchImage.png"
magick "$WORK/splash.png" -resize 640x640 "$IOS_LAUNCH/LaunchImage@2x.png"
magick "$WORK/splash.png" -resize 960x960 "$IOS_LAUNCH/LaunchImage@3x.png"

echo "Icons und Splash-Bilder neu erzeugt."
