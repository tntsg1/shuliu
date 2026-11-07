extends Node2D
## 世界内交互提示（挂在物体上方的小纸签）

var text := ""
var key := ""
var at := Vector2.ZERO
var v := 0.0
var _vv := 0.0
var target := 0.0

func show_at(p: Vector2, k: String, s: String) -> void:
	at = p
	key = k
	text = s
	target = 1.0

func hide_now() -> void:
	target = 0.0

func _process(dt: float) -> void:
	var r := Ink.spring(v, _vv, target, 14.0, dt); v = r[0]; _vv = r[1]
	queue_redraw()

func _draw() -> void:
	if v < 0.01 or text == "":
		return
	var a := clampf(v, 0.0, 1.0)
	var fnt: Font = Pal.font
	var tw := fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var kw := maxf(28.0, fnt.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 14)
	var w := tw + kw + 26
	var p := at + Vector2(-w * 0.5, -8.0 * (1.0 - v))
	draw_set_transform(p + Vector2(w * 0.5, 18), 0.0, Vector2(lerpf(0.85, 1.0, a), lerpf(0.85, 1.0, a)))
	var o := Vector2(-w * 0.5, -18)
	var el := Pal.equip_line()
	draw_rect(Rect2(o + Vector2(3, 4), Vector2(w, 36)), Color(0, 0, 0, 0.12 * a))
	draw_rect(Rect2(o, Vector2(w, 36)), Color(Pal.c("paper"), a))
	draw_rect(Rect2(o, Vector2(w, 36)), Color(el, a), false, 1.4)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 18), Vector2(7, 18), Vector2(0, 27)]), Color(Pal.c("paper"), a))
	draw_polyline(PackedVector2Array([Vector2(-7, 18), Vector2(0, 27), Vector2(7, 18)]), Color(el, a), 1.4, true)
	draw_rect(Rect2(o + Vector2(8, 7), Vector2(kw, 22)), Color(Pal.c("gold"), a))
	draw_rect(Rect2(o + Vector2(8, 7), Vector2(kw, 22)), Color(el, a), false, 1.2)
	Ink.text(self, key, o + Vector2(8 + kw * 0.5, 23), 13, Color(el, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, text, o + Vector2(kw + 18, 24), 16, Color(Pal.c("text"), a))
	draw_set_transform(Vector2.ZERO)
