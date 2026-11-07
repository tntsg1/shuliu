class_name Run
extends RefCounted
## 一局：累计总分制考核（design/DECISIONS.md Q15）

const LINES := [580, 1410, 2370]
const PER_STAGE := 3

var seed_value := 0
var rng := RandomNumberGenerator.new()
var stage := 0            # 0..LINES.size()；等于 size 即通关
var experiments_left := PER_STAGE
var total := 0
var beam: Beam = null
var log: Array = []       # 每条 {outcome, from, to, exp}
var experiment_no := 0
## 显示概率 vs 实际频率：期望次数（概率累加）与实际次数
var expected := PackedFloat64Array([0, 0, 0, 0, 0])
var actual := PackedInt32Array([0, 0, 0, 0, 0])
var best_value := 0

func _init(s := 0) -> void:
	seed_value = s if s != 0 else int(Time.get_unix_time_from_system() * 1000.0) % 2147483647
	rng.seed = seed_value

func seed_text() -> String:
	var h := "%08X" % (seed_value & 0xFFFFFFFF)
	return h.substr(0, 4) + "-" + h.substr(4, 4)

func won() -> bool:
	return stage >= LINES.size()

func lost() -> bool:
	return not won() and experiments_left <= 0 and beam == null

func line() -> int:
	return LINES[mini(stage, LINES.size() - 1)]

func can_start() -> bool:
	return beam == null and not won() and experiments_left > 0

func start_experiment() -> void:
	assert(can_start())
	beam = Beam.new()
	experiment_no += 1

func accelerate() -> Dictionary:
	var r := beam.accelerate(rng)
	for k in 5:
		expected[k] += r.odds[k]
	actual[r.outcome] += 1
	log.push_front({"outcome": r.outcome, "from": r.from, "to": r.to, "exp": experiment_no})
	if log.size() > 40:
		log.pop_back()
	if r.lost:
		r.merge(_finish(0))
	return r

## 引出：兑现当前价值
func extract() -> Dictionary:
	var v := beam.value()
	best_value = maxi(best_value, v)
	return _finish(v)

## 结束本次实验；可能连过多个阶段（大爆分垫后续阶段）
func _finish(v: int) -> Dictionary:
	beam = null
	total += v
	experiments_left -= 1
	var passed: Array = []
	while not won() and total >= LINES[stage]:
		passed.append(stage)
		stage += 1
		experiments_left = PER_STAGE
	return {"gained": v, "passed": passed, "won": won(), "lost": lost()}
