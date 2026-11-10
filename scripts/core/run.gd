class_name Run
extends RefCounted
## 一局：累计总分制考核 + 经费/商店 + 饰品与设备效果（纯逻辑，可无界面测试）
## 提交规则（DECISIONS Q30）：够线可选提交；次数用完强制提交。
## 结算顺序（GDD 4.6）：最终概率 → 抽取 → 重抽 → 结果转化 → 破碎抵挡 → 科研抢救 → 执行与后续效果

# 8 个阶段（DECISIONS Q56）：第 4、8 阶段是大考（线跳高、奖金翻倍）；数值由 tests/bot_balance.gd 校准
static var LINES := [150, 700, 1500, 2800, 3800, 5400, 7700, 12000]   # Q69 新曲线下机器人重定
const BIG := [3, 7]
const ENDLESS_G := 1.55          # 无尽：第 9 阶段起每阶段考核线 ×1.55
const PER_STAGE := 3
static var LEFTOVER_PAY := 20    # 提前提交：每束没用的束流折 $LEFTOVER_PAY + 阶段 × LEFTOVER_STEP
static var LEFTOVER_STEP := 4
static var OVERLINE_TAX := 0.3   # 已够线还继续赌，束流丢了：扣掉累计分的 30%（可能跌回线下）
const START_MONEY := 30
const REFRESH_BASE := 3

var seed_value := 0
var rng := RandomNumberGenerator.new()
var shop_rng := RandomNumberGenerator.new()   # 商店单独一路随机，买不买东西都不影响实验结果序列
var stage := 0
var endless := false             # 通过第 8 阶段后选择继续挑战
var experiments_left := PER_STAGE
var total := 0
# —— 氢气瓶（Q70）：全手动换瓶，成果装回瓶里，满瓶进当前评审的篮子；储备柜存不交的满瓶，留着翻身 ——
const CAB_SLOTS := 2
## 真实游戏里（main 打开）：引出的满瓶留在注入器瓶座上，要玩家拿去审核台放进篮子才算科研点（用户 2026-11-09）。
## 规则测试和平衡机器人不开：满瓶直接进篮子，结果等价于“每瓶都送到了”
static var MANUAL_BASKET := false
var inj := ""              # 注入器瓶座："" 空 / "fresh" 装着新瓶 / "empty" 实验后的空瓶 / "full" 装着成果的满瓶
var inj_bt := {}           # 瓶座上那只满瓶 {value, energy}
var held := ""             # 主角手里："" / "fresh" / "empty" / "full"
var held_bt := {}          # 手里那只满瓶 {value, energy}
var basket: Array = []     # 本次评审篮子里的满瓶 {value, energy}，提交后清空
var cab: Array = []        # 储备柜里的满瓶（最多 CAB_SLOTS 只，这一局结束清空）
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
var inherited: Array = []       # 这一束开局继承的锁相充能 [[来源 id, 格数]]（界面显示来自哪件物品）
var lost_charge_pending := false # 丢失数据：下一束开始时获得锁相充能
var stage_lost_data_used := false
var stage_letter_used := false   # 推荐信：本阶段已经加成过
var stage_had_loss := false      # 流动红旗：本阶段出现过束流丢失
var promise := 0                 # 毕业承诺：攒给下一次锁相的额外次数（0..4）
var stage_ext_used := false      # 灭火器：本阶段已经用过
var stage_call_used := false     # 紧急电话
var stage_protect_used := false  # 束流保护系统
var stage_sch_used := false      # 薛定谔的实验报告
# —— 科研计划书（第 2 阶段起每阶段三选一）——
var plan := ""                   # 本阶段生效的计划书
var plan_offers: Array = []      # 等玩家挑的三份（非空 = 还没挑）
var stage_safety_used := false
# —— 商店 ——
var offers: Array = []        # [{id, sold}]
var refresh_cost := REFRESH_BASE
# —— 开发者模式（~ 键）——
var dev_force := -1           # 开发者模式：每次加速都强制出这个结果（点“自动”恢复）
var dev_roll := -1            # 抽卡：-1 正常 / 0 必不中 / 1 必中
var dev_god := false          # 无敌：束流丢失改为保持稳定

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
	return maxi(2, Odds.LOCK_NEED - (1 if has("coffee_cup") else 0) - (2 if plan == "lock_rush" else 0) - (2 if has("calib_log") else 0))

## 打开采购终端（饭卡）
var meal_ready := true     # 饭卡：每次实验结束后（和开局）第一次打开才给，防止反复开关刷钱

func on_shop_open() -> int:
	if has("meal_card") and meal_ready:
		meal_ready = false
		money += 2
		return 2
	return 0

func has(id: String) -> bool:
	return relics.has(id) or devices.has(id)

func won() -> bool:
	return stage >= LINES.size() and not endless

## 第 s 阶段（从 0 数）的考核线，不含计划书修正
static func line_at(s: int) -> int:
	if s < LINES.size():
		return LINES[s]
	return int(round(LINES[-1] * pow(ENDLESS_G, s - LINES.size() + 1) / 100.0)) * 100

## 大考：第 4、8 阶段；无尽里每 4 阶段一次
static func is_big(s: int) -> bool:
	return s in BIG or (s >= LINES.size() and (s + 1) % 4 == 0)

## 通过第 8 阶段后继续挑战（无尽）
func go_endless() -> void:
	endless = true
	plan_offers = Plans.deal(shop_rng)

## 已够线还继续做实验：这束丢了会扣多少
func overline_tax() -> int:
	if total >= line():
		return int(floor(total * OVERLINE_TAX))
	return 0

func _apply_tax(res: Dictionary) -> void:
	var tax := overline_tax()
	if tax > 0:
		total -= tax
		res["tax"] = tax
		# 篮子里的瓶子跟着漏掉同样的比例
		for bt in basket:
			bt.value = int(bt.value) - int(floor(int(bt.value) * OVERLINE_TAX))

func lost() -> bool:
	return failed

func line() -> int:
	var l: int = line_at(stage)
	if plan == "collab":
		l = int(ceil(l * 1.1))
	elif plan == "downsizing":
		l = int(ceil(l * 0.8))
	return l

func can_submit() -> bool:
	return beam == null and not won() and not failed and total >= line()

func must_submit() -> bool:
	return beam == null and not won() and not failed and experiments_left <= 0

func can_start() -> bool:
	return beam == null and not won() and not failed and experiments_left > 0

func start_experiment() -> void:
	assert(can_start())
	beam = Beam.new()
	inherited = []
	if lost_charge_pending:
		beam.charge = mini(2, lock_need() - 1)
		lost_charge_pending = false
		if beam.charge > 0:
			inherited.append(["lost_data", beam.charge])
	beam.route = Forms.route_of(relics)     # 束流形态路线在注入时定下，中途买卖不换路线
	experiment_no += 1
	inj = "empty"           # 瓶里的氢气注进了环，瓶座上只剩空瓶
	if has("wipes"):
		beam.wipes = true

# —— 概率与价值 ——
func odds() -> PackedFloat64Array:
	var b := beam
	var p := Odds.table(b.energy)
	var d := PackedFloat64Array([0, 0, 0, 0, 0, 0])
	# 降丢失的饰品按比例（Q69）：丢失率 ×系数，能级越高省得越多；代价类仍是加百分点
	var lm := 1.0
	if has("magnet_sc"): lm *= 0.85
	if has("collimator"): lm *= 0.88
	if has("koi") and b.koi > 0: lm *= pow(0.95, b.koi)
	if plan == "energy_save": lm *= 0.92
	if b.wipes: lm *= 0.82
	if has("cryo_magnet") and b.energy >= 10: lm *= 0.75
	d[Odds.LOSS] -= p[Odds.LOSS] * (1.0 - lm)
	if has("injector_hi"): d[Odds.LOSS] += 0.05
	if has("quad_array"): d[Odds.SUCCESS] += 0.12
	if has("rf_backup"): d[Odds.PERFECT] += 0.06
	if has("ultimatum") and b.presses >= 3: d[Odds.LOSS] += 0.10
	if has("fast_clock") and b.presses == 0: d[Odds.LOSS] += 0.05
	match plan:
		"high_energy": d[Odds.LOSS] += 0.03
		"safety": d[Odds.PERFECT] -= 0.03
		"top_journal":
			d[Odds.PERFECT] += 0.04
			d[Odds.DETUNE] += 0.04
		"open_day":
			if b.presses == 0: d[Odds.LOSS] += 0.05
	if has("duty_roster") and b.presses == 0: d[Odds.SUCCESS] += 0.15
	if has("dose_card") and b.energy >= 10: d[Odds.PERFECT] += 0.08
	# 束流位置监测器：保持稳定的一半转给加速成功
	if has("bpm"):
		d[Odds.STABLE] -= p[Odds.STABLE] * 0.5
		d[Odds.SUCCESS] += p[Odds.STABLE] * 0.5
	var q := Odds.apply_mods(p, d)
	if b.locked():
		# 锁相（Q69）：纸带上只剩完美同步 / 加速成功 / 超级同步——丢失、保持稳定、射频失谐都不出现
		q[Odds.LOSS] = 0.0
		q[Odds.STABLE] = 0.0
		q[Odds.DETUNE] = 0.0
		var s := 0.0
		for k in Odds.N: s += q[k]
		for k in Odds.N: q[k] /= s
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
## 成果倍率逐件拆开（引出时一件一件播放给玩家看）：[来源 id, 倍率]。multiplier() 就是它们的乘积。
## 来源 id：物品 id；计划书写成 "plan:xxx"；束流形态写 "form"
func mult_parts() -> Array:
	var out: Array = []
	var b := beam
	_mp(out, "injector_hi", 1.5, has("injector_hi"))
	_mp(out, "collimator", 0.9, has("collimator"))
	if b != null:
		_mp(out, "chair", 1.0 + b.chair, has("chair"))
		_mp(out, "third_draft", 1.0 + b.draft, has("third_draft"))
		_mp(out, "marker", 1.15, has("marker") and not b.had_detune)
	_mp(out, "red_flag", 1.4, has("red_flag") and not stage_had_loss)
	_mp(out, "extractor", 1.2, has("extractor"))
	_mp(out, "plan:high_energy", 1.3, plan == "high_energy" and b != null and b.energy >= 10)
	_mp(out, "plan:energy_save", 0.85, plan == "energy_save")
	if b != null:
		_mp(out, "calorimeter", 1.6, has("calorimeter") and b.energy >= 8)
		_mp(out, "daq", 1.0 + minf(0.6, b.streak * 0.03), has("daq"))
		_mp(out, "last_slide", 1.5, has("last_slide") and experiments_left == 1)
		_mp(out, "red_button", b.red_mult, true)
		_mp(out, "impossible", b.imp_mult, true)
		_mp(out, "screw", b.screw_mult, true)
		_mp(out, "phd_cert", 2.0, has("phd_cert") and experiments_left == 1 and total < line())
	_mp(out, "dean_pen", 0.8 if stage_pen_used else 3.0, has("dean_pen"))
	_mp(out, "budget", 1.0 + minf(0.5, floor(money / 10.0) * 0.05), has("budget"))
	if b != null:
		_mp(out, "form", 1.0 + Forms.bonus(b.energy), true)
	return out

func _mp(out: Array, id: String, f: float, cond: bool) -> void:
	if cond and absf(f - 1.0) > 1e-6:
		out.append([id, f])

func multiplier() -> float:
	var m := 1.0
	for x in mult_parts():
		m *= float(x[1])
	return m

## 这一次加速，哪些物品在改概率：[物品 id, 一句短说明]（挂板上让它们晃一下、冒个小纸签）
func odds_notes() -> Array:
	var b := beam
	if b == null:
		return []
	var out: Array = []
	var lock := b.locked()
	if not lock:
		if has("magnet_sc"): out.append(["magnet_sc", "丢失 ×0.85"])
		if has("collimator"): out.append(["collimator", "丢失 ×0.88"])
		if has("koi") and b.koi > 0: out.append(["koi", "丢失 ×%.2f" % pow(0.95, b.koi)])
		if b.wipes and has("wipes"): out.append(["wipes", "丢失 ×0.82"])
		if has("cryo_magnet") and b.energy >= 10: out.append(["cryo_magnet", "丢失 ×0.75"])
		if has("injector_hi"): out.append(["injector_hi", "丢失 +5%"])
		if has("ultimatum") and b.presses >= 3: out.append(["ultimatum", "丢失 +10%"])
		if has("fast_clock") and b.presses == 0: out.append(["fast_clock", "丢失 +5%"])
		if has("bpm"): out.append(["bpm", "稳定一半 → 成功"])
	if has("quad_array"): out.append(["quad_array", "成功 +12%"])
	if has("rf_backup"): out.append(["rf_backup", "完美 +6%"])
	if has("duty_roster") and b.presses == 0: out.append(["duty_roster", "成功 +15%"])
	if has("dose_card") and b.energy >= 10: out.append(["dose_card", "完美 +8%"])
	return out

## 挂板上每张牌底下的状态签（圣遗物改造第二步）：{t: 文字, dim: 已用/没生效时变灰}；没有状态的物品返回 {}
## 周期：本局 / 本阶段（通过考核重置）/ 本束（注入新束流重置）。没在做实验时，本束类显示“每束一次”。
func charm_state(id: String) -> Dictionary:
	var b := beam
	var e := 0 if b == null else b.energy
	match id:
		# —— 攒进度 ——
		"rejected": return _cs("怨气 %d/3" % rejected_stacks, rejected_stacks == 0)
		"coffee":
			if b == null: return _cs("连成 0/3", true)
			return _cs("已用", true) if b.coffee_used else _cs("连成 %d/3" % mini(3, b.streak), b.streak == 0)
		"alarm_4am":
			if b == null: return _cs("加速 0/7", true)
			return _cs("已用", true) if b.alarm_used else _cs("加速 %d/7" % mini(7, b.presses), b.presses == 0)
		"third_draft":
			if b == null: return _cs("稳定 0/2", true)
			return _cs("×%.1f · %d/2" % [1.0 + b.draft, b.draft_stable % 2], b.draft <= 0.0)
		"koi": return _cs("好运 0/5", true) if b == null else _cs("好运 %d/5" % b.koi, b.koi == 0)
		"grad_promise": return _cs("承诺 %d/4" % promise, promise == 0)
		"chair":
			if b == null or b.chair <= 0.0: return _cs("×1.0", true)
			return _cs("×%.1f" % (1.0 + b.chair), false)
		"daq":
			if b == null: return _cs("×1.00", true)
			return _cs("×%.2f" % (1.0 + minf(0.6, b.streak * 0.03)), b.streak == 0)
		"budget": return _cs("×%.2f" % (1.0 + minf(0.5, floor(money / 10.0) * 0.05)), money < 10)
		"screw": return {} if b == null or b.screw_mult <= 1.0 else _cs("×%d" % int(b.screw_mult), false)
		"impossible": return _cs("完美<5%", true) if b == null or b.imp_mult <= 1.0 else _cs("×5", false)
		"note100": return _cs("下次必成", false) if b != null and b.guaranteed_next else _cs("成功≥75%", true)
		# —— 本阶段一次 ——
		"badge": return _once(stage_badge_used, "本阶段")
		"extinguisher": return _once(stage_ext_used, "本阶段")
		"emergency_call": return _once(stage_call_used, "本阶段")
		"rec_letter": return _once(stage_letter_used, "本阶段")
		"schrodinger": return _once(stage_sch_used, "本阶段")
		"protect_sys": return _once(stage_protect_used, "本阶段")
		"lost_data":
			if lost_charge_pending or lost_bonus > 0: return _cs("待兑现 +%d" % lost_bonus, false)
			return _once(stage_lost_data_used, "本阶段")
		"dean_pen": return _cs("之后 ×0.8", true) if stage_pen_used else _cs("首次 ×3", false)
		"red_flag": return _cs("已收起", true) if stage_had_loss else _cs("×1.4 有效", false)
		# —— 本局一次 ——
		"dean_paper": return _once(paper_used, "本局")
		# —— 本束一次 ——
		"tape_roll": return _beam_once(b, "tape_used")
		"lab_cat": return _beam_once(b, "cat_used")
		"coin": return _beam_once(b, "coin_used")
		"diagnostic": return _beam_once(b, "diag_used")
		"red_button": return _beam_once(b, "red_used")
		"marker":
			if b == null: return _cs("×1.15 待兑现", true)
			return _cs("失谐了", true) if b.had_detune else _cs("×1.15 待兑现", false)
		"meal_card": return _cs("可领 $2", false) if meal_ready else _cs("已领", true)
		# —— 条件生效 ——
		"dose_card": return _cs("E10 起", e < 10)
		"cryo_magnet": return _cs("E10 起", e < 10)
		"nobel_list": return _cs("E12 起", e < 12)
		"calorimeter": return _cs("E8 起", e < 8)
		"last_slide": return _cs("最后一束", experiments_left != 1)
		"phd_cert": return _cs("背水一战", not (experiments_left == 1 and total < line()))
		"duty_roster": return _cs("第 1 下", b == null or b.presses != 0)
		"ultimatum":
			if b == null or b.presses < 3: return _cs("必成 %d/3" % (0 if b == null else b.presses), false)
			return _cs("丢失 +10%", false)
	return {}

func _cs(t: String, dim: bool) -> Dictionary:
	return {"t": t, "dim": dim}

func _once(used: bool, per: String) -> Dictionary:
	return _cs("已用", true) if used else _cs(per + "可用", false)

func _beam_once(b: Beam, field: String) -> Dictionary:
	if b == null:
		return _cs("每束一次", true)
	return _cs("已用", true) if bool(b.get(field)) else _cs("本束可用", false)

func potential() -> int:
	return 0 if beam == null else int(floor(beam.value_base() * multiplier()))

# —— 加速 ——
func accelerate() -> Dictionary:
	var b := beam
	var p := odds()
	var g := guaranteed()
	var k := Odds.roll_at_least_success(p, rng) if g else Odds.roll(p, rng)
	if dev_force >= 0:
		k = dev_force            # 开发者模式：一直生效，直到点“自动”
	var raw := k                  # 饰品改写之前的原始结果：界面先揭晓它，再让饰品跳出来改
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
		trig.append(["diagnostic", "失谐 → 稳定"])
	if k == Odds.DETUNE and has("tape_roll") and not b.tape_used:
		b.tape_used = true
		k = Odds.STABLE
		trig.append(["tape_roll", "粘住了：失谐 → 稳定"])
	if k == Odds.DETUNE and has("badge") and not stage_badge_used:
		stage_badge_used = true
		k = Odds.STABLE
		trig.append(["badge", "刷开了：失谐 → 稳定"])
	# 带概率的饰品：触发记录里附上 {p, hit}，界面用它播“抽卡”
	if k == Odds.DETUNE and has("wrong_answer"):
		var hit := _hit(0.2)
		trig.append(["wrong_answer", "错得很对：失谐 → 完美同步" if hit else "这次是真的错了", {"p": 0.2, "hit": hit}])
		if hit:
			k = Odds.PERFECT
	if k == Odds.STABLE and has("bandaid"):
		var hit2 := _hit(0.4)
		trig.append(["bandaid", "稳定 → 加速成功" if hit2 else "没粘住", {"p": 0.4, "hit": hit2}])
		if hit2:
			k = Odds.SUCCESS
	if k == Odds.DETUNE:
		b.had_detune = true
	# 螺丝：2% 概率额外来一次束流丢失判定（锁相时不判）
	if k != Odds.LOSS and has("screw") and not b.locked() and rng.randf() < 0.02:
		var lost2 := _hit(p[Odds.LOSS])
		trig.append(["screw", "螺丝松了：束流丢失！" if lost2 else "螺丝松了，还好没事", {"p": p[Odds.LOSS], "hit": lost2}])
		if lost2:
			k = Odds.LOSS
	# 破碎抵挡
	if k == Odds.LOSS and has("lab_cat") and not b.cat_used:
		b.cat_used = true
		var hc := _hit(0.5)
		trig.append(["lab_cat", "猫踩了一脚：丢失 → 完美同步" if hc else "猫看了一眼，走了", {"p": 0.5, "hit": hc}])
		if hc:
			k = Odds.PERFECT
			b.saved = true
	if k == Odds.LOSS and has("emergency_call") and not stage_call_used:
		stage_call_used = true
		k = Odds.STABLE
		b.saved = true
		trig.append(["emergency_call", "教授接了：丢失 → 稳定"])
	if k == Odds.LOSS and has("extinguisher") and not stage_ext_used and b.energy <= 6:
		stage_ext_used = true
		k = Odds.STABLE
		b.saved = true
		trig.append(["extinguisher", "喷上了：丢失 → 稳定"])
	if k == Odds.LOSS and has("coin") and not b.coin_used:
		b.coin_used = true
		if _hit(0.5):
			k = Odds.STABLE
			b.saved = true
			trig.append(["coin", "正面！丢失 → 稳定", {"p": 0.5, "hit": true}])
		else:
			trig.append(["coin", "反面……", {"p": 0.5, "hit": false}])
	var gamble := b.sch_gamble
	if gamble:
		b.sch_gamble = false
		b.sch_pending = false
		if not Odds.is_good(k):
			k = Odds.LOSS
			trig.append(["schrodinger", "盒子打开了：没了"])
		else:
			trig.append(["schrodinger", "盒子打开了：还活着！"])
			b.saved = true
	if k == Odds.LOSS and dev_god:
		k = Odds.STABLE
	for kk in Odds.N:
		expected[kk] += p[kk]
	actual[k] += 1
	b.presses += 1
	var res := {"outcome": k, "raw": raw, "from": from, "odds": p, "lock_started": false, "lock_ended": false,
		"lost": false, "salvaged": 0, "money": 0, "triggers": trig}
	# 薛定谔：丢失进入待定，等玩家选
	if k == Odds.LOSS and not gamble and has("schrodinger") and not stage_sch_used:
		stage_sch_used = true
		b.sch_pending = true
		trig.append(["schrodinger", "待定：既丢了，又没丢"])
		res["sch"] = true
		res.to = from
		_log(Odds.LOSS, from, from)
		return res
	# 束流丢失（可能被稿纸抢救）
	if k == Odds.LOSS:
		stage_had_loss = true
		res.lost = true
		res.to = from
		var keep := 0
		if has("dean_paper") and not paper_used and not gamble:
			paper_used = true
			keep = int(floor(potential() * 0.8))
			trig.append(["dean_paper", "稿纸抢救 80%"])
		if keep == 0 and plan == "safety" and not stage_safety_used and not gamble:
			stage_safety_used = true
			keep = int(floor(potential() * 0.5))
			res["plan_note"] = "安全整改：保留 50%"
		if keep == 0 and has("protect_sys") and not stage_protect_used and not gamble:
			stage_protect_used = true
			keep = int(floor(potential() * 0.3))
			trig.append(["protect_sys", "保护系统保住 30%"])
		res.salvaged = keep
		if has("beam_dump"):
			var back := b.energy * 2
			money += back
			res.money += back
			trig.append(["beam_dump", "收集靶返还 $%d" % back])
		if has("reimburse"):
			money += 8
			res.money += 8
			trig.append(["reimburse", "报销 +$8"])
		if has("lost_data") and not stage_lost_data_used:
			var pot := potential()
			if pot >= best_potential and pot > 0:
				stage_lost_data_used = true
				lost_bonus = int(floor(pot * 0.15))
				lost_charge_pending = true
				trig.append(["lost_data", "下次引出 +%d · 下束充能 +2" % lost_bonus])
		_log(k, from, from)
		b.alive = false
		_apply_tax(res)
		res.merge(_finish(keep))
		return res
	# 执行结果
	var was_locked := b.locked()
	var delta: int = Odds.DELTA[k]
	if k == Odds.PERFECT and has("qm_book2"):
		var hq := _hit(0.3)
		trig.append(["qm_book2", "第二册翻到了：再 +1" if hq else "翻到的是目录", {"p": 0.3, "hit": hq}])
		if hq:
			delta += 1
	if k == Odds.PERFECT and has("impossible") and b.imp_mult == 1.0 and p[Odds.PERFECT] < 0.05:
		b.imp_mult = 5.0
		trig.append(["impossible", "这个结果不可能：×5"])
	if k == Odds.PERFECT and has("rf_cavity"):
		delta += 1
		trig.append(["rf_cavity", "完美同步再 +1"])
	if Odds.is_good(k) and has("rejected") and rejected_stacks >= 3:
		delta += 3
		rejected_stacks = 0
		trig.append(["rejected", "怨气爆发 +3"])
	b.energy = clampi(b.energy + delta, 1, Odds.EMAX)
	b.peak = maxi(b.peak, b.energy)
	if k == Odds.SUPER:
		b.crowned = true
	var good := Odds.is_good(k)
	if good:
		b.streak += 1
		if has("chair"):
			b.chair += 0.2
		if has("lucky_cat") and _hit(0.08):
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
	if has("screw") and rng.randf() < 0.03:
		b.screw_mult *= 2.0
		trig.append(["screw", "潜在成果翻倍！", {"p": 0.03, "hit": true}])
	if k == Odds.STABLE and has("third_draft"):
		b.draft = minf(1.0, b.draft + 0.1)
		b.draft_stable += 1
		trig.append(["third_draft", "第 %d 次修改：×%.1f" % [b.draft_stable, 1.0 + b.draft], {"quiet": true}])
		if b.draft_stable % 2 == 0 and not was_locked and not b.lock_used:
			b.charge += 1
			trig.append(["third_draft", "稳定两次：锁相充能 +1"])
	if good and has("nobel_list") and b.energy >= 12:
		money += 4
		res.money += 4
		trig.append(["nobel_list", "+$4"])
	if k == Odds.DETUNE and has("grad_promise") and promise < 4:
		promise += 1
		trig.append(["grad_promise", "下次锁相 +%d" % promise])
	if k == Odds.DETUNE and has("rejected"):
		rejected_stacks = mini(3, rejected_stacks + 1)
		trig.append(["rejected", "怨气 %d/3" % rejected_stacks + ("，下次成功 +3" if rejected_stacks >= 3 else ""), {"quiet": true}])
	if (k == Odds.PERFECT or k == Odds.SUPER) and has("koi") and b.koi < 5:
		b.koi += 1
		trig.append(["koi", "好运 ×%d" % b.koi])
	var lock_n := Odds.LOCK_PRESSES + (2 if has("fast_clock") else 0) - (1 if plan == "lock_rush" else 0)
	if was_locked:
		if has("thermos") and _hit(0.25):
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
				b.charge = lock_need()
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
	if res.lock_started and has("lock_loop"):
		b.lock_left += 1
		trig.append(["lock_loop", "锁相 +1"])
	if res.lock_started and has("grad_promise") and promise > 0:
		b.lock_left += promise
		trig.append(["grad_promise", "兑现承诺：锁相 +%d" % promise])
		promise = 0
	if res.lock_started and has("fast_clock"):
		trig.append(["fast_clock", "锁相 +2"])
	if res.lock_started and has("calib_log"):
		trig.append(["calib_log", "校准过的设备：4 格就锁相"])
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

## 薛定谔：选“结束”——保留 30%，实验结束
func sch_end() -> Dictionary:
	var b := beam
	b.sch_pending = false
	var keep := int(floor(potential() * 0.3))
	stage_had_loss = true
	b.alive = false
	var fin := _finish(keep)
	fin["lost"] = true
	fin["salvaged"] = keep
	return fin

## 绝对不能按的红色按钮：每次实验一次，四种结果概率公开
const RED_SEGS := [[0.10, "潜在成果 ×10"], [0.25, "4 次锁相"], [0.35, "束流直接丢失"], [0.30, "随机精良以上饰品"]]

func can_press_red() -> bool:
	return beam != null and has("red_button") and not beam.red_used

func press_red() -> Dictionary:
	var b := beam
	b.red_used = true
	var r := rng.randf()
	var pick := 0
	var acc := 0.0
	for i in RED_SEGS.size():
		acc += RED_SEGS[i][0]
		if r < acc:
			pick = i
			break
		pick = i
	if dev_roll == 1:
		pick = 0
	elif dev_roll == 0:
		pick = 2
	var res := {"pick": pick, "lost": false, "gift": ""}
	match pick:
		0:
			b.red_mult *= 10.0
		1:
			b.lock_left += 4
			b.lock_used = true
			b.full_sync = true
			b.synced = true
		2:
			res.lost = true
			res.from = b.energy
			res.odds = odds()
			res.salvaged = 0
			res.triggers = []
			stage_had_loss = true
			_log(Odds.LOSS, b.energy, b.energy)
			b.alive = false
			_apply_tax(res)
			res.merge(_finish(0))
		3:
			var pool: Array = []
			for id in Items.ids("relic"):
				if not has(id) and Items.ALL[id].rarity >= Items.UNCOMMON:
					pool.append(id)
			if not pool.is_empty():
				var g: String = pool[rng.randi() % pool.size()]
				relics.append(g)
				if Items.ALL[g].has("uses"):
					uses[g] = Items.ALL[g].uses
				res.gift = g
	return res

## 饰品概率判定：照常消耗一次随机数（保证结果序列不变），开发者模式可强制中/不中
func _hit(p: float) -> bool:
	var h := rng.randf() < p
	return h if dev_roll < 0 else dev_roll == 1

func _log(k: int, from: int, to: int) -> void:
	log.push_front({"outcome": k, "from": from, "to": to, "exp": experiment_no})
	if log.size() > 40:
		log.pop_back()

## 引出：兑现当前价值（含全部倍率）
func extract() -> Dictionary:
	var v := potential() + lost_bonus
	lost_bonus = 0
	if plan == "open_day":
		money += 5
	var trig: Array = []
	if has("rec_letter") and not stage_letter_used:
		var hit := _hit(0.25)
		trig.append(["rec_letter", "评分 +50%" if hit else "系主任没空", {"p": 0.25, "hit": hit}])
		if hit:
			stage_letter_used = true
			v = int(floor(v * 1.5))
	if has("calc7"):
		var h7 := _hit(0.07)
		trig.append(["calc7", "等于 7：×3！" if h7 else "等于 7……没用", {"p": 0.07, "hit": h7}])
		if h7:
			v *= 3
	promise = 0
	if has("dean_pen"):
		stage_pen_used = true
	best_value = maxi(best_value, v)
	var fin := _finish(v)
	fin["triggers"] = trig
	return fin

## 实验结束：结算经费，刷新商店
func _finish(v: int) -> Dictionary:
	if beam != null and beam.wipes:
		relics.erase("wipes")
	var e_end := beam.energy if beam != null else 1
	beam = null
	if v > 0:
		# 成果装回瓶座上的瓶子
		if MANUAL_BASKET:
			# 满瓶留在瓶座上，玩家拿去审核台放进篮子才计分
			inj = "full"
			inj_bt = {"value": v, "energy": e_end}
		else:
			basket.append({"value": v, "energy": e_end})
			inj = ""
	meal_ready = true
	if not MANUAL_BASKET:
		total += v
	experiments_left -= 1
	var income := int(floor(2.0 + 1.6 * sqrt(float(v))))
	if plan == "night_shift":
		income = int(floor(income * 0.5))
	money += income
	roll_shop()
	return {"gained": v, "income": income, "can_submit": can_submit(), "must_submit": must_submit()}

func submit() -> Dictionary:
	assert(beam == null and not won() and not failed)
	if total >= line():
		var s := stage
		var left := maxi(0, experiments_left)
		var leftover := left * (LEFTOVER_PAY + s * LEFTOVER_STEP)
		money += leftover
		basket.clear()
		# 没用上的新瓶（手里的、瓶座上的）和架子上的一起退回
		if held == "fresh":
			held = ""
		if inj == "fresh":
			inj = ""
		stage += 1
		experiments_left = PER_STAGE
		stage_badge_used = false
		stage_pen_used = false
		stage_lost_data_used = false
		stage_letter_used = false
		stage_ext_used = false
		stage_call_used = false
		stage_protect_used = false
		stage_had_loss = false
		stage_safety_used = false
		var bonus := 15 + 5 * s
		if is_big(s):
			bonus *= 2
		if plan == "audit":
			bonus *= 3
		if has("crooked_seal"):
			bonus *= 2
		if has("plant"):
			bonus += 6
		money += bonus
		plan = ""
		plan_offers = Plans.deal(shop_rng) if not won() else []
		return {"passed": true, "stage": s, "won": won(), "bonus": bonus, "leftover": leftover, "left": left, "big": is_big(s)}
	failed = true
	return {"passed": false, "stage": stage, "won": false, "bonus": 0}

# —— 商店 ——
## 槽位数（扳手 +1 设备槽）；螺丝不占饰品槽
func slot_count(kind: String) -> int:
	if kind == "device":
		return Items.device_slots(stage) + (1 if has("wrench") else 0)
	return Items.relic_slots(stage)

func slot_used(kind: String) -> int:
	if kind == "device":
		return devices.size()
	return relics.size() - (1 if has("screw") else 0)

func slots_free(kind: String, id := "") -> bool:
	if id == "screw":
		return true
	return slot_used(kind) < slot_count(kind)

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
			var price := price_of(id)
			if offers.is_empty() and has("applications"):
				price = int(ceil(price * 0.5))
			offers.append({"id": id, "sold": false, "price": price})
	# 第八号实验室的钥匙：10% 概率把一件饰品变成免费
	if has("lab8_key") and shop_rng.randf() < 0.1:
		var rel: Array = []
		for i in offers.size():
			if Items.ALL[offers[i].id].kind == "relic":
				rel.append(i)
		if not rel.is_empty():
			var fi: int = rel[shop_rng.randi() % rel.size()]
			offers[fi].price = 0
			offers[fi]["free"] = true

func refresh() -> bool:
	if money < refresh_cost:
		return false
	money -= refresh_cost
	if not has("printer"):
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
	if not slots_free(def.kind, o.id):
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
	if not has(id):
		return 0
	var v: int = Items.sell_price(id)
	relics.erase(id)
	devices.erase(id)
	uses.erase(id)
	money += v
	return v

## 商品价格（设备更新计划：设备 7 折、饰品贵 20%）
func price_of(id: String) -> int:
	var pr: int = Items.ALL[id].price
	if plan == "equip_renew":
		pr = int(ceil(pr * (0.7 if Items.ALL[id].kind == "device" else 1.2)))
	return pr

## 选定计划书：立即生效的部分在这里结算
func choose_plan(id: String) -> Dictionary:
	plan = id
	plan_offers = []
	var out := {"money": 0}
	match id:
		"collab":
			money += 25
			out.money = 25
		"steady":
			money += 10
			out.money = 10
		"audit":
			var lose := money / 2
			money -= lose
			out.money = -lose
		"night_shift":
			experiments_left += 1
		"downsizing":
			experiments_left = maxi(1, experiments_left - 1)
		"equip_renew":
			for o in offers:
				if not o.sold and not o.get("free", false):
					o.price = price_of(o.id)
	return out

## 这一束现在还剩哪些“丢失时能保住”的东西（控制台决策条用）
func protections() -> Array:
	var out: Array = []
	var b := beam
	if b == null:
		return out
	if has("lab_cat") and not b.cat_used: out.append("猫 50%")
	if has("emergency_call") and not stage_call_used: out.append("紧急电话")
	if has("extinguisher") and not stage_ext_used and b.energy <= 6: out.append("灭火器")
	if has("coin") and not b.coin_used: out.append("硬币 50%")
	if has("schrodinger") and not stage_sch_used: out.append("薛定谔")
	if has("dean_paper") and not paper_used: out.append("稿纸保 80%")
	if plan == "safety" and not stage_safety_used: out.append("安全整改保 50%")
	if has("protect_sys") and not stage_protect_used: out.append("保护系统保 30%")
	return out

# —— 氢气瓶操作（Q70）：都返回 "" 表示做到了，否则返回一句为什么不行 ——
## 气瓶架上还剩几瓶（本阶段剩余次数，减去正在用的、已经拿下来的）
func rack_left() -> int:
	return maxi(0, experiments_left - (1 if beam != null else 0) - (1 if held == "fresh" else 0) - (1 if inj == "fresh" else 0))

func take_fresh() -> String:
	if held != "":
		return "手里已经拿着东西了"
	if rack_left() <= 0:
		return "这一轮的氢气瓶用完了"
	held = "fresh"
	return ""

func return_fresh() -> String:
	if held != "fresh":
		return "手里没有新瓶"
	held = ""
	return ""

func load_fresh() -> String:
	if held != "fresh":
		return "先去气瓶架拿一瓶氢气"
	if inj == "empty":
		return "瓶座上还有空瓶，先拿下来扔掉"
	if inj != "":
		return "瓶座上已经有一瓶了"
	held = ""
	inj = "fresh"
	return ""

## 从瓶座上拿下满瓶（成果），送去审核台
func pick_full() -> String:
	if inj != "full":
		return "瓶座上没有成果瓶"
	if held != "":
		return "手里已经拿着东西了"
	held_bt = inj_bt
	inj_bt = {}
	inj = ""
	held = "full"
	return ""

func pick_empty() -> String:
	if inj != "empty":
		return "瓶座上没有空瓶"
	if held != "":
		return "手里已经拿着东西了"
	if beam != null:
		return "实验还在进行"
	inj = ""
	held = "empty"
	return ""

func toss_empty() -> String:
	if held != "empty":
		return "手里没有空瓶"
	held = ""
	return ""

## 从篮子里拿一瓶出来（i = -1 拿最后放进去的那瓶）
func take_from_basket(i := -1) -> String:
	if held != "":
		return "手里已经拿着东西了"
	if basket.is_empty():
		return "篮子是空的"
	var k := i if i >= 0 and i < basket.size() else basket.size() - 1
	held_bt = basket[k]
	basket.remove_at(k)
	total = maxi(0, total - int(held_bt.value))
	held = "full"
	return ""

func put_in_basket() -> String:
	if held != "full":
		return "手里没有满瓶"
	basket.append(held_bt)
	total += int(held_bt.value)
	held_bt = {}
	held = ""
	return ""

func store_in_cab() -> String:
	if held != "full":
		return "手里没有满瓶"
	if cab.size() >= CAB_SLOTS:
		return "储备柜满了"
	cab.append(held_bt)
	held_bt = {}
	held = ""
	return ""

func take_from_cab() -> String:
	if held != "":
		return "手里已经拿着东西了"
	if cab.is_empty():
		return "储备柜是空的"
	held_bt = cab.pop_back()
	held = "full"
	return ""

