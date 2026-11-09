extends Control
## 新手引导（DECISIONS F20）：第一局用手写便利贴逐步提示，每张带手绘箭头指向要操作的地方；
## 完成一步，便条打勾飞走。完成后写入 user://settings.cfg，之后不再出现；F1 可重看。

const CFG := "user://settings.cfg"

var main: Node
var active := false
var persist := true          # 测试/录像时设为 false，绝不写入玩家的真实配置
var idx := -1
var step_t := 0.0
var done_t := -1.0           # 当前便条打勾后飞走的计时
var shown: Dictionary = {}   # 已完成的步骤 id
var steps: Array = []
var _ctx := {}               # 用于判断“发生了新事”的快照

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)
	# 每步：id / 文字 / 何时出现 / 何时完成 / 箭头指向（返回屏幕坐标；null 表示不画箭头）/ 便条位置
	steps = [
		# —— 背景：开场信之后，先看墙上的日程表，再看束流从哪来（DECISIONS Q62/Q63）——
		{"id": "wall", "text": "墙上贴的是评审日程表，
总共要过 8 轮，每过一轮就划掉一格。
第 4 轮和第 8 轮会查得严一些，
听说到时候有大领导过来。
旁边还贴着一封校长办公室寄来的信，
有空可以看看。",
			"say": "我们必须在8次评审内都满足他们的考核要求，\n否则的话，我们的加速器马上就会被卖掉了",
			"show": func(): return main.mode == main.M.WALK,
			"done": func(): return step_t > 8.0 or main.mode != main.M.WALK or main.letter.open,
			"at": func(): return _w(Vector2(560, 372)), "note": func(): return _w(Vector2(1080, 300))},
		{"id": "bottles", "text": "这轮就给了这么几瓶氢气，
每做一次实验就得用掉一瓶，
用完可就没了，自己看着点用。
等气瓶全用完，就该去交评审了。",
			"say": "使用粒子对撞机的基本粒子就是氢气，\n这里面装的氢气可以供你完成一次完整的实验",
			"show": func(): return main.mode == main.M.WALK,
			"done": func(): return step_t > 8.0 or main.mode != main.M.WALK,
			"at": func(): return _w(Vector2(350, 690)), "note": func(): return _w(Vector2(470, 560))},
		{"id": "walk", "text": "欢迎上任，负责人。
点击地面走过去，
点击设备直接使用。
（键盘：A / D 走路，E 使用）",
			"show": func(): return main.mode == main.M.WALK,
			"done": func(): return absf(main.player.position.x - 700.0) > 40.0 or main.mode != main.M.WALK,
			"at": func(): return _w(main.player.position + Vector2(0, -175)), "note": func(): return _w(main.player.position + Vector2(-60, -420))},
		{"id": "shop", "text": "左边是采购终端，点它。
用经费买设备和饰品，
能改概率、加倍率、保命。
（也可以先不买）",
			"show": func(): return main.mode == main.M.WALK,
			"done": func(): return main.mode == main.M.SHOP or main.mode == main.M.ENTER or main.run.experiment_no > 0,
			"at": func(): return _w(Vector2(Geo.TERMINAL_X + 35, Geo.FLOOR - 190)), "note": func(): return _w(Vector2(Geo.TERMINAL_X + 120, Geo.FLOOR - 560))},
		{"id": "shop_ui", "text": "点击商品卡直接买下。
按住下面已有的东西，
半价卖掉。
右键或 × 离开。",
			"show": func(): return main.mode == main.M.SHOP,
			"done": func(): return main.mode != main.M.SHOP,
			"at": null, "note": func(): return Vector2(1500, 800)},
		{"id": "console", "text": "观测舱前面有台控制台，
过去点一下，把第一瓶氢气装进去
就能开始实验了。",
			"say": "可以在这里把氢气加速到接近光速进行对撞，产生科研成果",
			"show": func(): return main.mode == main.M.WALK,
			"done": func(): return main.mode != main.M.WALK and main.mode != main.M.SHOP,
			"at": func(): return _w(Vector2(Geo.CONSOLE_STAND + 30, Geo.FLOOR - 150)), "note": func(): return _w(Vector2(Geo.CONSOLE_STAND + 150, Geo.FLOOR - 520))},
		{"id": "space", "text": "点红色大按钮（或空格）加速。
纸带就是下一次的真实概率：
指针停在哪段，结果就是哪个。
鼠标停在纸带上能看具体数字。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.beam != null,
			"done": func(): return main.run.log.size() >= 1 and main.mode != main.M.SPIN,
			"at": func(): return _panel(Vector2(1530, 150)), "note": func(): return _panel(Vector2(1240, -150))},
		{"id": "value", "text": "能级越高，潜在成果越值钱。\n但红色的“束流丢失”段\n也会越来越宽——\n丢了，这一束就是 0。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.log.size() >= 1,
			"done": func(): return main.run.log.size() >= 3 or main.mode != main.M.CONSOLE,
			"at": func(): return _panel(Vector2(1260, 120)), "note": func(): return _panel(Vector2(760, -170))},
		{"id": "lock", "text": "成功会给锁相充能，\n攒满 6 格进入锁相：\n接下来几次加速绝不丢失。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.beam != null and main.run.beam.charge > 0,
			"done": func(): return main.run.log.size() >= 5 or main.mode != main.M.CONSOLE or (main.run.beam != null and main.run.beam.locked()),
			"at": func(): return _panel(Vector2(780, 214)), "note": func(): return _panel(Vector2(560, -170))},
		{"id": "lever", "text": "觉得够了，就把拉杆
往下拖到底（或按 E）引出：
潜在成果存进累计分，
还能换来经费。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.beam != null and main.run.beam.energy >= 4,
			"done": func(): return main.run.experiment_no > 1 or main.run.beam == null,
			"at": func(): return _panel(Vector2(1760, 110)), "note": func(): return _panel(Vector2(1530, -200))},
		{"id": "report", "text": "实验报告已经放到审核台上了，
上面写着这轮要攒多少科研点，
还有你现在已经攒了多少。
攒够了就能去交评审。",
			"say": "第一次科研成果成功出炉了，我们看一看得分如何呢",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.beam == null and main.run.experiment_no >= 1,
			"done": func(): return main.run.beam != null or main.mode != main.M.CONSOLE or step_t > 7.0,
			"at": func(): return _w(Vector2(main.review.X + 75, Geo.FLOOR - 200)), "note": func(): return _w(Vector2(main.review.X - 120, Geo.FLOOR - 420))},
		{"id": "clips", "text": "左边夹板：考核进度和累计分。
右边夹板：实验日志，
还有“显示概率 / 实际频率”，
不信可以自己查账。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.beam == null and main.run.experiment_no >= 1,
			"done": func(): return main.run.beam != null or main.mode != main.M.CONSOLE or step_t > 7.0,
			"at": func(): return Vector2(400, 300), "note": func(): return Vector2(440, 120)},
		{"id": "submit", "text": "科研点攒够了就能直接交，
不用把气瓶全用完，
剩下的气瓶会退回去，折成经费。
想趁着还有气瓶再多做几次也行，
不过得想好了，万一后面的实验失败，
之前攒下的科研点就会扣掉 30%。
要是气瓶已经用光了，
那就只能去交评审了。",
			"say": func(): return ("科研成果的分数已经能通过考核了，但是你还是剩下了几个气瓶，\n不过好心提醒你一下，你剩下的%d瓶也会被回收哦" % main.run.experiments_left) if main.run.total >= main.run.line() and main.run.experiments_left > 0 else "",
			"show": func(): return (main.mode == main.M.CONSOLE and main.run.beam == null or main.mode == main.M.WALK) and main.run.experiment_no >= 1 and shown.has("clips"),
			"done": func(): return main.mode == main.M.REVIEW or main.run.beam != null or step_t > 9.0,
			"at": func(): return _w(Vector2(main.review.STAND, Geo.FLOOR - 180)), "note": func(): return _w(Vector2(main.review.STAND - 200, Geo.FLOOR - 480))},
		{"id": "rebuy", "text": "每做完一次实验，
采购终端都会进新货。
点面板左上的纸签就能去逛，
实验做到一半也能去。",
			"show": func(): return (main.mode == main.M.CONSOLE or main.mode == main.M.WALK) and main.run.experiment_no >= 1 and shown.has("submit"),
			"done": func(): return main.mode == main.M.SHOP or main.run.experiment_no >= 2 or step_t > 12.0,
			"at": func(): return main.panel.leave_rect.get_center() if main.panel.leave_rect.size.x > 0 else Vector2(178, 760), "note": func(): return Vector2(520, 560)},
		# —— 第一局后半段：饰品与超级同步 ——
		{"id": "sell", "text": "想换掉旧东西？
按住它不放，
红圈合拢就半价卖掉。
（松手就取消）",
			"show": func(): return main.mode == main.M.SHOP and main.run.experiment_no >= 2 and not main.shop.inv_rects.is_empty(),
			"done": func(): return main.mode != main.M.SHOP or step_t > 8.0,
			"at": func(): return main.shop.inv_rects[0].rect.get_center() if not main.shop.inv_rects.is_empty() else Vector2(1000, 700),
			"note": func(): return Vector2(1480, 840)},
		{"id": "board", "text": "右下这块挂板上，
是你买的设备和饰品。
哪件生效，它就会飞出来亮相。
鼠标停上去能看说明。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.experiment_no >= 2 and main.charms.vis > 0.9 and not (main.run.devices + main.run.relics).is_empty(),
			"done": func(): return main.mode != main.M.CONSOLE or step_t > 8.0 or main.charms.fired > 0,
			"at": func(): return main.charms.board_rect().position + Vector2(main.charms.board_rect().size.x * 0.5, 0),
			"note": func(): return main.charms.board_rect().position + Vector2(-140, -170)},
		{"id": "fired", "text": "看，饰品生效了！
纸条上写着它做了什么。
构筑就靠这些凑出来。",
			"show": func(): return main.charms.fired > 0 and (main.mode == main.M.CONSOLE or main.mode == main.M.SPIN),
			"done": func(): return step_t > 6.0 or main.run.beam == null,
			"at": null, "note": func(): return Vector2(560, 300)},
		{"id": "super", "text": "锁相时，纸带最左边
多出一段金色：超级同步！
能级一下 +3。
能级越高，它越容易出。",
			"show": func(): return main.mode == main.M.CONSOLE and main.run.beam != null and main.run.beam.locked() and main.run.experiment_no >= 2,
			"done": func(): return main.run.beam == null or not main.run.beam.locked() or step_t > 9.0,
			"at": func(): return _panel(Vector2(600, 110)), "note": func(): return _panel(Vector2(420, -190))},
	]
	# 不再只放第一局：每次开新游戏由 main 按设置（Options.tutorial，默认开）启动

func start(manual: bool) -> void:
	active = true
	idx = -1
	shown.clear()
	if manual:
		main.overlay.say("新手便条已重新贴上")

func stop() -> void:
	active = false
	idx = -1
	queue_redraw()

func _cfg_done() -> bool:
	var c := ConfigFile.new()
	if c.load(CFG) != OK:
		return false
	return bool(c.get_value("tutorial", "done", false))

func _save_done() -> void:
	if not persist:
		return
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("tutorial", "done", true)
	c.save(CFG)

## 世界坐标 → 屏幕坐标（随相机）
func _w(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * p

## 控制台面板上的点：面板从底部升起，y 相对面板顶
func _panel(p: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(p.x, vp.y - 300.0 * main.panel.show_v + main.panel.jolt + 46.0 + p.y)

func _process(dt: float) -> void:
	if not active or main == null or main.run == null:
		return
	if main.letter != null and main.letter.open:
		queue_redraw()
		return
	step_t += dt
	if done_t >= 0.0:
		done_t += dt
		if done_t > 0.6:
			done_t = -1.0
			idx = -1
	if idx >= 0 and done_t < 0.0:
		var st: Dictionary = steps[idx]
		if st.done.call():
			shown[st.id] = true
			done_t = 0.0
			Sfx.play("paper", -10.0, 1.3)
	if idx < 0 and done_t < 0.0:
		# 挑下一步时计时从 0 算：否则“停留几秒算完成”的步骤会拿上一步的计时，一出现就被判完成
		step_t = 0.0
		for i in steps.size():
			var st: Dictionary = steps[i]
			if shown.has(st.id):
				continue
			if st.show.call() and not st.done.call():
				idx = i
				step_t = 0.0
				Sfx.play("paper", -12.0, 1.1)
				if st.has("say"):
					var line: String = st.say.call() if st.say is Callable else st.say
					if line != "":
						main.overlay.narrate(line, 6.5)
				break
			if st.show.call() and st.done.call():
				shown[st.id] = true
		if shown.size() >= steps.size():
			active = false
			_save_done()
	queue_redraw()

func _draw() -> void:
	if not active or idx < 0 or (main != null and main.letter != null and main.letter.open):
		return
	var st: Dictionary = steps[idx]
	var appear := Ink.ease_out_back(clampf(step_t / 0.3, 0.0, 1.0))
	var fly := clampf(done_t / 0.6, 0.0, 1.0) if done_t >= 0.0 else 0.0
	var np: Vector2 = st.note.call()
	var vp := get_viewport_rect().size
	var lines: PackedStringArray = st.text.split("\n")
	var fs := 21
	var w := 0.0
	for l in lines:
		w = maxf(w, Ink.size(Pal.hand, l, fs).x)
	w += 44.0
	var h := lines.size() * 30.0 + 40.0
	np.x = clampf(np.x, w * 0.5 + 20, vp.x - w * 0.5 - 20)
	np.y = clampf(np.y, h * 0.5 + 20, vp.y - h * 0.5 - 20)
	np += Vector2(fly * 260.0, -fly * 420.0)
	var a := 1.0 - fly
	# 箭头（手绘弧线）先画，被便条盖住起点
	if st.at != null and fly < 0.3:
		var tp: Vector2 = st.at.call()
		var from := np + (tp - np).normalized() * minf(w, h) * 0.45
		var mid := (from + tp) * 0.5 + (tp - from).orthogonal().normalized() * 40.0
		var pts := PackedVector2Array()
		var wob := sin(step_t * 5.0) * 4.0
		var tip := tp - (tp - mid).normalized() * (10.0 + wob)
		for i in 21:
			var k := i / 20.0
			pts.append(from.lerp(mid, k).lerp(mid.lerp(tip, k), k))
		var col := Color(Pal.c("red"), a * appear)
		Ink.pl(self, pts, col, 3.4)
		var dir := (tip - pts[18]).normalized()
		draw_line(tip, tip - dir.rotated(0.5) * 18.0, col, 3.4, true)
		draw_line(tip, tip - dir.rotated(-0.5) * 18.0, col, 3.4, true)
	draw_set_transform(np, -0.035 + fly * 0.6, Vector2(appear, appear))
	var o := Vector2(-w * 0.5, -h * 0.5)
	draw_rect(Rect2(o + Vector2(6, 8), Vector2(w, h)), Color(0, 0, 0, 0.18 * a))
	draw_rect(Rect2(o, Vector2(w, h)), Color(Color("#f4dd72"), a))
	draw_rect(Rect2(o, Vector2(w, 12)), Color(Color("#e8cd58"), a))
	draw_rect(Rect2(Vector2(-34, o.y - 10), Vector2(68, 22)), Color(Color("#ffffff"), 0.45 * a))
	var y := o.y + 46.0
	for l in lines:
		Ink.text(self, l, Vector2(o.x + 22, y), fs, Color(Color("#2b2a28"), a), Pal.hand, HORIZONTAL_ALIGNMENT_LEFT, -1)
		y += 30.0
	if done_t >= 0.0:
		Ink.text(self, "✓", o + Vector2(w - 46, 44), 40, Color(Pal.c("red"), a), Pal.bold, HORIZONTAL_ALIGNMENT_LEFT, -1)
	draw_set_transform(Vector2.ZERO)
