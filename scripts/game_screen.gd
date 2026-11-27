extends Node2D

## HitIT - Spielbildschirm (Version 1.0).
##
## Spielt die in der Songauswahl gewaehlte Beatmap: Spielzeit aus der Musik
## (conductor), Tiles in drei bis vier Spuren, Bewertung Perfect/Great/Miss, Combo
## mit Multiplikator, Fail-Regel (Miss oder Tipp in leere Spur), Pause, Ergebnis,
## lokaler Highscore und Kalibrierung des Audio-Offsets.

## Beatmap, wenn der Spielbildschirm direkt (ohne Songauswahl) gestartet wird.
const BEATMAP_PFAD: String = "res://assets/beatmaps/demo_leicht.json"

## Szene der Songauswahl (Zurueck mit Esc).
const AUSWAHL_SZENE: String = "res://song_select.tscn"

## Zeit, die ein Tile vom oberen Rand bis zur Trefferlinie braucht.
const ANFLUG_MS: float = 1400.0

## Wie lange eine Hold-Note vor dem Ende losgelassen werden darf (Testkonzept US3).
const HOLD_GNADE_MS: float = 100.0

## Wartezeit nach dem Ende der letzten Note, bis das Ergebnis erscheint.
const ENDE_NACHLAUF_MS: float = 800.0

## So lange bleibt die Bewertung (PERFECT, GREAT, MISS) sichtbar.
const WERTUNG_ANZEIGE_MS: float = 450.0

## Lage der Trefferlinie als Anteil der Bildschirmhoehe (von oben).
const TREFFERLINIE_ANTEIL: float = 0.78

## Deckkraft des dunklen Schleiers ueber Start- und Ergebnisanzeige.
const SCHLEIER_DECKKRAFT: float = 0.78

## Audio-Offset: Schrittweite und Grenzen in Millisekunden (Testkonzept US8).
const OFFSET_SCHRITT_MS: int = 10
const OFFSET_MIN_MS: int = -200
const OFFSET_MAX_MS: int = 200

const ZUSTAND_FEHLER: int = 0
const ZUSTAND_BEREIT: int = 1
const ZUSTAND_LAEUFT: int = 2
const ZUSTAND_ENDE: int = 3
const ZUSTAND_PAUSE: int = 4

## Groesse der Pause-Schaltflaeche oben rechts (in Pixeln).
const PAUSE_KNOPF: float = 96.0

const FARBE_HINTERGRUND := Color("101322")
const FARBE_SPUR_A := Color("181c30")
const FARBE_SPUR_B := Color("1e2238")
const FARBE_SPUR_AKTIV := Color("2b3356")
const FARBE_LINIE := Color("6f7bd0")
const FARBE_TAP := Color("4fc3f7")
const FARBE_HOLD := Color("7e6cf0")
const FARBE_TEXT := Color("e8ecff")
const FARBE_GRAU := Color("8690b5")

var _conductor: Conductor
var _score: ScoreManager
var _speicher: Dictionary = {}

var _beatmap: Dictionary = {}
var _noten: Array = []
var _spuren: int = 4
var _fehlertext: String = ""

var _zustand: int = ZUSTAND_BEREIT
var _gescheitert: bool = false
var _neuer_highscore: bool = false

var _spur_haelt: Array = []
var _touch_spur: Dictionary = {}
var _maus_spur: int = -1

var _letzte_wertung: int = Judgement.KEINE
var _letzte_wertung_zeit: float = -99999.0

var _breite: float = 720.0
var _hoehe: float = 1280.0
var _trefferlinie_y: float = 980.0
var _spurbreite: float = 180.0

var _tasten: Array = []


# ---------------------------------------------------------------- Start

func _ready() -> void:
	_conductor = Conductor.new()
	_conductor.setup($MusicPlayer)
	_speicher = SaveStore.laden()
	_conductor.audio_offset_ms = float(_speicher.get("audioOffset", 0))
	_masse_berechnen()
	_laden()
	get_viewport().size_changed.connect(_masse_berechnen)


func _masse_berechnen() -> void:
	var gr: Vector2 = get_viewport_rect().size
	_breite = gr.x
	_hoehe = gr.y
	_trefferlinie_y = _hoehe * TREFFERLINIE_ANTEIL
	_spurbreite = _breite / float(_spuren)


func _laden() -> void:
	var pfad: String = SpielAuswahl.beatmap_pfad if SpielAuswahl.beatmap_pfad != "" else BEATMAP_PFAD
	var ergebnis: Dictionary = BeatmapLoader.laden(pfad)
	if not ergebnis["ok"]:
		_zustand = ZUSTAND_FEHLER
		_fehlertext = ergebnis["fehler"]
		return

	_beatmap = ergebnis["daten"]
	_noten = _beatmap["noten"]
	_spuren = int(_beatmap["spuren"])
	_masse_berechnen()

	_tasten = [KEY_D, KEY_F, KEY_J, KEY_K]
	if _spuren == 3:
		_tasten = [KEY_D, KEY_F, KEY_J]

	_spur_haelt = []
	for i in range(_spuren):
		_spur_haelt.append(false)

	_musik_laden()

	_score = ScoreManager.new()
	_zustand = ZUSTAND_BEREIT
	_gescheitert = false
	_neuer_highscore = false
	_letzte_wertung = Judgement.KEINE


func _musik_laden() -> void:
	var pfad: String = "res://" + str(_beatmap.get("audiodatei", ""))
	if ResourceLoader.exists(pfad):
		$MusicPlayer.stream = load(pfad)
	else:
		$MusicPlayer.stream = null
	$MusicPlayer.volume_db = linear_to_db(
			clampf(float(_speicher.get("musiklautstaerke", 0.8)), 0.0, 1.0))


func _neustart() -> void:
	_conductor.stop()
	for note in _noten:
		note["status"] = "offen"
		note["wertung"] = -1
	_score = ScoreManager.new()
	for i in range(_spur_haelt.size()):
		_spur_haelt[i] = false
	_touch_spur.clear()
	_maus_spur = -1
	_gescheitert = false
	_neuer_highscore = false
	_letzte_wertung = Judgement.KEINE
	_zustand = ZUSTAND_BEREIT


func _starten() -> void:
	_zustand = ZUSTAND_LAEUFT
	_conductor.start()


## Pause-Dialog oeffnen: Musik und Spielzeit halten an.
func _pausieren() -> void:
	if _zustand != ZUSTAND_LAEUFT:
		return
	_conductor.pausieren()
	_zustand = ZUSTAND_PAUSE


func _fortsetzen() -> void:
	if _zustand != ZUSTAND_PAUSE:
		return
	_conductor.fortsetzen()
	_zustand = ZUSTAND_LAEUFT


## Zurueck zur Songauswahl; ohne Songauswahl wird das Spiel beendet.
func _zur_auswahl() -> void:
	_conductor.stop()
	if ResourceLoader.exists(AUSWAHL_SZENE):
		get_tree().change_scene_to_file(AUSWAHL_SZENE)
	else:
		get_tree().quit()


## Geht die App in den Hintergrund (Anruf, Home-Taste, Fensterwechsel), pausiert das Spiel.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_pausieren()


# ---------------------------------------------------------------- Ablauf

func _process(_delta: float) -> void:
	if _zustand == ZUSTAND_LAEUFT:
		_aktualisieren()
	queue_redraw()


func _aktualisieren() -> void:
	var zeit: float = _conductor.song_time_ms()
	var letztes_ende: float = 0.0
	var alle_fertig: bool = true

	for note in _noten:
		var ende: float = float(note["t"]) + float(note["dauer"])
		if ende > letztes_ende:
			letztes_ende = ende

		match str(note["status"]):
			"offen":
				alle_fertig = false
				if zeit - float(note["t"]) > Judgement.TREFFER_MS:
					_miss_werten(note, zeit)
			"gehalten":
				alle_fertig = false
				if zeit >= ende:
					note["status"] = "fertig"
					_score.hold_beendet()
				elif not _spur_haelt[int(note["spur"])] and zeit < ende - HOLD_GNADE_MS:
					_miss_werten(note, zeit)

	if _score.gescheitert:
		_beenden(true)
		return

	if alle_fertig and zeit > letztes_ende + ENDE_NACHLAUF_MS:
		_beenden(false)


## Eine Note als Miss werten (verpasst oder Hold-Note zu frueh losgelassen).
func _miss_werten(note: Dictionary, zeit: float) -> void:
	note["status"] = "verpasst"
	note["wertung"] = Judgement.MISS
	_score.werten(Judgement.MISS)
	_wertung_zeigen(Judgement.MISS, zeit)


## Schluessel des Highscores aus Kennung und Schwierigkeit, z. B. "demo_einfach|einfach".
func _highscore_schluessel() -> String:
	return "%s|%s" % [_beatmap.get("kennung", "song"), _beatmap.get("schwierigkeit", "standard")]


func _beenden(gescheitert: bool) -> void:
	_zustand = ZUSTAND_ENDE
	_gescheitert = gescheitert
	_conductor.stop()
	_neuer_highscore = SaveStore.highscore_merken(_speicher, _highscore_schluessel(), _score.punkte)


func _wertung_zeigen(wertung: int, zeit: float) -> void:
	_letzte_wertung = wertung
	_letzte_wertung_zeit = zeit


# ---------------------------------------------------------------- Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var spur: int = _tasten.find(event.keycode)
		if spur >= 0 and spur < _spuren:
			if event.pressed:
				_spur_gedrueckt(spur)
			else:
				_spur_losgelassen(spur)
			return
		if event.pressed:
			_sondertaste(event.keycode)
		return

	if event is InputEventScreenTouch:
		if event.pressed and _knopf_oder_pause(event.position):
			return
		var spur_t: int = _spur_fuer_x(event.position.x)
		if event.pressed:
			_touch_spur[event.index] = spur_t
			_spur_gedrueckt(spur_t)
		else:
			var alt: int = int(_touch_spur.get(event.index, -1))
			if alt >= 0:
				_spur_losgelassen(alt)
			_touch_spur.erase(event.index)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _knopf_oder_pause(event.position):
			return
		if event.pressed:
			_maus_spur = _spur_fuer_x(event.position.x)
			_spur_gedrueckt(_maus_spur)
		elif _maus_spur >= 0:
			_spur_losgelassen(_maus_spur)
			_maus_spur = -1


## Tipp auf die Pause-Schaltflaeche oder Tipp waehrend der Pause; true = Ereignis verbraucht.
func _knopf_oder_pause(pos: Vector2) -> bool:
	if _zustand == ZUSTAND_PAUSE:
		_fortsetzen()
		return true
	if _zustand == ZUSTAND_LAEUFT and _pause_knopf().has_point(pos):
		_pausieren()
		return true
	return false


func _pause_knopf() -> Rect2:
	return Rect2(_breite - PAUSE_KNOPF - 16.0, 16.0, PAUSE_KNOPF, PAUSE_KNOPF)


func _sondertaste(keycode: int) -> void:
	match keycode:
		KEY_SPACE:
			if _zustand == ZUSTAND_BEREIT:
				_starten()
			elif _zustand == ZUSTAND_ENDE:
				_neustart()
			elif _zustand == ZUSTAND_PAUSE:
				_fortsetzen()
		KEY_P:
			if _zustand == ZUSTAND_LAEUFT:
				_pausieren()
			elif _zustand == ZUSTAND_PAUSE:
				_fortsetzen()
		KEY_R:
			if _zustand != ZUSTAND_FEHLER:
				_neustart()
		KEY_ESCAPE:
			if _zustand == ZUSTAND_LAEUFT:
				_pausieren()
			else:
				_zur_auswahl()
		KEY_MINUS:
			_offset_aendern(-OFFSET_SCHRITT_MS)
		KEY_EQUAL, KEY_PLUS:
			_offset_aendern(OFFSET_SCHRITT_MS)


func _offset_aendern(delta_ms: int) -> void:
	var neu: int = clampi(int(_conductor.audio_offset_ms) + delta_ms, OFFSET_MIN_MS, OFFSET_MAX_MS)
	_conductor.audio_offset_ms = float(neu)
	_speicher["audioOffset"] = neu
	SaveStore.speichern(_speicher)


func _spur_fuer_x(x: float) -> int:
	return clampi(int(x / _spurbreite), 0, _spuren - 1)


func _spur_gedrueckt(spur: int) -> void:
	if spur < 0 or spur >= _spuren:
		return
	if _zustand == ZUSTAND_BEREIT:
		_starten()
		return
	if _zustand == ZUSTAND_ENDE:
		_neustart()
		return
	if _zustand != ZUSTAND_LAEUFT:
		return

	_spur_haelt[spur] = true

	var zeit: float = _conductor.song_time_ms()
	var beste: int = -1
	var beste_abweichung: float = 0.0

	for i in range(_noten.size()):
		var note: Dictionary = _noten[i]
		if int(note["spur"]) != spur or str(note["status"]) != "offen":
			continue
		var abweichung: float = zeit - float(note["t"])
		if abs(abweichung) > Judgement.TREFFER_MS:
			continue
		if beste < 0 or abs(abweichung) < abs(beste_abweichung):
			beste = i
			beste_abweichung = abweichung

	if beste < 0:
		# Tipp in eine leere Spur zaehlt wie ein Miss (Testkonzept US5).
		_score.werten(Judgement.MISS)
		_wertung_zeigen(Judgement.MISS, zeit)
		if _score.gescheitert:
			_beenden(true)
		return

	var treffer: Dictionary = _noten[beste]
	var wertung: int = Judgement.bewerten(beste_abweichung)
	treffer["wertung"] = wertung
	_score.werten(wertung)
	_wertung_zeigen(wertung, zeit)

	if wertung == Judgement.MISS:
		treffer["status"] = "verpasst"
	elif str(treffer["typ"]) == "hold":
		treffer["status"] = "gehalten"
	else:
		treffer["status"] = "fertig"

	if _score.gescheitert:
		_beenden(true)


func _spur_losgelassen(spur: int) -> void:
	if spur < 0 or spur >= _spur_haelt.size():
		return
	_spur_haelt[spur] = false


# ---------------------------------------------------------------- Darstellung

func _draw() -> void:
	draw_rect(Rect2(0, 0, _breite, _hoehe), FARBE_HINTERGRUND)

	if _zustand == ZUSTAND_FEHLER:
		_text(Vector2(40, _hoehe * 0.4), "Beatmap konnte nicht geladen werden", 30, FARBE_TEXT)
		_text(Vector2(40, _hoehe * 0.4 + 44), _fehlertext, 20, FARBE_GRAU)
		return

	_spuren_zeichnen()
	_noten_zeichnen()
	_hud_zeichnen()

	if _zustand == ZUSTAND_BEREIT:
		_start_overlay()
	elif _zustand == ZUSTAND_ENDE:
		_ergebnis_overlay()
	elif _zustand == ZUSTAND_PAUSE:
		_pause_overlay()
	elif _zustand == ZUSTAND_LAEUFT:
		var k: Rect2 = _pause_knopf()
		draw_rect(k, Color(FARBE_HINTERGRUND, 0.6))
		draw_rect(Rect2(k.position + Vector2(k.size.x * 0.32, k.size.y * 0.25),
				Vector2(k.size.x * 0.12, k.size.y * 0.5)), FARBE_TEXT)
		draw_rect(Rect2(k.position + Vector2(k.size.x * 0.56, k.size.y * 0.25),
				Vector2(k.size.x * 0.12, k.size.y * 0.5)), FARBE_TEXT)


func _spuren_zeichnen() -> void:
	for i in range(_spuren):
		var x: float = float(i) * _spurbreite
		var farbe: Color = FARBE_SPUR_A if i % 2 == 0 else FARBE_SPUR_B
		if _zustand == ZUSTAND_LAEUFT and _spur_haelt.size() > i and _spur_haelt[i]:
			farbe = FARBE_SPUR_AKTIV
		draw_rect(Rect2(x, 0, _spurbreite, _hoehe), farbe)
		draw_line(Vector2(x, 0), Vector2(x, _hoehe), FARBE_HINTERGRUND, 2.0)

	draw_line(Vector2(0, _trefferlinie_y), Vector2(_breite, _trefferlinie_y), FARBE_LINIE, 4.0)

	if not _tasten.is_empty():
		for i in range(_spuren):
			var beschriftung: String = OS.get_keycode_string(_tasten[i])
			_text(Vector2(float(i) * _spurbreite + _spurbreite * 0.5 - 8.0,
					_trefferlinie_y + 46.0), beschriftung, 24, FARBE_GRAU)


func _noten_zeichnen() -> void:
	var zeit: float = _conductor.song_time_ms()
	var kopf_hoehe: float = max(18.0, _hoehe * 0.022)
	var rand: float = _spurbreite * 0.08

	for note in _noten:
		var status: String = str(note["status"])
		if status == "fertig" or status == "verpasst":
			continue

		var start: float = float(note["t"])
		var ende: float = start + float(note["dauer"])
		var y_kopf: float = _y_fuer(start, zeit)
		var y_ende: float = _y_fuer(ende, zeit)

		if y_ende < -200.0 or y_kopf > _hoehe + 200.0:
			continue

		var x: float = float(int(note["spur"])) * _spurbreite + rand
		var b: float = _spurbreite - 2.0 * rand

		if str(note["typ"]) == "hold":
			var oben: float = min(y_ende, y_kopf)
			var unten: float = max(y_ende, y_kopf)
			if status == "gehalten":
				oben = min(oben, _trefferlinie_y)
				unten = min(unten, _trefferlinie_y)
			draw_rect(Rect2(x + b * 0.2, oben, b * 0.6, max(unten - oben, 4.0)),
					Color(FARBE_HOLD, 0.55))
			draw_rect(Rect2(x, y_kopf - kopf_hoehe * 0.5, b, kopf_hoehe), FARBE_HOLD)
		else:
			draw_rect(Rect2(x, y_kopf - kopf_hoehe * 0.5, b, kopf_hoehe), FARBE_TAP)


func _y_fuer(note_ms: float, zeit_ms: float) -> float:
	var fortschritt: float = 1.0 - (note_ms - zeit_ms) / ANFLUG_MS
	return fortschritt * _trefferlinie_y


func _hud_zeichnen() -> void:
	var punkte_text: String = "0"
	if _score != null:
		punkte_text = str(_score.punkte)
	_text(Vector2(24, 54), punkte_text, 44, FARBE_TEXT)
	_text(Vector2(24, 92), str(_beatmap.get("titel", "")) + "  -  "
			+ str(_beatmap.get("interpret", "")), 18, FARBE_GRAU)
	_text(Vector2(24, 118), "Schwierigkeit: " + str(_beatmap.get("schwierigkeit", "")), 18,
			FARBE_GRAU)

	if _zustand == ZUSTAND_LAEUFT:
		if _score != null and _score.combo > 1:
			_text(Vector2(_breite * 0.5 - 40.0, _hoehe * 0.42), "%dx" % _score.combo, 52, FARBE_TEXT)

		var zeit: float = _conductor.song_time_ms()
		if _letzte_wertung != Judgement.KEINE and zeit - _letzte_wertung_zeit < WERTUNG_ANZEIGE_MS:
			_text(Vector2(_breite * 0.5 - 60.0, _hoehe * 0.50),
					Judgement.BEZEICHNUNG[_letzte_wertung], 34, FARBE_LINIE)

	var fuss: String = "Offset %d ms  (- / + anpassen)" % int(_conductor.audio_offset_ms)
	if _conductor.is_clock_mode():
		fuss += "   |   OHNE AUDIODATEI - Zeit laeuft ueber die Systemuhr"
	_text(Vector2(24, _hoehe - 28.0), fuss, 17, FARBE_GRAU)


func _start_overlay() -> void:
	_schleier()
	var y: float = _hoehe * 0.34
	_text(Vector2(_breite * 0.5 - 70.0, y), "HitIT", 56, FARBE_TEXT)
	_text(Vector2(40, y + 60.0), str(_beatmap.get("titel", "")) + "  -  "
			+ str(_beatmap.get("interpret", "")), 22, FARBE_TEXT)
	_text(Vector2(40, y + 110.0), "Tippen oder Leertaste zum Starten", 24, FARBE_LINIE)

	var tastenliste: String = ""
	for t in _tasten:
		tastenliste += OS.get_keycode_string(t) + "  "
	_text(Vector2(40, y + 170.0), "Spuren: " + tastenliste, 20, FARBE_GRAU)
	_text(Vector2(40, y + 200.0), "P = Pause,  R = Neustart,  Esc = Songauswahl,  - / + = Offset",
			20, FARBE_GRAU)

	var hs: int = SaveStore.highscore(_speicher, _highscore_schluessel())
	_text(Vector2(40, y + 240.0), "Highscore: " + ("-" if hs == 0 else str(hs)), 20, FARBE_GRAU)


func _ergebnis_overlay() -> void:
	_schleier()
	var y: float = _hoehe * 0.28
	var titel: String = "GAME OVER" if _gescheitert else "Song beendet"
	_text(Vector2(40, y), titel, 46, FARBE_TEXT)

	var zeilen: Array = [
		"Punkte: %d" % _score.punkte,
		"Genauigkeit: %.1f %%" % _score.genauigkeit(),
		"Groesste Combo: %d" % _score.max_combo,
		"Perfect: %d    Great: %d    Miss: %d" % [_score.anzahl_perfect,
				_score.anzahl_great, _score.anzahl_miss],
	]
	for i in range(zeilen.size()):
		_text(Vector2(40, y + 70.0 + float(i) * 38.0), str(zeilen[i]), 24, FARBE_TEXT)

	if _neuer_highscore:
		_text(Vector2(40, y + 240.0), "Neuer Highscore!", 26, FARBE_LINIE)

	_text(Vector2(40, y + 300.0), "Tippen oder R = nochmals,  Esc = Songauswahl", 22, FARBE_GRAU)


func _pause_overlay() -> void:
	_schleier()
	var y: float = _hoehe * 0.34
	_text(Vector2(40, y), "PAUSE", 56, FARBE_TEXT)
	_text(Vector2(40, y + 70.0), "Tippen, Leertaste oder P = weiter", 24, FARBE_LINIE)
	_text(Vector2(40, y + 110.0), "R = Neustart,  Esc = Songauswahl", 22, FARBE_GRAU)
	_text(Vector2(40, y + 150.0), "Punkte: %d    Combo: %d" % [_score.punkte, _score.combo], 22,
			FARBE_TEXT)


func _schleier() -> void:
	draw_rect(Rect2(0, 0, _breite, _hoehe), Color(FARBE_HINTERGRUND, SCHLEIER_DECKKRAFT))


func _text(pos: Vector2, inhalt: String, groesse: int, farbe: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse, farbe)
