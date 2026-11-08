extends Node2D
## 胶囊舱外框：玻璃双线、端盖、螺栓、磁体灯、支架、标签

var chamber: Node2D

func _stadium(h: Vector2, n := 64) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var r := h.y
	var cx := h.x - r
	for i in n + 1:
		var a := -PI / 2 + PI * i / n
		pts.append(Vector2(cx, 0) + Vector2.from_angle(a) * r)
	for i in n + 1:
		var a := PI / 2 + PI * i / n
		pts.append(Vector2(-cx, 0) + Vector2.from_angle(a) * r)
	pts.append(pts[0])
	return pts

var _stand: Baked      # 支架
var _glass: Baked      # 玻璃环 + 螺栓（跟着舱体微震移动，不重画）
var _boxes: Baked      # 灯座 + 标签

func _ready() -> void:
	_stand = Baked.make(self, _paint_stand, true)
	_glass = Baked.make(self, _paint_glass, true)
	_boxes = Baked.make(self, _paint_boxes, true)

func _lamp_x(i: int) -> float:
	var h := Geo.CH_SIZE * 0.5
	return -h.x + h.y * 0.9 + i * (Geo.CH_SIZE.x - h.y * 1.8) / 5.0

func _paint_stand(ci: CanvasItem) -> void:
	var h := Geo.CH_SIZE * 0.5
	var el := Pal.equip_line()
	for sx in [-120.0, 100.0]:
		Ink.box(ci, Rect2(sx, h.y, 22, Geo.FLOOR - Geo.BEAMY - h.y), Pal.c("equip_dark"), el, 1.6, int(sx))
		Ink.box(ci, Rect2(sx - 16, Geo.FLOOR - Geo.BEAMY - 8, 54, 8), Pal.c("equip_dark"), el, 1.2, int(sx) + 7)
		ci.draw_line(Vector2(sx + 2, h.y + 20), Vector2(sx + 20, h.y + 60), Color(el, 0.4), 1.0)

func _paint_glass(ci: CanvasItem) -> void:
	var h := Geo.CH_SIZE * 0.5
	var el := Pal.equip_line()
	Ink.pl(ci, _stadium(h + Vector2(7, 7)), Pal.c("equip"), 10.0)
	Ink.pl(ci, _stadium(h + Vector2(12, 12)), el, 1.8)
	Ink.pl(ci, _stadium(h + Vector2(2, 2)), el, 1.8)
	Ink.pl(ci, _stadium(h - Vector2(5, 5)), Color(el, 0.25), 1.0)
	var ring := _stadium(h + Vector2(7, 7), 18)
	for i in range(0, ring.size() - 1, 2):
		Ink.rivet(ci, ring[i], 2.2)

func _paint_boxes(ci: CanvasItem) -> void:
	var h := Geo.CH_SIZE * 0.5
	var el := Pal.equip_line()
	for i in 6:
		for y in [-h.y - 32.0, h.y + 12.0]:
			Ink.box(ci, Rect2(_lamp_x(i) - 11, y, 22, 20), Pal.c("equip_dark"), el, 1.2, i * 7 + int(y))
	Ink.sticker(ci, "OBS-01 观测舱", Vector2(-h.x + 70, -h.y - 48), -0.02, 11)

func _draw() -> void:
	var h := Geo.CH_SIZE * 0.5
	var el := Pal.equip_line()
	_glass.position = chamber.beam_rect.position + Geo.CH_SIZE * 0.5
	# 磁体灯（上下各 6 个）
	var lock_on: bool = chamber.lockf > 0.5
	for i in 6:
		var x := -h.x + h.y * 0.9 + i * (Geo.CH_SIZE.x - h.y * 1.8) / 5.0
		var on: bool = i < chamber.lit
		var col := Pal.c("equip")
		if on:
			col = Pal.c("lock") if lock_on else Pal.ramp(float(i) / 5.0 * chamber.value + 0.1)
			if chamber.danger > 0.75 and int(chamber.flick * 9.0 + i) % 5 == 0:
				col = Pal.c("red")
		for y in [-h.y - 32.0, h.y + 12.0]:
			draw_rect(Rect2(x - 7, y + 4, 14, 12), col)
			if on:
				draw_rect(Rect2(x - 5, y + 5, 4, 3), Color(1, 1, 1, 0.45))
	# 冲击波：从舱心扩散的墨线环
	for w in chamber.waves:
		var k: float = w.t / 0.55
		var e := Ink.ease_out_cubic(k)
		var rx := lerpf(h.x * 0.3, h.x * 1.35, e)
		var ry := lerpf(h.y * 0.3, h.y * 1.35, e)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			pts.append(Vector2(cos(a) * rx, sin(a) * ry))
		Ink.pl(self, pts, Color(w.col, 1.0 - k), w.w * (1.0 - k) + 0.6)
	# 飞溅墨线
	for s in chamber.sparks:
		var a: float = clampf(s.life / 0.3, 0.0, 1.0)
		draw_line(s.p, s.p - s.v * 0.035, Color(s.col, a), 2.2, true)
	# 对撞：两团束流从舱两端相向冲向核心
	if chamber.collide >= 0.0:
		var e: float = pow(clampf(chamber.collide, 0.0, 1.0), 2.2)
		var bc := Pal.ramp(chamber.value)
		for sgn in [-1.0, 1.0]:
			var x: float = sgn * h.x * 0.92 * (1.0 - e)
			for i in 10:
				var tx: float = x + sgn * i * 9.0 * (0.4 + e)
				Ink.disc(self, Vector2(tx, 0), (9.0 - i * 0.7) * (0.8 + e * 0.4), Color(bc, 0.85 - i * 0.08))
			Ink.disc(self, Vector2(x, 0), 10.0 + e * 4.0, bc)
			draw_arc(Vector2(x, 0), 10.0 + e * 4.0, 0, TAU, 24, el, 2.0, true)
	# 丢失：玻璃裂纹
	if chamber.cracks > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for b in 7:
			var p0 := Vector2(rng.randf_range(-h.x * 0.6, h.x * 0.6), rng.randf_range(-h.y * 0.5, h.y * 0.5))
			var pts := PackedVector2Array([p0])
			var ang := rng.randf() * TAU
			var steps := int(8 * chamber.cracks)
			for i in steps:
				ang += rng.randf_range(-0.7, 0.7)
				pts.append(pts[-1] + Vector2.from_angle(ang) * rng.randf_range(14, 34))
			if pts.size() > 1:
				Ink.pl(self, pts, Color(el, 0.85), 1.6)
				Ink.pl(self, pts, Color(1, 1, 1, 0.5), 0.6)

