extends Node2D
## 主控：行走 ↔ 控制台推近 ↔ 引出开花 ↔ 结算（DECISIONS Q19/Q20/Q26）

enum M { WALK, ENTER, CONSOLE, SHOT, BLOOM, LOSING, RESULT, END }

var run: Run
var mode := M.WALK
var world: Node2D
var lab: Node2D
var chamber: Node2D
var detector: Node2D
var desk: Node2D
var player: Node2D
var shot: Node2D
var prompt: Node2D
var cam: Camera2D
var panel: Control
var clip_l: Control
var clip_r: Control
var overlay: Control
var grain: ColorRect

var cam_pos := Vector2(960, 540)
var cam_vel := Vector2.ZERO
var cam_zoom := 1.0
var cam_zv := 0.0
var cam_target := Vector2(960, 540)
var zoom_target := 1.0
var cam_omega := 4.2
var shake := 0.0

var cooldown := 0.0
var e_guard := 0.0
var timer := 0.0
var last_result := {}
var bloom_value := 0
var bloom_energy := 1
var test_mode := false

func _ready() -> void:
	_inputs()
	run = Run.new()
	world = Node2D.new()
	add_child(world)
	lab = _node("res://scripts/world/lab.gd", world)
	detector = _node("res://scripts/world/detector.gd", world)
	chamber = _node("res://scripts/world/chamber.gd", world)
	shot = _node("res://scripts/world/shot.gd", world)
	desk = _node("res://scripts/world/desk.gd", world)
	desk.set("main", self)
	player = _node("res://scripts/world/player.gd", world)
	prompt = _node("res://scripts/world/prompt.gd", world)
	cam = Camera2D.new()
	cam.position = cam_pos
	add_child(cam)
	cam.make_current()
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	clip_l = _ctrl("res://scripts/ui/clipboard.gd", ui)
	clip_l.set("side", -1)
	clip_r = _ctrl("res://scripts/ui/clipboard.gd", ui)
	clip_r.set("side", 1)
	panel = _ctrl("res://scripts/ui/console_panel.gd", ui)
	overlay = _ctrl("res://scripts/ui/overlay.gd", ui)
	for c in [clip_l, clip_r, panel, overlay]:
		c.set("main", self)
	var gl := CanvasLayer.new()
	gl.layer = 50
	add_child(gl)
	grain = ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/grain.gdshader")
	grain.material = gm
	gl.add_child(grain)
	shot.arrived.connect(_on_shot_arrived)
	Pal.changed.connect(_apply_theme)
	_apply_theme()
	chamber.empty()

func _node(path: String, parent: Node) -> Node2D:
	var n := Node2D.new()
	n.set_script(load(path))
	parent.add_child(n)
	return n

func _ctrl(path: String, parent: Node) -> Control:
	var c := Control.new()
	c.set_script(load(path))
	parent.add_child(c)
	return c

func _inputs() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E], "accelerate": [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER],
		"back": [KEY_ESCAPE], "theme": [KEY_F2], "restart": [KEY_R],
	}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
			for k in map[a]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(a, ev)

func _apply_theme() -> void:
	RenderingServer.set_default_clear_color(Pal.c("bg"))
	var gm: ShaderMaterial = grain.material
	gm.set_shader_parameter("strength", Pal.f("grain"))
	gm.set_shader_parameter("fiber", 0.0 if Pal.dark else 1.0)
	gm.set_shader_parameter("vignette", 0.28 if Pal.dark else 0.16)

# —— 查询（供 desk/面板用） ——
func has_beam() -> bool:
	return run.beam != null

func danger_high() -> bool:
	return run.beam != null and run.beam.odds()[Odds.LOSS] >= 0.2

func fmt(v: int) -> String:
	return preload("res://scripts/ui/clipboard.gd")._fmt(v)

# —— 输入 ——
func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_echo() or not ev.is_pressed():
		return
	if ev.is_action("theme"):
		Pal.set_dark(not Pal.dark)
		overlay.say("配色：" + ("七十年代实验室（暗）" if Pal.dark else "工程图纸（亮）"))
		return
	match mode:
		M.WALK:
			if ev.is_action("interact"):
				if _near_console():
					enter_console()
				elif _near_terminal():
					overlay.say("采购终端暂停营业（下个版本开放）")
		M.CONSOLE:
			if ev.is_action("accelerate"):
				accelerate()
			elif ev.is_action("interact") and e_guard <= 0.0:
				extract()
		M.BLOOM:
			if ev.is_action("accelerate") or ev.is_action("interact"):
				if timer > 0.5:
					_finish_bloom()
		M.RESULT:
			if ev.is_action("interact") or ev.is_action("accelerate"):
				if run.can_start():
					_new_beam()
			elif ev.is_action("back"):
				leave_console()
		M.END:
			if ev.is_action("restart"):
				restart()

func _near_console() -> bool:
	return absf(player.position.x - Geo.CONSOLE_STAND) < 70.0

func _near_terminal() -> bool:
	return absf(player.position.x - (Geo.TERMINAL_X + 35)) < 60.0

# —— 流程 ——
func enter_console() -> void:
	mode = M.ENTER
	player.input_enabled = false
	player.auto_target = Geo.CONSOLE_STAND
	prompt.hide_now()
	timer = 0.0

func _console_ready() -> void:
	player.t_console = 1.0
	cam_target = Vector2(Geo.CHAMBER.x, 630)
	zoom_target = 1.45
	cam_omega = 4.0
	panel.show_t = 1.0
	clip_l.show_t = 1.0
	clip_r.show_t = 1.0
	overlay.strip_t = 0.0
	_new_beam()

func _new_beam() -> void:
	overlay.hide_card()
	run.start_experiment()
	chamber.inject()
	panel.reset_beam()
	panel.val_disp = Odds.value_at(1)
	_sync()
	mode = M.CONSOLE
	e_guard = 0.4
	cooldown = 0.25

func accelerate() -> void:
	if cooldown > 0.0 or run.beam == null:
		return
	cooldown = 0.15
	panel.press()
	var r := run.accelerate()
	var k: int = r.outcome
	if r.lost:
		_lose(r)
		return
	chamber.kick(1.6 if k == Odds.PERFECT else (1.0 if k == Odds.SUCCESS else 0.5))
	shake = maxf(shake, 0.25 if k != Odds.PERFECT else 0.6)
	var txt: String = Odds.NAMES[k]
	if r.lock_started:
		txt = "锁相！"
		shake = 0.8
	overlay.stamp(txt, Pal.c("lock") if r.lock_started else Pal.outcome(k))
	_sync()

func _lose(r: Dictionary) -> void:
	mode = M.LOSING
	timer = 0.0
	chamber.lose()
	shake = 1.4
	panel.press()
	overlay.stamp("束流丢失", Pal.c("red"), true)
	last_result = {"lost": true, "energy": r.from, "p": r.odds[Odds.LOSS], "fin": r}
	panel.val_target = 0
	panel.hint = ""
	panel.enabled = false

func extract() -> void:
	if run.beam == null or cooldown > 0.0:
		return
	mode = M.SHOT
	timer = 0.0
	panel.pull()
	panel.enabled = false
	panel.hint = ""
	bloom_energy = run.beam.energy
	var kind := "burst" if run.beam.lock_used else ("dirty" if run.beam.energy >= 10 else "precise")
	detector.set_meta("kind", kind)
	shot.fire(Pal.ramp(clampf((bloom_energy - 1) / 12.0, 0.0, 1.0)))
	var fin := run.extract()
	bloom_value = fin.gained
	last_result = {"lost": false, "energy": bloom_energy, "fin": fin}
	chamber.empty()

func _on_shot_arrived() -> void:
	mode = M.BLOOM
	timer = 0.0
	detector.bloom(bloom_energy, detector.get_meta("kind", "precise"))
	cam_target = Geo.SCREEN.get_center() + Vector2(0, 60)
	zoom_target = 3.0
	cam_omega = 5.0
	panel.show_t = 0.0
	clip_l.show_t = 0.0
	clip_r.show_t = 0.0
	overlay.show_bloom(bloom_value)

func _finish_bloom() -> void:
	overlay.hide_bloom()
	cam_target = Vector2(Geo.CHAMBER.x, 630)
	zoom_target = 1.45
	cam_omega = 4.0
	panel.show_t = 1.0
	clip_l.show_t = 1.0
	clip_r.show_t = 1.0
	_show_result()

func _show_result() -> void:
	var fin: Dictionary = last_result.fin
	var lines: Array = []
	for s in fin.get("passed", []):
		lines.append("第 %d 阶段考核通过！" % (s + 1))
		clip_l.stamp("阶段 %d 通过" % (s + 1))
	panel.reset_beam()
	panel.val_target = 0
	chamber.set_state(1, 0.0, false)
	if run.won():
		mode = M.END
		overlay.show_card({"title": "科研资助续期！", "title_col": Pal.c("green"), "value": fmt(run.total) + " RP",
			"sub": "三个阶段全部通过 · 共 %d 次实验" % run.experiment_no, "lines": lines + ["实验室保住了。至少保住到下一个财年。"], "keys": "R  重新开始"})
		return
	if run.lost():
		mode = M.END
		overlay.show_card({"title": "科研资助终止", "title_col": Pal.c("red"), "value": fmt(run.total) + " / " + fmt(run.line()),
			"sub": "第 %d 阶段的实验次数用完了" % (run.stage + 1), "lines": lines + ["“经费的事，明年再说吧。” —— 校长"], "keys": "R  重新开始"})
		return
	mode = M.RESULT
	var keys := "E / 空格  注入新束流        Esc  离开控制台"
	if last_result.lost:
		overlay.show_card({"title": "实验 #%d · 束流丢失" % run.experiment_no, "title_col": Pal.c("red"), "value": "0 RP",
			"sub": "在 E%d 丢失（当时丢失概率 %.1f%%）" % [last_result.energy, last_result.p * 100.0], "lines": lines, "keys": keys})
	else:
		overlay.show_card({"title": "实验 #%d · 引出成功" % run.experiment_no, "value": "+" + fmt(fin.gained) + " RP",
			"sub": "E%d 引出 · 累计 %s / %s" % [last_result.energy, fmt(run.total), fmt(run.line())], "lines": lines, "keys": keys})

func leave_console() -> void:
	mode = M.WALK
	overlay.hide_card()
	player.t_console = 0.0
	player.auto_target = -1.0
	player.input_enabled = true
	panel.show_t = 0.0
	clip_l.show_t = 0.0
	clip_r.show_t = 0.0
	overlay.strip_t = 1.0
	cam_omega = 3.6
	chamber.empty()

func restart() -> void:
	run = Run.new()
	overlay.hide_card()
	leave_console()

func _sync() -> void:
	var b: Beam = run.beam
	if b == null:
		return
	var p := b.odds()
	panel.set_beam(b.energy, b.value(), p, b.charge, b.lock_left)
	panel.enabled = true
	chamber.set_state(b.energy, p[Odds.LOSS], b.locked())
	if run.total + b.value() >= run.line():
		panel.hint = "现在引出就能过关……还要再按吗？"
	elif p[Odds.LOSS] >= 0.2:
		panel.hint = "丢失概率已经很高了。"
	else:
		panel.hint = ""

# —— 每帧 ——
func _process(dt: float) -> void:
	cooldown = maxf(0.0, cooldown - dt)
	e_guard = maxf(0.0, e_guard - dt)
	timer += dt
	match mode:
		M.WALK:
			cam_target = Vector2(960 + clampf((player.position.x - 960) * 0.05, -36, 36), 540)
			zoom_target = 1.04
			if _near_console():
				prompt.show_at(Vector2(Geo.CONSOLE_STAND, Geo.FLOOR - 205), "E", "开始实验")
			elif _near_terminal():
				prompt.show_at(Vector2(Geo.TERMINAL_X + 35, Geo.FLOOR - 225), "E", "采购终端")
			else:
				prompt.hide_now()
		M.ENTER:
			if absf(player.position.x - Geo.CONSOLE_STAND) < 3.0 or timer > 1.6:
				_console_ready()
		M.LOSING:
			if timer > 1.5:
				overlay.st_t = -1.0
				_show_result()
		M.BLOOM:
			if timer > 2.6:
				_finish_bloom()
	# 相机：临界阻尼弹簧
	var r := Ink.spring2(cam_pos, cam_vel, cam_target, cam_omega, dt)
	cam_pos = r[0]; cam_vel = r[1]
	var z := Ink.spring(cam_zoom, cam_zv, zoom_target, cam_omega, dt)
	cam_zoom = z[0]; cam_zv = z[1]
	shake = maxf(0.0, shake - dt * 2.4)
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * shake * 9.0
	cam.position = cam_pos + sh
	cam.zoom = Vector2(cam_zoom, cam_zoom)
