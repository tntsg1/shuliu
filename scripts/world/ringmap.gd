extends Node2D
## 墙上的主环平面图海报：26.7 km 大环 + 八个实验站 + “你在这里”；束流在环上跑，每次加速绕一圈

const RECT := Rect2(626, 566, 196, 168)   # M5a 右移，给货梯让位
var main: Node
var ang := -PI * 0.5
var lap_t := 0.0
var t := 0.0
var trail: Array = []

func lap() -> void:
	lap_t = 1.0

func _process(dt: float) -> void:
	t += dt
	var running: bool = main != null and main.has_beam()
	var spd := 0.35 if running else 0.0
	if lap_t > 0.0:
		var k := minf(dt * 3.6, lap_t)
		ang += TAU * k
		lap_t -= k
	ang += spd * dt
	trail.push_front(ang)
	if trail.size() > 14:
		trail.pop_back()
	queue_redraw()

func _paint_map(ci: CanvasItem) -> void:
	var r := RECT
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	# 纸 + 胶带
	ci.draw_set_transform(r.get_center(), -0.015)
	var o := -r.size * 0.5
	ci.draw_rect(Rect2(o + Vector2(4, 5), r.size), Color(0, 0, 0, 0.12))
	ci.draw_rect(Rect2(o, r.size), Pal.c("paper"))
	Ink.frame(ci, Rect2(o, r.size), Color(el, 0.6), 1.2)
	ci.draw_rect(Rect2(o + Vector2(-8, -6), Vector2(36, 14)), Color(Pal.c("gold"), 0.45))
	ci.draw_rect(Rect2(o + Vector2(r.size.x - 28, -6), Vector2(36, 14)), Color(Pal.c("gold"), 0.45))
	Ink.text(ci, "主环总平面图", o + Vector2(10, 20), 13, ink, Pal.bold)
	Ink.text(ci, "1 : 50 000", o + Vector2(r.size.x - 10, 20), 10, Pal.c("text2"), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
	var c := Vector2(0, 14)
	var R := 56.0
	# 等高线 / 道路 / 城镇（示意）
	for i in 3:
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * k / 32.0
			pts.append(c + Vector2(cos(a) * (R + 14 + i * 9) * (1.0 + 0.08 * sin(a * 3 + i)), sin(a) * (R + 10 + i * 8)))
		Ink.pl(ci, pts, Color(Pal.c("green"), 0.25), 1.0)
	ci.draw_line(o + Vector2(0, r.size.y - 30), o + Vector2(r.size.x, r.size.y - 52), Color(ink, 0.3), 2.0)
	for k in 5:
		ci.draw_rect(Rect2(o + Vector2(14 + k * 9, r.size.y - 24 - (k % 2) * 6), Vector2(6, 6)), Color(ink, 0.3))
	# 主环
	ci.draw_arc(c, R, 0, TAU, 72, Pal.c("blue"), 3.0, true)
	ci.draw_arc(c, R, 0, TAU, 72, el, 0.8, true)
	# 实验站
	for i in 8:
		var a := -PI * 0.5 + TAU * i / 8.0
		var p := c + Vector2.from_angle(a) * R
		var me := i == 6
		ci.draw_rect(Rect2(p - Vector2(3.5, 3.5), Vector2(7, 7)), Pal.c("red") if me else Pal.c("paper"))
		Ink.frame(ci, Rect2(p - Vector2(3.5, 3.5), Vector2(7, 7)), el, 1.0)
		if not me:
			Ink.text(ci, str(i + 1), p + Vector2.from_angle(a) * 11 + Vector2(-3, 4), 9, Pal.c("text2"), Pal.mono)
	# 你在这里
	var me_p := c + Vector2.from_angle(-PI * 0.5 + TAU * 6 / 8.0) * R
	ci.draw_line(me_p, me_p + Vector2(-22, -26), Pal.c("red"), 1.2, true)
	Ink.text(ci, "你在这里", me_p + Vector2(-38, -30), 11, Pal.c("red"), Pal.hand)
	ci.draw_set_transform(Vector2.ZERO)

var _map: Baked

func _ready() -> void:
	_map = Baked.make(self, _paint_map, true)

func _draw() -> void:
	var r := RECT
	draw_set_transform(r.get_center(), -0.015)
	var c := Vector2(0, 14)
	var R := 56.0
	# 束流光点 + 拖尾
	for i in trail.size():
		var p: Vector2 = c + Vector2.from_angle(trail[i]) * R
		Ink.disc(self, p, 3.2 * (1.0 - i / 15.0), Color(Pal.c("lock") if main and main.run and main.run.beam and main.run.beam.locked() else Pal.c("orange"), 1.0 - i / 14.0))
	Ink.text(self, "周长 26.7 km", c + Vector2(0, 5), 11, Pal.c("text2"), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
