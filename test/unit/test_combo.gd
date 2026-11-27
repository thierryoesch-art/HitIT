extends GutTest

## Modultests fuer Punkte, Combo und Fail-Regel (F3), Testfaelle 2 und 3 im Testkonzept.
## Soll: Combo steigt pro Treffer um 1, Multiplikator x2 / x3 / x4 ab Combo 10 / 30 / 50.

var _score: ScoreManager


func before_each() -> void:
	_score = ScoreManager.new()


func test_combo_steigt_pro_treffer_um_eins() -> void:
	_score.werten(Judgement.PERFECT)
	_score.werten(Judgement.GREAT)
	_score.werten(Judgement.PERFECT)
	assert_eq(_score.combo, 3, "Nach 3 Treffern ist die Combo 3")


func test_erster_great_gibt_100_punkte() -> void:
	_score.werten(Judgement.GREAT)
	assert_eq(_score.punkte, 100, "Ein Great bei Combo 1 gibt 100 Punkte (Multiplikator x1)")


func test_20_perfect_ergeben_9300_punkte() -> void:
	for i in 20:
		_score.werten(Judgement.PERFECT)
	assert_eq(_score.punkte, 9300, "9 x 300 + 11 x 600 = 9300 Punkte")
	assert_eq(_score.max_combo, 20, "Maximale Combo 20")


func test_multiplikator_an_den_grenzen() -> void:
	var erwartet: Dictionary = {9: 1, 10: 2, 29: 2, 30: 3, 49: 3, 50: 4}
	for c in erwartet:
		assert_eq(ScoreManager.multiplikator(c), erwartet[c],
				"Combo %d ergibt Multiplikator x%d" % [c, erwartet[c]])


func test_hold_note_gibt_bonus() -> void:
	_score.hold_beendet()
	assert_eq(_score.punkte, 100, "Eine ganz gehaltene Hold-Note gibt 100 Bonuspunkte")


func test_miss_setzt_combo_zurueck_und_beendet_song() -> void:
	_score.werten(Judgement.PERFECT)
	_score.werten(Judgement.PERFECT)
	_score.werten(Judgement.MISS)
	assert_eq(_score.combo, 0, "Ein Miss setzt die Combo auf 0")
	assert_eq(_score.max_combo, 2, "Die maximale Combo bleibt erhalten")
	assert_true(_score.gescheitert, "Fail-Regel: ein Miss beendet den Song")


func test_genauigkeit() -> void:
	_score.fail_bei_miss = false
	_score.werten(Judgement.PERFECT)
	_score.werten(Judgement.GREAT)
	_score.werten(Judgement.MISS)
	_score.werten(Judgement.PERFECT)
	assert_almost_eq(_score.genauigkeit(), 62.5, 0.01,
			"(2 x 100 % + 1 x 50 % + 1 x 0 %) / 4 = 62,5 %")
