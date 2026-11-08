class_name Run
extends RefCounted
## 一局：累计总分制考核 + 经费/商店 + 饰品与设备效果（纯逻辑，可无界面测试）
## 提交规则（DECISIONS Q30）：够线可选提交；次数用完强制提交。
## 结算顺序（GDD 4.6）：最终概率 → 抽取 → 重抽 → 结果转化 → 破碎抵挡 → 科研抢救 → 执行与后续效果

const LINES := [580, 1410, 2370]
const PER_STAGE := 3
const START_MONEY := 30
const REFRESH_BASE := 3

var seed_value := 0
var rng := RandomNumberGenerator.new()
var shop_rng := RandomNumberGenerator.new()   # 商店单独一路随机，买不买东西都不影响实验结果序列
var stage := 0
var experiments_left := PER_STAGE
var total := 0
var beam: Beam = null
var log: Array = []
var experiment_no := 0
var failed := false
var expected := PackedFloat64Array([0, 0, 0, 0, 0, 0])
var actual := PackedInt32Array([0, 0, 0, 0, 0, 0])
var best_value := 0
# —— 经费与构筑 ——
var money := START_MONEY
var relics: Array = []        # 饰品 id
var devices: Array = []       # 设备 id
var uses := {}                # 有使用次数的饰品剩余次数
var paper_used := false       # 校长稿纸：每局一次
var stage_badge_used := false
var stage_pen_used := false
var rejected_stacks := 0
var best_potential := 0       # 本局到过的最高潜在成果（忘记保存的数据）
var lost_bonus := 0           # 下一次引出额外加上的科研点
var stage_lost_data_used := false
# —— 商店 ——
var offers: Array = []        # [{id, sold}]
var refresh_cost := REFRESH_BASE

func _init(s := 0) -> void:
	seed_value = s if s != 0 else int(Time.get_unix_time_from_system() * 1000.0) % 2147483647
	rng.seed = seed_value
	shop_rng.seed = seed_value ^ 0x5bd1e995
	roll_shop()

func seed_text() -> String:
	var h := "%08X" % (seed_value & 0xFFFFFFFF)
	return h.substr(0, 4) + "-" + h.substr(4, 4)

## 攒满几格进入锁相（没洗的咖啡杯 -1）
func lock_need() -> int:
	return Odds.LOCK_NEED - (1 if has("coffee_cup") else 0)

func has(id: String) -> bool:
	return relics.has(id) or devices.has(id)

func won() -> bool:
	return stage >= LINES.size()

func lost() -> bool:
	return failed

func line() -> int:
	return LINES[mini(stage, LINES.size() - 1)]

func can_submit() -> bool:
	return beam == null and not won() and not failed and total >= line()

func must_submit() -> bool:
	return beam == null and not won() and not failed and experiments_left <= 0

func can_start() -> bool:
	return beam == null and not won() and not failed and experiments_left > 0

func start_experiment() -> void:
	assert(can_start())
	beam = Beam.new()
	experiment_no += 1
	if has("wipes"):
		beam.wipes = true

# —— 概率与价值 ——
func odds() -> PackedFloat64Array:
	var b := beam
	var p := Odds.table(b.energy)
	var d := PackedFloat64Array([0, 0, 0, 0, 0, 0])
	if has("magnet_sc"): d[Odds.LOSS] -= 0.05
	if has("collimator"): d[Odds.LOSS] -= 0.04
	if has("injector_hi"): d[Odds.LOSS] += 0.05
	if has("quad_array"): d[Odds.SUCCESS] += 0.08
	if has("rf_backup"): d[Odds.PERFECT] += 0.04
	if has("koi") and b.koi > 0: d[Odds.LOSS] -= 0.02 * b.koi
	if has("ultimatum") and b.presses >= 3: d[Odds.LOSS] += 0.10
	if has("fast_clock") and b.presses == 0: d[Odds.LOSS] += 0.05
	if has("duty_roster") and b.presses == 0: d[Odds.SUCCESS] += 0.15
	if b.wipes: d[Odds.LOSS] -= 0.06
	var q := Odds.apply_mods(p, d)
	if b.locked():
		q[Odds.LOSS] = 0.0
		var s := 0.0
		for k in Odds.N: s += q[k]
		for k in Odds.N: q[k] /= s
		if b.full_sync:
			# 完全同步：保持稳定、射频失谐都不出现，按比例分给其余结果
			q[Odds.STABLE] = 0.0
			q[Odds.DETUNE] = 0.0
			var s2 := 0.0
			for k in Odds.N: s2 += q[k]
			for k in Odds.N: q[k] /= s2
		Odds.add_super(q, b.energy)
		if has("nobel_list") and b.energy >= 12:
			Odds.add_super(q, b.energy)
	return q

## 本次是否必定至少普通成功
func guaranteed() -> bool:
	if beam == null:
		return false
	return beam.guaranteed_next or (has("ultimatum") and beam.presses < 3)

## 当前倍率（显示与引出都用它，保证所见即所得）
func multiplier() -> float:
	var m := 1.0
	if has("injector_hi"): m *= 1.5
	if has("collimator"): m *= 0.9
	if beam != null and has("chair"): m *= 1.0 + beam.chair
	if beam != null and has("third_draft"): m *= 1.0 + beam.draft
	if beam != null and has("marker") and not beam.had_detune: m *= 1.15
	if has("dean_pen"): m *= 0.8 if stage_pen_used else 3.0
	if has("budget"): m *= 1.0 + minf(0.5, floor(money / 10.0) * 0.05)
	return m

func potential() -> int:
	return 0 if beam == null else int(floor(beam.value_base() * multiplier()))

# —— 加速 ——
func accelerate() -> Dictionary:
	var b := beam
	var p := odds()
	var g := guaranteed()
	var k := Odds.roll_at_least_success(p, rng) if g else Odds.roll(p, rng)
	var trig: Array = []
	var from := b.energy
	if b.guaranteed_next:
		b.guaranteed_next = false
		trig.append(["note100", "必定成功"])
	# 重抽
	if k == Odds.DETUNE and has("eraser") and int(uses.get("eraser", 0)) > 0:
		uses["eraser"] -= 1
		k = Odds.roll(p, rng)
		trig.append(["eraser", "橡皮重抽"])
		if uses["eraser"] <= 0:
			relics.erase("eraser")
	# 结果转化
	if k == Odds.DETUNE and has("diagnostic") and not b.diag_used:
		b.diag_used = true
		k = Odds.STABLE
		trig.append(["diagnostic", "诊断仪拦下失谐"])
	if k == Odds.DETUNE and has("tape_roll") and not b.tape_used:
		b.tape_used = true
		k = Odds.STABLE
		trig.append(["tape_roll", "胶带粘住了"])
	if k == Odds.DETUNE and has("badge") and not stage_badge_used:
		stage_badge_used = true
		k = Odds.STABLE
		trig.append(["badge", "工牌刷开了"])
	# 带概率的饰品：触发记录里附上 {p, hit}，界面用它播“抽卡”
	if k == Odds.DETUNE and has("wrong_answer"):
		var hit := rng.randf() < 0.2
		trig.append(["wrong_answer", "错得很对：失谐 → 完美同步" if hit else "这次是真的错了", {"p": 0.2, "hit": hit}])
		if hit:
			k = Odds.PERFECT
	if k == Odds.STABLE and has("bandaid") and b.locked():
		var hit2 := rng.randf() < 0.4
		trig.append(["bandaid", "稳定 → 加速成功" if hit2 else "没粘住", {"p": 0.4, "hit": hit2}])
		if hit2:
			k = Odds.SUCCESS
	if k == Odds.DETUNE:
		b.had_detune = true
	# 破碎抵挡
	if k == Odds.LOSS and has("coin") and not b.coin_used:
		b.coin_used = true
		if rng.randf() < 0.5:
			k = Odds.STABLE
			trig.append(["coin", "正面！挡住了", {"p": 0.5, "hit": true}])
		else:
			trig.append(["coin", "反面……", {"p": 0.5, "hit": false}])
	for kk in Odds.N:
		expected[kk] += p[kk]
	actual[k] += 1
	b.presses += 1
	var res := {"outcome": k, "from": from, "odds": p, "lock_started": false, "lock_ended": false,
		"lost": false, "salvaged": 0, "money": 0, "triggers": trig}
	# 束流丢失（可能被稿纸抢救）
	if k == Odds.LOSS:
		res.lost = true
		res.to = from
		var keep := 0
		if has("dean_paper") and not paper_used:
			paper_used = true
			keep = int(floor(potential() * 0.8))
			trig.append(["dean_paper", "稿纸抢救 80%"])
		res.salvaged = keep
		if has("reimburse"):
			money += 8
			res.money += 8
			trig.append(["reimburse", "报销 +$8"])
		if has("lost_data") and not stage_lost_data_used:
			var pot := potential()
			if pot >= best_potential and pot > 0:
				stage_lost_data_used = true
				lost_bonus = int(floor(pot * 0.15))
				trig.append(["lost_data", "下次引出 +%d" % lost_bonus])
		_log(k, from, from)
		b.alive = false
		res.merge(_finish(keep))
		return res
	# 执行结果
	var was_locked := b.locked()
	var delta: int = Odds.DELTA[k]
	if Odds.is_good(k) and has("rejected") and rejected_stacks >= 5:
		delta += 3
		rejected_stacks = 0
		trig.append(["rejected", "怨气爆发 +3"])
	b.energy = clampi(b.energy + delta, 1, Odds.EMAX)
	var good := Odds.is_good(k)
	if good:
		b.streak += 1
		if has("chair"):
			b.chair += 0.2
		if has("lucky_cat") and rng.randf() < 0.08:
			var gain := 6 if b.cat_last else 3
			money += gain
			res.money += gain
			b.cat_last = true
			trig.append(["lucky_cat", "+$%d" % gain, {"p": 0.08, "hit": true}])
		else:
			if has("lucky_cat"):
				trig.append(["lucky_cat", "没招来钱", {"p": 0.08, "hit": false}])
			b.cat_last = false
	else:
		b.streak = 0
		if has("chair") and b.chair > 0.0:
			b.chair = 0.0
			trig.append(["chair", "椅子被抢了"])
		b.cat_last = false
	if k == Odds.STABLE and has("third_draft") and b.draft < 1.0:
		b.draft = minf(1.0, b.draft + 0.1)
		trig.append(["third_draft", "倍率 +%.1f" % b.draft])
	if good and has("nobel_list") and b.energy >= 12:
		money += 4
		res.money += 4
		trig.append(["nobel_list", "+$4"])
	if k == Odds.DETUNE and has("rejected"):
		rejected_stacks = mini(5, rejected_stacks + 1)
	if (k == Odds.PERFECT or k == Odds.SUPER) and has("koi") and b.koi < 5:
		b.koi += 1
		trig.append(["koi", "好运 ×%d" % b.koi])
	var lock_n := Odds.LOCK_PRESSES + (2 if has("fast_clock") else 0)
	if was_locked:
		if has("thermos") and rng.randf() < 0.25:
			trig.append(["thermos", "锁相没减少", {"p": 0.25, "hit": true}])
		else:
			if has("thermos"):
				trig.append(["thermos", "茶喝完了", {"p": 0.25, "hit": false}])
			b.lock_left -= 1
		res.lock_ended = b.lock_left == 0
		if res.lock_ended:
			b.full_sync = false
	else:
		if not b.lock_used:
			b.charge = 0 if k == Odds.DETUNE else b.charge + Odds.CHARGE[k]
			if b.charge >= lock_need():
				b.charge = Odds.LOCK_NEED
				b.lock_left = lock_n
				b.lock_used = true
				res.lock_started = true
		if not res.lock_started and has("coffee") and not b.coffee_used and b.streak >= 3:
			b.coffee_used = true
			b.lock_left = 3 + (2 if has("fast_clock") else 0)
			res.lock_started = true
			trig.append(["coffee", "第七杯咖啡"])
	if not was_locked and not res.lock_started and has("alarm_4am") and not b.alarm_used and b.presses >= 7:
		b.alarm_used = true
		b.lock_left = 4 + (2 if has("fast_clock") else 0)
		res.lock_started = true
		trig.append(["alarm_4am", "凌晨四点，锁相"])
	if res.lock_started and has("fast_clock"):
		trig.append(["fast_clock", "锁相 +2"])
	if res.lock_started and has("calib_log") and not b.calib_used:
		b.calib_used = true
		b.full_sync = true
		res["full_sync"] = true
		trig.append(["calib_log", "完全同步"])
	# 便利贴：成功率够高时预备下一次必定成功
	if has("note100") and not b.guaranteed_next:
		var q := odds()
		if q[Odds.SUCCESS] + q[Odds.PERFECT] + q[Odds.SUPER] >= 0.75:
			b.guaranteed_next = true
			relics.erase("note100")
			trig.append(["note100", "贴上了"])
	res.to = b.energy
	best_potential = maxi(best_potential, potential())
	_log(k, from, b.energy)
	return res

func _log(k: int, from: int, to: int) -> void:
	log.push_front({"outcome": k, "from": from, "to": to, "exp": experiment_no})
	if log.size() > 40:
		log.pop_back()

## 引出：兑现当前价值（含全部倍率）
func extract() -> Dictionary:
	var v := potential() + lost_bonus
	lost_bonus = 0
	if has("dean_pen"):
		stage_pen_used = true
	best_value = maxi(best_value, v)
	return _finish(v)

## 实验结束：结算经费，刷新商店
func _finish(v: int) -> Dictionary:
	if beam != null and beam.wipes:
		relics.erase("wipes")
	beam = null
	total += v
	experiments_left -= 1
	var income := int(floor(2.0 + 1.6 * sqrt(float(v))))
	money += income
	roll_shop()
	return {"gained": v, "income": income, "can_submit": can_submit(), "must_submit": must_submit()}

func submit() -> Dictionary:
	assert(beam == null and not won() and not failed)
	if total >= line():
		var s := stage
		stage += 1
		experiments_left = PER_STAGE
		stage_badge_used = false
		stage_pen_used = false
		stage_lost_data_used = false
		var bonus := 15 + 5 * s
		money += bonus
		return {"passed": true, "stage": s, "won": won(), "bonus": bonus}
	failed = true
	return {"passed": false, "stage": stage, "won": false, "bonus": 0}

# —— 商店 ——
func slots_free(kind: String) -> bool:
	if kind == "device":
		return devices.size() < Items.device_slots(stage)
	return relics.size() < Items.relic_slots(stage)

func _pick(kind: String, exclude: Array) -> String:
	var pool: Array = []
	var weights := [55, 32, 13, 4]
	for id in Items.ids(kind):
		if has(id) or exclude.has(id):
			continue
		for i in weights[Items.ALL[id].rarity]:
			pool.append(id)
	if pool.is_empty():
		return ""
	return pool[shop_rng.randi() % pool.size()]

func roll_shop() -> void:
	offers.clear()
	refresh_cost = REFRESH_BASE
	_fill_offers()

func _fill_offers() -> void:
	var picked: Array = []
	for kind in ["device", "device", "relic", "relic", "relic"]:
		var id := _pick(kind, picked)
		if id != "":
			picked.append(id)
			var price: int = Items.ALL[id].price
			if offers.is_empty() and has("applications"):
				price = int(ceil(price * 0.5))
			offers.append({"id": id, "sold": false, "price": price})

func refresh() -> bool:
	if money < refresh_cost:
		return false
	money -= refresh_cost
	refresh_cost *= 2
	offers.clear()
	_fill_offers()
	return true

## 购买：返回空字符串表示成功，否则为原因
func buy(i: int) -> String:
	if i < 0 or i >= offers.size():
		return "没有这件商品"
	var o: Dictionary = offers[i]
	if o.sold:
		return "已经卖掉了"
	var def: Dictionary = Items.get_def(o.id)
	var price: int = o.get("price", def.price)
	if money < price:
		return "经费不够"
	if not slots_free(def.kind):
		return ("设备" if def.kind == "device" else "饰品") + "槽已满，先卖掉一件"
	money -= price
	o.sold = true
	if def.kind == "device":
		devices.append(o.id)
	else:
		relics.append(o.id)
		if def.has("uses"):
			uses[o.id] = def.uses
	return ""

func sell(id: String) -> int:
	if beam != null or not has(id):
		return 0
	var v: int = Items.sell_price(id)
	relics.erase(id)
	devices.erase(id)
	uses.erase(id)
	money += v
	return v
