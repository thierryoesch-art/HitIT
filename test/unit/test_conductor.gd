extends GutTest

## Modultests fuer die Pause im Conductor (F4 Spielsitzung, UC2 Pause), Uhrmodus ohne Musik.

var _c: Conductor


func before_each() -> void:
	_c = Conductor.new()
	_c.setup(null)


func test_spielzeit_laeuft() -> void:
	_c.start()
	OS.delay_msec(200)
	assert_gt(_c.song_time_ms(), 150.0, "Nach 0,2 s ist die Spielzeit groesser als 150 ms")


func test_pause_haelt_die_spielzeit_an() -> void:
	_c.start()
	OS.delay_msec(150)
	_c.pausieren()
	var t1: float = _c.song_time_ms()
	OS.delay_msec(300)
	assert_true(_c.ist_pausiert(), "Conductor ist pausiert")
	assert_eq(_c.song_time_ms(), t1, "Waehrend der Pause bleibt die Spielzeit stehen")


func test_fortsetzen_ohne_zeitsprung() -> void:
	_c.start()
	OS.delay_msec(150)
	_c.pausieren()
	var t1: float = _c.song_time_ms()
	OS.delay_msec(300)
	_c.fortsetzen()
	var t2: float = _c.song_time_ms()
	assert_almost_eq(t2, t1, 30.0, "Nach dem Fortsetzen geht es an derselben Stelle weiter")
