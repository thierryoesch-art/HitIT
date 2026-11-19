# HitIT – Grundgerüst

Lauffähiges Grundgerüst des Spiels aus dem Konzeptbericht, umgesetzt mit **Godot 4**
(getestet gegen die Godot-4-API, Projektdatei auf 4.2 gesetzt – neuere 4.x öffnen es
ebenfalls).

## Starten

1. Godot 4 öffnen → **Importieren** → in diesen Ordner wechseln → `project.godot` wählen.
2. **F5** drücken.
3. Tippen oder Leertaste startet den Song.

## Steuerung

| Eingabe | Wirkung |
|---|---|
| `D` `F` `J` `K` | Spur 0 bis 3 (bei 3 Spuren nur `D` `F` `J`) |
| Tippen / Klicken | Spur nach x-Position – so wird später auf dem Handy gespielt |
| `-` / `+` | Audio-Offset um 5 ms verschieben (wird gespeichert) |
| `R` | Neustart |
| `Esc` | Beenden |

## Musik einsetzen

Das Projekt läuft **ohne** Audiodatei: Fehlt die Musik, zählt die Zeit über die Systemuhr
weiter, damit man das Spiel sofort ausprobieren kann. Im Spiel steht dann unten
„OHNE AUDIODATEI".

Für den Machbarkeitsnachweis braucht es echte Musik:

1. Eine lizenzfreie Datei als `assets/songs/demo.ogg` ablegen (Godot mag `.ogg` am liebsten).
2. In `assets/beatmaps/demo_einfach.json` Titel, Interpret, `lizenz` und `quelle` eintragen.
3. `bpm` und `startOffset` an den Song anpassen; `startOffset` ist der Zeitpunkt des ersten
   Schlags in Millisekunden.

Die Demo-Beatmap hat 96 Noten bei 128 BPM (ca. 50 Sekunden) und ist nur ein Platzhalter.

## Was umgesetzt ist

* **conductor.gd** – Spielzeit aus der Abspielposition der Musik, korrigiert um die Zeit seit
  dem letzten Mischvorgang und die Ausgabeverzögerung des Geräts. Das ist der Punkt, auf dem
  der ganze Variantenentscheid beruht.
* **beatmap_loader.gd** – liest und **validiert** das Beatmap-Format aus Kapitel 4.2
  (Pflichtfelder, Spurnummern, Sortierung). Fehlerhafte Beatmaps werden nicht geladen.
* **judgement.gd** – Perfect ±50 ms, Great ±110 ms, Miss bis ±180 ms (Anforderung A10).
* **score_manager.gd** – Punkte, Combo, Genauigkeit, Fail-Regel.
* **save_store.gd** – `user://spielstand.json` mit Audio-Offset und Highscores,
  Format wie im Konzeptbericht.
* **game_screen.gd** – Spuren, Tiles, Tap- und Hold-Notes, Eingabe über Tastatur, Maus und
  Touch, HUD, Game Over und Ergebnisanzeige.

## Was noch fehlt

* Startbildschirm, Songauswahl und Einstellungen als eigene Szenen (UC1, UC5) – aktuell gibt
  es nur den Spielbildschirm mit einer fest eingetragenen Beatmap.
* Pause-Dialog (UC2, Ausnahme „Person pausiert").
* Song anspielen (UC6).
* Grafik und Ton: keine Trefferklänge, keine Effekte, keine Schriftart – bewusst roh
  gehalten.

## Offene Entscheide

* **Fail-Regel:** Aktuell beendet *jeder* Miss den Song (`fail_bei_miss` in
  `score_manager.gd`). Das macht das Spiel sehr hart. Zum Testen auf `false` setzen und im
  Team festlegen, was gelten soll.
* **Anflugzeit** `ANFLUG_MS` in `game_screen.gd` (1400 ms) bestimmt, wie schnell die Tiles
  fallen – das ist der wichtigste Regler für das Spielgefühl.
* **Trefferfenster** in `judgement.gd` – nach den ersten Messungen auf echten Geräten
  überprüfen und den Wert in der Studie (Z4, A10) nachführen.

## Messung für den Machbarkeitsnachweis

1. Projekt auf zwei verschiedene Android-Geräte exportieren.
2. Mit Kopfhörer spielen und mit `-` / `+` den Offset suchen, bei dem sich Treffer richtig
   anfühlen.
3. Den gefundenen Wert je Gerät notieren – das ist das Ergebnis, das in den Konzeptbericht
   und in den Projektbericht gehört.
