class_name SaveStore
extends RefCounted

## Liest und schreibt die Spielstanddatei im Format aus Kapitel 4.2 des
## Konzeptberichts. Fehlt die Datei oder ist sie beschaedigt, wird mit
## Standardwerten weitergearbeitet - die App startet also auch nach einem Fehler.

const PFAD: String = "user://spielstand.json"
const VERSION: int = 1


static func standard() -> Dictionary:
	return {
		"version": VERSION,
		"audioOffset": 0,
		"musiklautstaerke": 0.8,
		"highscores": {},
	}


static func laden() -> Dictionary:
	if not FileAccess.file_exists(PFAD):
		return standard()
	var datei: FileAccess = FileAccess.open(PFAD, FileAccess.READ)
	if datei == null:
		return standard()
	var roh: Variant = JSON.parse_string(datei.get_as_text())
	datei.close()
	if typeof(roh) != TYPE_DICTIONARY:
		return standard()
	var daten: Dictionary = standard()
	for schluessel in daten.keys():
		if roh.has(schluessel):
			daten[schluessel] = roh[schluessel]
	return daten


static func speichern(daten: Dictionary) -> bool:
	var datei: FileAccess = FileAccess.open(PFAD, FileAccess.WRITE)
	if datei == null:
		return false
	datei.store_string(JSON.stringify(daten, "\t"))
	datei.close()
	return true


static func highscore(daten: Dictionary, schluessel: String) -> int:
	var hs: Dictionary = daten.get("highscores", {})
	if not hs.has(schluessel):
		return 0
	return int(hs[schluessel].get("punkte", 0))


## Gibt true zurueck, wenn ein neuer Highscore gesetzt wurde.
static func highscore_merken(daten: Dictionary, schluessel: String, punkte: int) -> bool:
	if punkte <= highscore(daten, schluessel):
		return false
	if not daten.has("highscores"):
		daten["highscores"] = {}
	daten["highscores"][schluessel] = {
		"punkte": punkte,
		"erreichtAm": Time.get_datetime_string_from_system(),
	}
	speichern(daten)
	return true
