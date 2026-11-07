extends Node2D
## 控制台桌（世界里，舱前）：小屏、指示灯随状态变化

var main: Node
var blink := 0.0

func _process(dt: float) -> void:
	blink += dt
	queue_redraw()

func _draw() -> void:
	var x := Geo.CONSOLE_X
	var y := Geo.FLOOR
	var el := Pal.equip_line()
	var top := PackedVector2Array([Vector2(x, y), Vector2(x, y - 92), Vector2(x + 150, y - 112), Vector2(x + 150, y)])
	Ink.poly(self, top, Pal.c("equip"), el, 1.8, 401)
	draw_line(Vector2(x, y - 92), Vector2(x + 150, y - 112), el, 3.0, true)
	draw_rect(Rect2(x + 8, y - 70, 134, 3), Color(el, 0.3))
	for i in 3:
		Ink.box(self, Rect2(x + 14 + i * 40, y - 52, 30, 44), Pal.c("equip_dark"), el, 1.0, 402 + i)
		draw_rect(Rect2(x + 26 + i * 40, y - 32, 6, 2), el)
	# 指示灯
	var cols := [Pal.c("red"), Pal.c("gold"), Pal.c("ramp2")]
	for i in 3:
		var on := true
		if i == 0:
			on = main != null and main.danger_high() and int(blink * 6.0) % 2 == 0
		if i == 1:
			on = main != null and main.has_beam()
		var lp := Vector2(x + 20 + i * 18, y - 84 - i * 2.4)
		draw_circle(lp, 5.0, cols[i] if on else Pal.c("equip_dark"))
		draw_arc(lp, 5.0, 0, TAU, 16, el, 1.0, true)
	# 斜面小屏
	draw_set_transform(Vector2(x + 96, y - 138), -0.13)
	var bg := Pal.c("screen") if Pal.dark else Pal.c("paper")
	draw_rect(Rect2(-46, -30, 92, 58), Pal.c("equip"))
	draw_rect(Rect2(-40, -25, 80, 48), bg)
	draw_rect(Rect2(-46, -30, 92, 58), el, false, 1.6)
	var ink := Pal.c("paper") if Pal.dark else Pal.c("ink")
	var lines := [Pal.c("ramp2"), Pal.c("ramp3"), Pal.c("gold"), Pal.c("ramp1"), Pal.c("red")]
	for i in 5:
		var w := 14.0 + fmod(float(i * 37) + blink * (8.0 if main and main.has_beam() else 0.0), 50.0)
		draw_rect(Rect2(-34, -19 + i * 8, w, 3), lines[i])
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(x + 90, y - 110), Vector2(x + 96, y - 118), el, 4.0)
