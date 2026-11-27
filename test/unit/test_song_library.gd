extends GutTest

## Modultests fuer die Songbibliothek (F7, US1, US2), Testfaelle 1, 7 und 13 im Testkonzept.

const TEST_ORDNER: String = "user://test_bibliothek"


func after_each() -> void:
	for datei in DirAccess.get_files_at(TEST_ORDNER):
		DirAccess.remove_absolute(TEST_ORDNER.path_join(datei))


func test_fuenf_songs_mit_leicht_und_schwer() -> void:
	var songs: Array = SongLibrary.laden()["songs"]
	assert_eq(songs.size(), 5, "Die Bibliothek enthaelt 5 Songs")
	for song in songs:
		assert_true(song["grade"].has("leicht") and song["grade"].has("schwer"),
				"%s hat die Grade leicht und schwer" % song["titel"])


func test_schwer_hat_mindestens_1_5_fache_notendichte() -> void:
	for song in SongLibrary.laden()["songs"]:
		var leicht: int = int(song["grade"]["leicht"]["noten"])
		var schwer: int = int(song["grade"]["schwer"]["noten"])
		assert_true(float(schwer) >= 1.5 * float(leicht),
				"%s: %d Noten schwer, %d Noten leicht" % [song["titel"], schwer, leicht])


func test_musikdatei_zu_jedem_song_vorhanden() -> void:
	for song in SongLibrary.laden()["songs"]:
		assert_true(ResourceLoader.exists("res://" + str(song["audiodatei"])),
				"Musikdatei %s vorhanden" % song["audiodatei"])


func test_ungueltige_beatmap_wird_ausgeblendet() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_ORDNER)
	var gueltig: String = FileAccess.get_file_as_string("res://assets/beatmaps/demo_leicht.json")
	var f: FileAccess = FileAccess.open(TEST_ORDNER.path_join("gut_leicht.json"), FileAccess.WRITE)
	f.store_string(gueltig)
	f.close()
	f = FileAccess.open(TEST_ORDNER.path_join("kaputt_leicht.json"), FileAccess.WRITE)
	f.store_string("{ kein json")
	f.close()
	var ergebnis: Dictionary = SongLibrary.laden(TEST_ORDNER)
	assert_eq(ergebnis["songs"].size(), 1, "Nur die gueltige Beatmap erscheint")
	assert_eq(ergebnis["fehler"].size(), 1, "Die ungueltige Beatmap wird gemeldet, nicht angezeigt")
