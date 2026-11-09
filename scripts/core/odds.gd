class_name Odds
## 概率与价值（数值来源：design/BALANCE.md，tools/sim.py 反推）

## SUPER 超级同步：只在锁相期间出现（DECISIONS Q34）
enum { SUPER, PERFECT, SUCCESS, STABLE, DETUNE, LOSS }
const N := 6
const NAMES := ["超级同步", "完美同步", "加速成功", "保持稳定", "射频失谐", "束流丢失"]
const DELTA := [3, 2, 1, 0, -1, 0]
const CHARGE := [0, 2, 1, 0, 0, 0]

const BASE := 40.0
static var GROWTH := 1.40          # Q69：丢失提前变陡后成果涨快一点（1.32 → 1.40），机器人校准
const EMAX := 99
const LOCK_NEED := 6
const LOCK_PRESSES := 4

## 锚点：完美/成功/稳定/失谐/丢失（百分比）
## 2026-11-09 Q69 学《铸剑纳贡》：前两下几乎不丢，E3 起陡升（E5 约三成），逼玩家早做决定、靠饰品撑
const ANCHORS := {
	1: [10.0, 72.0, 12.0, 5.0, 1.0],
	2: [10.0, 70.0, 13.0, 5.0, 2.0],
	3: [9.0, 60.0, 12.0, 7.0, 12.0],
	4: [8.0, 52.0, 12.0, 6.0, 22.0],
	5: [8.0, 45.0, 11.0, 6.0, 30.0],
	9: [6.0, 32.0, 10.0, 7.0, 45.0],
	13: [5.0, 25.0, 8.0, 7.0, 55.0],
}

static func value_at(e: int) -> int:
	return roundi(BASE * pow(GROWTH, e - 1))

## 锁相期间超级同步的概率：能级越高越大（E5≈6%，E13≈15%），从“加速成功”里分出
static func super_chance(e: int) -> float:
	return clampf(0.06 + (e - 5) * 0.01125, 0.05, 0.18)

## 返回 N 个概率（0..1，和为 1）；锚点只有后 5 种，超级同步另算
static func table(e: int, lock := false) -> PackedFloat64Array:
	var keys := [1, 2, 3, 4, 5, 9, 13]
	var p: Array = []
	if e >= 13:
		p = ANCHORS[13].duplicate()
		var extra := minf(20.0, (e - 13) * 4.0)
		p[4] += extra
		p[1] -= extra * 0.7
		p[0] -= extra * 0.1
		p[2] -= extra * 0.2
		# E18 以后：丢失继续往上爬，但永远到不了 100%——成功总留着一丝（E50 约 7%、E99 约 2.6%）
		if e > 18:
			var more := 25.0 * (1.0 - exp(-(e - 18) / 20.0))
			var rest: float = 100.0 - p[4]
			var k: float = (rest - more) / rest
			for i in 4:
				p[i] *= k
			p[4] += more
	else:
		for i in range(keys.size() - 1):
			var a: int = keys[i]
			var b: int = keys[i + 1]
			if e >= a and e <= b:
				var t := float(e - a) / float(b - a)
				for k in 5:
					p.append(lerpf(ANCHORS[a][k], ANCHORS[b][k], t))
				break
	var out := PackedFloat64Array([0.0])
	var s := 0.0
	for k in 5:
		var v := maxf(0.0, p[k])
		# 锁相：只剩完美同步 / 加速成功（+ 超级同步），稳定、失谐、丢失都没有（Q69）
		if lock and k + 1 >= STABLE:
			v = 0.0
		out.append(v)
		s += v
	for k in N:
		out[k] /= s
	if lock:
		add_super(out, e)
	return out

## 锁相：把超级同步从加速成功里分出来（就地修改）
static func add_super(q: PackedFloat64Array, e: int) -> void:
	var sc := minf(super_chance(e), q[SUCCESS])
	q[SUPER] += sc
	q[SUCCESS] -= sc

## 按概率抽取一个结果
static func roll(p: PackedFloat64Array, rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	var acc := 0.0
	for k in N:
		acc += p[k]
		if r < acc:
			return k
	return SUCCESS if p[LOSS] == 0.0 else LOSS

## 概率分配器：在基础概率上叠加百分点修正（deltas，0..1 量纲）。
## 被修正的结果按修正后取值（不小于 0），剩余概率按比例分给未被修正的结果；
## 若修正后已超过 100%，再整体按比例压回。保证五项非负、总和为 1。
static func apply_mods(p: PackedFloat64Array, d: PackedFloat64Array) -> PackedFloat64Array:
	var q := PackedFloat64Array()
	q.resize(N)
	var mod_sum := 0.0
	var unmod_sum := 0.0
	for k in N:
		if d[k] != 0.0:
			q[k] = maxf(0.0, p[k] + d[k])
			mod_sum += q[k]
		else:
			q[k] = p[k]
			unmod_sum += p[k]
	var rest := 1.0 - mod_sum
	if rest >= 0.0 and unmod_sum > 0.0:
		for k in N:
			if d[k] == 0.0:
				q[k] *= rest / unmod_sum
	else:
		var s := 0.0
		for k in N:
			if d[k] == 0.0:
				q[k] = 0.0
			s += q[k]
		for k in N:
			q[k] /= maxf(s, 1e-9)
	return q

## 只在“至少普通成功”的结果里按原比例抽
static func roll_at_least_success(p: PackedFloat64Array, rng: RandomNumberGenerator) -> int:
	var s := p[SUPER] + p[PERFECT] + p[SUCCESS]
	if s <= 0.0:
		return SUCCESS
	var r := rng.randf() * s
	if r < p[SUPER]:
		return SUPER
	return PERFECT if r < p[SUPER] + p[PERFECT] else SUCCESS

static func is_good(k: int) -> bool:
	return k == SUPER or k == PERFECT or k == SUCCESS
