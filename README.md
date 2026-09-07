# Speedster

Flutter-App zur Aufzeichnung von Fahrten: Geschwindigkeit, Route, Statistiken
und eine Heatmap der häufig gefahrenen Strecken.

Das Laravel-Backend liegt in einem eigenen Repository:
[Code-Sphere-Development/Speedster_Cloud](https://github.com/Code-Sphere-Development/Speedster_Cloud).
Ändert sich die Rasterung der Heatmap in `lib/heat/heat_grid.dart`, muss der
Spiegel dort nachgezogen werden — `test/fixtures/heat_parity*.json` ist der
gemeinsame Vertrag beider Seiten.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
