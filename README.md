# HitIT – Version 1.0

Rhythmusspiel aus dem Konzeptbericht, umgesetzt mit **Godot 4** (getestet mit Godot 4.3).
Zielplattform ist Android im Hochformat; zum Testen läuft das Spiel auch am Computer.

## Starten

1. Godot 4 öffnen → **Importieren** → in diesen Ordner wechseln → `project.godot` wählen.
2. **F5** drücken. Es erscheint die Songauswahl.
3. Song und Schwierigkeitsgrad wählen und **Spielen** tippen (oder Enter).

## Steuerung

| Eingabe | Wirkung |
|---|---|
| Songauswahl: Tippen oder Pfeiltasten | Song und Grad wählen, Enter/Leertaste = spielen |
| `D` `F` `J` `K` | Spur 0 bis 3 (bei 3 Spuren nur `D` `F` `J`) |
| Tippen / Klicken | Spur nach x-Position, Halten für Hold-Notes |
| `P`, `Esc` oder Tipp oben rechts | Pause (weiter mit Tippen, Leertaste oder `P`) |
| `-` / `+` | Audio-Offset um 10 ms verschieben, −200 bis +200 ms (wird gespeichert) |
| `R` | Neustart des Songs |
| `Esc` | Zurück zur Songauswahl; in der Songauswahl: Beenden |

## Songs und Musik

Es gibt fünf Songs mit je einer Beatmap «leicht» und «schwer» (`assets/beatmaps`,
Musik in `assets/songs`). Die Musik ist eine eigene Komposition: Sie wird mit
`tools/songs.py` (Python, numpy, ffmpeg) synthetisch erzeugt und unter **CC0** freigegeben.
Die Melodietöne liegen genau auf den Noten der leichten Beatmap; «schwer» hat zusätzliche
Noten auf den Achteln (mindestens 1,5-fache Notendichte).

## Android-APK erstellen

Die Exportvorlage `export_presets.cfg` ist eingerichtet (Paket `ch.gibb.hitit`, Hochformat,
**keine Berechtigungen**, Tests und GUT werden nicht exportiert). Einmalig nötig:

1. Godot → Editor → **Exportvorlagen verwalten** → Vorlagen für 4.3 herunterladen.
2. Android SDK (z. B. über Android Studio) und OpenJDK 17 installieren und unter
   Editor → Editoreinstellungen → Export → Android die Pfade eintragen.
3. Projekt → **Exportieren** → Preset „Android“ → **Projekt exportieren** → `HitIT.apk`.

## Was umgesetzt ist

* **song_select.gd** – Songauswahl mit Titel, Interpret, Dauer, Highscore und Grad (UC1, UC4).
* **song_library.gd** – liest alle Beatmaps, fasst sie pro Song zusammen, blendet ungültige aus.
* **conductor.gd** – Spielzeit aus der Abspielposition der Musik, korrigiert um die Zeit seit
  dem letzten Mischvorgang und die Ausgabeverzögerung; Pause und Fortsetzen.
* **beatmap_loader.gd** – liest und **validiert** das Beatmap-Format (Pflichtfelder,
  Spurnummern, Sortierung, Hold-Dauer).
* **judgement.gd** – Perfect ±50 ms, Great ±100 ms, darüber Miss; Abweichung gerundet.
* **score_manager.gd** – Punkte mit Multiplikator ×2 / ×3 / ×4 ab Combo 10 / 30 / 50,
  Combo, Genauigkeit, Fail-Regel.
* **save_store.gd** – `user://spielstand.json` mit Audio-Offset und Highscores.
* **game_screen.gd** – Spuren, Tiles, Tap- und Hold-Notes, Eingabe über Tastatur, Maus und
  Touch, Pause (auch automatisch, wenn die App in den Hintergrund geht), Game Over, Ergebnis.

## Bewusst nicht umgesetzt

* Song anspielen in der Songauswahl (UC6, KANN-Anforderung).
* Eigene Einstellungsseite (UC5): Der Audio-Offset wird direkt in der Songauswahl und im
  Spiel mit `-` / `+` eingestellt.

## Offene Entscheide

* **Anflugzeit** `ANFLUG_MS` in `game_screen.gd` (1400 ms) bestimmt, wie schnell die Tiles
  fallen – das ist der wichtigste Regler für das Spielgefühl.
* **Trefferfenster** in `judgement.gd` – nach den ersten Messungen auf echten Geräten
  überprüfen.

## Änderungen in Version 0.2 (27.11.2026)

* Trefferfenster gemäss Testkonzept: Great bis 100 ms (vorher 110 ms), Abweichung gerundet.
* Combo-Multiplikator ×2 / ×3 / ×4 ab Combo 10 / 30 / 50 (vorher: Combo wurde zu den Punkten addiert).
* Fail-Regel gemäss Testkonzept (US5): auch ein Tipp in eine leere Spur zählt als Miss.
* Audio-Offset auf −200 bis +200 ms begrenzt (US8); Hold-Toleranz 100 ms (US3).
* Aufgeräumt: doppelter Miss-Code in `_miss_werten()`, Highscore-Schlüssel in
  `_highscore_schluessel()`, harte Zahlen als benannte Konstanten.
* Combo und Bewertung werden auf Start- und Ergebnisanzeige nicht mehr durchscheinend gezeichnet.

## Änderungen in Version 1.0 (27.11.2026)

* Songauswahl als Startbildschirm, fünf Songs mit eigener Musik, je «leicht» und «schwer».
* Pause-Dialog, automatische Pause im Hintergrund.
* Audio-Offset in 10-ms-Schritten (Testkonzept US8).
* Android-Exportvorlage ohne Berechtigungen.

## Tests

Die Unit-Tests liegen in `test/unit` und laufen mit dem Addon GUT 9.3 (liegt in `addons/gut`).

* Im Editor: Projekt → Projekteinstellungen → Plugins → „Gut“ aktivieren, dann unten im
  GUT-Panel `res://test/unit` wählen und **Run All** klicken.
* Im Terminal (im Projektordner):
  `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit`

Erwartet: 33 Tests, alle bestanden.

## Messung für den Machbarkeitsnachweis

1. Projekt auf zwei verschiedene Android-Geräte exportieren.
2. Mit Kopfhörer spielen und mit `-` / `+` den Offset suchen, bei dem sich Treffer richtig
   anfühlen.
3. Den gefundenen Wert je Gerät notieren – das ist das Ergebnis, das in den Konzeptbericht
   und in den Projektbericht gehört.
