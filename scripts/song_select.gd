extends Node2D

## HitIT - Songauswahl (Startbildschirm).
##
## Zeigt alle Songs mit gueltiger Beatmap (Titel, Interpret, Dauer, Highscore),
## laesst den Schwierigkeitsgrad waehlen und startet den Spielbildschirm.
## Bedienung: Tippen/Klicken oder Pfeiltasten, Enter/Leertaste = spielen,
## - / + = Audio-Offset, Esc = beenden.

const SPIEL_SZENE: String = "res://main.tscn"

const FARBE_HINTERGRUND: Color = Color(0.06, 0.07, 0.12)
const FARBE_ZEILE: Color = Color(0.12, 0.14, 0.22)
const FARBE_AKTIV: Color = Color(0.20, 0.24, 0.42)
const FARBE_TEXT: Color = Color(0.95, 0.96, 1.0)
const FARBE_GRAU: Color = Color(0.62, 0.66, 0.78)
const FARBE_AKZENT: Color = Color(0.36, 0.84, 1.0)

const LISTE_Y: float = 190.0
const ZEILE_H: float = 118.0
const RAND: float = 32.0

const OFFSET_SCHRITT_MS: int = 10
const OFFSET_MIN_MS: int = -200
const OFFSET_MAX_MS: int = 200

var _songs: Array = []
var _fehler: Array = []
var _auswahl: int = 0
var _grad: String = "leicht"
var _speicher: Dictionary = {}
var _breite: float = 720.0
var _hoehe: float = 1280.0


func _ready() -> void:
	var bibliothek: Dictionary = SongLibrary.laden()
	_songs = bibliothek["songs"]
	_fehler = bibliothek["fehler"]
	_speicher = SaveStore.laden()
	_auswahl = clampi(SpielAuswahl.song_index, 0, maxi(0, _songs.size() - 1))
	_grad = SpielAuswahl.grad
	_grad_pruefen()
	_masse()
	get_viewport().size_changed.connect(_masse)


func _masse() -> void:
	var gr: Vector2 = get_viewport_rect().size
	_breite = gr.x
	_hoehe = gr.y
	queue_redraw()


func _grad_pruefen() -> void:
	if _songs.is_empty():
		return
	var grade: Array[String] = SongLibrary.grade_von(_songs[_auswahl])
	if not grade.has(_grad):
		_grad = grade[0]


# ---------------------------------------------------------------- Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				_waehlen(_auswahl - 1)
			KEY_DOWN, KEY_S:
				_waehlen(_auswahl + 1)
			KEY_LEFT, KEY_RIGHT, KEY_TAB:
				_grad_wechseln()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				spielen()
			KEY_MINUS:
				_offset_aendern(-OFFSET_SCHRITT_MS)
			KEY_EQUAL, KEY_PLUS:
				_offset_aendern(OFFSET_SCHRITT_MS)
			KEY_ESCAPE:
				get_tree().quit()
	elif (event is InputEventScreenTouch and event.pressed) or \
			(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_tippen(event.position)


func _tippen(pos: Vector2) -> void:
	for i in range(_songs.size()):
		if _zeile_rect(i).has_point(pos):
			_waehlen(i)
			return
	var grade: Array[String] = _aktuelle_grade()
	for i in range(grade.size()):
		if _grad_rect(i, grade.size()).has_point(pos):
			_grad = grade[i]
			queue_redraw()
			return
	if _spielen_rect().has_point(pos):
		spielen()


func _waehlen(index: int) -> void:
	if _songs.is_empty():
		return
	_auswahl = clampi(index, 0, _songs.size() - 1)
	_grad_pruefen()
	queue_redraw()


func _grad_wechseln() -> void:
	var grade: Array[String] = _aktuelle_grade()
	if grade.is_empty():
		return
	_grad = grade[(grade.find(_grad) + 1) % grade.size()]
	queue_redraw()


func _offset_aendern(delta_ms: int) -> void:
	var neu: int = clampi(int(_speicher.get("audioOffset", 0)) + delta_ms, OFFSET_MIN_MS, OFFSET_MAX_MS)
	_speicher["audioOffset"] = neu
	SaveStore.speichern(_speicher)
	queue_redraw()


## Startet den gewaehlten Song im gewaehlten Grad.
func spielen() -> void:
	if _songs.is_empty():
		return
	SpielAuswahl.beatmap_pfad = str(_songs[_auswahl]["grade"][_grad]["pfad"])
	SpielAuswahl.song_index = _auswahl
	SpielAuswahl.grad = _grad
	get_tree().change_scene_to_file(SPIEL_SZENE)


func _aktuelle_grade() -> Array[String]:
	if _songs.is_empty():
		return []
	return SongLibrary.grade_von(_songs[_auswahl])


# ---------------------------------------------------------------- Darstellung

func _zeile_rect(i: int) -> Rect2:
	return Rect2(RAND, LISTE_Y + float(i) * (ZEILE_H + 12.0), _breite - 2.0 * RAND, ZEILE_H)


func _grad_rect(i: int, anzahl: int) -> Rect2:
	var y: float = LISTE_Y + float(maxi(_songs.size(), 1)) * (ZEILE_H + 12.0) + 30.0
	var b: float = (_breite - 2.0 * RAND - 20.0 * float(anzahl - 1)) / float(anzahl)
	return Rect2(RAND + float(i) * (b + 20.0), y, b, 80.0)


func _spielen_rect() -> Rect2:
	var g: Rect2 = _grad_rect(0, 1)
	return Rect2(RAND, g.position.y + 110.0, _breite - 2.0 * RAND, 96.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, _breite, _hoehe), FARBE_HINTERGRUND)
	_text(Vector2(RAND, 92), "HitIT", 60, FARBE_TEXT)
	_text(Vector2(RAND, 142), "Song auswaehlen", 26, FARBE_GRAU)

	if _songs.is_empty():
		_text(Vector2(RAND, LISTE_Y + 40.0), "Keine gueltige Beatmap gefunden.", 26, FARBE_TEXT)
		return

	for i in range(_songs.size()):
		var song: Dictionary = _songs[i]
		var r: Rect2 = _zeile_rect(i)
		draw_rect(r, FARBE_AKTIV if i == _auswahl else FARBE_ZEILE)
		if i == _auswahl:
			draw_rect(Rect2(r.position, Vector2(8.0, r.size.y)), FARBE_AKZENT)
		_text(r.position + Vector2(28, 46), str(song["titel"]), 30, FARBE_TEXT)
		var dauer: int = int(song["dauer_ms"]) / 1000
		_text(r.position + Vector2(28, 86), "%s  -  %d:%02d" % [song["interpret"], dauer / 60, dauer % 60],
				20, FARBE_GRAU)
		var grad: String = _grad if i == _auswahl else SongLibrary.grade_von(song)[0]
		var hs: int = SaveStore.highscore(_speicher, _schluessel(song, grad))
		var hs_text: String = "Highscore " + ("-" if hs == 0 else str(hs))
		_text(r.position + Vector2(r.size.x - 250.0, 86), hs_text, 20, FARBE_GRAU)

	var grade: Array[String] = _aktuelle_grade()
	for i in range(grade.size()):
		var g: String = grade[i]
		var r: Rect2 = _grad_rect(i, grade.size())
		draw_rect(r, FARBE_AKTIV if g == _grad else FARBE_ZEILE)
		if g == _grad:
			draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6.0), Vector2(r.size.x, 6.0)), FARBE_AKZENT)
		var noten: int = int(_songs[_auswahl]["grade"][g]["noten"])
		_text(r.position + Vector2(24, 36), g.capitalize(), 26, FARBE_TEXT)
		_text(r.position + Vector2(24, 64), "%d Noten" % noten, 18, FARBE_GRAU)

	var s: Rect2 = _spielen_rect()
	draw_rect(s, FARBE_AKZENT)
	_text(s.position + Vector2(s.size.x * 0.5 - 70.0, 62), "SPIELEN", 36, FARBE_HINTERGRUND)

	_text(Vector2(RAND, _hoehe - 92.0), "Pfeiltasten: Song und Grad,  Enter: spielen,  Esc: beenden", 18,
			FARBE_GRAU)
	_text(Vector2(RAND, _hoehe - 60.0), "Audio-Offset %d ms  (- / + in 10-ms-Schritten)" %
			int(_speicher.get("audioOffset", 0)), 18, FARBE_GRAU)
	if not _fehler.is_empty():
		_text(Vector2(RAND, _hoehe - 28.0), "%d ungueltige Beatmap(s) ausgeblendet" % _fehler.size(), 18,
				FARBE_GRAU)


func _schluessel(song: Dictionary, grad: String) -> String:
	return "%s|%s" % [song["grade"][grad]["kennung"], grad]


func _text(pos: Vector2, inhalt: String, groesse: int, farbe: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, farbe)
