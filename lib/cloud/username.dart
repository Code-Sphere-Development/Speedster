/// Regeln für den Benutzernamen, gespiegelt aus der Cloud
/// (`User::USERNAME_RULES` bzw. `App\Support\ValidatesUsername`).
///
/// Die App validiert vorab, damit ein Tippfehler nicht erst nach einem
/// Netzwerk-Roundtrip auffällt. Der Server bleibt die entscheidende
/// Instanz — vor allem für die Eindeutigkeit, die lokal grundsätzlich
/// nicht prüfbar ist. Die Meldungstexte sind wörtlich vom Server
/// übernommen, damit derselbe Fehler nicht in zwei Formulierungen
/// auftaucht.
library;

final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');

/// Bringt eine Eingabe in die Form, in der sie gespeichert wird.
///
/// Der Server normalisiert nur die Kleinschreibung (`Str::lower`) und
/// lässt die Regex über Leerzeichen entscheiden. Hier wird zusätzlich
/// getrimmt, weil eine Handytastatur gern ein unsichtbares Leerzeichen
/// anhängt und ein Formatfehler dafür nicht erklärbar wäre. Gesendet
/// wird der getrimmte Wert, der Server sieht also genau das, was er
/// auch speichert — die Regel selbst bleibt unverändert.
String normaliseUsername(String value) => value.trim().toLowerCase();

/// Woran eine Eingabe scheitert, oder `null`, wenn sie den Regeln
/// entspricht.
///
/// Bewusst ohne Text: die App spricht seit der Zweisprachigkeit auch
/// Englisch, und eine hier festgeschriebene deutsche Meldung erschien
/// dort mitten in einer englischen Oberflaeche. Den Text waehlt die
/// Oberflaeche aus ihren eigenen Uebersetzungen -- er ist woertlich vom
/// Server uebernommen, damit derselbe Fehler nicht in zwei
/// Formulierungen auftaucht.
enum UsernameProblem { empty, format }

UsernameProblem? validateUsername(String value) {
  final username = normaliseUsername(value);
  if (username.isEmpty) {
    return UsernameProblem.empty;
  }
  if (_usernamePattern.hasMatch(username)) {
    return null;
  }
  return UsernameProblem.format;
}
