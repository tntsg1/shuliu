extends Control
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

## 一次实验结束：纸条从上方落下，报出这一束加了多少，然后飞进左边的考核夹板
func tally(title: String, value: String, sub: String, col: Color) -> void:
	tl = {"title": title, "value": value, "sub": sub, "col": col, "t": 0.0}

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

func show_bloom(v: int) -> void:
	bloom_target = v
	bloom_disp = 0.0
	_vb = 0.0
	bloom_v = 0.0

func hide_bloom() -> void:
	bloom_v = -1.0

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

func say(s: String) -> void:
	toast = s
	toast_t = 2.2

func _process(dt: float) -> void:
	t += dt
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
	_edges(vp)
	_strip(vp)
	_pops(vp)
	_trigs(vp)
	_tip(vp)
	if bloom_v >= 0.0:
		_bloom(vp)
	if not tl.is_empty():
		_tally(vp)
	if not prev.is_empty():
		_prev_stamp(vp)
	if st_t >= 0.0:
		_stamp(vp)
	if card_v > 0.01:
		_card(vp)
	if toast_t > 0.0:
		var a := clampf(toast_t / 0.3, 0.0, 1.0)
		var w := Pal.font.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 40
		var rr := Rect2(vp.x * 0.5 - w * 0.5, 76, w, 40)
		draw_rect(rr, Color(Pal.c("paper"), a))
		draw_rect(rr, Color(Pal.equip_line(), a), false, 1.4)
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
	draw_rect(Rect2(0, 0, w, 42), Color(el, 0.5), false, 1.0)
	draw_rect(Rect2(-8, 8, 34, 26), Color(Pal.c("gold"), 0.45))
	draw_rect(Rect2(w - 26, 8, 34, 26), Color(Pal.c("gold"), 0.45))
	Ink.text(self, "BEAMLINE  束流", Vector2(40, 29), 18, Pal.c("text"), Pal.bold)
	var stg := "全部通过" if run.won() else "考核 %d/%d" % [run.stage + 1, Run.LINES.size()]
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
	var w := Pal.bold.get_string_size(st_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 48
	var h := fs + 34.0
	var col := Color(st_col, a * 0.92)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a * 0.55))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), col, false, 4.0)
	draw_rect(Rect2(-w * 0.5 + 7, -h * 0.5 + 7, w - 14, h - 14), col, false, 1.6)
	Ink.text(self, st_text, Vector2(0, fs * 0.36), fs, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 印泥不均：随机白点
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(st_text)
	for i in 26:
		var p := Vector2(rng.randf_range(-w * 0.5, w * 0.5), rng.randf_range(-h * 0.5, h * 0.5))
		draw_circle(p, rng.randf_range(0.8, 2.4), Color(Pal.c("paper"), a * 0.7))
	draw_set_transform(Vector2.ZERO)

func _tally(vp: Vector2) -> void:
	var k: float = tl.t
	var drop := Ink.ease_out_back(clampf(k / 0.35, 0.0, 1.0))
	var fly := Ink.ease_in_out(clampf((k - 2.0) / 0.5, 0.0, 1.0))
	var home := Vector2(vp.x * 0.5, 150.0)
	var dest := Vector2(230.0, 250.0)
	var p := Vector2(home.x, lerpf(-80.0, home.y, drop)).lerp(dest, fly)
	var sc := lerpf(1.0, 0.35, fly)
	var a := 1.0 - clampf((k - 2.35) / 0.25, 0.0, 1.0)
	draw_set_transform(p, -0.03 + 0.1 * fly, Vector2(sc, sc))
	var w := 430.0
	var h := 112.0
	draw_rect(Rect2(-w * 0.5 + 5, -h * 0.5 + 7, w, h), Color(0, 0, 0, 0.14 * a))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, 10), Color(tl.col, a))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.equip_line(), a), false, 1.6)
	Ink.text(self, tl.title, Vector2(-w * 0.5 + 20, -h * 0.5 + 36), 16, Color(Pal.c("text2"), a), Pal.bold)
	Ink.text(self, tl.sub, Vector2(w * 0.5 - 20, -h * 0.5 + 36), 15, Color(Pal.c("green"), a), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
	Ink.text(self, tl.value, Vector2(0, h * 0.5 - 20), 40, Color(tl.col, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

## 被饰品改写的旧章：往上让开、变小，一道红笔划掉，然后淡出
func _prev_stamp(vp: Vector2) -> void:
	var k: float = prev.t
	var a := clampf((1.1 - k) / 0.4, 0.0, 1.0)
	var mv := Ink.ease_out_cubic(minf(1.0, k / 0.25))
	var c := Vector2(vp.x * 0.5 - 150.0 * mv, 210.0 - 40.0 * mv)
	var sc := lerpf(1.0, 0.72, mv)
	var fs := 34
	draw_set_transform(c, prev.rot - 0.1 * mv, Vector2(sc, sc))
	var w := Pal.bold.get_string_size(prev.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 48
	var h := fs + 34.0
	var col := Color(prev.col, a * 0.6)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a * 0.5))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), col, false, 3.0)
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
	draw_rect(Rect2(vp.x * 0.5 - bw * 0.5, y - 80, bw, 132), Color(Pal.equip_line(), a), false, 1.6)
	var s: String = main.fmt(int(round(bloom_disp)))
	Ink.text(self, "+" + s + " RP", Vector2(vp.x * 0.5 + 3, y + 3), 64, Color(0, 0, 0, 0.25 * a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "+" + s + " RP", Vector2(vp.x * 0.5, y), 64, Color(Pal.c("text"), a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "探测屏 · 事件图谱", Vector2(vp.x * 0.5, y + 40), 18, Color(Pal.c("text2"), a), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

func _card(vp: Vector2) -> void:
	var el := Pal.equip_line()
	var w := 640.0
	var h: float = 300.0 + 30.0 * card.get("lines", []).size()
	var x := vp.x * 0.5 - w * 0.5
	var y := lerpf(vp.y + 40, vp.y * 0.5 - h * 0.5 - 60, card_v)
	draw_set_transform(Vector2(x + w * 0.5, y + h * 0.5), 0.01 * (1.0 - card_v) + 0.006)
	var o := Vector2(-w * 0.5, -h * 0.5)
	draw_rect(Rect2(o + Vector2(8, 10), Vector2(w, h)), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(o, Vector2(w, h)), Pal.c("paper"))
	draw_rect(Rect2(o, Vector2(w, h)), el, false, 2.0)
	draw_rect(Rect2(o + Vector2(10, 10), Vector2(w - 20, h - 20)), Color(el, 0.3), false, 1.0)
	# 打孔
	for i in 3:
		draw_circle(o + Vector2(28, 60 + i * 70), 7.0, Pal.c("paper2"))
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
		var bw := Pal.bold.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + Pal.mono.get_string_size(b.key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 52
		var br := Rect2(bx, o.y + h - 54, bw, 40)
		var hot := hover_btn == i
		draw_rect(br.grow(2) if hot else br, Pal.c("gold") if hot else Pal.c("paper2"))
		draw_rect(br, Pal.equip_line(), false, 2.0 if hot else 1.4)
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
		var w := Pal.font.get_string_size(tg.s, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 84
		var p := Vector2(lerpf(-w, 470.0, k), 120.0 + i * 64)
		draw_set_transform(p, -0.02)
		draw_rect(Rect2(4, 5, w, 54), Color(0, 0, 0, 0.15 * a))
		draw_rect(Rect2(0, 0, w, 54), Color(Pal.c("paper"), a))
		draw_rect(Rect2(0, 0, w, 54), Color(Pal.c("gold"), a), false, 3.0)
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
		w = maxf(w, f.get_string_size(tip_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17 if i == 0 else 15).x)
	w = minf(w + 32, 460.0)
	var h := 0.0
	for i in tip_lines.size():
		h += 30.0 if i == 0 else Pal.font.get_multiline_string_size(tip_lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 32, 15).y + 6
	h += 22.0
	var p := tip_pos + Vector2(22, 18)
	if p.x + w > vp.x - 10: p.x = tip_pos.x - w - 16
	if p.y + h > vp.y - 10: p.y = tip_pos.y - h - 10
	var a := tip_v
	draw_rect(Rect2(p + Vector2(4, 5), Vector2(w, h)), Color(0, 0, 0, 0.15 * a))
	draw_rect(Rect2(p, Vector2(w, h)), Color(Pal.c("paper"), a))
	draw_rect(Rect2(p, Vector2(w, h)), Color(Pal.equip_line(), a), false, 1.6)
	var y := p.y + 30.0
	for i in tip_lines.size():
		if i == 0:
			Ink.text(self, tip_lines[i], Vector2(p.x + 16, y), 17, Color(Pal.c("text"), a), Pal.bold)
			y += 10.0
		else:
			draw_multiline_string(Pal.font, Vector2(p.x + 16, y + 14), tip_lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 32, 15, -1, Color(Pal.c("text") if i == 1 else Pal.c("blue"), a))
			y += Pal.font.get_multiline_string_size(tip_lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 32, 15).y + 6
