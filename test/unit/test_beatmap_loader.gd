extends GutTest

## Modultests fuer das Laden und Pruefen der Beatmaps (F5), Testfall 7 im Testkonzept.
## Fehlerhafte Beatmaps duerfen nicht geladen werden und duerfen keinen Absturz ausloesen.

const DEMO_PFAD: String = "res://assets/beatmaps/demo_leicht.json"
const TEST_PFAD: String = "user://test_beatmap.json"


func _gueltige_beatmap() -> Dictionary:
	return {
		"titel": "Test", "interpret": "HitIT-Team", "audiodatei": "assets/songs/test.ogg",
		"lizenz": "CC0", "quelle": "eigene Aufnahme", "bpm": 120.0, "startOffset": 0,
		"spuren": 4, "schwierigkeit": "einfach",
		"noten": [
			{"t": 500, "spur": 0, "typ": "tap"},
			{"t": 1000, "spur": 3, "typ": "hold", "dauer": 400},
		],
	}


func _schreiben(inhalt: String) -> void:
	var datei: FileAccess = FileAccess.open(TEST_PFAD, FileAccess.WRITE)
	datei.store_string(inhalt)
	datei.close()


func after_each() -> void:
	if FileAccess.file_exists(TEST_PFAD):
		DirAccess.remove_absolute(TEST_PFAD)


func test_demo_beatmap_wird_geladen() -> void:
	var ergebnis: Dictionary = BeatmapLoader.laden(DEMO_PFAD)
	assert_true(ergebnis["ok"], "Die Demo-Beatmap ist gueltig")
	assert_eq(ergebnis["daten"]["noten"].size(), 96, "Die Demo-Beatmap hat 96 Noten")


func test_gueltige_beatmap_wird_geladen() -> void:
	_schreiben(JSON.stringify(_gueltige_beatmap()))
	var ergebnis: Dictionary = BeatmapLoader.laden(TEST_PFAD)
	assert_true(ergebnis["ok"], "Gueltige Beatmap wird geladen")
	assert_eq(ergebnis["daten"]["kennung"], "test_beatmap", "Kennung aus dem Dateinamen")


func test_fehlende_datei() -> void:
	var ergebnis: Dictionary = BeatmapLoader.laden("user://gibt_es_nicht.json")
	assert_false(ergebnis["ok"], "Fehlende Datei wird abgelehnt")


func test_kein_json() -> void:
	_schreiben("das ist kein JSON")
	assert_false(BeatmapLoader.laden(TEST_PFAD)["ok"], "Text ohne JSON wird abgelehnt")


func test_pflichtfeld_fehlt() -> void:
	var daten: Dictionary = _gueltige_beatmap()
	daten.erase("lizenz")
	_schreiben(JSON.stringify(daten))
	var ergebnis: Dictionary = BeatmapLoader.laden(TEST_PFAD)
	assert_false(ergebnis["ok"], "Beatmap ohne Lizenz wird abgelehnt")
	assert_string_contains(ergebnis["fehler"], "lizenz")


func test_spur_ausserhalb() -> void:
	var daten: Dictionary = _gueltige_beatmap()
	daten["noten"][0]["spur"] = 4
	_schreiben(JSON.stringify(daten))
	assert_false(BeatmapLoader.laden(TEST_PFAD)["ok"], "Spur 4 bei 4 Spuren wird abgelehnt")


func test_noten_nicht_sortiert() -> void:
	var daten: Dictionary = _gueltige_beatmap()
	daten["noten"][0]["t"] = 2000
	_schreiben(JSON.stringify(daten))
	assert_false(BeatmapLoader.laden(TEST_PFAD)["ok"], "Unsortierte Noten werden abgelehnt")


func test_hold_ohne_dauer() -> void:
	var daten: Dictionary = _gueltige_beatmap()
	daten["noten"][1].erase("dauer")
	_schreiben(JSON.stringify(daten))
	assert_false(BeatmapLoader.laden(TEST_PFAD)["ok"], "Hold-Note ohne Dauer wird abgelehnt")
