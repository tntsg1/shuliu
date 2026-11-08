extends Node2D
## 引出：束流从舱中拉直，沿管道射向探测器（墨线 + 色块，无辉光）

var t := -1.0
var dur := 0.55
var col := Color.WHITE
signal arrived

func fire(c: Color) -> void:
	col = c
	t = 0.0

func _process(dt: float) -> void:
	if t < 0.0:
		return
	t += dt
	queue_redraw()
	if t >= dur and t - dt < dur:
		arrived.emit()
	if t > dur + 0.35:
		t = -1.0
		queue_redraw()

func _draw() -> void:
	if t < 0.0:
		return
	var x0 := Geo.CHAMBER.x
	var x1 := Geo.DETECTOR_X + 10.0
	var k := Ink.ease_in_out(t / dur)
	var head := lerpf(x0, x1, k)
	var tail := lerpf(x0, x1, maxf(0.0, (t - 0.18) / dur))
	if t > dur:
		tail = lerpf(tail, x1, (t - dur) / 0.35)
	var y := Geo.BEAMY
	var ink := Pal.c("ink") if not Pal.dark else Pal.c("paper")
	draw_rect(Rect2(tail, y - 4, head - tail, 8), col)
	draw_line(Vector2(tail, y - 4), Vector2(head, y - 4), ink, 1.2)
	draw_line(Vector2(tail, y + 4), Vector2(head, y + 4), ink, 1.2)
	# 速度线
	for i in 5:
		var xx := head - 30.0 - i * 26.0
		if xx > tail:
			draw_line(Vector2(xx, y - 10 - i % 2 * 4), Vector2(xx - 16, y - 10 - i % 2 * 4), Color(ink, 0.6), 1.0)
			draw_line(Vector2(xx - 8, y + 10 + i % 2 * 4), Vector2(xx - 24, y + 10 + i % 2 * 4), Color(ink, 0.6), 1.0)
	Ink.disc(self, Vector2(head, y), 7.0, col)
	draw_arc(Vector2(head, y), 7.0, 0, TAU, 20, ink, 1.4, true)
