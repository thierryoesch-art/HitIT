class_name SongLibrary
extends RefCounted

## Liest alle Beatmaps eines Ordners und fasst sie pro Song zusammen.
## Ungueltige Beatmaps werden nicht angezeigt (Testkonzept US1, TF7), ihre
## Fehlermeldungen stehen in "fehler".

const ORDNER: String = "res://assets/beatmaps"

## Reihenfolge der Schwierigkeitsgrade in der Anzeige.
const GRADE: Array[String] = ["leicht", "schwer"]


## Ergebnis: {"songs": Array, "fehler": Array[String]}
## Jeder Song: {"titel", "interpret", "audiodatei", "dauer_ms", "grade": {grad: {"pfad", "kennung", "noten"}}}
static func laden(ordner: String = ORDNER) -> Dictionary:
	var songs: Dictionary = {}
	var fehler: Array[String] = []
	var dateien: PackedStringArray = DirAccess.get_files_at(ordner)
	dateien.sort()
	for datei in dateien:
		if not datei.ends_with(".json"):
			continue
		var pfad: String = ordner.path_join(datei)
		var ergebnis: Dictionary = BeatmapLoader.laden(pfad)
		if not ergebnis["ok"]:
			fehler.append("%s: %s" % [datei, ergebnis["fehler"]])
			continue
		var d: Dictionary = ergebnis["daten"]
		var schluessel: String = str(d["audiodatei"])
		if not songs.has(schluessel):
			songs[schluessel] = {"titel": str(d["titel"]), "interpret": str(d["interpret"]),
					"audiodatei": schluessel, "dauer_ms": 0, "grade": {}}
		var song: Dictionary = songs[schluessel]
		var ende: int = 0
		for n in d["noten"]:
			ende = maxi(ende, int(float(n["t"]) + float(n.get("dauer", 0))))
		song["dauer_ms"] = maxi(int(song["dauer_ms"]), ende)
		song["grade"][str(d["schwierigkeit"])] = {"pfad": pfad, "kennung": str(d["kennung"]),
				"noten": (d["noten"] as Array).size()}
	var liste: Array = songs.values()
	liste.sort_custom(func(a, b): return str(a["titel"]) < str(b["titel"]))
	return {"songs": liste, "fehler": fehler}


## Schwierigkeitsgrade eines Songs in Anzeigereihenfolge.
static func grade_von(song: Dictionary) -> Array[String]:
	var ergebnis: Array[String] = []
	for g in GRADE:
		if song["grade"].has(g):
			ergebnis.append(g)
	for g in song["grade"].keys():
		if not ergebnis.has(str(g)):
			ergebnis.append(str(g))
	return ergebnis
