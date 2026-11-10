extends Node2D
## 主控：行走 ↔ 控制台推近 ↔ 引出开花 ↔ 结算（DECISIONS Q19/Q20/Q26）

enum M { WALK, ENTER, CONSOLE, SPIN, SHOT, BLOOM, LOSING, RESULT, END, SHOP, REVIEW, CHOICE, PLAN, TITLE, PAUSE }

var run: Run
var mode := M.WALK
var world: Node2D
var lab: Node2D
var chamber: Node2D
var pollution: Node2D
var form: Node2D            # 束流形态层
var title: Control          # 主页
var demo_t := 0.0           # 主页演示束流
var demo_wait := 0.0
var demo_n := 0
const DEMO_ROUTES := [[], ["note100", "third_draft"], ["lucky_cat", "plant"]]
var bloom_form := {}        # 这一束引出时的形态（成果卡）
var detector: Node2D
var desk: Node2D
var review: Node2D
var notice: Node2D          # 墙上的评审日程表 + 经费处理决定（点它重读开场信）
var bottles: Node2D         # 束流配额气瓶架
var stash: Node2D           # 回收站 / 注入器瓶座 / 储备柜（Q70）
var letter: Control         # 开场信
var goal_card := Callable()   # 庆祝播到 1.5 秒时升起“下一阶段目标”卡
var review_passed := false   # 审核台：刚通过一个阶段，卡片只剩“好的”
var player: Node2D
var shot: Node2D
var prompt: Node2D
var cam: Camera2D
var panel: Control
var charms: Control
var dev: Control
var cel: Control
var plans: Control
var clip_l: Control
var clip_r: Control
var overlay: Control
var grain: ColorRect
var ringmap: Node2D
var intro: Control
var play_intro := true
var gear: Node2D
var shop: Control
var tutorial: Control
var play_tutorial := true
var walk_goal := ""        # 点击寻路到达后要做的事：shop / console
var cursor := -1
var hover_interact := false
var mouse_sp := Vector2(-999, -999)   # 最近一次鼠标事件的屏幕坐标

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
var stop_until := 0.0     # 顿帧结束的真实时间（秒）
var slow_until := 0.0
var slow_scale := 1.0
var dev_speed := 1.0         # 开发者模式：整体加速
var dev_meme_always := false   # 开发者模式：每次引出都出奇葩事件（随机一种）
var dev_meme_force := ""
var meme_rng := RandomNumberGenerator.new()
var beat_t := 0.0
var count_tick := 0
var pending := {}          # 已抽定、等待揭晓的结果
var charge_snd: AudioStreamPlayer
var shown_e := 1            # 画面上正在显示的能级/危险（揭晓前不泄露新结果）
var shown_dang := 0.0
var shown_lock := false

func _ready() -> void:
	_inputs()
	meme_rng.randomize()
	run = Run.new()
	world = Node2D.new()
	add_child(world)
	lab = _node("res://scripts/world/lab.gd", world)
	ringmap = _node("res://scripts/world/ringmap.gd", world)
	ringmap.set("main", self)
	detector = _node("res://scripts/world/detector.gd", world)
	chamber = _node("res://scripts/world/chamber.gd", world)
	pollution = _node("res://scripts/world/pollution.gd", chamber)
	pollution.set("main", self)
	pollution.set("chamber", chamber)
	chamber.move_child(pollution, 1)      # 在束流之上、舱框之下
	form = _node("res://scripts/world/form_layer.gd", chamber)
	form.set("main", self)
	form.set("chamber", chamber)
	chamber.move_child(form, 2)           # 形态在污染之上、舱框之下
	shot = _node("res://scripts/world/shot.gd", world)
	gear = _node("res://scripts/world/gear.gd", world)
	gear.set("main", self)
	desk = _node("res://scripts/world/desk.gd", world)
	desk.set("main", self)
	review = _node("res://scripts/world/review.gd", world)
	review.set("main", self)
	notice = _node("res://scripts/world/notice.gd", world)
	notice.set("main", self)
	bottles = _node("res://scripts/world/bottles.gd", world)
	bottles.set("main", self)
	stash = _node("res://scripts/world/stash.gd", world)
	stash.set("main", self)
	Run.MANUAL_BASKET = true      # 满瓶要玩家亲手送到审核台才计分
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
	charms = _ctrl("res://scripts/ui/charms.gd", ui)
	cel = _ctrl("res://scripts/ui/celebrate.gd", ui)
	overlay = _ctrl("res://scripts/ui/overlay.gd", ui)
	shop = _ctrl("res://scripts/ui/shop.gd", ui)
	plans = _ctrl("res://scripts/ui/plans.gd", ui)
	plans.chosen.connect(_on_plan_chosen)
	shop.closed.connect(_on_shop_closed)
	tutorial = Control.new()
	tutorial.set_script(load("res://scripts/ui/tutorial.gd"))
	tutorial.set("main", self)
	if not play_tutorial:
		tutorial.set("persist", false)
	for c in [clip_l, clip_r, panel, charms, cel, overlay, shop, plans]:
		c.set("main", self)
	ui.add_child(tutorial)
	if not play_tutorial:
		tutorial.call_deferred("stop")
	var tl := CanvasLayer.new()
	tl.layer = 25
	add_child(tl)
	title = _ctrl("res://scripts/ui/title.gd", tl)
	title.set("main", self)
	title.start_game.connect(_on_title_start)
	title.continue_game.connect(_on_title_continue)
	title.quit_game.connect(func(): get_tree().quit())
	var il := CanvasLayer.new()
	il.layer = 30
	add_child(il)
	intro = _ctrl("res://scripts/ui/intro.gd", il)
	intro.finished.connect(_on_intro_done)
	letter = _ctrl("res://scripts/ui/letter.gd", il)
	letter.closed.connect(_on_letter_closed)
	var dl := CanvasLayer.new()
	dl.layer = 40
	add_child(dl)
	dev = _ctrl("res://scripts/ui/dev.gd", dl)
	dev.set("main", self)
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
	Options.load_and_apply()
	if play_intro:
		_open_title()

# —— 存档（Save）：状态一变就写；关窗口时再写一次 ——
var live_save := false      # 主页的演示束流不存；开始/继续一局后才存
var _save_t := 0.0
var _save_sig := 0

func _autosave(dt: float, force := false) -> void:
	if not live_save or mode == M.TITLE:
		return
	_save_t += dt
	if _save_t < 0.5 and not force:
		return
	_save_t = 0.0
	var sig := var_to_str(Save.pack(run)).hash()
	if sig != _save_sig or force:
		_save_sig = sig
		Save.write(run)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave(0.0, true)

## 主页“继续实验”：读档，舱里有束流就直接回控制台接着按
func _on_title_continue() -> void:
	var loaded := Save.read()
	if loaded == null:
		_on_title_start()
		return
	resume(loaded)

## 接着玩一局读回来的存档（测试也直接调这个）
func resume(loaded: Run) -> void:
	run = loaded
	tutorial.stop()      # 读档接着玩不重放教程
	live_save = true
	_save_sig = 0
	chamber.empty()
	form.reset()
	form.shatter_t = -1.0
	overlay.strip_t = 1.0
	title.demo_text = ""
	panel.dec = {}
	panel.reset_beam()
	timer = 0.0
	cam_pos = Vector2(1000, 520)
	cam_zoom = 1.45
	cam_omega = 2.2
	player.input_enabled = true
	mode = M.WALK
	Sfx.play("paper", -6.0, 0.9)
	overlay.say("读取存档：第 %d 阶段 · 累计 %s RP" % [run.stage + 1, fmt(run.total)])
	if not run.plan_offers.is_empty():
		# 存档时正在挑计划书
		mode = M.PLAN
		player.input_enabled = false
		plans.show_plans(run.plan_offers, run.stage + 1)
	elif run.beam != null:
		chamber.inject()
		_sync()
		player.position.x = Geo.CONSOLE_STAND - 80
		enter_console()

func _on_intro_done() -> void:
	player.input_enabled = true
	cam_omega = 2.2
	# 第一次开局：剖面图之后先递上那封信（交代破产、8 次评审、3 瓶束流、审核台）
	if tutorial.active and not letter_seen:
		open_letter()

var letter_seen := false

func open_letter() -> void:
	letter_seen = true
	player.input_enabled = false
	letter.show_letter()

func _on_letter_closed() -> void:
	if mode == M.WALK:
		player.input_enabled = true

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
		"back": [KEY_ESCAPE], "submit": [KEY_F], "take": [KEY_Q], "help": [KEY_F1], "theme": [KEY_F2], "restart": [KEY_R],
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
	return run.beam != null and run.odds()[Odds.LOSS] >= 0.2

func fmt(v: int) -> String:
	return preload("res://scripts/ui/clipboard.gd")._fmt(v)

# —— 输入 ——
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_QUOTELEFT:
		dev.toggle()
		return
	if ev is InputEventMouse:
		if dev.mouse(ev):
			return
		_mouse(ev)
		return
	if ev.is_echo() or not ev.is_pressed():
		return
	if intro.active:
		intro.skip()
		return
	if letter.open:
		letter.press()
		return
	if mode == M.TITLE:
		title.handle(ev)
		return
	if ev.is_action("help"):
		tutorial.persist = false
		tutorial.start(true)
		return
	if ev.is_action("theme"):
		Pal.set_dark(not Pal.dark)
		overlay.say("配色：" + ("七十年代实验室（暗）" if Pal.dark else "工程图纸（亮）"))
		return
	match mode:
		M.SHOP:
			shop.handle(ev)
		M.PLAN:
			plans.handle(ev)
		M.PAUSE:
			if ev.is_action("back"):
				to_title()
			elif ev.is_action("interact") or ev.is_action("accelerate"):
				close_pause()
		M.WALK:
			if ev.is_action("back"):
				open_pause()
			elif ev.is_action("interact"):
				if _near_console():
					enter_console()
				elif _near_terminal():
					open_shop()
				elif _near_review():
					_review_e()
				elif _spot() != "":
					_spot_do(_spot())
			elif ev.is_action("take") and _near_review():
				_review_q()
		M.CHOICE:
			if ev.is_action("interact"):
				_sch_end()
			elif ev.is_action("accelerate"):
				_sch_go()
		M.REVIEW:
			if ev.is_action("back"):
				close_review()
			elif ev.is_action("submit") or ev.is_action("interact") or ev.is_action("accelerate"):
				if review_passed:
					close_review()
				elif _review_can_submit():
					submit()
		M.SPIN:
			if ev.is_action("accelerate"):
				panel.skip()
		M.CONSOLE:
			if ev.is_action("accelerate"):
				if run.beam == null:
					_next_beam()
				else:
					accelerate()
			elif ev.is_action("interact") and e_guard <= 0.0:
				if run.beam == null:
					_next_beam()
				else:
					extract()
			elif ev.is_action("back"):
				leave_console()
			elif ev is InputEventKey and ev.physical_keycode == KEY_B:
				press_red()
		M.BLOOM:
			if ev.is_action("accelerate") or ev.is_action("interact"):
				if timer > 0.5:
					_finish_bloom()
		M.RESULT:
			if run.must_submit():
				if ev.is_action("submit") or ev.is_action("accelerate") or ev.is_action("interact"):
					submit()
			elif ev.is_action("submit"):
				submit()
			elif ev.is_action("interact") or ev.is_action("accelerate"):
				if run.can_start() and run.inj == "fresh":
					_new_beam()
			elif ev.is_action("back"):
				leave_console()
		M.END:
			if ev.is_action("back"):
				to_title()
			elif ev.is_action("restart"):
				restart()
			elif ev is InputEventKey and ev.physical_keycode == KEY_C and run.won():
				go_endless()

func _near_console() -> bool:
	return absf(player.position.x - Geo.CONSOLE_STAND) < 70.0

func _near_review() -> bool:
	return absf(player.position.x - review.STAND) < 60.0

func _near_terminal() -> bool:
	return absf(player.position.x - (Geo.TERMINAL_X + 35)) < 60.0

# —— 流程 ——
func enter_console() -> void:
	if run.beam == null and not run.can_start() and not run.won() and not run.failed:
		overlay.say("本阶段的束流用完了——去右边的审核台提交考核")
		Sfx.play("hit_low", -10.0, 1.3)
		return
	if run.beam == null and not run.won() and not run.failed:
		if run.held != "":
			overlay.say("先把手里的瓶子放下")
			Sfx.play("hit_low", -10.0, 1.3)
			return
		if run.inj != "fresh":
			overlay.say(_inj_hint())
			Sfx.play("hit_low", -10.0, 1.3)
			return
	mode = M.ENTER
	player.input_enabled = false
	player.auto_target = Geo.CONSOLE_STAND
	prompt.hide_now()
	timer = 0.0

func _console_ready() -> void:
	Sfx.play("paper", -6.0)
	Sfx.play("btn2", -8.0, 0.8)
	player.t_console = 1.0
	cam_target = Vector2(Geo.CHAMBER.x, 630)
	zoom_target = 1.45
	cam_omega = 4.0
	panel.show_t = 1.0
	clip_l.show_t = 1.0
	clip_r.show_t = 1.0
	overlay.strip_t = 0.0
	if run.beam != null:
		# 中途离开又回来：束流还在舱里，接着加速
		Sfx.play("arc", -16.0, 1.2)
		_sync()
		mode = M.CONSOLE
		e_guard = 0.4
		cooldown = 0.25
		overlay.say("束流还在，继续实验")
	else:
		_new_beam()

func _new_beam() -> void:
	overlay.hide_card()
	Sfx.play("arc", -14.0, 1.4)
	Sfx.play("btn2", -6.0)
	run.start_experiment()
	chamber.inject()
	form.reset()
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
	var b: Beam = run.beam
	var was_locked := b.locked()
	var p := run.odds()
	var danger := p[Odds.LOSS]
	panel.press()
	player.press()
	var r := run.accelerate()        # 结果在按下瞬间按真实概率抽定；下面只是揭晓
	pending = r
	# 指针落点：结果所在色段内的随机位置
	# 指针停在“原始结果”上：饰品改写的，先让玩家看到原来抽中了什么
	var shown_k: int = r.get("raw", r.outcome)
	var acc := 0.0
	for k in shown_k:
		acc += p[k]
	var target := acc + p[shown_k] * randf_range(0.18, 0.82)
	var T := 0.45 if was_locked else 0.95 + clampf(danger / 0.35, 0.0, 1.0) * 0.65
	var laps := 1 if was_locked else 2 + int(danger * 4.0)
	panel.spin(target, T, laps)
	mode = M.SPIN
	timer = 0.0
	chamber.t_charge = 1.0
	Sfx.charge_boost = 0.35
	charge_snd = Sfx.play("arc", -9.0, 1.0 / T * 0.9 + (0.4 if was_locked else 0.0), 0.02)
	Sfx.play("btn", -4.0, 0.9)
	cam_zv += 0.08

## 指针停稳：对撞 → 揭晓
func _reveal() -> void:
	var r := pending
	pending = {}
	chamber.t_charge = 0.0
	chamber.collide = -1.0
	Sfx.charge_boost = 0.0
	if charge_snd and charge_snd.playing:
		charge_snd.stop()
	ringmap.lap()
	var raw: int = r.get("raw", r.outcome)
	if raw != r.outcome:
		# 先揭晓原始结果（盖章 + 对应的音效与震动），停一拍，再让饰品跳出来改写
		mode = M.SPIN
		_pre_reveal(raw)
		await get_tree().create_timer(0.6 / dev_speed, true, false, true).timeout
	_triggers(r)
	# 有“抽卡”的饰品：先让它在屏幕中央转完、揭晓中没中；改写类饰品要等它飞出来亮完相
	var wait: float = charms.roll_wait()
	if raw != r.outcome:
		wait = maxf(wait, 0.75)
	if wait > 0.0:
		mode = M.SPIN
		await get_tree().create_timer(wait / dev_speed, true, false, true).timeout
	mode = M.CONSOLE
	if raw != r.outcome:
		overlay.strike_next = true
	if r.get("sch", false):
		_sch_choice(r)
		return
	if r.lost:
		_lose(r)
		return
	_impact(r)
	_sync()

## 绝对不能按的红色按钮：抽四格转盘，揭晓后执行
func press_red() -> void:
	if mode != M.CONSOLE or not run.can_press_red() or cooldown > 0.0:
		return
	var segs_c := [Pal.c("gold"), Pal.c("lock"), Pal.c("red"), Pal.c("blue")]
	var res := run.press_red()
	var segs: Array = []
	for i in Run.RED_SEGS.size():
		segs.append([Run.RED_SEGS[i][0], Run.RED_SEGS[i][1], segs_c[i]])
	Sfx.play("btn", 0.0, 0.6)
	Sfx.play("discharge", -8.0, 1.6)
	shake = maxf(shake, 0.5)
	charms.fire("red_button", Run.RED_SEGS[res.pick][1], {"segs": segs, "pick": res.pick, "hit": res.pick != 2, "p": 0.0})
	mode = M.SPIN
	await get_tree().create_timer(charms.roll_wait() / dev_speed, true, false, true).timeout
	mode = M.CONSOLE
	match int(res.pick):
		0:
			Sfx.play("perfect", -2.0, 0.8)
			chamber.kick(2.4, Pal.c("gold"))
			overlay.pop("×10", Pal.c("gold"), true)
			overlay.stamp("潜在成果 ×10", Pal.c("gold"))
			hitstop(0.14)
			shake = 0.9
			_sync()
		1:
			Sfx.play("arc", -2.0, 1.1)
			Sfx.play("ring", -5.0, 1.2)
			overlay.flash_lock()
			overlay.stamp("锁相！", Pal.c("lock"))
			hitstop(0.12)
			_sync()
		2:
			last_result = {"lost": true, "energy": res.from, "p": 1.0, "fin": res}
			_lose(res)
		3:
			if res.gift != "":
				gear_bought()
				Sfx.play("metal", -4.0, 1.3)
				overlay.stamp("天降：" + Items.ALL[res.gift].name, Pal.c("blue"))
				charms.fire(res.gift, "从红按钮里掉出来的")

## 薛定谔的实验报告：束流“既丢了又没丢”，玩家二选一
func _sch_choice(r: Dictionary) -> void:
	mode = M.CHOICE
	Sfx.play("glass", -6.0, 1.3)
	Sfx.play("ring", -6.0, 0.6)
	chamber.kick(1.4, Pal.c("lock"))
	overlay.flash_red(0.5)
	overlay.stamp("束流丢失？", Pal.c("lock"), false, true)
	shake = 0.6
	hitstop(0.1)
	var keep := int(floor(run.potential() * 0.3))
	var q := run.odds()
	var win: float = q[Odds.SUCCESS] + q[Odds.PERFECT] + q[Odds.SUPER]
	overlay.show_card({"title": "薛定谔的实验报告 · 待定", "title_col": Pal.c("lock"), "value": "E%d：既丢了，又没丢" % run.beam.energy,
		"sub": "盒子还没打开。你来决定。",
		"lines": ["结束：保留 30%%，拿走 %s RP。" % fmt(keep),
			"再加速一次：加速成功 / 完美 / 超级同步就撤销丢失（%.0f%%）；" % (win * 100.0),
			"　　　　　　其他任何结果，全部归零。"], "keys": ""})

func _sch_end() -> void:
	overlay.hide_card()
	var fin := run.sch_end()
	last_result = {"lost": true, "energy": int(shown_e), "p": 1.0, "fin": fin}
	Sfx.play("paper", -4.0, 0.9)
	chamber.lose()
	form.shatter()
	overlay.strike_next = true
	overlay.stamp("保留 30%", Pal.c("lock"))
	mode = M.LOSING
	timer = 0.0

func _sch_go() -> void:
	overlay.hide_card()
	run.beam.sch_gamble = true
	mode = M.CONSOLE
	cooldown = 0.0
	Sfx.play("arc", -4.0, 0.8)
	overlay.strike_next = true
	overlay.stamp("再赌一次！", Pal.c("red"))
	accelerate()

## 原始结果的揭晓：只盖章、出声、轻震，不执行（之后可能被饰品改写）
func _pre_reveal(k: int) -> void:
	var col := Pal.outcome(k)
	match k:
		Odds.LOSS:
			Sfx.play("glass", -6.0, 1.0)
			Sfx.play("hit_low", -4.0, 0.7)
			overlay.flash_red(0.9)
			chamber.kick(1.2, col)
			shake = maxf(shake, 0.8)
			hitstop(0.08)
		Odds.DETUNE:
			Sfx.play("crackle", -4.0, 1.0)
			chamber.kick(0.7, col)
			shake = maxf(shake, 0.4)
		_:
			Sfx.play("hit_low", -10.0, 1.1)
			chamber.kick(0.4, col)
	overlay.stamp(Odds.NAMES[k], col, false, true)

func _lose(r: Dictionary) -> void:
	mode = M.LOSING
	timer = 0.0
	chamber.lose()
	form.shatter()
	shake = 1.5
	panel.press()
	player.press()
	Sfx.play("btn", -4.0)
	Sfx.play("glass", 0.0, 0.9)
	Sfx.play("discharge", -1.0)
	Sfx.play("boom", -1.0, 0.8)
	hitstop(0.20)
	slowmo(0.55, 0.35)
	cam_vel += Vector2(0, -380)
	cam_zv += 0.5
	overlay.flash_red(1.0)
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
	Sfx.play("lever", -2.0)
	Sfx.play("whoosh", -6.0, 1.15)
	hitstop(0.06)
	panel.enabled = false
	panel.hint = ""
	bloom_energy = run.beam.energy
	var kind := "burst" if run.beam.lock_used else ("dirty" if run.beam.energy >= 10 else "precise")
	detector.set_meta("kind", kind)
	shot.fire(Pal.ramp(clampf((bloom_energy - 1) / 12.0, 0.0, 1.0)))
	bloom_form = Forms.of(run)
	bloom_form["first"] = Forms.record(bloom_form)
	bloom_form["no"] = run.experiment_no
	var fin := run.extract()
	_triggers(fin)
	bloom_value = fin.gained
	last_result = {"lost": false, "energy": bloom_energy, "fin": fin}
	chamber.empty()

func _on_shot_arrived() -> void:
	# 推荐信在引出时抽卡：等它揭晓了再开花
	var wait: float = charms.roll_wait()
	if wait > 0.0:
		await get_tree().create_timer(wait / dev_speed, true, false, true).timeout
	mode = M.BLOOM
	timer = 0.0
	# 奇葩事件：约 1/8 概率径迹拼成梗图（纯画面，单独的随机数）
	var mm: String = Memes.roll(bloom_energy, meme_rng, "woodfish" if dev_meme_always else "")
	if dev_meme_force != "":
		mm = dev_meme_force
		dev_meme_force = ""
	detector.form = bloom_form
	detector.bloom(bloom_energy, detector.get_meta("kind", "precise"), mm)
	overlay.bloom_meme = {}
	if mm != "":
		var first := Memes.record(mm)
		overlay.bloom_meme = {"name": Memes.LIST[mm].name, "first": first}
		Sfx.play("perfect", -8.0, 1.6)
		Sfx.play("tick", -6.0, 2.0)
	Sfx.play("metal", -3.0, 0.9 + bloom_energy * 0.02)
	Sfx.play("ring", -9.0)
	shake = 0.5
	hitstop(0.07)
	cam_target = Geo.SCREEN.get_center() + Vector2(0, 60)
	zoom_target = 3.0
	cam_omega = 5.0
	panel.show_t = 0.0
	clip_l.show_t = 0.0
	clip_r.show_t = 0.0
	overlay.show_bloom(bloom_value)
	overlay.form_card = bloom_form

func _finish_bloom() -> void:
	overlay.hide_bloom()
	cam_target = Vector2(Geo.CHAMBER.x, 630)
	zoom_target = 1.45
	cam_omega = 4.0
	panel.show_t = 1.0
	clip_l.show_t = 1.0
	clip_r.show_t = 1.0
	_show_result()

## 一次实验结束：不弹结算卡，只让一张纸条报出这一束加了多少，然后留在控制台
func _after_experiment() -> void:
	var fin: Dictionary = last_result.fin
	Sfx.play("paper", -8.0)
	panel.reset_beam()
	panel.val_target = 0
	chamber.set_state(1, 0.0, false)
	chamber.empty()
	mode = M.CONSOLE
	e_guard = 0.35
	var g: int = fin.get("gained", 0)
	var tax: int = fin.get("tax", 0)
	# 有成果就装回瓶子：满瓶跟着报告一起出现，再飞进审核台的篮子（Q70）
	var bt: Dictionary = run.basket[-1] if g > 0 and not run.basket.is_empty() else {}
	if last_result.lost and tax > 0:
		# 已够线还赌、丢了：扣分（可能跌回线下）
		overlay.tally("实验 #%d · 够线后丢失 · 扣 %d%%" % [run.experiment_no, int(Run.OVERLINE_TAX * 100)], ("+%s RP" % fmt(g - tax)) if g >= tax else ("−%s RP" % fmt(tax - g)), "经费 +$%d" % fin.get("income", 0), Pal.c("red"), bt)
		clip_l.stamp("扣 %s" % fmt(tax))
		Sfx.play("hit_low", -4.0, 0.7)
	elif last_result.lost:
		overlay.tally("实验 #%d · 束流丢失" % run.experiment_no, ("+%d RP（稿纸抢救）" % g) if g > 0 else "+0 RP", "经费 +$%d" % fin.get("income", 0), Pal.c("red"), bt)
	else:
		overlay.tally("实验 #%d · E%d 引出" % [run.experiment_no, last_result.energy], "+%s RP" % fmt(g), "经费 +$%d" % fin.get("income", 0), Pal.c("green"), bt)
	_idle_hint()

## 控制台空着（没有束流）时面板上的提示
func _idle_hint() -> void:
	panel.enabled = false
	panel.dec = {}
	if run.won() or run.failed:
		panel.hint = ""
	elif run.inj == "full":
		panel.hint = "成果装在注入器的瓶子里了：拿去审核台放进篮子，才算科研点"
	elif run.experiments_left <= 0:
		panel.hint = "本阶段束流用完了 → 去审核台提交考核"
	elif run.can_submit():
		panel.hint = "已够线：可以去审核台提交，也可以去换一瓶氢气再来一束（剩 %d 瓶）" % run.experiments_left
	else:
		panel.hint = "去左边换一瓶氢气，装好再回来开始下一束（本阶段还剩 %d 瓶）" % run.experiments_left

## 控制台里没有束流时按加速：注入下一束；用完了就提示去审核台
func _next_beam() -> void:
	if cooldown > 0.0:
		return
	if run.can_start() and run.inj != "fresh":
		# 全手动换瓶（Q70）：瓶座上没有新瓶，控制台里开不了下一束
		overlay.say("先离开控制台：" + _inj_hint())
		Sfx.play("hit_low", -10.0, 1.3)
		cooldown = 0.4
	elif run.can_start():
		_new_beam()
	elif not run.won() and not run.failed:
		overlay.say("本阶段的束流用完了——去审核台提交考核")
		Sfx.play("hit_low", -10.0, 1.3)
		cooldown = 0.4

func _show_result() -> void:
	_after_experiment()
	return
	var fin: Dictionary = last_result.fin
	Sfx.play("paper", -8.0)
	panel.reset_beam()
	panel.val_target = 0
	chamber.set_state(1, 0.0, false)
	mode = M.RESULT
	var lines: Array = []
	var keys := _result_keys()
	if run.must_submit():
		lines.append("本阶段实验次数用完了，必须提交考核。")
	elif run.can_submit():
		lines.append("累计已够本阶段考核线——可以现在提交，也可以接着做实验多攒分。")
	lines.append("经费 +$%d（现有 $%d）" % [fin.get("income", 0), run.money])
	if last_result.lost:
		var sv: int = fin.get("gained", 0)
		overlay.show_card({"title": "实验 #%d · 束流丢失" % run.experiment_no, "title_col": Pal.c("red"), "value": ("+%s RP（稿纸抢救）" % fmt(sv)) if sv > 0 else "0 RP",
			"sub": "在 E%d 丢失（当时丢失概率 %.1f%%）· 累计 %s / %s" % [last_result.energy, last_result.p * 100.0, fmt(run.total), fmt(run.line())], "lines": lines, "keys": keys})
	else:
		overlay.show_card({"title": "实验 #%d · 引出成功" % run.experiment_no, "value": "+" + fmt(fin.gained) + " RP",
			"sub": "E%d 引出 · 累计 %s / %s" % [last_result.energy, fmt(run.total), fmt(run.line())], "lines": lines, "keys": keys})

func _result_keys() -> String:
	if run.must_submit():
		return "F / 空格  提交考核"
	if run.can_submit():
		return "E / 空格  继续实验      F  提交考核      Esc  离开（去采购）"
	return "E / 空格  注入新束流        Esc  离开控制台（去采购）"

## 提交考核：够线进入下一阶段，不够则资助终止
func submit() -> void:
	if not _review_can_submit():
		return
	var res := run.submit()
	review.bump = 1.0
	if res.passed and res.get("left", 0) > 0:
		bottles.refund(res.left, res.leftover)
	if res.passed:
		clip_l.stamp("阶段 %d 通过" % (res.stage + 1))
		Sfx.play("btn", 0.0, 0.6)
		Sfx.play("metal", -5.0, 1.2)
		Sfx.play("ring", -10.0, 1.1)
		shake = 0.5
		hitstop(0.08)
		if run.won():
			mode = M.END
			Save.clear()
			overlay.show_card({"title": "科研资助续期！", "title_col": Pal.c("green"), "value": fmt(run.total) + " RP",
				"sub": "%d 个阶段全部通过 · 共 %d 次实验" % [Run.LINES.size(), run.experiment_no],
				"lines": ["实验室保住了。至少保住到下一个财年。", "想看看能撑到第几阶段？继续挑战：考核线每阶段 ×%.2f，没有终点。" % Run.ENDLESS_G],
				"keys": "C  继续挑战（无尽）      R  重新开始"})
			return
		mode = M.REVIEW
		review_passed = true
		overlay.hide_card()
		overlay.card_v = 0.0
		var quips := ["经费续上了。今晚终于能睡个好觉。", "校长点了点头。你偷偷松了口气。", "差点就要去隔壁实验室打工了。", "导师说“还行”。这是他说过最高的评价。", "实验室保住了。至少保住到下一次考核。"]
		cel.start(res.stage + 1, quips[(res.stage + run.experiment_no) % quips.size()])
		Sfx.play("perfect", -2.0, 0.8)
		Sfx.play("metal", -4.0, 0.7)
		hitstop(0.12)
		shake = 1.2
		# 1.5 秒后升起“下一阶段目标”卡片
		var carry := run.total
		var nl := run.line()
		goal_card = func():
			if mode != M.REVIEW or not review_passed:
				return
			Sfx.play("paper", -4.0, 0.9)
			var lines: Array = ["束流重新配给 %d 束 · 阶段奖金 +$%d%s" % [Run.PER_STAGE, res.bonus, "（大考翻倍）" if res.big else ""]]
			if res.leftover > 0:
				lines.append("提前提交：没用的 %d 束折成经费 +$%d" % [res.left, res.leftover])
			if Run.is_big(run.stage):
				lines.append("下一阶段是大考：考核线明显更高。")
			if carry >= nl:
				lines.append("攒下的分已经够这一关了！想交，回审核台再交一次。")
			else:
				lines.append("已经带过去 %s RP，还差 %s RP。" % [fmt(carry), fmt(nl - carry)])
			overlay.show_card({"title": ("下一阶段目标 · 第 %d 阶段（大考）" if Run.is_big(run.stage) else "下一阶段目标 · 第 %d 阶段") % (run.stage + 1), "title_col": Pal.c("blue"), "value": "%s RP" % fmt(nl),
				"sub": "累计分达到 %s 即可提交（现在 %s，%d%%）" % [fmt(nl), fmt(carry), int(100.0 * carry / maxf(1.0, nl))], "lines": lines, "keys": "", "dy": 150.0})
	else:
		mode = M.END
		Save.clear()
		Sfx.play("boom", -3.0, 0.7)
		overlay.show_card({"title": "科研资助终止", "title_col": Pal.c("red"), "value": fmt(run.total) + " / " + fmt(run.line()),
			"sub": "第 %d 阶段考核未达标" % (run.stage + 1), "lines": ["“经费的事，明年再说吧。” —— 校长"], "keys": "R  重新开始"})

func _on_plan_chosen(id: String) -> void:
	var r := run.choose_plan(id)
	var d: Dictionary = Plans.LIST[id]
	mode = M.WALK
	player.input_enabled = true
	var note := ""
	if r.money > 0:
		note = "，经费 +$%d" % r.money
	elif r.money < 0:
		note = "，经费 −$%d" % -r.money
	overlay.say("本阶段计划书：" + d.name + note)
	Sfx.play("paper", -6.0, 1.2)

## 开发者模式：立刻发三份计划书来挑
func dev_plans() -> void:
	if mode != M.WALK and mode != M.CONSOLE:
		return
	if mode == M.CONSOLE:
		leave_console()
	run.plan_offers = Plans.deal(meme_rng)
	mode = M.PLAN
	player.input_enabled = false
	plans.show_plans(run.plan_offers, run.stage + 1)

## 审核台：查看本阶段进度，够线（或束流用完）时提交
func _review_can_submit() -> bool:
	return run.beam == null and (run.can_submit() or run.must_submit())

func open_review() -> void:
	mode = M.REVIEW
	review_passed = false
	player.input_enabled = false
	prompt.hide_now()
	Sfx.play("paper", -4.0, 0.9)
	_review_card()

func _review_card() -> void:
	var lines: Array = []
	var title_col := Pal.c("text")
	if run.inj == "full":
		lines.append("注入器上还有一瓶成果（%s RP）没送来——拿过来放进篮子才算分。" % fmt(int(run.inj_bt.get("value", 0))))
	if run.beam != null:
		lines.append("控制台那边还有一束没结束——先回去引出（或者让它丢了）才能提交。")
	elif run.can_submit():
		lines.append("累计已经够线。现在提交就进入下一阶段，多出来的分会带过去。")
		if run.experiments_left > 0:
			lines.append("也可以先不交：还剩 %d 束，接着攒分。" % run.experiments_left)
		title_col = Pal.c("green")
	elif run.must_submit():
		lines.append("束流用完了，还差 %s RP。只能提交——结果可能不太好看。" % fmt(run.line() - run.total))
		title_col = Pal.c("red")
	else:
		lines.append("还差 %s RP 才够线。本阶段还剩 %d 束。" % [fmt(run.line() - run.total), run.experiments_left])
	if run.plan != "":
		lines.append("本阶段计划书：" + Plans.LIST[run.plan].name)
	overlay.show_card({"title": "第 %d 阶段考核" % (run.stage + 1), "title_col": title_col, "value": "%s / %s RP" % [fmt(run.total), fmt(run.line())],
		"sub": "已做 %d 次实验 · 剩余束流 %d" % [run.experiment_no - (1 if run.beam != null else 0), run.experiments_left], "lines": lines, "keys": ""})

func close_review() -> void:
	# 刚过阶段：先挑本阶段的科研计划书
	if review_passed and not run.plan_offers.is_empty():
		overlay.hide_card()
		cel.finish()
		goal_card = Callable()
		review_passed = false
		mode = M.PLAN
		plans.show_plans(run.plan_offers, run.stage + 1)
		return
	overlay.hide_card()
	cel.finish()     # 庆祝收尾淡出
	review_passed = false
	mode = M.WALK
	player.input_enabled = true
	Sfx.play("paper", -8.0, 1.1)

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
	panel.show_leave = false
	if run.beam == null:
		chamber.empty()
	else:
		overlay.say("束流在舱里等你，随时回控制台继续")

# —— Esc：回到主页（用户 2026-11-08）——
## 走动时按 Esc 先弹确认卡（防误按）；进度一直在自动存，主页点“继续实验”接着玩
func open_pause() -> void:
	mode = M.PAUSE
	player.input_enabled = false
	Sfx.play("paper", -6.0, 1.0)
	overlay.show_card({"title": "回到主页？", "title_col": Pal.c("blue"), "value": "已攒 %s RP" % fmt(run.total),
		"sub": "第 %d 次评审 · 进度已自动保存" % (run.stage + 1), "lines": ["回到主页后点“继续实验”，从这里接着玩。"], "keys": ""})

func close_pause() -> void:
	overlay.hide_card()
	mode = M.WALK
	player.input_enabled = true
	Sfx.play("paper", -8.0, 1.2)

func to_title() -> void:
	if mode != M.END:
		_autosave(0.0, true)
	live_save = false
	overlay.hide_card()
	overlay.card_v = 0.0
	tutorial.stop()
	if letter.open:
		letter.open = false
		letter.visible = false
	cel.finish()
	plans.open = false
	leave_console()
	chamber.empty()
	form.reset()
	Sfx.play("whoosh", -8.0, 0.8)
	_open_title()

## 通过第 8 阶段后继续挑战：考核线每阶段 ×ENDLESS_G，先挑计划书再接着做
func go_endless() -> void:
	if not run.won():
		return
	run.go_endless()
	review_passed = true
	Sfx.play("btn", -4.0, 0.8)
	overlay.say("继续挑战：第 %d 阶段起没有终点，考核线每阶段 ×%.2f" % [run.stage + 1, Run.ENDLESS_G])
	close_review()
	Save.write(run)

func restart() -> void:
	run = Run.new()
	_begin_tutorial()
	if tutorial.active:
		open_letter()
	overlay.hide_card()
	leave_console()

func _sync() -> void:
	var b: Beam = run.beam
	if b == null:
		return
	var p := run.odds()
	panel.set_beam(b.energy, run.potential(), p, b.charge, b.lock_left)
	shown_e = b.energy
	shown_lock = b.locked()
	shown_dang = 0.0 if shown_lock else p[Odds.LOSS]
	panel.enabled = true
	chamber.set_state(b.energy, p[Odds.LOSS], b.locked())
	panel.hint = ""
	panel.dec = {"total": run.total, "pot": run.potential(), "line": run.line(), "tax": run.overline_tax(), "loss": 0.0 if b.locked() else p[Odds.LOSS],
		"prot": run.protections(), "lock_left": b.lock_left}

# —— 每帧 ——
func _process(dt: float) -> void:
	_hover()
	_autosave(dt)
	var now := Time.get_ticks_usec() / 1e6
	if now >= stop_until:
		Engine.time_scale = (slow_scale if now < slow_until else 1.0) * dev_speed
	var dang := 0.0
	panel.show_red = (mode == M.CONSOLE or mode == M.SPIN) and run.has("red_button") and run.beam != null
	panel.red_used = run.beam != null and run.beam.red_used
	panel.show_leave = mode == M.CONSOLE
	if run.beam == null and run.inj == "full":
		panel.leave_label = "← 去拿成果"
	else:
		panel.leave_label = "← 去审核台" if (run.beam == null and (run.experiments_left <= 0 or run.can_submit())) else ("← 去换瓶" if run.beam == null and run.inj != "fresh" else "← 先去采购")
	if mode == M.CONSOLE or mode == M.SPIN:
		dang = shown_dang
		Sfx.set_hum(true, shown_e, clampf(dang / 0.35, 0.0, 1.0), shown_lock)
		# 危险心跳：丢失概率越高越快、越重
		if dang >= 0.12:
			beat_t -= dt
			if beat_t <= 0.0:
				var d := clampf((dang - 0.12) / 0.3, 0.0, 1.0)
				beat_t = lerpf(1.05, 0.42, d)
				Sfx.play("hit_low", -22.0 + d * 10.0, 0.5, 0.02)
				chamber.pulse = minf(1.0, chamber.pulse + 0.25 + d * 0.3)
				overlay.flash_red(0.25 + d * 0.5)
	else:
		Sfx.set_hum(mode == M.CONSOLE or mode == M.LOSING, 1, 0.0, false)
	overlay.danger = clampf((dang - 0.1) / 0.3, 0.0, 1.0)
	cooldown = maxf(0.0, cooldown - dt)
	e_guard = maxf(0.0, e_guard - dt)
	if goal_card.is_valid() and cel.t >= 2.6:
		var gc := goal_card
		goal_card = Callable()
		gc.call()
	timer += dt
	if run != null:
		player.carry = run.held
		player.carry_bt = run.held_bt
	match mode:
		M.TITLE:
			cam_target = Vector2(848, 520)
			zoom_target = 1.35
			_demo_tick(dt)
		M.WALK:
			cam_target = Vector2(960 + clampf((player.position.x - 960) * 0.05, -36, 36), 540)
			zoom_target = 1.04
			if intro.active:
				cam_target = Vector2(1000, 520)
				zoom_target = 1.6
			if _near_console():
				prompt.show_at(Vector2(Geo.CONSOLE_STAND, Geo.FLOOR - 205), "E", "继续实验" if run.beam != null else "开始实验")
			elif _near_terminal():
				prompt.show_at(Vector2(Geo.TERMINAL_X + 35, Geo.FLOOR - 225), "E", "采购终端")
			elif _near_review():
				if run.held == "full":
					prompt.show_at(Vector2(review.STAND, Geo.FLOOR - 250), "E", "放进篮子")
				elif run.held == "" and not run.basket.is_empty():
					prompt.show_at(Vector2(review.STAND, Geo.FLOOR - 250), "E", "考核审核台 · Q 从篮子拿一瓶")
				else:
					prompt.show_at(Vector2(review.STAND, Geo.FLOOR - 250), "E", "考核审核台")
			elif player.busy():
				prompt.hide_now()
			elif _spot() != "" and _spot_label(_spot()) != "":
				var sid := _spot()
				prompt.show_at(Vector2(float(SPOTS[sid][0]), _spot_rect(sid).position.y - 12), "E", _spot_label(sid))
			elif not hover_interact:
				prompt.hide_now()
		M.ENTER:
			if absf(player.position.x - Geo.CONSOLE_STAND) < 3.0 or timer > 1.6:
				_console_ready()
		M.SPIN:
			var pg: float = panel.progress() if panel.spinning else 0.0
			chamber.collide = clampf((pg - 0.62) / 0.38, 0.0, 1.0) if pg > 0.62 else -1.0
			if panel.spin_done:
				panel.spin_done = false
				_reveal()
		M.LOSING:
			if timer > 1.5:
				overlay.st_t = -1.0
				_show_result()
		M.BLOOM:
			if timer > 3.6:
				_finish_bloom()
	# 相机：临界阻尼弹簧
	var r := Ink.spring2(cam_pos, cam_vel, cam_target, cam_omega, dt)
	cam_pos = r[0]; cam_vel = r[1]
	var z := Ink.spring(cam_zoom, cam_zv, zoom_target, cam_omega, dt)
	cam_zoom = z[0]; cam_zv = z[1]
	shake = maxf(0.0, shake - dt * 2.4)
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * shake * 9.0 * (1.0 if Options.shake else 0.0)
	cam.position = cam_pos + sh
	cam.zoom = Vector2(cam_zoom, cam_zoom)

# —— 打击感 ——
## 顿帧：真实时间 dur 秒内几乎冻结（只冻画面，不吞输入）
func hitstop(dur: float) -> void:
	stop_until = Time.get_ticks_usec() / 1e6 + dur
	Engine.time_scale = 0.03 * dev_speed

func slowmo(dur: float, sc: float) -> void:
	slow_until = Time.get_ticks_usec() / 1e6 + dur
	slow_scale = sc

func _impact(r: Dictionary) -> void:
	var k: int = r.outcome
	var e: int = r.to
	var col := Pal.outcome(k)
	Sfx.play("btn", -3.0, 1.0, 0.04)
	match k:
		Odds.SUPER:
			# 三连撞：+1 +1 +1 一下比一下重，最后金色射线炸满全屏
			Sfx.play("perfect", 0.0, 0.9 + e * 0.015)
			Sfx.play("arc", -3.0, 1.3)
			hitstop(0.16)
			slowmo(0.7, 0.35)
			for i in 3:
				get_tree().create_timer(0.11 * i, true, false, true).timeout.connect(func():
					Sfx.play("hit", -4.0 + i * 1.5, 1.1 + i * 0.18)
					chamber.kick(1.4 + i * 0.6, col)
					cam_vel += Vector2(randf_range(-90, 90), -220 - i * 90)
					cam_zv += 0.25 + i * 0.15
					shake = maxf(shake, 0.5 + i * 0.25)
					overlay.pop("+%d" % (i + 1), col, i == 2))
			get_tree().create_timer(0.33, true, false, true).timeout.connect(func():
				Sfx.play("ring", -2.0, 1.15)
				Sfx.play("discharge", -8.0, 1.4)
				overlay.super_burst(get_viewport().get_canvas_transform() * Geo.CHAMBER))
		Odds.PERFECT:
			Sfx.play("perfect", -2.0, 1.0 + e * 0.015)
			Sfx.play("hit", -4.0, 1.25 + e * 0.03)
			hitstop(0.11)
			chamber.kick(1.9, col)
			cam_vel += Vector2(randf_range(-80, 80), -300)
			cam_zv += 0.55
			shake = maxf(shake, 0.7)
			overlay.pop("+2", col, true)
		Odds.SUCCESS:
			# 能级越高，撞击声越尖越响 → 越来越紧绷
			Sfx.play("hit", -7.0 + minf(e, 12) * 0.35, 0.82 + e * 0.035)
			hitstop(0.045 + e * 0.003)
			chamber.kick(1.0 + e * 0.04, col)
			cam_vel += Vector2(randf_range(-40, 40), -160 - e * 8)
			cam_zv += 0.22 + e * 0.012
			shake = maxf(shake, 0.3)
			overlay.pop("+1", col, false)
		Odds.STABLE:
			Sfx.play("hit_low", -14.0, 1.2)
			chamber.kick(0.35, col)
			cam_vel += Vector2(0, -50)
			overlay.pop("±0", col, false)
		Odds.DETUNE:
			Sfx.play("crackle", -4.0, 1.0)
			Sfx.play("hit_low", -8.0, 0.75)
			hitstop(0.05)
			chamber.kick(0.8, col)
			cam_vel += Vector2(randf_range(-160, 160), 60)
			shake = maxf(shake, 0.55)
			overlay.pop("−1", col, false)
	var txt: String = Odds.NAMES[k]
	if r.lock_started:
		txt = "完全同步！" if r.get("full_sync", false) else "锁相！"
		Sfx.play("arc", -2.0, 1.1)
		Sfx.play("ring", -5.0, 1.2)
		Sfx.play("perfect", -6.0, 0.7)
		hitstop(0.14)
		slowmo(0.45, 0.3)
		shake = 0.9
		overlay.flash_lock()
	elif r.lock_ended:
		Sfx.play("ring", -10.0, 0.7)
	overlay.stamp(txt, Pal.c("lock") if r.lock_started else col)

# —— 商店与构筑 ——
func open_shop() -> void:
	mode = M.SHOP
	player.input_enabled = false
	prompt.hide_now()
	overlay.strip_t = 0.0
	var meal: int = run.on_shop_open()
	shop.show_shop()
	if meal > 0:
		shop.money_disp -= meal
		shop._say("食堂的饭卡：+$%d" % meal)
		Sfx.play("btn2", -8.0, 1.6)

func _on_shop_closed() -> void:
	cursor = -1
	mode = M.WALK
	player.input_enabled = true
	overlay.strip_t = 1.0

func gear_bought() -> void:
	for id in run.relics + run.devices:
		gear.ping(id)

## 饰品/设备触发：护身符架上对应物件弹起 + 屏幕上浮出纸签
func _triggers(r: Dictionary) -> void:
	for tr in r.get("triggers", []):
		gear.ping(tr[0])
		if charms.vis > 0.5:
			charms.fire(tr[0], tr[1], tr[2] if tr.size() > 2 else {})
		else:
			overlay.trig(tr[0], Items.ALL[tr[0]].name + " · " + tr[1])
		Sfx.play("tick", -6.0, 1.6)
	if r.get("money", 0) > 0:
		Sfx.play("btn2", -8.0, 1.5)

# —— 结算卡按钮（鼠标可点，同时显示快捷键） ——
func card_buttons() -> Array:
	if mode == M.PAUSE:
		return [{"label": "回到主页", "key": "Esc", "action": "to_title"}, {"label": "继续实验", "key": "E / 空格", "action": "close_pause"}]
	if mode == M.END:
		if run.won():
			return [{"label": "继续挑战（无尽）", "key": "C", "action": "endless"}, {"label": "重新开始", "key": "R", "action": "restart"}]
		return [{"label": "重新开始", "key": "R", "action": "restart"}]
	if mode == M.CHOICE:
		return [{"label": "结束，保留 30%", "key": "E", "action": "sch_end"}, {"label": "再加速一次", "key": "空格", "action": "sch_go"}]
	if mode == M.REVIEW:
		if review_passed:
			return [{"label": "好的", "key": "E", "action": "close_review"}]
		var rb: Array = []
		if _review_can_submit():
			rb.append({"label": "提交考核" if run.can_submit() else "提交（未达标）", "key": "F / E", "action": "submit"})
		rb.append({"label": "先不交" if _review_can_submit() else "离开", "key": "Esc", "action": "close_review"})
		return rb
	if mode != M.RESULT:
		return []
	if run.must_submit():
		return [{"label": "提交考核", "key": "F / 空格", "action": "submit"}]
	var out: Array = []
	out.append({"label": "继续实验" if run.can_submit() else "注入新束流", "key": "E / 空格", "action": "new"})
	if run.can_submit():
		out.append({"label": "提交考核", "key": "F", "action": "submit"})
	out.append({"label": "离开（去采购）", "key": "Esc", "action": "leave"})
	return out

func _card_action(a: String) -> void:
	match a:
		"restart": restart()
		"endless": go_endless()
		"to_title": to_title()
		"close_pause": close_pause()
		"submit": submit()
		"new":
			if run.can_start() and run.inj == "fresh": _new_beam()
		"leave": leave_console()
		"close_review": close_review()
		"sch_end": _sch_end()
		"sch_go": _sch_go()

# —— 鼠标 ——
func _mouse(ev: InputEventMouse) -> void:
	var sp: Vector2 = ev.position
	mouse_sp = sp
	if mode == M.TITLE:
		title.mouse(ev)
		return
	if mode == M.SHOP:
		shop.mouse(ev)
		return
	if mode == M.PLAN:
		plans.mouse(ev)
		return
	if ev is InputEventMouseMotion:
		if panel.dragging:
			panel.drag_to(sp.y)
		return
	var mb := ev as InputEventMouseButton
	if mb == null:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and panel.dragging:
		if panel.end_drag() and mode == M.CONSOLE:
			extract()
		return
	if not mb.pressed:
		return
	if intro.active:
		intro.skip()
		return
	if letter.open:
		letter.press()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if mode == M.RESULT and not run.must_submit():
			leave_console()
		elif mode == M.CONSOLE:
			_leave_tab_go()
		elif mode == M.REVIEW:
			close_review()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	match mode:
		M.RESULT, M.END, M.REVIEW, M.CHOICE, M.PAUSE:
			var a: String = overlay.button_at(sp)
			if a != "":
				_card_action(a)
		M.CONSOLE:
			if clip_r.toggle_at(sp):
				pass
			elif panel.red_rect.has_point(sp):
				press_red()
			elif panel.leave_rect.has_point(sp):
				_leave_tab_go()
			elif panel.hit_button(sp):
				if run.beam == null:
					_next_beam()
				else:
					accelerate()
			elif panel.hit_knob(sp) and e_guard <= 0.0:
				panel.start_drag()
		M.SPIN:
			panel.skip()
		M.BLOOM:
			if timer > 0.5:
				_finish_bloom()
		M.WALK:
			var wp := _to_world(sp)
			if notice.rect().has_point(wp):
				Sfx.play("paper", -6.0, 1.0)
				open_letter()
			elif _terminal_rect().has_point(wp):
				_walk_to(Geo.TERMINAL_X + 35, "shop")
			elif review.rect().has_point(wp):
				_walk_to(review.STAND, "review")
			elif _spot_at(wp) != "":
				_walk_to(float(SPOTS[_spot_at(wp)][0]), "spot:" + _spot_at(wp))
			elif _console_rect().has_point(wp):
				_walk_to(Geo.CONSOLE_STAND, "console")
			elif wp.y > Geo.CEIL and wp.y < Geo.FLOOR + 30:
				_walk_to(wp.x, "")

## 瓶座不是新瓶时，告诉玩家下一步该干什么
func _inj_hint() -> String:
	match run.inj:
		"full": return "注入器上放着这一束的成果瓶，先拿去审核台放进篮子"
		"empty": return "注入器上是空瓶，先取下来扔进回收站，再装一瓶新的"
	return "注入器上还没装新瓶，去气瓶架拿一瓶氢气装上"

## 面板纸签：束流用完 → 去审核台；否则 → 去采购
func _leave_tab_go() -> void:
	var to_review: bool = run.beam == null and run.inj != "full" and (run.experiments_left <= 0 or run.can_submit())
	leave_console()
	if run.beam == null and run.inj == "full":
		_walk_to(float(SPOTS["cradle"][0]), "spot:cradle")
	elif to_review:
		_walk_to(review.STAND, "review")
	elif run.beam == null and run.inj != "fresh":
		# 去换瓶：瓶座上是空瓶就先走到瓶座，否则直接去气瓶架
		_walk_to(float(SPOTS["cradle"][0]) if run.inj == "empty" else float(SPOTS["rack"][0]), "")
	else:
		_walk_to(Geo.TERMINAL_X + 35, "shop")


# —— 氢气瓶的几个地点（Q70）：全手动——回收站扔空瓶、气瓶架取新瓶、注入器装瓶；储备柜存取满瓶 ——
# 站位让开一点：主角站在瓶座右边、伸手去够，不挡住瓶子
const SPOTS := {"bin": [122.0, 44.0], "cradle": [282.0, 28.0], "rack": [354.0, 42.0], "cab": [1560.0, 34.0]}

func _spot() -> String:
	var best := ""
	var bd := 1e9
	for id in SPOTS:
		var d := absf(player.position.x - float(SPOTS[id][0]))
		if d < float(SPOTS[id][1]) and d < bd:
			bd = d
			best = id
	return best

func _spot_rect(id: String) -> Rect2:
	match id:
		"bin": return stash.BIN.grow(8)
		"cradle": return Rect2(stash.CRADLE.x - 20, stash.CRADLE.y - 130, 40, 130)
		"rack": return bottles.RACK.grow(4)
		"cab": return stash.CAB.grow(4)
	return Rect2()

## 这个地点现在按 E 会做什么（"" = 什么也做不了）
func _spot_label(id: String) -> String:
	match id:
		"bin":
			return "扔掉空瓶" if run.held == "empty" else ""
		"cradle":
			if run.inj == "full" and run.held == "":
				return "拿起成果瓶"
			if run.inj == "empty" and run.held == "" and run.beam == null:
				return "取下空瓶"
			if run.inj == "" and run.held == "fresh":
				return "装上氢气瓶"
			return ""
		"rack":
			if run.held == "fresh":
				return "放回架子"
			return "拿一瓶氢气" if run.held == "" and run.rack_left() > 0 else ""
		"cab":
			if run.held == "full":
				return "存进储备柜" if run.cab.size() < Run.CAB_SLOTS else ""
			return "取出备用瓶" if run.held == "" and not run.cab.is_empty() else ""
	return ""

## 搬瓶的每个动作：规则先改好，画面上主角弯腰伸手、瓶子沿弧线飞过去，落位那一下出声、卡箍合上、桶晃、柜门开合
func _spot_do(id: String) -> void:
	if player.busy():
		return
	var err := ""
	var cp: Vector2 = player.carry_point()
	var cradle: Vector2 = stash.CRADLE + Vector2(0, -8)
	match id:
		"bin":
			err = run.toss_empty()
			if err == "":
				# 扔：手往后一蓄，甩出去，瓶子打着转落进桶里
				player.act(Vector2(stash.BIN.get_center().x, stash.BIN.position.y - 10), 0.42, true)
				Sfx.play("whoosh", -18.0, 1.5, 0.1)
				stash.fly("empty", {}, cp, Vector2(stash.BIN.get_center().x, stash.BIN.position.y + 26), 0.36, 0.14, 70.0, -5.5, func():
					stash.bin_n = mini(stash.bin_n + 1, 3)
					stash.bin_wob = 0.09
					Sfx.play("bin_clang", -5.0, 1.0, 0.06))
		"cradle":
			if run.inj == "full" or run.inj == "empty":
				var kind: String = run.inj
				var bt: Dictionary = run.inj_bt.duplicate()
				err = run.pick_full() if kind == "full" else run.pick_empty()
				if err == "":
					# 拆：先咔哒松开卡箍，再把瓶子拎起来抱进怀里
					player.act(cradle + Vector2(0, -60), 0.36)
					player.carry_hide = 0.4
					stash.open_clamp()
					Sfx.play("bottle_unlock", -6.0, 1.0, 0.05)
					stash.fly(kind, bt, cradle, cp, 0.24, 0.14, 24.0, 0.0, func():
						Sfx.play("grab", -10.0, 1.0, 0.08)
						stash.close_clamp())
			else:
				err = run.load_fresh()
				if err == "":
					# 装：瓶子落进瓶座，卡箍“咚”地锁上，阀口嘶一小口气
					player.act(cradle + Vector2(0, -60), 0.36)
					stash.hide_inj = 0.36
					stash.open_clamp()
					stash.fly("fresh", {}, cp, cradle, 0.24, 0.08, 18.0, 0.0, func():
						Sfx.play("bottle_lock", -3.0, 1.0, 0.04)
						Sfx.play("gas_hiss", -15.0, 1.1, 0.08)
						stash.lock_clamp())
		"rack":
			var slot: Vector2 = bottles.slot_pos(maxi(0, run.rack_left() - (0 if run.held == "fresh" else 1)))
			if run.held == "fresh":
				err = run.return_fresh()
				if err == "":
					player.act(slot + Vector2(0, -70), 0.3)
			else:
				err = run.take_fresh()
				if err == "":
					player.act(slot + Vector2(0, -70), 0.34)
					player.carry_hide = 0.38
					Sfx.play("grab", -12.0, 1.1, 0.08)
		"cab":
			if run.held == "full":
				var bt2: Dictionary = run.held_bt.duplicate()
				err = run.store_in_cab()
				if err == "":
					var to: Vector2 = stash.cab_slot(run.cab.size() - 1)
					player.act(to + Vector2(0, -30), 0.36)
					stash.open_door(0.5)
					stash.hide_cab = 0.34
					Sfx.play("cab_door", -10.0, 1.0, 0.05)
					stash.fly("full", bt2, cp, to, 0.26, 0.08, 16.0, 0.0, func():
						Sfx.play("bottle_ring", -14.0, 1.4, 0.05))
			else:
				var from: Vector2 = stash.cab_slot(run.cab.size() - 1) if not run.cab.is_empty() else Vector2.ZERO
				var bt3: Dictionary = run.cab[-1].duplicate() if not run.cab.is_empty() else {}
				err = run.take_from_cab()
				if err == "":
					player.act(from + Vector2(0, -30), 0.36)
					player.carry_hide = 0.4
					stash.open_door(0.45)
					Sfx.play("cab_door", -10.0, 1.0, 0.05)
					stash.fly("full", bt3, from, cp, 0.24, 0.12, 16.0, 0.0, func():
						Sfx.play("grab", -10.0, 1.0, 0.08))
	if err != "":
		overlay.say(err)
		Sfx.play("hit_low", -12.0, 1.3)
	else:
		Save.write(run)

## 审核台：手里拿着满瓶就放进篮子，否则打开考核
func _review_e() -> void:
	if player.busy():
		return
	if run.held == "full":
		var bt: Dictionary = run.held_bt.duplicate()
		var cp: Vector2 = player.carry_point()
		run.put_in_basket()
		var to: Vector2 = review.basket_slot(run.basket.size() - 1)
		player.act(to + Vector2(0, -40), 0.36)
		review.hide_last = 0.34
		stash.fly("full", bt, cp, to, 0.26, 0.08, 30.0, 0.0, func():
			review.bump = 1.0
			Sfx.play("basket_drop", -6.0, 1.0, 0.06)
			Sfx.play("bottle_ring", -16.0, 1.5, 0.05)
			stash.pop("+%s RP" % fmt(int(bt.get("value", 0))), to + Vector2(0, -70), Pal.c("green")))
		Save.write(run)
	elif run.held != "":
		overlay.say("先把手里的瓶子放下")
	else:
		open_review()

func _review_q() -> void:
	if player.busy():
		return
	var from: Vector2 = review.basket_slot(run.basket.size() - 1) if not run.basket.is_empty() else Vector2.ZERO
	var bt: Dictionary = run.basket[-1].duplicate() if not run.basket.is_empty() else {}
	var err := run.take_from_basket()
	if err != "":
		overlay.say(err)
		Sfx.play("hit_low", -12.0, 1.3)
	else:
		player.act(from + Vector2(0, -40), 0.34)
		player.carry_hide = 0.38
		Sfx.play("basket_drop", -12.0, 1.2, 0.06)
		stash.fly("full", bt, from, player.carry_point(), 0.24, 0.12, 24.0, 0.0, func():
			Sfx.play("grab", -10.0, 1.0, 0.08))
		stash.pop("−%s RP" % fmt(int(bt.get("value", 0))), from + Vector2(0, -70), Pal.c("red"))
		Save.write(run)

func _spot_at(wp: Vector2) -> String:
	for id in SPOTS:
		if _spot_rect(id).has_point(wp):
			return id
	return ""

func _terminal_rect() -> Rect2:
	return Rect2(Geo.TERMINAL_X - 10, Geo.FLOOR - 200, 90, 200)

func _console_rect() -> Rect2:
	return Rect2(Geo.CONSOLE_X - 10, Geo.FLOOR - 180, 170, 180)

func _walk_to(x: float, goal: String) -> void:
	player.auto_target = clampf(x, Geo.WALK_MIN, Geo.WALK_MAX)
	walk_goal = goal
	Sfx.play("tick", -14.0, 0.9)

## 每帧：悬停高亮、说明纸签、光标形状、点击寻路到达
func _hover() -> void:
	var sp := mouse_sp
	var wp := _to_world(sp)
	var hand := false
	hover_interact = false
	var tip := PackedStringArray()
	panel.hover_btn = false
	panel.hover_knob = false
	overlay.hover_btn = -1
	review.hot = lerpf(review.hot, 1.0 if (mode == M.WALK and (review.rect().has_point(wp) or _near_review())) else 0.0, 0.25)
	match mode:
		M.WALK:
			notice.hot = lerpf(notice.hot, 1.0 if notice.rect().has_point(wp) else 0.0, 0.3)
			if notice.rect().has_point(wp):
				hand = true
				hover_interact = true
				prompt.show_at(Vector2(notice.NOTE.get_center().x, notice.NOTE.position.y - 14), "点击", "重读那封信")
			elif review.rect().has_point(wp):
				hand = true
				hover_interact = true
				prompt.show_at(Vector2(review.STAND, Geo.FLOOR - 250), "点击", "考核审核台")
			elif _terminal_rect().has_point(wp) or _console_rect().has_point(wp):
				hand = true
				hover_interact = true
				var is_term := _terminal_rect().has_point(wp)
				prompt.show_at(Vector2(Geo.TERMINAL_X + 35, Geo.FLOOR - 225) if is_term else Vector2(Geo.CONSOLE_STAND, Geo.FLOOR - 205), "点击", "去采购" if is_term else ("继续实验" if run.beam != null else "开始实验"))
		M.CONSOLE, M.SPIN:
			panel.hover_btn = mode == M.CONSOLE and panel.hit_button(sp)
			panel.hover_leave = mode == M.CONSOLE and panel.leave_rect.has_point(sp)
			panel.hover_red = mode == M.CONSOLE and panel.red_rect.has_point(sp)
			if panel.hover_red:
				tip = PackedStringArray(["绝对不能按的红色按钮", "潜在成果 ×10（10%）· 4 次锁相（25%）", "束流直接丢失（35%）· 随机精良以上饰品（30%）"])
			panel.hover_knob = mode == M.CONSOLE and panel.hit_knob(sp)
			hand = panel.hover_btn or panel.hover_knob or panel.hover_leave or panel.hover_red or panel.dragging or mode == M.SPIN
			var k: int = panel.seg_at(sp)
			if k >= 0 and run.beam != null:
				var p := run.odds()
				tip = PackedStringArray([Odds.NAMES[k], "下一次加速出现这个结果的真实概率：%.1f%%" % (p[k] * 100.0)])
		M.RESULT, M.END, M.REVIEW, M.CHOICE, M.PAUSE:
			overlay.hover_btn = overlay.hover_at(sp)
			hand = overlay.hover_btn >= 0
	if tip.is_empty() and mode != M.SHOP:
		var id: String = charms.item_at(sp)
		if id != "":
			charms.hover_id = id
			hand = true
		else:
			charms.hover_id = ""
			id = gear.item_at(wp)
		if id != "":
			var d: Dictionary = Items.ALL[id]
			tip = PackedStringArray([d.name + "（" + ("设备" if d.kind == "device" else "饰品") + " · " + Items.RARITY_NAME[d.rarity] + "）", d.desc])
			if d.lore != "":
				tip.append("“" + d.lore + "”")
			if run.uses.has(id):
				tip.append("剩余 %d 次" % run.uses[id])
	overlay.tip(tip, sp)
	var shape := Input.CURSOR_POINTING_HAND if hand else Input.CURSOR_ARROW
	if panel.dragging:
		shape = Input.CURSOR_DRAG
	if shape != cursor and mode != M.SHOP:
		cursor = shape
		Input.set_default_cursor_shape(shape)
	# 点击寻路：到了就做事
	if mode == M.WALK and walk_goal != "" and player.auto_target >= 0.0 and absf(player.position.x - player.auto_target) < 4.0:
		var g := walk_goal
		walk_goal = ""
		player.auto_target = -1.0
		if g == "shop":
			open_shop()
		elif g == "console":
			enter_console()
		elif g == "review":
			_review_e()
		elif g.begins_with("spot:"):
			_spot_do(g.substr(5))
	elif mode == M.WALK and player.auto_target < 0.0:
		walk_goal = ""

func _to_world(sp: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * sp

# —— 主页 ——
func _open_title() -> void:
	live_save = false
	title.cont_info = Save.summary()
	mode = M.TITLE
	player.input_enabled = false
	cam_pos = Vector2(848, 520)
	cam_zoom = 1.35
	title.lens_c = Vector2(1300, 540)
	title.show_title()
	overlay.strip_t = 0.0
	demo_n = randi() % DEMO_ROUTES.size()
	_demo_new()

func _demo_new() -> void:
	run = Run.new()
	run.relics = DEMO_ROUTES[demo_n % DEMO_ROUTES.size()].duplicate()
	demo_n += 1
	run.start_experiment()
	chamber.inject()
	form.reset()
	_sync()
	panel.dec = {}
	demo_t = -0.6

## 演示束流：每 0.85 秒加速一次，偶尔完美同步跳两级；冲到 E15 左右碎掉，停一下换下一条路线
func _demo_tick(dt: float) -> void:
	if run.beam == null:
		demo_wait -= dt
		if demo_wait <= 0.0:
			_demo_new()
		return
	demo_t += dt
	if demo_t < 0.85:
		return
	demo_t = 0.0
	var b: Beam = run.beam
	if b.energy >= 14 + demo_n % 3:
		chamber.lose()
		form.shatter()
		Sfx.play("hit_low", -14.0, 0.8)
		run.beam = null
		demo_wait = 2.6
		title.demo_text = "E%02d · 束流丢失" % b.energy
		return
	var d := 2 if randf() < 0.18 else 1
	b.energy += d
	b.peak = maxi(b.peak, b.energy)
	if b.energy >= 9 and randf() < 0.08:
		b.crowned = true
	_sync()
	panel.dec = {}
	chamber.kick(0.45 + 0.25 * d, Pal.ramp(clampf((b.energy - 1) / 12.0, 0.0, 1.0)))
	Sfx.play("tick", -16.0, 0.8 + b.energy * 0.03)
	title.demo_text = "E%02d · %s" % [b.energy, form.info.get("name", "")]

## 开新游戏：只有全新存档的第一局放新手教程（开场信 + 逐步引导）；失败后重开、回主页再开都不放。
## 设置里“新手教程 · 下一局重看”可以让下一局再放一次（用完自动关）。用户 2026-11-09 定（Q68）
func _begin_tutorial() -> void:
	letter_seen = false
	var fresh: bool = Memes._testing() or not tutorial._cfg_done()
	if play_tutorial and (fresh or Options.tutorial_replay):
		tutorial.start(false)
		# 一开局就记下“这份存档放过教程了”：哪怕第一局中途失败，重开也不再放
		tutorial._save_done()
		if Options.tutorial_replay:
			Options.tutorial_replay = false
			Options.save()
	else:
		tutorial.stop()

func _on_title_start() -> void:
	_begin_tutorial()
	run = Run.new()
	Save.clear()
	live_save = true
	_save_sig = 0
	chamber.empty()
	form.reset()
	form.shatter_t = -1.0
	mode = M.WALK
	timer = 0.0
	overlay.strip_t = 1.0
	title.demo_text = ""
	intro.play()
	player.input_enabled = false
	cam_pos = Vector2(1000, 520)
	cam_zoom = 1.6
