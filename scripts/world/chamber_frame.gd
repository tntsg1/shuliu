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

func _draw() -> void:
	var h := Geo.CH_SIZE * 0.5
	var el := Pal.equip_line()
	var off: Vector2 = chamber.beam_rect.position + Geo.CH_SIZE * 0.5
	# 支架
	for sx in [-120.0, 100.0]:
		Ink.box(self, Rect2(sx, h.y, 22, Geo.FLOOR - Geo.BEAMY - h.y), Pal.c("equip_dark"), el, 1.6, int(sx))
		Ink.box(self, Rect2(sx - 16, Geo.FLOOR - Geo.BEAMY - 8, 54, 8), Pal.c("equip_dark"), el, 1.2, int(sx) + 7)
		draw_line(Vector2(sx + 2, h.y + 20), Vector2(sx + 20, h.y + 60), Color(el, 0.4), 1.0)
	# 玻璃：外圈金属环 + 内细线 + 反光
	draw_set_transform(off)
	draw_polyline(_stadium(h + Vector2(7, 7)), Pal.c("equip"), 10.0, true)
	draw_polyline(_stadium(h + Vector2(12, 12)), el, 1.8, true)
	draw_polyline(_stadium(h + Vector2(2, 2)), el, 1.8, true)
	draw_polyline(_stadium(h - Vector2(5, 5)), Color(el, 0.25), 1.0, true)
	# 螺栓
	var ring := _stadium(h + Vector2(7, 7), 18)
	for i in range(0, ring.size() - 1, 2):
		Ink.rivet(self, ring[i], 2.2)
	draw_set_transform(Vector2.ZERO)
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
			Ink.box(self, Rect2(x - 11, y, 22, 20), Pal.c("equip_dark"), el, 1.2, i * 7 + int(y))
			draw_rect(Rect2(x - 7, y + 4, 14, 12), col)
			if on:
				draw_rect(Rect2(x - 5, y + 5, 4, 3), Color(1, 1, 1, 0.45))
	Ink.sticker(self, "OBS-01 观测舱", Vector2(-h.x + 70, -h.y - 48), -0.02, 11)
