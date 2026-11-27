class_name SpielAuswahl
extends RefCounted

## Uebergabe der gewaehlten Beatmap von der Songauswahl an den Spielbildschirm.

## Pfad der gewaehlten Beatmap, leer = Standard-Beatmap des Spielbildschirms.
static var beatmap_pfad: String = ""

## Zuletzt gewaehlter Song und Schwierigkeitsgrad (fuer die Rueckkehr in die Auswahl).
static var song_index: int = 0
static var grad: String = "leicht"
