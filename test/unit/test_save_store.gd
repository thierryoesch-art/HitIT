extends GutTest

## Modultests fuer den lokalen Spielstand (F11), Testfaelle 5 und 6 im Testkonzept.
## Achtung: Die Tests ueberschreiben user://spielstand.json.


func before_each() -> void:
	if FileAccess.file_exists(SaveStore.PFAD):
		DirAccess.remove_absolute(SaveStore.PFAD)


func test_ohne_datei_gibt_es_standardwerte() -> void:
	var daten: Dictionary = SaveStore.laden()
	assert_eq(int(daten["audioOffset"]), 0, "Standard-Offset 0 ms")
	assert_eq(SaveStore.highscore(daten, "song|einfach"), 0, "Noch kein Highscore")


func test_beschaedigte_datei_fuehrt_nicht_zum_absturz() -> void:
	var datei: FileAccess = FileAccess.open(SaveStore.PFAD, FileAccess.WRITE)
	datei.store_string("{ kaputt")
	datei.close()
	var daten: Dictionary = SaveStore.laden()
	assert_eq(int(daten["version"]), SaveStore.VERSION, "Beschaedigte Datei ergibt Standardwerte")


func test_highscore_wird_gespeichert_und_wieder_geladen() -> void:
	var daten: Dictionary = SaveStore.laden()
	assert_true(SaveStore.highscore_merken(daten, "song|einfach", 5000), "Erster Highscore")
	var neu_geladen: Dictionary = SaveStore.laden()
	assert_eq(SaveStore.highscore(neu_geladen, "song|einfach"), 5000,
			"Highscore ist nach dem Neuladen vorhanden")


func test_tieferer_score_ueberschreibt_highscore_nicht() -> void:
	var daten: Dictionary = SaveStore.laden()
	SaveStore.highscore_merken(daten, "song|einfach", 5000)
	assert_false(SaveStore.highscore_merken(daten, "song|einfach", 4000),
			"4000 ist kein neuer Highscore")
	assert_eq(SaveStore.highscore(daten, "song|einfach"), 5000, "Highscore bleibt 5000")


func test_offset_wird_gespeichert() -> void:
	var daten: Dictionary = SaveStore.laden()
	daten["audioOffset"] = -35
	assert_true(SaveStore.speichern(daten), "Speichern gelingt")
	assert_eq(int(SaveStore.laden()["audioOffset"]), -35, "Offset bleibt nach Neuladen -35 ms")
