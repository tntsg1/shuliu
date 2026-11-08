extends Control
## 开场：园区总平面图上的 26.7 km 主环 → 推近到第七实验站 → 剖切线 A-A → 转成实验室剖面（任意键跳过）

signal finished

var t := 0.0
var active := false
const DUR := 6.2
const R := 400.0
const ME := -PI * 0.5 + TAU * 6.0 / 8.0   # 第七实验站在环上的方位

func play() -> void:
	t = 0.0
	active = true
	visible = true

func skip() -> void:
	if active and t > 0.3:
		t = maxf(t, DUR - 0.5)

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

func _process(dt: float) -> void:
	if not active:
		return
	t += dt
	if t >= DUR:
		active = false
		visible = false
		finished.emit()
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	var paper := Pal.c("paper") if not Pal.dark else Color("#e9dfc6")
	var ink := Color("#2b2a28")
	var blue := Color("#2f5d9e")
	var red := Color("#c2412d")
	# 结尾 0.5 s 纸面淡出露出游戏
	var fade := 1.0 - clampf((t - (DUR - 0.5)) / 0.5, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(paper, fade))
	if fade <= 0.0:
		return
	var center := vp * 0.5 + Vector2(0, 20)
	var me := center + Vector2.from_angle(ME) * R
	# 推近：1.6 s 后从 1× 指数推到 60×，焦点从图心滑到实验站
	var zk := Ink.ease_in_out(clampf((t - 1.6) / 2.6, 0.0, 1.0))
	var zoom := exp(lerpf(0.0, log(60.0), zk))
	var focus := center.lerp(me, Ink.ease_in_out(clampf((t - 1.4) / 1.6, 0.0, 1.0)))
	var xf := Transform2D(0.0, Vector2(zoom, zoom), 0.0, vp * 0.5 - focus * zoom)
	draw_set_transform_matrix(xf)
	var a := fade
	var draw_k := clampf(t / 1.3, 0.0, 1.0)   # 主环“画”出来的进度
	var lw := 1.0 / zoom
	# 地形：河流、道路、城镇色块
	var river := PackedVector2Array()
	for i in 40:
		var x := -200.0 + i * 60.0
		river.append(Vector2(x, center.y + 330 + sin(i * 0.5) * 40))
	draw_polyline(river, Color(blue, 0.35 * a), 8.0 * maxf(lw, 0.2), true)
	for i in 14:
		var p := center + Vector2(cos(i * 2.3) * (R + 120 + (i % 3) * 60), sin(i * 1.7) * (R * 0.7 + 60))
		draw_rect(Rect2(p, Vector2(28 + (i % 4) * 10, 18 + (i % 3) * 8)), Color(ink, 0.12 * a))
	draw_line(center + Vector2(-900, -260), center + Vector2(900, 120), Color(ink, 0.18 * a), 3.0 * maxf(lw, 0.3))
	# 主环（逐步画出）
	var n := int(240 * draw_k)
	if n > 1:
		var pts := PackedVector2Array()
		for i in n + 1:
			pts.append(center + Vector2.from_angle(-PI * 0.5 + TAU * i / 240.0) * R)
		draw_polyline(pts, Color(blue, a), maxf(5.0 * lw * zoom * 0.2, 4.0 * lw), true)
		draw_polyline(pts, Color(ink, a), 1.2 * lw, true)
	var bk := clampf((zoom - 6.0) / 10.0, 0.0, 1.0)
	# 八个实验站（推近后淡出，让位给建筑平面）
	for i in 8:
		var p := center + Vector2.from_angle(-PI * 0.5 + TAU * i / 8.0) * R
		var s := 9.0
		var sa := a * (1.0 - bk)
		draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2), Color(red if i == 6 else paper, sa))
		draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2), Color(ink, sa), false, 1.4 * lw)
		if zoom < 4.0:
			Ink.text(self, "EXP-%d" % (i + 1), p + Vector2.from_angle(-PI * 0.5 + TAU * i / 8.0) * 26 + Vector2(-20, 6), 15, Color(ink, a * clampf(4.0 - zoom, 0, 1)), Pal.mono)
	draw_set_transform(Vector2.ZERO)
	# 第七实验站的建筑平面 + 剖切线 A-A（屏幕空间绘制，线宽清晰）
	if bk > 0.0:
		var half := Vector2(3.5, 2.1)
		var p0: Vector2 = xf * (me - half)
		var p1: Vector2 = xf * (me + half)
		var br := Rect2(p0, p1 - p0)
		draw_rect(br, Color(paper, a * bk))
		draw_rect(br, Color(ink, a * bk), false, 3.0)
		draw_rect(br.grow(-14), Color(ink, 0.35 * a * bk), false, 1.4)
		for i in 6:
			var x := br.position.x + br.size.x * (i + 1) / 7.0
			draw_line(Vector2(x, br.position.y + 14), Vector2(x, br.end.y - 14), Color(ink, 0.18 * a * bk), 1.0)
		Ink.text(self, "第七实验站 EXP-7", br.position + Vector2(18, 40), 22, Color(ink, a * bk), Pal.bold)
		var ck := clampf((t - 4.2) / 0.6, 0.0, 1.0)
		if ck > 0.0:
			var y := br.get_center().y
			var x0 := br.position.x - 60.0
			var x1 := lerpf(x0, br.end.x + 60.0, ck)
			_dash(Vector2(x0, y), Vector2(x1, y), Color(red, a))
			Ink.text(self, "A", Vector2(x0 - 10, y - 14), 30, Color(red, a), Pal.bold)
			if ck >= 1.0:
				Ink.text(self, "A", Vector2(x1 - 10, y - 14), 30, Color(red, a), Pal.bold)
				Ink.text(self, "剖面 A-A", Vector2(br.get_center().x, y + 52), 28, Color(red, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 标题与图签（屏幕空间）
	var ta := a * clampf(t / 0.5, 0.0, 1.0)
	_titleblock(vp, ta, zoom)

func _titleblock(vp: Vector2, a: float, zoom: float) -> void:
	var ink := Color("#2b2a28")
	var red := Color("#c2412d")
	var r := Rect2(vp.x - 470, vp.y - 160, 430, 120)
	draw_rect(r, Color(Color("#f7f2e6"), a))
	draw_rect(r, Color(ink, a), false, 2.0)
	draw_line(Vector2(r.position.x, r.position.y + 44), Vector2(r.end.x, r.position.y + 44), Color(ink, a), 1.0)
	draw_line(Vector2(r.position.x + 250, r.position.y + 44), Vector2(r.position.x + 250, r.end.y), Color(ink, a), 1.0)
	var title := "园区总平面图" if zoom < 20.0 else "第七实验站 · 剖面 A-A"
	Ink.text(self, title, r.position + Vector2(16, 31), 22, Color(ink, a), Pal.bold)
	Ink.text(self, "主环周长 26.7 km", r.position + Vector2(16, 74), 16, Color(ink, a))
	Ink.text(self, "实验站 8 座", r.position + Vector2(16, 100), 16, Color(ink, a))
	Ink.text(self, "比例", r.position + Vector2(266, 74), 14, Color(ink, a * 0.7))
	Ink.text(self, "1 : %s" % _scale_text(zoom), r.position + Vector2(266, 100), 16, Color(ink, a), Pal.mono)
	Ink.text(self, "BEAMLINE  束流", Vector2(60, 90), 44, Color(ink, a), Pal.bold)
	Ink.text(self, "加速器只有这么一角归你管。", Vector2(64, 132), 22, Color(red, a), Pal.hand)
	if t > 0.6:
		Ink.text(self, "任意键跳过", Vector2(64, vp.y - 50), 15, Color(ink, a * 0.5))

func _scale_text(zoom: float) -> String:
	var s := int(50000.0 / zoom)
	if s >= 1000:
		return "%d %03d" % [s / 1000, s % 1000]
	return str(maxi(s, 1))

func _dash(a: Vector2, b: Vector2, col: Color) -> void:
	var L := a.distance_to(b)
	var d := 0.0
	var k := 0
	while d < L:
		var seg := 26.0 if k % 2 == 0 else 8.0
		if k % 4 == 2:
			seg = 4.0
		if k % 2 == 0:
			draw_line(a.lerp(b, d / L), a.lerp(b, minf(d + seg, L) / L), col, 3.0)
		d += seg
		k += 1
