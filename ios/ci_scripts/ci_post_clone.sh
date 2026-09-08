#!/bin/sh

# Xcode Cloud fuehrt dieses Skript direkt nach dem Klonen aus, bevor es
# das Xcode-Projekt anfasst. Es muss neben dem Xcode-Projekt liegen, also
# unter ios/ci_scripts/ -- an anderer Stelle findet Xcode Cloud es nicht.
#
# Warum es ueberhaupt noetig ist: ios/Flutter/Generated.xcconfig ist
# bewusst nicht eingecheckt (ios/.gitignore), weil sie den lokalen Pfad zur
# Flutter-Installation enthaelt. Genau diese Datei definiert aber
# FLUTTER_BUILD_NAME und FLUTTER_BUILD_NUMBER, und Runner/Info.plist setzt
# sie als $(FLUTTER_BUILD_NAME) bzw. $(FLUTTER_BUILD_NUMBER) ein. Auf einem
# frisch geklonten Rechner fehlt die Datei -- die Version loest damit zu
# einer leeren Zeichenkette auf, und Xcode Cloud scheitert bereits daran,
# das Projekt zu lesen. Zusaetzlich koennte Release.xcconfig ihr #include
# nicht aufloesen.
#
# Das Skript holt deshalb Flutter und erzeugt die Datei, bevor Xcode baut.

set -e

# Angeheftet auf die Version, mit der lokal entwickelt wird. Ein
# gleitendes "stable" hiesse, dass ein Flutter-Release die Pipeline
# umwirft, ohne dass sich am Projekt etwas geaendert hat.
FLUTTER_VERSION=3.47.2

echo "Flutter $FLUTTER_VERSION holen..."
git clone https://github.com/flutter/flutter.git \
    --depth 1 --branch "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# CI_WORKSPACE zeigt auf die Wurzel des geklonten Repositoriums; das
# Flutter-Projekt liegt dort, nicht im ios-Ordner.
cd "$CI_WORKSPACE"

flutter --version
flutter precache --ios
flutter pub get

# --config-only erzeugt Generated.xcconfig und die uebrigen abgeleiteten
# Dateien, ohne selbst zu bauen -- bauen und signieren ist danach Aufgabe
# von Xcode Cloud.
flutter build ios --release --no-codesign --config-only

echo "Generated.xcconfig:"
cat ios/Flutter/Generated.xcconfig
