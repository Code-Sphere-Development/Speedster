#!/bin/sh

# Xcode Cloud fuehrt dieses Skript direkt nach dem Klonen aus, bevor es
# das Xcode-Projekt anfasst. Es muss neben dem Xcode-Projekt liegen, also
# unter ios/ci_scripts/ -- an anderer Stelle findet Xcode Cloud es nicht.
#
# Warum es noetig ist: ios/Flutter/Generated.xcconfig ist bewusst nicht
# eingecheckt (ios/.gitignore), weil sie den lokalen Pfad zur
# Flutter-Installation enthaelt. Genau diese Datei definiert aber
# FLUTTER_BUILD_NAME und FLUTTER_BUILD_NUMBER, und Runner/Info.plist setzt
# sie als $(FLUTTER_BUILD_NAME) bzw. $(FLUTTER_BUILD_NUMBER) ein. Auf einem
# frisch geklonten Rechner fehlt die Datei -- die Version loest zu einer
# leeren Zeichenkette auf, und Release.xcconfig kann ihr #include nicht
# aufloesen.

set -e

FLUTTER_VERSION=3.47.2

# Die Projektwurzel aus dem eigenen Ort ableiten, nicht aus einer
# Umgebungsvariablen: das Skript liegt unter <wurzel>/ios/ci_scripts/, also
# sind zwei Ebenen darueber die Wurzel. CI_WORKSPACE ist je nach
# Xcode-Cloud-Version gesetzt, leer oder durch
# CI_PRIMARY_REPOSITORY_PATH ersetzt -- ein leeres `cd ""` faellt nicht auf
# und laesst den Rest im falschen Verzeichnis weiterlaufen.
REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

echo "--- Umgebung ---"
echo "Skript:                     $0"
echo "Projektwurzel:              $REPO_ROOT"
echo "CI_WORKSPACE:               ${CI_WORKSPACE:-<nicht gesetzt>}"
echo "CI_PRIMARY_REPOSITORY_PATH: ${CI_PRIMARY_REPOSITORY_PATH:-<nicht gesetzt>}"
ls -la pubspec.yaml ios/Flutter/

echo "--- Flutter $FLUTTER_VERSION holen ---"
git clone https://github.com/flutter/flutter.git \
    --depth 1 --branch "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
flutter precache --ios
flutter pub get

CONFIG=ios/Flutter/Generated.xcconfig

echo "--- Konfiguration erzeugen ---"
flutter build ios --release --no-codesign --config-only

# --config-only hat die Datei in einem Lauf nicht erzeugt, ohne dabei zu
# scheitern. Ein vollstaendiger Build erzeugt sie zuverlaessig; er kostet
# einige Minuten, ist aber allemal billiger als ein Lauf, der erst in Xcode
# an einer leeren Versionsnummer scheitert.
if [ ! -f "$CONFIG" ]; then
    echo "$CONFIG fehlt nach --config-only, vollstaendiger Build folgt."
    flutter build ios --release --no-codesign
fi

if [ ! -f "$CONFIG" ]; then
    echo "FEHLER: $CONFIG wurde nicht erzeugt."
    echo "Inhalt von ios/Flutter/:"
    ls -la ios/Flutter/
    exit 1
fi

echo "--- $CONFIG ---"
cat "$CONFIG"
