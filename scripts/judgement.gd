class_name Judgement
extends RefCounted

## Bewertet einen Treffer anhand der Abweichung zur Notenzeit.
## Die Fenster stammen aus dem Testkonzept (US4): Perfect bis +/- 50 ms,
## Great bis +/- 100 ms, darueber Miss. Abweichungen werden auf ganze
## Millisekunden gerundet (+50,4 ms = Perfect, +50,5 ms = Great).

enum { PERFECT, GREAT, MISS, KEINE }

const PERFECT_MS: float = 50.0
const GREAT_MS: float = 100.0
const TREFFER_MS: float = 180.0     # weiter weg gilt die Spur als leer

const PUNKTE_PERFECT: int = 300
const PUNKTE_GREAT: int = 100

const BEZEICHNUNG: Array[String] = ["PERFECT", "GREAT", "MISS", ""]


## abweichung_ms: Spielzeit minus Notenzeit (negativ = zu frueh)
static func bewerten(abweichung_ms: float) -> int:
	var a: float = absf(roundf(abweichung_ms))
	if a <= PERFECT_MS:
		return PERFECT
	if a <= GREAT_MS:
		return GREAT
	if a <= TREFFER_MS:
		return MISS
	return KEINE


static func punkte(wertung: int) -> int:
	match wertung:
		PERFECT:
			return PUNKTE_PERFECT
		GREAT:
			return PUNKTE_GREAT
		_:
			return 0
