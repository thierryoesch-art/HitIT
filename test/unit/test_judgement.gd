extends GutTest

## Modultests fuer die Bewertungslogik (F2), Testfall 3 im Testkonzept.
## Soll-Werte: Perfect bis +/- 50 ms, Great bis +/- 100 ms, darueber Miss.
## Abweichungen werden auf ganze Millisekunden gerundet.


func test_minus_101_ms_ist_miss() -> void:
	assert_eq(Judgement.bewerten(-101.0), Judgement.MISS, "-101 ms muss Miss sein")


func test_plus_101_ms_ist_miss() -> void:
	assert_eq(Judgement.bewerten(101.0), Judgement.MISS, "+101 ms muss Miss sein")


func test_great_an_den_grenzen() -> void:
	for abweichung in [-100.0, -51.0, 50.5, 51.0, 100.0]:
		assert_eq(Judgement.bewerten(abweichung), Judgement.GREAT,
				"%.1f ms muss Great sein" % abweichung)


func test_perfect_an_den_grenzen() -> void:
	for abweichung in [-50.0, 0.0, 50.0]:
		assert_eq(Judgement.bewerten(abweichung), Judgement.PERFECT,
				"%.1f ms muss Perfect sein" % abweichung)


func test_rundung_50_4_ms_ist_perfect() -> void:
	assert_eq(Judgement.bewerten(50.4), Judgement.PERFECT,
			"+50,4 ms wird auf 50 ms gerundet und ist Perfect")


func test_punkte_je_wertung() -> void:
	assert_eq(Judgement.punkte(Judgement.PERFECT), 300, "Perfect gibt 300 Punkte")
	assert_eq(Judgement.punkte(Judgement.GREAT), 100, "Great gibt 100 Punkte")
	assert_eq(Judgement.punkte(Judgement.MISS), 0, "Miss gibt 0 Punkte")
