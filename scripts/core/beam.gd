class_name Beam
extends RefCounted
## 一束粒子的状态（一次实验）

var energy := 1
var charge := 0
var lock_left := 0
var lock_used := false
var presses := 0
var streak := 0
var alive := true

func value() -> int:
	return Odds.value_at(energy)

func locked() -> bool:
	return lock_left > 0

func odds() -> PackedFloat64Array:
	return Odds.table(energy, locked())

## 加速一次。返回 {outcome, from, to, odds, lock_started, lock_ended, lost}
func accelerate(rng: RandomNumberGenerator) -> Dictionary:
	assert(alive)
	var p := odds()
	var was_locked := locked()
	var k := Odds.roll(p, rng)
	var from := energy
	presses += 1
	var res := {"outcome": k, "from": from, "odds": p, "lock_started": false, "lock_ended": false, "lost": false, "value_before": value()}
	if k == Odds.LOSS:
		alive = false
		res.lost = true
		res.to = from
		return res
	energy = clampi(energy + Odds.DELTA[k], 1, Odds.EMAX)
	streak = 0 if k == Odds.DETUNE or k == Odds.STABLE else streak + 1
	if was_locked:
		lock_left -= 1
		res.lock_ended = lock_left == 0
	elif not lock_used:
		charge = 0 if k == Odds.DETUNE else charge + Odds.CHARGE[k]
		if charge >= Odds.LOCK_NEED:
			charge = Odds.LOCK_NEED
			lock_left = Odds.LOCK_PRESSES
			lock_used = true
			res.lock_started = true
	res.to = energy
	return res
