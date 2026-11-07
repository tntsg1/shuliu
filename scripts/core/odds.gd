class_name Odds
## 概率与价值（数值来源：design/BALANCE.md，tools/sim.py 反推）

enum { PERFECT, SUCCESS, STABLE, DETUNE, LOSS }
const NAMES := ["完美同步", "加速成功", "保持稳定", "射频失谐", "束流丢失"]
const DELTA := [2, 1, 0, -1, 0]
const CHARGE := [2, 1, 0, 0, 0]

const BASE := 40.0
const GROWTH := 1.32
const EMAX := 20
const LOCK_NEED := 6
const LOCK_PRESSES := 4

## 锚点：完美/成功/稳定/失谐/丢失（百分比）
const ANCHORS := {
	1: [10.0, 69.0, 15.0, 5.0, 1.0],
	5: [9.0, 62.0, 14.0, 10.0, 5.0],
	9: [7.0, 50.0, 13.0, 14.0, 16.0],
	13: [5.0, 33.0, 10.0, 12.0, 40.0],
}

static func value_at(e: int) -> int:
	return roundi(BASE * pow(GROWTH, e - 1))

## 返回 5 个概率（0..1，和为 1）
static func table(e: int, lock := false) -> PackedFloat64Array:
	var keys := [1, 5, 9, 13]
	var p: Array = []
	if e >= 13:
		p = ANCHORS[13].duplicate()
		var extra := minf(30.0, (e - 13) * 6.0)
		p[4] += extra
		p[1] -= extra * 0.7
		p[0] -= extra * 0.1
		p[2] -= extra * 0.2
	else:
		for i in range(keys.size() - 1):
			var a: int = keys[i]
			var b: int = keys[i + 1]
			if e >= a and e <= b:
				var t := float(e - a) / float(b - a)
				for k in 5:
					p.append(lerpf(ANCHORS[a][k], ANCHORS[b][k], t))
				break
	var out := PackedFloat64Array()
	var s := 0.0
	for k in 5:
		var v := maxf(0.0, p[k])
		if lock and k == LOSS:
			v = 0.0
		out.append(v)
		s += v
	for k in 5:
		out[k] /= s
	return out

## 按概率抽取一个结果
static func roll(p: PackedFloat64Array, rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	var acc := 0.0
	for k in 5:
		acc += p[k]
		if r < acc:
			return k
	return SUCCESS if p[LOSS] == 0.0 else LOSS
