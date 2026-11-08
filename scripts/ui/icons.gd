class_name Icons
## 物品图标：在 64×64 的坐标系里程序化绘制（墨线 + 平涂），商店卡片与护身符架共用

static func draw(ci: CanvasItem, id: String, c: Vector2, size: float, rot := 0.0) -> void:
	var s := size / 64.0
	ci.draw_set_transform(c, rot, Vector2(s, s))
	var ink := Color("#2b2a28")
	var paper := Color("#f7f2e6")
	match id:
		"magnet_sc":
			_poly(ci, [Vector2(-22, -22), Vector2(22, -22), Vector2(22, -8), Vector2(-8, -8), Vector2(-8, 8), Vector2(22, 8), Vector2(22, 22), Vector2(-22, 22)], Pal.c("dip_b"), ink)
			for y in [-18, -13, 13, 18]:
				ci.draw_line(Vector2(-18, y), Vector2(18, y), Pal.c("dip_a"), 2.0)
			ci.draw_circle(Vector2(8, 0), 3.0, Pal.c("ramp2"))
		"quad_array":
			for i in 4:
				var a := PI / 4 + i * PI / 2
				ci.draw_set_transform(c + Vector2.from_angle(a) * 14 * s, rot + a, Vector2(s, s))
				_poly(ci, [Vector2(-6, -9), Vector2(10, -6), Vector2(10, 6), Vector2(-6, 9)], Pal.c("quad_a"), ink)
			ci.draw_set_transform(c, rot, Vector2(s, s))
			ci.draw_circle(Vector2.ZERO, 4.0, Pal.c("ramp2"))
			ci.draw_arc(Vector2.ZERO, 4.0, 0, TAU, 16, ink, 1.5, true)
		"injector_hi":
			_box(ci, Rect2(-24, -18, 40, 36), Pal.c("equip"), ink)
			for i in 4:
				ci.draw_rect(Rect2(-20 + i * 9, -13, 6, 26), Pal.ramp(i / 3.0))
			_poly(ci, [Vector2(18, -8), Vector2(28, 0), Vector2(18, 8)], Pal.c("red"), ink)
		"collimator":
			ci.draw_line(Vector2(-28, 0), Vector2(28, 0), Pal.c("ramp2"), 3.0)
			_box(ci, Rect2(-10, -26, 20, 22), Color("#9aa0a6"), ink)
			_box(ci, Rect2(-10, 4, 20, 22), Color("#9aa0a6"), ink)
			ci.draw_line(Vector2(-10, -4), Vector2(10, -4), ink, 2.0)
		"rf_backup":
			for i in 4:
				ci.draw_circle(Vector2(-18 + i * 12, 0), 9.0, Pal.c("gold"))
				ci.draw_arc(Vector2(-18 + i * 12, 0), 9.0, 0, TAU, 20, ink, 1.6, true)
			ci.draw_line(Vector2(-28, 0), Vector2(28, 0), ink, 1.5)
			_box(ci, Rect2(-6, -24, 12, 8), Pal.c("equip"), ink)
		"diagnostic":
			_box(ci, Rect2(-26, -20, 52, 36), Pal.c("screen"), ink)
			var pts := PackedVector2Array()
			for i in 21:
				pts.append(Vector2(-22 + i * 2.2, sin(i * 0.9) * 8.0 * (1.0 - absf(i - 10) / 12.0)))
			ci.draw_polyline(pts, Pal.c("ramp3"), 2.0, true)
			_box(ci, Rect2(-8, 16, 16, 8), Pal.c("equip"), ink)
		"dean_paper":
			_poly(ci, [Vector2(-18, -26), Vector2(14, -26), Vector2(22, -18), Vector2(22, 26), Vector2(-18, 26)], Color("#ead9a8"), ink)
			for i in 6:
				ci.draw_line(Vector2(-12, -14 + i * 7), Vector2(14 - (i % 3) * 6, -14 + i * 7), Color(ink, 0.5), 1.4)
			ci.draw_polyline(PackedVector2Array([Vector2(4, 16), Vector2(9, 21), Vector2(20, 8)]), Pal.c("red"), 2.6, true)
		"eraser":
			ci.draw_set_transform(c, rot - 0.35, Vector2(s, s))
			_box(ci, Rect2(-24, -11, 48, 22), paper, ink)
			_box(ci, Rect2(-6, -12, 30, 24), Pal.c("blue"), ink)
			ci.draw_rect(Rect2(-24, -11, 8, 22), Color("#d8cfc0"))
		"coin":
			ci.draw_circle(Vector2.ZERO, 22.0, Pal.c("gold"))
			ci.draw_arc(Vector2.ZERO, 22.0, 0, TAU, 40, ink, 2.0, true)
			ci.draw_arc(Vector2.ZERO, 16.0, 0, TAU, 40, Color(ink, 0.6), 1.2, true)
			_star(ci, Vector2.ZERO, 8.0, ink)
		"badge":
			_box(ci, Rect2(-18, -20, 36, 44), paper, ink)
			_box(ci, Rect2(-12, -12, 14, 16), Pal.c("ramp1"), ink)
			ci.draw_line(Vector2(5, -8), Vector2(13, -8), ink, 1.6)
			ci.draw_line(Vector2(5, -2), Vector2(13, -2), ink, 1.6)
			ci.draw_rect(Rect2(-18, 12, 36, 6), Pal.c("red"))
			_box(ci, Rect2(-6, -28, 12, 8), Color("#9aa0a6"), ink)
		"note100":
			ci.draw_set_transform(c, rot + 0.08, Vector2(s, s))
			_box(ci, Rect2(-22, -22, 44, 44), Color("#f2d65a"), ink)
			ci.draw_rect(Rect2(-22, -22, 44, 8), Color("#e4c446"))
			Ink.text(ci, "100%", Vector2(0, 8), 15, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"wrong_answer":
			_box(ci, Rect2(-20, -24, 40, 48), paper, ink)
			for i in 4:
				ci.draw_line(Vector2(-14, -14 + i * 8), Vector2(10, -14 + i * 8), Color(ink, 0.45), 1.3)
			ci.draw_line(Vector2(-6, 6), Vector2(14, 22), Pal.c("red"), 3.0)
			ci.draw_line(Vector2(14, 6), Vector2(-6, 22), Pal.c("red"), 3.0)
		"koi":
			_box(ci, Rect2(-24, -18, 48, 36), paper, ink)
			_box(ci, Rect2(-19, -13, 38, 26), Color("#cfe6ea"), Color(ink, 0.5))
			_poly(ci, [Vector2(-16, 0), Vector2(-4, -8), Vector2(6, -6), Vector2(6, 6), Vector2(-4, 8)], Pal.c("orange"), ink)
			ci.draw_line(Vector2(6, -10), Vector2(6, 10), Color(ink, 0.7), 1.0)
			ci.draw_circle(Vector2(-10, -1), 1.6, ink)
		"ultimatum":
			_box(ci, Rect2(-26, -16, 52, 34), paper, ink)
			ci.draw_polyline(PackedVector2Array([Vector2(-26, -16), Vector2(0, 4), Vector2(26, -16)]), ink, 1.6, true)
			ci.draw_circle(Vector2(0, 6), 8.0, Pal.c("red"))
			Ink.text(ci, "!", Vector2(0, 11), 14, paper, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"lucky_cat":
			ci.draw_circle(Vector2(0, 10), 16.0, paper)
			ci.draw_arc(Vector2(0, 10), 16.0, 0, TAU, 32, ink, 1.8, true)
			ci.draw_circle(Vector2(0, -10), 13.0, paper)
			ci.draw_arc(Vector2(0, -10), 13.0, 0, TAU, 32, ink, 1.8, true)
			_poly(ci, [Vector2(-12, -16), Vector2(-9, -28), Vector2(-3, -21)], paper, ink)
			_poly(ci, [Vector2(12, -16), Vector2(9, -28), Vector2(3, -21)], paper, ink)
			ci.draw_line(Vector2(-6, -11), Vector2(-3, -11), ink, 1.6)
			ci.draw_line(Vector2(3, -11), Vector2(6, -11), ink, 1.6)
			ci.draw_rect(Rect2(-10, -1, 20, 4), Pal.c("red"))
			ci.draw_circle(Vector2(0, 3), 3.0, Pal.c("gold"))
			_box(ci, Rect2(12, -24, 8, 16), paper, ink)
		"rejected":
			for i in 3:
				_box(ci, Rect2(-20 + i * 3, -24 + i * 3, 38, 46), paper, ink)
			ci.draw_set_transform(c, rot - 0.3, Vector2(s, s))
			ci.draw_rect(Rect2(-20, 0, 40, 14), Color(Pal.c("red"), 0.2))
			ci.draw_rect(Rect2(-20, 0, 40, 14), Pal.c("red"), false, 2.0)
			Ink.text(ci, "REJECT", Vector2(0, 11), 9, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"dean_pen":
			ci.draw_set_transform(c, rot - 0.7, Vector2(s, s))
			_box(ci, Rect2(-26, -5, 40, 10), Color("#1d1f26"), ink)
			ci.draw_rect(Rect2(-6, -5, 4, 10), Pal.c("gold"))
			_poly(ci, [Vector2(14, -5), Vector2(28, 0), Vector2(14, 5)], Pal.c("gold"), ink)
		"chair":
			_box(ci, Rect2(-14, -26, 28, 26), Pal.c("blue"), ink)
			_box(ci, Rect2(-18, 0, 36, 7), Pal.c("blue"), ink)
			ci.draw_line(Vector2(0, 7), Vector2(0, 20), ink, 3.0)
			ci.draw_line(Vector2(-14, 24), Vector2(14, 24), ink, 3.0)
			for x in [-14, 0, 14]:
				ci.draw_circle(Vector2(x, 26), 2.6, ink)
		"budget":
			_box(ci, Rect2(-26, -16, 52, 34), Color("#d9c49a"), ink)
			ci.draw_polyline(PackedVector2Array([Vector2(-26, -16), Vector2(0, 2), Vector2(26, -16)]), ink, 1.4, true)
			Ink.text(ci, "$", Vector2(0, 15), 18, Pal.c("green"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"coffee":
			_poly(ci, [Vector2(-14, -14), Vector2(14, -14), Vector2(10, 24), Vector2(-10, 24)], paper, ink)
			_poly(ci, [Vector2(-13, -2), Vector2(13, -2), Vector2(11.6, 10), Vector2(-11.6, 10)], Color("#8a5a3a"), ink)
			_box(ci, Rect2(-16, -20, 32, 6), Color("#6a4a3a"), ink)
			for i in 3:
				var pts := PackedVector2Array()
				for k in 7:
					pts.append(Vector2(-8 + i * 8 + sin(k * 1.2) * 2.0, -24 - k * 2.4))
				ci.draw_polyline(pts, Color(ink, 0.35), 1.2, true)
		"fast_clock":
			ci.draw_circle(Vector2.ZERO, 22.0, paper)
			ci.draw_arc(Vector2.ZERO, 22.0, 0, TAU, 40, ink, 2.0, true)
			for i in 12:
				var a := TAU * i / 12.0
				ci.draw_line(Vector2.from_angle(a) * 18, Vector2.from_angle(a) * 21, ink, 1.4)
			ci.draw_line(Vector2.ZERO, Vector2.from_angle(-PI / 2 + 0.6) * 12, ink, 2.6)
			ci.draw_line(Vector2.ZERO, Vector2.from_angle(-PI / 2 + TAU * 5 / 60.0) * 18, Pal.c("red"), 1.8)
			Ink.text(ci, "+5", Vector2(14, 28), 12, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		# —— M3 第 1 批：纸张 ——
		"lost_data":
			# 一张软盘 + 红色问号
			_box(ci, Rect2(-22, -22, 44, 44), Color("#3a4a5c"), ink)
			_box(ci, Rect2(-12, -22, 24, 14), Color("#c9ccd0"), ink)
			ci.draw_rect(Rect2(4, -19, 5, 9), Color("#3a4a5c"))
			_box(ci, Rect2(-16, 2, 32, 18), paper, ink)
			Ink.text(ci, "?", Vector2(0, 18), 16, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"calib_log":
			# 发黄的记录卡 + 绿色对勾 + 旧日期
			ci.draw_set_transform(c, rot - 0.06, Vector2(s, s))
			_box(ci, Rect2(-22, -26, 44, 52), Color("#ead9a8"), ink)
			ci.draw_rect(Rect2(-22, -26, 44, 9), Color("#d8c48a"))
			for i in 3:
				ci.draw_line(Vector2(-16, -8 + i * 8), Vector2(16, -8 + i * 8), Color(ink, 0.4), 1.2)
			ci.draw_polyline(PackedVector2Array([Vector2(-10, 12), Vector2(-3, 19), Vector2(13, 3)]), Pal.c("green"), 3.0, true)
			Ink.text(ci, "1994", Vector2(10, -19), 8, Color(ink, 0.7), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
		"duty_roster":
			# 排班表：网格，周末两列全是红圈
			_box(ci, Rect2(-26, -22, 52, 44), paper, ink)
			ci.draw_rect(Rect2(-26, -22, 52, 8), Pal.c("blue"))
			for x in range(-26, 27, 8):
				ci.draw_line(Vector2(x, -14), Vector2(x, 22), Color(ink, 0.35), 1.0)
			for y in range(-14, 23, 9):
				ci.draw_line(Vector2(-26, y), Vector2(26, y), Color(ink, 0.35), 1.0)
			for y in [-10, -1, 8, 17]:
				ci.draw_arc(Vector2(14, y), 3.2, 0, TAU, 12, Pal.c("red"), 1.6, true)
				ci.draw_arc(Vector2(22, y), 3.2, 0, TAU, 12, Pal.c("red"), 1.6, true)
		"third_draft":
			# 三张叠稿，最上面写着 v3（下面隐约 v1）
			_box(ci, Rect2(-14, -26, 36, 46), paper, ink)
			_box(ci, Rect2(-18, -22, 36, 46), paper, ink)
			_box(ci, Rect2(-22, -18, 36, 46), paper, ink)
			for i in 3:
				ci.draw_line(Vector2(-16, -2 + i * 7), Vector2(8, -2 + i * 7), Color(ink, 0.45), 1.3)
			Ink.text(ci, "v3", Vector2(-4, -6), 13, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			ci.draw_line(Vector2(-18, 24), Vector2(10, 24), Pal.c("red"), 1.4)
		"reimburse":
			# 报销单 + 红色“退回”章
			_box(ci, Rect2(-20, -26, 40, 52), paper, ink)
			Ink.text(ci, "报销", Vector2(0, -12), 10, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			for i in 3:
				ci.draw_line(Vector2(-14, -4 + i * 7), Vector2(14, -4 + i * 7), Color(ink, 0.4), 1.2)
			ci.draw_set_transform(c, rot + 0.35, Vector2(s, s))
			ci.draw_rect(Rect2(-15, 6, 30, 14), Color(Pal.c("red"), 0.15))
			ci.draw_rect(Rect2(-15, 6, 30, 14), Pal.c("red"), false, 2.0)
			Ink.text(ci, "退回", Vector2(0, 17), 10, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"applications":
			# 一沓申报书，最上面一张盖着“新”
			for i in 5:
				_box(ci, Rect2(-24 + i * 1.5, 8 - i * 6, 46, 14), paper, ink)
			_box(ci, Rect2(-18, -26, 38, 26), paper, ink)
			Ink.text(ci, "申报书", Vector2(1, -15), 9, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			ci.draw_line(Vector2(-12, -8), Vector2(14, -8), Color(ink, 0.4), 1.2)
		"nobel_list":
			# 名单：一行被红笔划掉，旁边一颗金色小奖章
			_box(ci, Rect2(-22, -26, 40, 52), paper, ink)
			for i in 5:
				ci.draw_line(Vector2(-16, -16 + i * 8), Vector2(10, -16 + i * 8), Color(ink, 0.45), 1.3)
			ci.draw_line(Vector2(-18, -8), Vector2(14, -8), Pal.c("red"), 2.6)
			ci.draw_circle(Vector2(16, 16), 9.0, Pal.c("gold"))
			ci.draw_arc(Vector2(16, 16), 9.0, 0, TAU, 24, ink, 1.6, true)
			_star(ci, Vector2(16, 16), 4.5, ink)
		_:
			_box(ci, Rect2(-20, -20, 40, 40), paper, ink)
			Ink.text(ci, "?", Vector2(0, 8), 20, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	ci.draw_set_transform(Vector2.ZERO)

static func _box(ci: CanvasItem, r: Rect2, fill: Color, line: Color) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(r, line, false, 1.8)

static func _poly(ci: CanvasItem, pts: Array, fill: Color, line: Color) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_colored_polygon(p, fill)
	p.append(p[0])
	ci.draw_polyline(p, line, 1.8, true)

static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2.from_angle(-PI / 2 + i * PI / 5) * rr)
	ci.draw_colored_polygon(pts, col)

## 稀有度颜色
static func rarity_col(r: int) -> Color:
	return [Pal.c("text2"), Pal.c("blue"), Pal.c("lock"), Pal.c("gold")][r]
