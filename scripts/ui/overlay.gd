extends Control
const STASH := preload("res://scripts/world/stash.gd")
## 屏幕层：顶部纸胶带状态条、结果印章、实验结果卡、开花计数、结局卡、提示

var main: Node
var t := 0.0
# 印章
var st_text := ""
var st_col := Color.RED
var st_t := -1.0
var st_big := false
var st_rot := 0.0
# 结果卡
var card := {}          # {title, value, sub, lines:[], keys}
var card_v := 0.0
var _vc := 0.0
var card_t := 0.0
# 开花计数
var bloom_v := -1.0
var bloom_target := 0
var bloom_disp := 0.0
var _vb := 0.0
var strip_v := 1.0
var _vst := 0.0
var strip_t := 1.0
var toast := ""
var toast_t := 0.0
var btn_rects: Array = []   # 结算卡按钮 [{rect, action}]
var hover_btn := -1
var tip_lines: PackedStringArray = PackedStringArray()
var tip_pos := Vector2.ZERO
var tip_v := 0.0
var trigs: Array = []     # 饰品触发纸签 {id, s, t}
var pops: Array = []      # 飞字 {s, col, big, t}
var red := 0.0            # 红色边缘闪
var lockfx := 0.0
var superfx := -1.0       # 超级同步：从观测舱炸开的金色射线（秒，-1 = 无）
var super_c := Vector2.ZERO
var super_t0 := 0             # 用真实时间推进（顿帧/慢动作时射线照样炸开）
var danger := 0.0
var last_tick := 0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

var tl := {}               # 一次实验结束的小纸条 {title, value, sub, col, t}
var cel_t := -1.0          # 阶段通过的庆祝（秒，-1 = 无）
var cel_stage := 1
var cel_quip := ""
var confetti: Array = []

## 一次实验结束：纸条从上方落下，报出这一束加了多少，然后飞进左边的考核夹板
func tally(title: String, value: String, sub: String, col: Color, bottle := {}) -> void:
	tl = {"title": title, "value": value, "sub": sub, "col": col, "t": 0.0, "bottle": bottle}

var strike_next := false   # 下一次盖章前，把当前章划掉（饰品改写结果）
var prev := {}             # 被划掉的旧章 {text, col, rot, t}

var st_hold := false        # 原始结果的章：一直留着，等饰品改写时被划掉

func stamp(s: String, col: Color, big := false, hold := false) -> void:
	if strike_next and st_t >= 0.0 and st_text != "":
		prev = {"text": st_text, "col": st_col, "rot": st_rot, "t": 0.0}
	strike_next = false
	st_hold = hold
	st_text = s
	st_col = col
	st_t = 0.0
	st_big = big
	st_rot = randf_range(-0.14, 0.08)

func show_card(c: Dictionary) -> void:
	card = c
	card_t = 1.0

func hide_card() -> void:
	card_t = 0.0

var bloom_meme := {}       # 奇葩事件 {name, first}
var form_card := {}        # 束流形态成果卡（Forms.describe + first/no）
var form_art := FormArt.new()

func show_bloom(v: int) -> void:
	bloom_target = v
	bloom_disp = 0.0
	_vb = 0.0
	bloom_v = 0.0

func hide_bloom() -> void:
	bloom_v = -1.0
	form_card = {}

func pop(s: String, col: Color, big: bool) -> void:
	pops.append({"s": s, "col": col, "big": big, "t": 0.0, "x": randf_range(-40, 40)})

func trig(id: String, s: String) -> void:
	trigs.append({"id": id, "s": s, "t": 0.0})

func flash_red(a: float) -> void:
	red = maxf(red, a)

func super_burst(center: Vector2) -> void:
	superfx = 0.0
	super_t0 = Time.get_ticks_usec()
	super_c = center

func flash_lock() -> void:
	lockfx = 1.0

# —— 旁白字幕（像锻刀模拟器那样，屏幕下方一行字；控制台升起时让到面板上面）——
var narr := ""
var narr_t := 0.0
var narr_dur := 0.0

func narrate(s: String, dur := 5.0) -> void:
	narr = s
	narr_t = 0.0
	narr_dur = dur

func _narration(vp: Vector2) -> void:
	if narr == "" or narr_t > narr_dur:
		return
	var a := clampf(narr_t / 0.35, 0.0, 1.0) * clampf((narr_dur - narr_t) / 0.5, 0.0, 1.0)
	var sv: float = main.panel.show_v if main and main.panel else 0.0
	var y := vp.y - 120.0 - 300.0 * sv
	var lines := narr.split(String.chr(10))
	var fs := 24
	var w := 0.0
	for l in lines:
		w = maxf(w, Ink.size(Pal.hand, l, fs).x)
	var h := lines.size() * 34.0 + 18.0
	var r := Rect2(vp.x * 0.5 - w * 0.5 - 30, y - h, w + 60, h)
	draw_rect(r, Color(Color("#1f1d1a"), 0.62 * a))
	var ly := r.position.y + 36.0
	for l in lines:
		Ink.text(self, l, Vector2(vp.x * 0.5, ly), fs, Color(Color("#f8f3e7"), a), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
		ly += 34.0

func say(s: String) -> void:
	toast = s
	toast_t = 2.2

func _process(dt: float) -> void:
	t += dt
	if cel_t >= 0.0:
		cel_t += dt
		for q in confetti:
			q.v.y += 520.0 * dt
			q.v.x *= 1.0 - 1.2 * dt
			q.v.y = minf(q.v.y, 220.0)
			q.p += q.v * dt + Vector2(sin(cel_t * q.f + q.ph) * 40.0 * dt, 0)
			q.r += q.w * dt
		if cel_t > 9.0:
			cel_t = -1.0
			confetti.clear()
	if not tl.is_empty():
		tl.t += dt
		if tl.t > 2.6:
			tl = {}
	if not prev.is_empty():
		prev.t += dt
		if prev.t > 1.1:
			prev = {}
	if st_t >= 0.0:
		st_t += dt
		if not st_big and not st_hold and st_t > 0.9:
			st_t = -1.0
	var r := Ink.spring(card_v, _vc, card_t, 9.0, dt); card_v = r[0]; _vc = r[1]
	r = Ink.spring(strip_v, _vst, strip_t, 8.0, dt); strip_v = r[0]; _vst = r[1]
	if bloom_v >= 0.0:
		bloom_v += dt
		r = Ink.spring(bloom_disp, _vb, float(bloom_target), 4.2, dt); bloom_disp = r[0]; _vb = r[1]
	toast_t = maxf(0.0, toast_t - dt)
	if narr != "":
		narr_t += dt
	tip_v = lerpf(tip_v, 1.0 if not tip_lines.is_empty() else 0.0, 1.0 - exp(-18.0 * dt))
	red = maxf(0.0, red - dt * 2.2)
	lockfx = maxf(0.0, lockfx - dt * 1.2)
	if superfx >= 0.0:
		superfx = (Time.get_ticks_usec() - super_t0) / 1e6
		if superfx > 1.6:
			superfx = -1.0
	for p in pops:
		p.t += dt
	pops = pops.filter(func(p): return p.t < 0.9)
	for tg in trigs:
		tg.t += dt
	trigs = trigs.filter(func(tg): return tg.t < 2.2)
	# 开花计数：滚动时咔哒作响
	if bloom_v >= 0.0:
		var step := maxi(1, bloom_target / 24)
		var n := int(bloom_disp) / step
		if n != last_tick:
			last_tick = n
			Sfx.play("tick", -8.0, 1.0 + bloom_disp / maxf(1.0, bloom_target) * 0.5, 0.03, 0.03)
	queue_redraw()

func _draw() -> void:
	if main == null or main.run == null:
		return
	var vp := get_viewport_rect().size
	_super(vp)
	if cel_t >= 0.0:
		_celebrate(vp)
	_edges(vp)
	_strip(vp)
	_pops(vp)
	_trigs(vp)
	_tip(vp)
	if bloom_v >= 0.0:
		_bloom(vp)
		if not form_card.is_empty():
			_form_card(vp)
	if not tl.is_empty():
		_tally(vp)
	if not prev.is_empty():
		_prev_stamp(vp)
	if st_t >= 0.0:
		_stamp(vp)
	if card_v > 0.01:
		_card(vp)
	_narration(vp)
	if toast_t > 0.0:
		var a := clampf(toast_t / 0.3, 0.0, 1.0)
		var w := Ink.size(Pal.font, toast, 18).x + 40
		var rr := Rect2(vp.x * 0.5 - w * 0.5, 76, w, 40)
		draw_rect(rr, Color(Pal.c("paper"), a))
		Ink.frame(self, rr, Color(Pal.equip_line(), a), 1.4)
		Ink.text(self, toast, Vector2(vp.x * 0.5, 102), 18, Color(Pal.c("text"), a), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

## 超级同步：金色/纸色相间的射线从观测舱中心转着炸开，三道墨圈依次扩散（哑光平涂，不发光）
func _super(vp: Vector2) -> void:
	if superfx < 0.0:
		return
	var k := superfx
	var a := clampf(k / 0.08, 0.0, 1.0) * clampf((1.5 - k) / 0.6, 0.0, 1.0)
	var c := super_c
	var L := vp.length() * 0.6
	var open := Ink.ease_out_cubic(clampf(k / 0.35, 0.0, 1.0))
	for i in 24:
		var ang := i * TAU / 24.0 + k * 0.35
		var col: Color = Pal.c("gold") if i % 2 == 0 else Pal.c("paper")
		var r0 := 120.0 + 60.0 * k
		var dir := Vector2.from_angle(ang)
		# 分三段画，越往外越宽越淡（线段比多边形稳，不会三角化失败）
		for seg in 3:
			var f0 := lerpf(r0, L, seg / 3.0)
			var f1 := lerpf(r0, L, (seg + 1) / 3.0)
			var wd := (8.0 + seg * 22.0) * open * (1.0 + (i % 2) * 0.4)
			draw_line(c + dir * f0, c + dir * f1, Color(col, (0.55 - seg * 0.12) * a), wd)
	for ri in 3:
		var kk := clampf((k - ri * 0.12) / 0.7, 0.0, 1.0)
		if kk > 0.0 and kk < 1.0:
			var rr := 160.0 + 900.0 * Ink.ease_out_cubic(kk)
			draw_arc(c, rr, 0, TAU, 96, Color(Pal.c("gold").darkened(0.2 * ri), 0.9 * (1.0 - kk)), 10.0 * (1.0 - kk) + 1.0, true)

## 顶部：一条贴在镜头上的纸胶带
func _strip(vp: Vector2) -> void:
	var run: Run = main.run
	var y := lerpf(vp.y + 60.0, vp.y - 58.0, strip_v)
	var el := Pal.equip_line()
	draw_set_transform(Vector2(30, y), -0.008)
	var w := 860.0
	draw_rect(Rect2(4, 5, w, 42), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(0, 0, w, 42), Pal.c("paper"))
	Ink.frame(self, Rect2(0, 0, w, 42), Color(el, 0.5), 1.0)
	draw_rect(Rect2(-8, 8, 34, 26), Color(Pal.c("gold"), 0.45))
	draw_rect(Rect2(w - 26, 8, 34, 26), Color(Pal.c("gold"), 0.45))
	Ink.text(self, "BEAMLINE  束流", Vector2(40, 29), 18, Pal.c("text"), Pal.bold)
	var stg := "全部通过" if run.won() else (("无尽 %d" % (run.stage + 1)) if run.endless else "考核 %d/%d" % [run.stage + 1, Run.LINES.size()])
	if Run.is_big(run.stage) and not run.won():
		stg += " 大考"
	Ink.text(self, stg, Vector2(230, 29), 17, Pal.c("text"))
	Ink.text(self, "累计 %s / %s" % [main.fmt(run.total), main.fmt(run.line())], Vector2(350, 29), 17, Pal.c("text"), Pal.mono)
	Ink.text(self, "剩余实验 %d" % run.experiments_left, Vector2(610, 29), 17, Pal.c("text"))
	Ink.text(self, "$%d" % run.money, Vector2(735, 29), 17, Pal.c("green"), Pal.mono)
	Ink.text(self, "F2 配色", Vector2(800, 29), 13, Pal.c("text2"))
	draw_set_transform(Vector2.ZERO)

func _stamp(vp: Vector2) -> void:
	var k := minf(1.0, st_t / 0.14)
	var sc := lerpf(1.9, 1.0, Ink.ease_out_back(k))
	var a := 1.0 if (st_big or st_hold) else clampf((0.9 - st_t) / 0.3, 0.0, 1.0)
	var c := Vector2(vp.x * 0.5, 210 if not st_big else 330)
	var fs := 34 if not st_big else 72
	draw_set_transform(c, st_rot, Vector2(sc, sc))
	var w := Ink.size(Pal.bold, st_text, fs).x + 48
	var h := fs + 34.0
	var col := Color(st_col, a * 0.92)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a * 0.55))
	Ink.frame(self, Rect2(-w * 0.5, -h * 0.5, w, h), col, 4.0)
	Ink.frame(self, Rect2(-w * 0.5 + 7, -h * 0.5 + 7, w - 14, h - 14), col, 1.6)
	Ink.text(self, st_text, Vector2(0, fs * 0.36), fs, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 印泥不均：随机白点
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(st_text)
	for i in 26:
		var p := Vector2(rng.randf_range(-w * 0.5, w * 0.5), rng.randf_range(-h * 0.5, h * 0.5))
		Ink.disc(self, p, rng.randf_range(0.8, 2.4), Color(Pal.c("paper"), a * 0.7))
	draw_set_transform(Vector2.ZERO)

func _tally(vp: Vector2) -> void:
	var k: float = tl.t
	var drop := Ink.ease_out_back(clampf(k / 0.35, 0.0, 1.0))
	var fly := Ink.ease_in_out(clampf((k - 2.0) / 0.5, 0.0, 1.0))
	var home := Vector2(vp.x * 0.5, 150.0)
	# 实验报告送进审核台的收件盘（DECISIONS Q64）
	var dest := Vector2(230.0, 250.0)
	if main and main.run and main.run.inj == "full":
		# 成果瓶回到注入器瓶座上，等玩家拿去审核台
		dest = get_viewport().get_canvas_transform() * (main.stash.CRADLE + Vector2(0, -20))
	elif main and main.review:
		dest = get_viewport().get_canvas_transform() * (main.review.inbox() as Vector2)
	var has_bt: bool = not tl.get("bottle", {}).is_empty()
	var p := Vector2(home.x, lerpf(-80.0, home.y, drop))
	var sc := 1.0
	var a := 1.0 - clampf((k - 2.35) / 0.25, 0.0, 1.0)
	if has_bt:
		# 有满瓶：报告留在原地淡出，飞进篮子的是瓶子
		a = 1.0 - clampf((k - 1.9) / 0.4, 0.0, 1.0)
	else:
		p = p.lerp(dest, fly)
		sc = lerpf(1.0, 0.35, fly)
	draw_set_transform(p, -0.03 + 0.1 * fly, Vector2(sc, sc))
	var w := 430.0
	var h := 112.0
	draw_rect(Rect2(-w * 0.5 + 5, -h * 0.5 + 7, w, h), Color(0, 0, 0, 0.14 * a))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, 10), Color(tl.col, a))
	Ink.frame(self, Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.equip_line(), a), 1.6)
	Ink.text(self, tl.title, Vector2(-w * 0.5 + 20, -h * 0.5 + 36), 16, Color(Pal.c("text2"), a), Pal.bold)
	Ink.text(self, tl.sub, Vector2(w * 0.5 - 20, -h * 0.5 + 36), 15, Color(Pal.c("green"), a), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
	Ink.text(self, tl.value, Vector2(0, h * 0.5 - 20), 40, Color(tl.col, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	if has_bt:
		# 满瓶：在报告左边弹出来（束流装回瓶里），再飞进审核台的篮子
		var pop := Ink.ease_out_back(clampf((k - 0.25) / 0.35, 0.0, 1.0))
		if pop > 0.0:
			var b0 := Vector2(home.x - 300.0, home.y + 70.0)
			var bfly := Ink.ease_in_out(clampf((k - 1.9) / 0.6, 0.0, 1.0))
			var bp := b0.lerp(dest + Vector2(0, 20), bfly) + Vector2(0, -sin(bfly * PI) * 80.0)
			var bsc := lerpf(2.4 * pop, 0.45, bfly)
			if k < 2.5:
				STASH.full_bottle(self, bp, bsc, tl.bottle)

## 被饰品改写的旧章：往上让开、变小，一道红笔划掉，然后淡出
func _prev_stamp(vp: Vector2) -> void:
	var k: float = prev.t
	var a := clampf((1.1 - k) / 0.4, 0.0, 1.0)
	var mv := Ink.ease_out_cubic(minf(1.0, k / 0.25))
	var c := Vector2(vp.x * 0.5 - 150.0 * mv, 210.0 - 40.0 * mv)
	var sc := lerpf(1.0, 0.72, mv)
	var fs := 34
	draw_set_transform(c, prev.rot - 0.1 * mv, Vector2(sc, sc))
	var w := Ink.size(Pal.bold, prev.text, fs).x + 48
	var h := fs + 34.0
	var col := Color(prev.col, a * 0.6)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a * 0.5))
	Ink.frame(self, Rect2(-w * 0.5, -h * 0.5, w, h), col, 3.0)
	Ink.text(self, prev.text, Vector2(0, fs * 0.36), fs, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	var sk := clampf(k / 0.18, 0.0, 1.0)
	draw_line(Vector2(-w * 0.55, 6), Vector2(-w * 0.55 + w * 1.1 * sk, -6), Color(Pal.c("red"), a), 5.0, true)
	draw_set_transform(Vector2.ZERO)

func _bloom(vp: Vector2) -> void:
	var a := clampf(bloom_v / 0.3, 0.0, 1.0)
	var y := vp.y - 150
	var bw := 520.0
	draw_rect(Rect2(vp.x * 0.5 - bw * 0.5 + 6, y - 74, bw, 132), Color(0, 0, 0, 0.15 * a))
	draw_rect(Rect2(vp.x * 0.5 - bw * 0.5, y - 80, bw, 132), Color(Pal.c("paper"), a))
	Ink.frame(self, Rect2(vp.x * 0.5 - bw * 0.5, y - 80, bw, 132), Color(Pal.equip_line(), a), 1.6)
	var s: String = main.fmt(int(round(bloom_disp)))
	Ink.text(self, "+" + s + " RP", Vector2(vp.x * 0.5 + 3, y + 3), 64, Color(0, 0, 0, 0.25 * a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "+" + s + " RP", Vector2(vp.x * 0.5, y), 64, Color(Pal.c("text"), a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	if bloom_meme.is_empty():
		Ink.text(self, "探测屏 · 事件图谱", Vector2(vp.x * 0.5, y + 40), 18, Color(Pal.c("text2"), a), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		Ink.text(self, "奇葩事件 · " + bloom_meme.name, Vector2(vp.x * 0.5, y + 40), 20, Color(Pal.c("red"), a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		# 纸签从卡片右上角“啪”地贴上：第一次见到写“新发现！”，否则写“已收录”
		var k := clampf((bloom_v - 0.5) / 0.18, 0.0, 1.0)
		if k > 0.0:
			var sc := lerpf(2.0, 1.0, Ink.ease_out_back(k))
			draw_set_transform(Vector2(vp.x * 0.5 + bw * 0.5 - 30, y - 80), 0.22, Vector2(sc, sc))
			var col := Pal.c("red") if bloom_meme.first else Pal.c("text2")
			var txt := "新发现！" if bloom_meme.first else "已收录"
			draw_rect(Rect2(-58, -18, 116, 36), Color(Pal.c("paper"), a))
			Ink.frame(self, Rect2(-58, -18, 116, 36), Color(col, a), 3.0)
			Ink.text(self, txt, Vector2(0, 8), 20, Color(col, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			draw_set_transform(Vector2.ZERO)

func _card(vp: Vector2) -> void:
	var el := Pal.equip_line()
	var w := 640.0
	var h: float = 300.0 + 30.0 * card.get("lines", []).size()
	var x := vp.x * 0.5 - w * 0.5
	var y := lerpf(vp.y + 40, vp.y * 0.5 - h * 0.5 - 60 + float(card.get("dy", 0.0)), card_v)
	draw_set_transform(Vector2(x + w * 0.5, y + h * 0.5), 0.01 * (1.0 - card_v) + 0.006)
	var o := Vector2(-w * 0.5, -h * 0.5)
	draw_rect(Rect2(o + Vector2(8, 10), Vector2(w, h)), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(o, Vector2(w, h)), Pal.c("paper"))
	Ink.frame(self, Rect2(o, Vector2(w, h)), el, Ink.W1)
	Ink.frame(self, Rect2(o + Vector2(10, 10), Vector2(w - 20, h - 20)), Color(el, 0.3), Ink.W3)
	# 打孔
	for i in 3:
		Ink.disc(self, o + Vector2(28, 60 + i * 70), 7.0, Pal.c("paper2"))
		draw_arc(o + Vector2(28, 60 + i * 70), 7.0, 0, TAU, 16, Color(el, 0.5), 1.0, true)
	Ink.text(self, card.get("title", ""), o + Vector2(64, 62), 30, card.get("title_col", Pal.c("text")), Pal.bold)
	Ink.text(self, card.get("value", ""), o + Vector2(64, 138), 56, Pal.c("text"), Pal.mono)
	Ink.text(self, card.get("sub", ""), o + Vector2(64, 176), 18, Pal.c("text2"))
	var ly := 220.0
	for l in card.get("lines", []):
		Ink.text(self, l, o + Vector2(64, ly), 18, Pal.c("blue"), Pal.hand)
		ly += 30.0
	draw_line(o + Vector2(40, h - 62), o + Vector2(w - 40, h - 62), Color(el, 0.4), 1.0)
	# 可点击的纸按钮（同时标出快捷键）
	btn_rects.clear()
	var bx := o.x + 48.0
	var btns: Array = main.card_buttons()
	for i in btns.size():
		var b: Dictionary = btns[i]
		var label: String = b.label
		var bw := Ink.size(Pal.bold, label, 18).x + Ink.size(Pal.mono, b.key, 13).x + 52
		var br := Rect2(bx, o.y + h - 54, bw, 40)
		var hot := hover_btn == i
		draw_rect(br.grow(2) if hot else br, Pal.c("gold") if hot else Pal.c("paper2"))
		Ink.frame(self, br, Pal.equip_line(), 2.0 if hot else 1.4)
		Ink.text(self, label, br.position + Vector2(14, 27), 18, Pal.c("text"), Pal.bold)
		Ink.text(self, b.key, br.end - Vector2(12, 13), 13, Pal.c("text2"), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
		# 按钮矩形转回屏幕坐标（卡片绕中心有极小旋转，可忽略）
		btn_rects.append({"rect": Rect2(br.position + Vector2(x + w * 0.5, y + h * 0.5), br.size), "action": b.action})
		bx += bw + 14.0
	draw_set_transform(Vector2.ZERO)

## 屏幕边缘：危险时红色呼吸 + 心跳闪；锁相时紫色一闪（平涂渐变，无辉光）
func _edges(vp: Vector2) -> void:
	var a := clampf(danger * 0.22 + red * 0.35, 0.0, 0.6)
	if a > 0.01:
		_edge_band(vp, Pal.c("red"), a)
	if lockfx > 0.01:
		_edge_band(vp, Pal.c("lock"), lockfx * 0.5)
	if superfx >= 0.0:
		_edge_band(vp, Pal.c("gold"), clampf(1.0 - superfx / 1.4, 0.0, 1.0) * 0.8)

func _edge_band(vp: Vector2, col: Color, a: float) -> void:
	var w := 140.0
	for i in 10:
		var k := 1.0 - i / 10.0
		var c := Color(col, a * k * k * 0.35)
		var o := i * w / 10.0
		draw_rect(Rect2(o, o, vp.x - o * 2, w / 10.0), c)
		draw_rect(Rect2(o, vp.y - o - w / 10.0, vp.x - o * 2, w / 10.0), c)
		draw_rect(Rect2(o, o, w / 10.0, vp.y - o * 2), c)
		draw_rect(Rect2(vp.x - o - w / 10.0, o, w / 10.0, vp.y - o * 2), c)

## 飞字：从观测舱上方弹出、上浮、淡出
func _pops(vp: Vector2) -> void:
	for p in pops:
		var t: float = p.t
		var k := minf(1.0, t / 0.16)
		var sc := lerpf(0.4, 1.0, Ink.ease_out_back(k))
		var a := clampf((0.9 - t) / 0.35, 0.0, 1.0)
		var fs := 96 if p.big else 72
		var pos := Vector2(vp.x * 0.5 + 360 + p.x * 0.5, 330 - t * 90.0)
		draw_set_transform(pos, -0.05, Vector2(sc, sc))
		Ink.text(self, p.s, Vector2(3, 4), fs, Color(0, 0, 0, 0.2 * a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, p.s, Vector2.ZERO, fs, Color(p.col, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform(Vector2.ZERO)

## 饰品触发：从左上方依次滑入的小纸签（图标 + 说明）
func _trigs(vp: Vector2) -> void:
	var i := 0
	for tg in trigs:
		var t: float = tg.t
		var k := Ink.ease_out_back(minf(1.0, t / 0.25))
		var a := clampf((2.2 - t) / 0.4, 0.0, 1.0)
		var w := Ink.size(Pal.font, tg.s, 18).x + 84
		var p := Vector2(lerpf(-w, 470.0, k), 120.0 + i * 64)
		draw_set_transform(p, -0.02)
		draw_rect(Rect2(4, 5, w, 54), Color(0, 0, 0, 0.15 * a))
		draw_rect(Rect2(0, 0, w, 54), Color(Pal.c("paper"), a))
		Ink.frame(self, Rect2(0, 0, w, 54), Color(Pal.c("gold"), a), 3.0)
		draw_set_transform(Vector2.ZERO)
		Icons.draw(self, tg.id, p + Vector2(32, 27), 40.0)
		draw_set_transform(p, -0.02)
		Ink.text(self, tg.s, Vector2(62, 34), 18, Color(Pal.c("text"), a), Pal.bold)
		draw_set_transform(Vector2.ZERO)
		i += 1

func button_at(p: Vector2) -> String:
	if card_v < 0.9:
		return ""
	for i in btn_rects.size():
		if btn_rects[i].rect.has_point(p):
			return btn_rects[i].action
	return ""

func hover_at(p: Vector2) -> int:
	if card_v < 0.9:
		return -1
	for i in btn_rects.size():
		if btn_rects[i].rect.has_point(p):
			return i
	return -1

## 悬停说明纸签：跟随鼠标，自动避开屏幕边缘
func tip(lines: PackedStringArray, p: Vector2) -> void:
	tip_lines = lines
	tip_pos = p

func _tip(vp: Vector2) -> void:
	if tip_lines.is_empty() or tip_v < 0.02:
		return
	var w := 0.0
	for i in tip_lines.size():
		var f: Font = Pal.bold if i == 0 else Pal.font
		w = maxf(w, Ink.size(f, tip_lines[i], 17 if i == 0 else 15).x)
	w = minf(w + 32, 460.0)
	var h := 0.0
	for i in tip_lines.size():
		h += 30.0 if i == 0 else Ink.para_size(Pal.font, tip_lines[i], w - 32, 15).y + 6
	h += 22.0
	var p := tip_pos + Vector2(22, 18)
	if p.x + w > vp.x - 10: p.x = tip_pos.x - w - 16
	if p.y + h > vp.y - 10: p.y = tip_pos.y - h - 10
	var a := tip_v
	draw_rect(Rect2(p + Vector2(4, 5), Vector2(w, h)), Color(0, 0, 0, 0.15 * a))
	draw_rect(Rect2(p, Vector2(w, h)), Color(Pal.c("paper"), a))
	Ink.frame(self, Rect2(p, Vector2(w, h)), Color(Pal.equip_line(), a), 1.6)
	var y := p.y + 30.0
	for i in tip_lines.size():
		if i == 0:
			Ink.text(self, tip_lines[i], Vector2(p.x + 16, y), 17, Color(Pal.c("text"), a), Pal.bold)
			y += 10.0
		else:
			Ink.para(self, Pal.font, Vector2(p.x + 16, y + 14), tip_lines[i], w - 32, 15, -1, Color(Pal.c("text") if i == 1 else Pal.c("blue"), a))
			y += Ink.para_size(Pal.font, tip_lines[i], w - 32, 15).y + 6

## 阶段通过：大红“通过”章砸下来 → 横幅展开“恭喜通过第 N 阶段审核” → 两边礼炮喷纸屑 → 章盖到横幅角上
func celebrate(stage_no: int, quip: String) -> void:
	cel_t = 0.0
	cel_stage = stage_no
	cel_quip = quip
	confetti.clear()
	var vp := get_viewport_rect().size
	var cols := [Pal.c("red"), Pal.c("gold"), Pal.c("blue"), Pal.c("green"), Pal.c("paper"), Pal.c("orange"), Pal.c("lock")]
	for side in [-1.0, 1.0]:
		for i in 70:
			var a := deg_to_rad(-90.0 - side * randf_range(8.0, 50.0))
			var sp := randf_range(700.0, 1350.0)
			confetti.append({"p": Vector2(vp.x * 0.5 + side * (vp.x * 0.5 + 10.0), vp.y + 10.0), "v": Vector2.from_angle(a) * sp,
				"r": randf() * TAU, "w": randf_range(-9, 9), "s": Vector2(randf_range(7, 15), randf_range(4, 8)), "c": cols[i % cols.size()],
				"f": randf_range(2.0, 5.0), "ph": randf() * TAU, "d": randf_range(0.25, 0.75)})

func _celebrate(vp: Vector2) -> void:
	var k := cel_t
	var fade := clampf((8.6 - k) / 0.6, 0.0, 1.0)
	# 背景压暗一点
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.22 * clampf(k / 0.2, 0.0, 1.0) * fade))
	var c := Vector2(vp.x * 0.5, 400.0)
	# 背后的射线：金纸相间，慢慢转
	var ra := clampf((k - 0.1) / 0.3, 0.0, 1.0) * fade
	if ra > 0.0:
		for i in 20:
			var ang := i * TAU / 20.0 + k * 0.25
			var col: Color = Pal.c("gold") if i % 2 == 0 else Pal.c("paper")
			draw_line(c + Vector2.from_angle(ang) * 120.0, c + Vector2.from_angle(ang) * 1300.0, Color(col, 0.28 * ra), 70.0)
	# 横幅：从中间往两边展开
	var bo := Ink.ease_out_back(clampf((k - 0.3) / 0.45, 0.0, 1.0))
	if bo > 0.0:
		var bw := 1040.0 * bo
		var br := Rect2(vp.x * 0.5 - bw * 0.5, 96.0, bw, 120.0)
		draw_rect(Rect2(br.position + Vector2(8, 10), br.size), Color(0, 0, 0, 0.2 * fade))
		draw_rect(br, Color(Pal.c("red"), fade))
		Ink.frame(self, br.grow(-8), Color(Pal.c("gold"), fade), 3.0)
		# 两头燕尾
		for sd in [-1.0, 1.0]:
			var ex := br.position.x if sd < 0 else br.end.x
			draw_colored_polygon(PackedVector2Array([Vector2(ex, br.position.y + 18), Vector2(ex + sd * 70.0 * bo, br.position.y + 30), Vector2(ex + sd * 40.0 * bo, br.get_center().y + 12), Vector2(ex + sd * 70.0 * bo, br.end.y + 6), Vector2(ex, br.end.y - 18)]), Color(Pal.c("red").darkened(0.25), fade))
		if bo > 0.85:
			var ta := clampf((bo - 0.85) / 0.15, 0.0, 1.0) * fade
			Ink.text(self, "恭喜通过第 %d 阶段审核！" % cel_stage, Vector2(vp.x * 0.5 + 3, br.get_center().y + 22), 54, Color(0, 0, 0, 0.25 * ta), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			Ink.text(self, "恭喜通过第 %d 阶段审核！" % cel_stage, Vector2(vp.x * 0.5, br.get_center().y + 19), 54, Color(Pal.c("paper"), ta), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 手写的一句“劫后余生”
	var qa := clampf((k - 1.0) / 0.4, 0.0, 1.0) * fade
	if qa > 0.0 and cel_quip != "":
		var qw := Ink.size(Pal.hand, cel_quip, 26).x + 60.0
		draw_rect(Rect2(vp.x * 0.5 - qw * 0.5, 232.0, qw, 44.0), Color(Pal.c("paper"), 0.92 * qa))
		Ink.frame(self, Rect2(vp.x * 0.5 - qw * 0.5, 232.0, qw, 44.0), Color(Pal.equip_line(), 0.5 * qa), 1.2)
		Ink.text(self, cel_quip, Vector2(vp.x * 0.5, 263.0), 26, Color(Pal.c("blue"), qa), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	# 大红“通过”章：先从天而降砸在中间，再缩到横幅右上角
	var drop := clampf(k / 0.22, 0.0, 1.0)
	var move := Ink.ease_in_out(clampf((k - 1.1) / 0.4, 0.0, 1.0))
	var sp := c.lerp(Vector2(vp.x * 0.5 + 470.0, 120.0), move)
	var sc := lerpf(3.2, 1.0, Ink.ease_out_cubic(drop)) * lerpf(1.0, 0.42, move)
	var sa := drop * fade
	draw_set_transform(sp, -0.18, Vector2(sc, sc))
	Ink.disc(self, Vector2.ZERO, 120.0, Color(Pal.c("paper"), 0.85 * sa))
	draw_arc(Vector2.ZERO, 120.0, 0.3, TAU - 0.1, 64, Color(Pal.c("red"), sa), 10.0, true)
	draw_arc(Vector2.ZERO, 100.0, 0, TAU, 64, Color(Pal.c("red"), sa), 3.0, true)
	var star := PackedVector2Array()
	for i in 10:
		star.append(Vector2.from_angle(-PI / 2 + i * PI / 5) * (26.0 if i % 2 == 0 else 11.0) + Vector2(0, -52))
	draw_colored_polygon(star, Color(Pal.c("red"), sa))
	Ink.text(self, "通过", Vector2(0, 30), 64, Color(Pal.c("red"), sa), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "第七实验站 · 评审委员会", Vector2(0, 70), 14, Color(Pal.c("red"), sa), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	# 砸下那一刻的冲击圈
	if k > 0.2 and k < 0.7:
		var ik := (k - 0.2) / 0.5
		draw_arc(c, 130.0 + 260.0 * Ink.ease_out_cubic(ik), 0, TAU, 72, Color(Pal.c("red"), 0.7 * (1.0 - ik)), 8.0 * (1.0 - ik) + 1.0, true)
	# 纸屑礼炮（两边一起喷）
	if k > 0.45:
		for q in confetti:
			var qa2 := fade
			draw_set_transform(q.p, q.r, Vector2(absf(cos(q.r * 1.7)) * 0.85 + 0.15, 1.0))
			draw_rect(Rect2(-q.s * 0.5, q.s), Color(q.c, qa2))
			draw_set_transform(Vector2.ZERO)

## 束流形态成果卡：引出后从左边甩进来，迷你画 + 名字 + 档次章 + 加成 + 称号，第一次做出来贴“新发现！”
func _form_card(vp: Vector2) -> void:
	var d := form_card
	var k := clampf((bloom_v - 0.3) / 0.45, 0.0, 1.0)
	if k <= 0.0:
		return
	var out := clampf((bloom_v - 3.3) / 0.3, 0.0, 1.0)
	var e := Ink.ease_out_back(k)
	var W := 400.0
	var H := 520.0
	var c := Vector2(lerpf(-W, 60.0 + W * 0.5, e) - out * (W + 120.0), vp.y * 0.5 - 20.0)
	var rot := (1.0 - e) * -0.25 - 0.025
	draw_set_transform(c, rot)
	var r := Rect2(-W * 0.5, -H * 0.5, W, H)
	var el := Pal.equip_line()
	var legend: bool = d.legend != ""
	var head := Pal.c("gold").darkened(0.15) if legend else (Pal.c("blue") if d.tier == 2 else (Pal.c("green") if d.tier == 1 else Pal.c("ink2")))
	draw_rect(Rect2(r.position + Vector2(10, 14), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, Pal.c("paper"))
	draw_rect(Rect2(r.position, Vector2(W, 48)), head)
	Ink.text(self, "实验成果 · #%d · E%d 引出" % [d.get("no", 1), d.energy], r.position + Vector2(20, 32), 20, Pal.c("paper"), Pal.bold)
	Ink.frame(self, r, el, 2.0)
	# 画框：迷你束流
	var box := Rect2(r.position + Vector2(24, 66), Vector2(W - 48, 230))
	draw_rect(box, Pal.c("inner0"))
	Ink.frame(self, box, Color(el, 0.6), 1.4)
	for gx in range(1, 12):
		draw_line(Vector2(box.position.x + gx * box.size.x / 12.0, box.position.y), Vector2(box.position.x + gx * box.size.x / 12.0, box.end.y), Color(Pal.c("grid"), 0.6), 1.0)
	var st := d.duplicate()
	st["g"] = float(d.peak)
	st["t"] = t
	st["dmg"] = 0.6 if d.damaged else 0.0
	st["col"] = Pal.ramp(clampf((d.peak - 1) / 12.0, 0.0, 1.0))
	st["core_r"] = 9.0 + clampf((d.peak - 1) / 12.0, 0.0, 1.0) * 16.0
	st["card"] = true
	st["omen"] = 0.0
	st["grow"] = 1.0
	var cs := 0.62
	form_art.draw(self, box.get_center() + Vector2(0, 6), cs, st)
	draw_set_transform(c, rot)
	# 名字（太长就缩）
	var name: String = d.name
	var fs := 34
	while fs > 18 and Ink.size(Pal.bold, name, fs).x > W - 48:
		fs -= 1
	Ink.text(self, name, Vector2(0, r.position.y + 346), fs, Pal.c("text"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	var y := r.position.y + 374.0
	if d.from != "":
		Ink.text(self, d.from, Vector2(0, y), 16, Pal.c("text2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
		y += 24.0
	# 档次章 + 加成
	var bonus_s := ("成果加成 +%d%%" % int(round(d.bonus * 100.0))) if d.bonus > 0.0 else "成果加成 —"
	Ink.text(self, bonus_s, Vector2(r.position.x + 120, y + 26), 18, Pal.c("green") if d.bonus > 0.0 else Pal.c("text2"), Pal.bold)
	var sk := clampf((bloom_v - 0.75) / 0.16, 0.0, 1.0)
	if sk > 0.0:
		var ssc := lerpf(2.2, 1.0, Ink.ease_out_back(sk))
		draw_set_transform(c + Vector2(r.position.x + 64, y + 18).rotated(rot), rot - 0.2, Vector2(ssc, ssc))
		draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, head, 3.0, true)
		Ink.text(self, d.rank, Vector2(0, 8), 20, head, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform(c, rot)
	y += 62.0
	Ink.para(self, Pal.hand, Vector2(r.position.x + 28, y), d.desc, W - 56, 18, -1, Pal.c("blue"))
	y += 52.0
	if d.damaged:
		Ink.text(self, "受损：引出时掉回了 E%d，加成按%s档算" % [d.energy, Forms.TIER_NAMES[Forms.tier_of(d.energy)]], Vector2(r.position.x + 28, y), 14, Pal.c("red"))
		y += 22.0
	for tr in d.traits:
		Ink.text(self, "◆ " + Forms.TRAITS[tr].name + "：" + Forms.TRAITS[tr].desc, Vector2(r.position.x + 28, y), 14, Pal.c("text2"))
		y += 20.0
	# 新发现 / 已收录
	var nk := clampf((bloom_v - 1.0) / 0.18, 0.0, 1.0)
	if nk > 0.0:
		var nsc := lerpf(2.0, 1.0, Ink.ease_out_back(nk))
		draw_set_transform(c + Vector2(W * 0.5 - 40, -H * 0.5 + 10).rotated(rot), rot + 0.22, Vector2(nsc, nsc))
		var ncol := Pal.c("red") if d.first else Pal.c("text2")
		var txt := "新发现！" if d.first else "已收录"
		draw_rect(Rect2(-58, -18, 116, 36), Pal.c("paper"))
		Ink.frame(self, Rect2(-58, -18, 116, 36), ncol, 3.0)
		Ink.text(self, txt, Vector2(0, 8), 20, ncol, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
