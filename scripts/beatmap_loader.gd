class_name BeatmapLoader
extends RefCounted

## Liest eine Beatmap-Datei im Format aus Kapitel 4.2 des Konzeptberichts.
## Rueckgabe: { "ok": bool, "fehler": String, "daten": Dictionary }

const PFLICHTFELDER: Array[String] = [
	"titel", "interpret", "audiodatei", "lizenz", "quelle",
	"bpm", "startOffset", "spuren", "schwierigkeit", "noten",
]


static func laden(pfad: String) -> Dictionary:
	if not FileAccess.file_exists(pfad):
		return _fehler("Datei nicht gefunden: " + pfad)

	var datei: FileAccess = FileAccess.open(pfad, FileAccess.READ)
	if datei == null:
		return _fehler("Datei kann nicht gelesen werden: " + pfad)

	var text: String = datei.get_as_text()
	datei.close()

	var roh: Variant = JSON.parse_string(text)
	if typeof(roh) != TYPE_DICTIONARY:
		return _fehler("Kein gueltiges JSON-Objekt: " + pfad)

	var daten: Dictionary = roh

	for feld in PFLICHTFELDER:
		if not daten.has(feld):
			return _fehler("Pflichtfeld fehlt: " + feld)

	var spuren: int = int(daten["spuren"])
	if spuren < 3 or spuren > 4:
		return _fehler("Feld 'spuren' muss 3 oder 4 sein, ist: " + str(spuren))

	if typeof(daten["noten"]) != TYPE_ARRAY:
		return _fehler("Feld 'noten' muss eine Liste sein")

	var noten: Array = []
	var letzter_zeitpunkt: float = -1.0
	var nummer: int = 0

	for eintrag in daten["noten"]:
		nummer += 1
		if typeof(eintrag) != TYPE_DICTIONARY:
			return _fehler("Note %d ist kein Objekt" % nummer)
		if not eintrag.has("t") or not eintrag.has("spur") or not eintrag.has("typ"):
			return _fehler("Note %d: t, spur oder typ fehlt" % nummer)

		var zeitpunkt: float = float(eintrag["t"])
		var spur: int = int(eintrag["spur"])
		var typ: String = str(eintrag["typ"])

		if spur < 0 or spur >= spuren:
			return _fehler("Note %d: Spur %d liegt ausserhalb von 0 bis %d"
					% [nummer, spur, spuren - 1])
		if typ != "tap" and typ != "hold":
			return _fehler("Note %d: typ muss 'tap' oder 'hold' sein" % nummer)
		if zeitpunkt < letzter_zeitpunkt:
			return _fehler("Note %d: Noten muessen zeitlich aufsteigend sortiert sein" % nummer)
		letzter_zeitpunkt = zeitpunkt

		var dauer: float = 0.0
		if typ == "hold":
			if not eintrag.has("dauer"):
				return _fehler("Note %d: Hold-Note ohne 'dauer'" % nummer)
			dauer = float(eintrag["dauer"])
			if dauer <= 0.0:
				return _fehler("Note %d: 'dauer' muss groesser als 0 sein" % nummer)

		noten.append({
			"t": zeitpunkt,
			"spur": spur,
			"typ": typ,
			"dauer": dauer,
			"status": "offen",     # offen | gehalten | fertig | verpasst
			"wertung": -1,         # Index aus Judgement
		})

	daten["noten"] = noten
	daten["kennung"] = pfad.get_file().get_basename()
	return {"ok": true, "fehler": "", "daten": daten}


static func _fehler(meldung: String) -> Dictionary:
	return {"ok": false, "fehler": meldung, "daten": {}}
