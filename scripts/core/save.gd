class_name Save
## 一局的存档（DECISIONS Q58）：随时存全部状态——包括舱里正在跑的束流和两路随机数的状态，
## 退出再进完全接上；结果在按下加速那一刻就已经抽定并写进来，退出重进不能“重抽”。
## 单存档位：一局结束（失败、或通过第 8 阶段且没选继续挑战）就删掉。
## -s 测试既不读也不写（测试不能碰玩家的存档）。

static var PATH := "user://run.save"
static var probe := false        # tests/save_probe：换一个单独的文件名真写真读（不碰玩家的存档）
const VER := 1
const SKIP := ["rng", "shop_rng", "beam", "dev_force", "dev_roll", "dev_god"]

static func _off() -> bool:
	return Memes._testing() and not probe

static func exists() -> bool:
	return not _off() and FileAccess.file_exists(PATH)

static func clear() -> void:
	if _off():
		return
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

## 把一个对象的脚本变量收成字典（数组/字典深拷贝，跳过对象）
static func _props(o: Object, skip: Array) -> Dictionary:
	var d := {}
	for p in o.get_property_list():
		if not (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var k: String = p.name
		if k in skip:
			continue
		var v = o.get(k)
		if v is Object:
			continue
		d[k] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return d

static func pack(run: Run) -> Dictionary:
	var d := {"_ver": VER, "run": _props(run, SKIP), "rng": run.rng.state, "shop_rng": run.shop_rng.state}
	if run.beam != null:
		d["beam"] = _props(run.beam, [])
	return d

static func unpack(d: Dictionary) -> Run:
	if int(d.get("_ver", 0)) != VER or not d.has("run"):
		return null
	var rd: Dictionary = d.run
	var run := Run.new(int(rd.get("seed_value", 1)))
	for k in rd:
		run.set(k, rd[k])
	run.rng.state = int(d.get("rng", run.rng.state))
	run.shop_rng.state = int(d.get("shop_rng", run.shop_rng.state))
	if d.has("beam"):
		var b := Beam.new()
		for k in d.beam:
			b.set(k, d.beam[k])
		run.beam = b
	return run

## 摘要：主页“继续实验”那一行
static func summary() -> String:
	var run := read()
	if run == null:
		return ""
	var s := ("无尽 · 第 %d 阶段" % (run.stage + 1)) if run.endless else ("第 %d / %d 阶段" % [run.stage + 1, Run.LINES.size()])
	return s + " · 累计 %s RP" % _fmt(run.total)

static func _fmt(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if v < 0 else "") + s + out

static func write(run: Run) -> void:
	if _off() or run == null:
		return
	if run.failed or run.won():
		clear()
		return
	var tmp := PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(var_to_str(pack(run)))
	f.close()
	# 先写临时文件再改名：写到一半断电也不会把旧存档弄坏
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(PATH))

static func read() -> Run:
	if not exists():
		return null
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return null
	var v = str_to_var(f.get_as_text())
	f.close()
	if not v is Dictionary:
		return null
	return unpack(v)
