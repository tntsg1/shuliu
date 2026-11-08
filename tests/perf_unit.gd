extends SceneTree
## 单价测量：每种画法画 N 次，看 _draw 耗时
class P extends Node2D:
	var mode := 0
	var n := 300
	var tt := 0.0
	var fr := 0
	var fnt := SystemFont.new()
	func _process(_d): queue_redraw()
	func _draw():
		var a := Time.get_ticks_usec()
		for i in n:
			match mode:
				0: draw_string(fnt, Vector2(10, 20 + i % 40 * 20), "累计 %d / 580" % (i + fr), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.BLACK)
				1: draw_string(fnt, Vector2(10, 20 + i % 40 * 20), "累计固定文字 580", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.BLACK)
				2: draw_polyline(Ink.wobble(Ink.rect_pts(Rect2(10 + i, 10, 120, 40)), i), Color.BLACK, 1.6, true)
				3: draw_polyline(Ink.rect_pts(Rect2(10 + i, 10, 120, 40)), Color.BLACK, 1.6, true)
				4: draw_rect(Rect2(10 + i, 10, 120, 40), Color.BLACK)
				5: draw_circle(Vector2(10 + i, 10), 6.0, Color.BLACK)
				6: draw_arc(Vector2(10 + i, 10), 30.0, 0, TAU, 48, Color.BLACK, 2.0, true)
				7: Color("#f7f2e6")
				8: fnt.get_string_size("累计 %d / 580" % (i + fr), HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
		tt += (Time.get_ticks_usec() - a) / 1000.0
		fr += 1

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var p := P.new()
	root.add_child(p)
	_go(p)

func _go(p) -> void:
	var names := ["字(数字每帧变)", "字(固定)", "抖动描边", "直描边(抗锯齿)", "矩形", "圆", "抗锯齿圆弧", "Pal.c 查色", "量字宽"]
	for m in names.size():
		p.mode = m; p.tt = 0.0
		for i in 5: await process_frame
		p.tt = 0.0
		for i in 60: await process_frame
		print("%-16s 每次 %.4f ms" % [names[m], p.tt / 60.0 / p.n])
	quit(0)
