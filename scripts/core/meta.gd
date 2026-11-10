class_name Meta
## 局外进度（M5，FULL_GAME_PLAN M5-1…M5-18）：科研声望、已借阅（解锁）的物品、楼层开放、统计。
## 单独存 user://meta.cfg（M5-7），每次写之前滚动备份 3 份；-s 测试一律不读不写（测试不能碰玩家的进度），
## 测试里就是一份内存里的全新进度，可以随意改。

static var PATH := "user://meta.cfg"
static var probe := false          # tests/meta_probe：换单独文件名真写真读
const VER := 1
const BACKUPS := 3

# 声望（M5-8）
const PER_STAGE := 15
const CLEAR_BONUS := 60
const BORROW := [20, 40, 70, 120]   # 借书价：普通 / 精良 / 稀有 / 传说

static var d := {}
static var _loaded := false

static func _off() -> bool:
	return Memes._testing() and not probe

static func _fresh() -> Dictionary:
	return {"_ver": VER, "runs": 0, "prestige": 0, "prestige_total": 0, "unlocked": [],
		"storage_open": false, "office_open": false, "best_stage": 0, "clears": 0, "groups": ["base"]}

static func ensure() -> void:
	if _loaded:
		return
	_loaded = true
	d = _fresh()
	if _off() or not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var v = str_to_var(f.get_as_text())
	if v is Dictionary and int(v.get("_ver", 0)) == VER:
		for k in v:
			d[k] = v[k]

static func save() -> void:
	if _off():
		return
	# 滚动备份：meta.cfg.bak1（最新）… bak3（最旧）
	var g := ProjectSettings.globalize_path(PATH)
	for i in range(BACKUPS - 1, 0, -1):
		var a := g + ".bak%d" % i
		if FileAccess.file_exists(a):
			DirAccess.copy_absolute(a, g + ".bak%d" % (i + 1))
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(g, g + ".bak1")
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(d))

## 测试用：回到一份全新的内存进度
static func reset_for_test() -> void:
	_loaded = true
	d = _fresh()

static func get_v(k: String, def = null):
	ensure()
	return d.get(k, def)

static func storage_open() -> bool:
	return bool(get_v("storage_open", false))

static func prestige() -> int:
	return int(get_v("prestige", 0))

## 本局商店能出的物品：首局 25 件（Items.BASE）+ 借阅过的
static func pool() -> Array:
	ensure()
	var out: Array = Items.BASE.duplicate()
	for id in d.unlocked:
		if not out.has(id) and Items.ALL.has(id):
			out.append(id)
	return out

static func unlocked(id: String) -> bool:
	ensure()
	return Items.BASE.has(id) or d.unlocked.has(id)

## 一局结束（失败或通关）结算声望；paid = 这一局已经结算过的阶段数（通关后继续无尽，再结束只补新阶段）。
## 返回 {gain, stages, clear, opened: [新开放的楼层名]}
static func settle(run: Run) -> Dictionary:
	ensure()
	# 到达的阶段（从 1 数）：失败在第 s+1 阶段 = s+1；刚通关（stage=8）= 8；无尽里失败照样 +1
	var reached: int = run.stage + (0 if run.won() else 1)
	var stages: int = maxi(0, reached - run.meta_paid)
	var clear: bool = run.won() and not run.meta_cleared
	var base := stages * PER_STAGE + (CLEAR_BONUS if clear else 0)
	# 挑战合同：声望按倍数多给（M5-16；评审等级的倍数 M5c 再乘上）
	var mult := 1.0
	if run.challenge != "":
		mult *= 1.0 + float(Contracts.CHALLENGES[run.challenge].bonus)
	var gain := int(round(base * mult))
	run.meta_paid += stages
	if clear:
		run.meta_cleared = true
		d.clears = int(d.clears) + 1
	d.prestige = int(d.prestige) + gain
	d.prestige_total = int(d.prestige_total) + gain
	d.best_stage = maxi(int(d.best_stage), run.stage)   # 通过了几个阶段
	var opened: Array = []
	if not run.meta_counted:
		run.meta_counted = true
		d.runs = int(d.runs) + 1
	if not d.storage_open:
		d.storage_open = true          # M5 F18：第一局结束就开放（不论输赢）
		opened.append("storage")
	if not d.office_open and int(d.best_stage) >= 5:   # 通过第 5 阶段
		d.office_open = true           # 第一次通过第 5 阶段（M5b 再做办公室本身）
		opened.append("office")
	# 课题组解锁（M5-15）
	var g: Array = d.groups
	var want := {"theory": int(d.best_stage) >= 3, "engineering": run.eng_full_pass, "finance": run.spent >= 300, "postdoc": int(d.clears) >= 1}
	for gid in Contracts.GROUP_ORDER:
		if want.get(gid, false) and not g.has(gid):
			g.append(gid)
			opened.append("group:" + gid)
	save()
	return {"gain": gain, "base": base, "mult": mult, "stages": stages, "clear": clear, "opened": opened}

static func group_open(id: String) -> bool:
	ensure()
	return id == "base" or (d.groups as Array).has(id)

# —— 教授书架借阅（M5-9）——
static func borrow_price(id: String) -> int:
	return BORROW[Items.ALL[id].rarity]

## 借不了的原因（"" = 可以借）
static func borrow_block(id: String) -> String:
	ensure()
	if unlocked(id):
		return "已借阅"
	if Items.ALL[id].rarity == Items.LEGEND and int(d.clears) < 1:
		return "传说那一格：第一次通关后打开"
	if prestige() < borrow_price(id):
		return "声望不够（要 %d，现有 %d）" % [borrow_price(id), prestige()]
	return ""

static func borrow(id: String) -> String:
	var why := borrow_block(id)
	if why != "":
		return why
	d.prestige = prestige() - borrow_price(id)
	(d.unlocked as Array).append(id)
	save()
	return ""
