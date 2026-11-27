class_name ScoreManager
extends RefCounted

## Fuehrt Punkte, Combo und die Trefferstatistik eines Durchgangs.
## Punkte pro Treffer = Grundpunkte x Multiplikator der aktuellen Combo (Testkonzept US4).

## Ab dieser Combo gilt der Multiplikator x2, x3 bzw. x4.
const COMBO_STUFEN: Array[int] = [10, 30, 50]

## Bonus fuer eine bis zum Ende gehaltene Hold-Note.
const HOLD_BONUS: int = 100

var punkte: int = 0
var combo: int = 0
var max_combo: int = 0
var anzahl_perfect: int = 0
var anzahl_great: int = 0
var anzahl_miss: int = 0
var gescheitert: bool = false

## Fail-Regel aus dem Konzeptbericht: ein Miss beendet den Song.
## Zum Testen auf false setzen.
var fail_bei_miss: bool = true


## Multiplikator fuer eine Combo: x1 bis 9, x2 ab 10, x3 ab 30, x4 ab 50.
static func multiplikator(aktuelle_combo: int) -> int:
	var faktor: int = 1
	for stufe in COMBO_STUFEN:
		if aktuelle_combo >= stufe:
			faktor += 1
	return faktor


func werten(wertung: int) -> void:
	match wertung:
		Judgement.PERFECT:
			anzahl_perfect += 1
			_treffer(wertung)
		Judgement.GREAT:
			anzahl_great += 1
			_treffer(wertung)
		Judgement.MISS:
			anzahl_miss += 1
			combo = 0
			if fail_bei_miss:
				gescheitert = true


func _treffer(wertung: int) -> void:
	combo += 1
	punkte += Judgement.punkte(wertung) * multiplikator(combo)
	if combo > max_combo:
		max_combo = combo


func hold_beendet() -> void:
	punkte += HOLD_BONUS


func anzahl_noten() -> int:
	return anzahl_perfect + anzahl_great + anzahl_miss


## Genauigkeit in Prozent (Perfect = 100 %, Great = 50 %, Miss = 0 %)
func genauigkeit() -> float:
	var gesamt: int = anzahl_noten()
	if gesamt == 0:
		return 0.0
	return (float(anzahl_perfect) + 0.5 * float(anzahl_great)) / float(gesamt) * 100.0
