class_name Conductor
extends RefCounted

## Liefert die Spielzeit in Millisekunden seit Songbeginn.
##
## Die rohe Abspielposition von Godot springt blockweise und liegt vor dem, was
## tatsaechlich aus dem Lautsprecher kommt. Deshalb wird die Zeit seit dem letzten
## Mischvorgang dazugerechnet und die Ausgabeverzoegerung abgezogen - genau so, wie
## es die Godot-Dokumentation ("Gameplay mit Audio und Musik synchronisieren")
## beschreibt.
##
## Ist kein Musikstueck geladen (Testbetrieb ohne Audiodatei), laeuft die Zeit
## ersatzweise ueber die Systemuhr. Das Spiel ist dann spielbar, aber der
## Machbarkeitsnachweis zur Audio-Latenz braucht zwingend eine echte Audiodatei.

var _player: AudioStreamPlayer = null
var _running: bool = false
var _clock_mode: bool = false
var _start_usec: int = 0
var _pausiert: bool = false
var _pause_zeit_ms: float = 0.0
var _pause_usec: int = 0

## Vom Benutzer kalibrierter Versatz in Millisekunden (positiv = Noten spaeter werten)
var audio_offset_ms: float = 0.0


func setup(player: AudioStreamPlayer) -> void:
	_player = player


func start() -> void:
	_clock_mode = _player == null or _player.stream == null
	_pausiert = false
	if not _clock_mode:
		_player.stream_paused = false
		_player.play()
	_start_usec = Time.get_ticks_usec()
	_running = true


func stop() -> void:
	_running = false
	_pausiert = false
	if _player != null and _player.playing:
		_player.stop()


## Haelt Musik und Spielzeit an (Pause-Dialog oder App im Hintergrund).
func pausieren() -> void:
	if not _running or _pausiert:
		return
	_pause_zeit_ms = song_time_ms()
	_pausiert = true
	_pause_usec = Time.get_ticks_usec()
	if not _clock_mode:
		_player.stream_paused = true


## Setzt Musik und Spielzeit an der angehaltenen Stelle fort.
func fortsetzen() -> void:
	if not _pausiert:
		return
	_pausiert = false
	if _clock_mode:
		_start_usec += Time.get_ticks_usec() - _pause_usec
	else:
		_player.stream_paused = false


func ist_pausiert() -> bool:
	return _pausiert


func is_clock_mode() -> bool:
	return _clock_mode


## Spielzeit in Millisekunden seit Songbeginn.
func song_time_ms() -> float:
	if not _running:
		return 0.0
	if _pausiert:
		return _pause_zeit_ms
	if _clock_mode:
		var elapsed: float = float(Time.get_ticks_usec() - _start_usec) / 1000.0
		return elapsed - audio_offset_ms
	var t: float = _player.get_playback_position()
	t += AudioServer.get_time_since_last_mix()
	t -= AudioServer.get_output_latency()
	return t * 1000.0 - audio_offset_ms


## Laenge des Songs in Millisekunden, 0 wenn unbekannt.
func song_length_ms() -> float:
	if _clock_mode or _player == null or _player.stream == null:
		return 0.0
	return _player.stream.get_length() * 1000.0
