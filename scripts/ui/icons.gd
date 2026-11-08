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
			Ink.text(ci, "2000", Vector2(10, -19), 8, Color(ink, 0.7), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
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
		# —— M3 第 2 批：咖啡 / 钟表 ——
		"coffee_cup":
			# 马克杯：杯口一圈褐色干渍，杯底长出一小撮绿毛
			_box(ci, Rect2(-18, -16, 30, 36), paper, ink)
			ci.draw_arc(Vector2(14, 2), 8.0, -PI / 2, PI / 2, 12, ink, 3.0, true)
			ci.draw_rect(Rect2(-18, -16, 30, 6), Color("#8a5a3a"))
			ci.draw_line(Vector2(-18, -10), Vector2(12, -10), ink, 1.4)
			for i in 3:
				ci.draw_line(Vector2(-12 + i * 9, -10), Vector2(-12 + i * 9, -3 + i * 2), Color("#8a5a3a"), 2.0)
			ci.draw_circle(Vector2(-6, 13), 4.0, Color("#7a9a5a"))
			ci.draw_circle(Vector2(0, 14), 3.0, Color("#8aaa6a"))
			ci.draw_rect(Rect2(-14, 4, 20, 4), Color(Pal.c("red"), 0.8))
		"thermos":
			# 老式保温杯：深红杯身 + 不锈钢盖，杯口飘出茶叶
			_box(ci, Rect2(-11, -16, 22, 42), Color("#8a2f2a"), ink)
			_box(ci, Rect2(-12, -26, 24, 12), Color("#b8bcc0"), ink)
			ci.draw_line(Vector2(-11, -8), Vector2(11, -8), Color(ink, 0.5), 1.2)
			ci.draw_line(Vector2(-11, 18), Vector2(11, 18), Color(ink, 0.5), 1.2)
			Ink.text(ci, "福", Vector2(0, 9), 12, Pal.c("gold"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			_poly(ci, [Vector2(14, -24), Vector2(22, -28), Vector2(20, -20)], Color("#6a8a4a"), ink)
		"alarm_4am":
			# 双铃闹钟，指针停在四点
			ci.draw_circle(Vector2(-14, -18), 7.0, Pal.c("red"))
			ci.draw_arc(Vector2(-14, -18), 7.0, 0, TAU, 16, ink, 1.6, true)
			ci.draw_circle(Vector2(14, -18), 7.0, Pal.c("red"))
			ci.draw_arc(Vector2(14, -18), 7.0, 0, TAU, 16, ink, 1.6, true)
			ci.draw_line(Vector2(-12, 18), Vector2(-17, 26), ink, 2.4)
			ci.draw_line(Vector2(12, 18), Vector2(17, 26), ink, 2.4)
			ci.draw_circle(Vector2(0, 2), 19.0, Pal.c("red"))
			ci.draw_circle(Vector2(0, 2), 15.0, paper)
			ci.draw_arc(Vector2(0, 2), 19.0, 0, TAU, 32, ink, 1.8, true)
			for i in 12:
				var a := TAU * i / 12.0
				ci.draw_line(Vector2(0, 2) + Vector2.from_angle(a) * 12, Vector2(0, 2) + Vector2.from_angle(a) * 14, ink, 1.2)
			ci.draw_line(Vector2(0, 2), Vector2(0, 2) + Vector2.from_angle(-PI / 2 + TAU * 4 / 12.0) * 8, ink, 2.6)
			ci.draw_line(Vector2(0, 2), Vector2(0, 2) + Vector2.from_angle(-PI / 2) * 11, ink, 1.8)
		# —— M3 第 3 批：文具 ——
		"bandaid":
			# 一块屏幕，裂缝上斜贴着创可贴
			_box(ci, Rect2(-26, -20, 52, 36), Pal.c("screen"), ink)
			ci.draw_polyline(PackedVector2Array([Vector2(-18, -14), Vector2(-6, -4), Vector2(-10, 4), Vector2(6, 12)]), Color(1, 1, 1, 0.6), 1.4, true)
			ci.draw_set_transform(c, rot - 0.6, Vector2(s, s))
			_box(ci, Rect2(-18, -6, 36, 12), Color("#e8b88a"), ink)
			ci.draw_rect(Rect2(-6, -6, 12, 12), Color("#f2d2b0"))
			for x in [-3, 0, 3]:
				for y in [-3, 0, 3]:
					ci.draw_circle(Vector2(x, y), 0.8, Color(ink, 0.5))
		"marker":
			# 白板笔，红色笔帽
			ci.draw_set_transform(c, rot - 0.75, Vector2(s, s))
			_box(ci, Rect2(-24, -7, 36, 14), paper, ink)
			_box(ci, Rect2(12, -8, 14, 16), Pal.c("red"), ink)
			ci.draw_rect(Rect2(-16, -7, 6, 14), Pal.c("red"))
			_poly(ci, [Vector2(-24, -5), Vector2(-30, -2), Vector2(-30, 2), Vector2(-24, 5)], Color("#9aa0a6"), ink)
		"wipes":
			# 扁扁的湿巾包，掀开的封口露出一张
			_box(ci, Rect2(-26, -12, 52, 28), Color("#cfe6ea"), ink)
			_box(ci, Rect2(-12, -12, 24, 10), Color("#a8d0d8"), ink)
			_poly(ci, [Vector2(-8, -12), Vector2(-4, -26), Vector2(8, -22), Vector2(6, -12)], paper, ink)
			Ink.text(ci, "½", Vector2(16, 12), 12, Pal.c("blue"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"tape_roll":
			# 透明胶带卷，找不到头
			ci.draw_circle(Vector2.ZERO, 22.0, Color("#e9dfc4"))
			ci.draw_arc(Vector2.ZERO, 22.0, 0, TAU, 40, ink, 1.8, true)
			ci.draw_arc(Vector2.ZERO, 17.0, 0, TAU, 40, Color(ink, 0.3), 1.0, true)
			ci.draw_circle(Vector2.ZERO, 11.0, paper)
			ci.draw_arc(Vector2.ZERO, 11.0, 0, TAU, 32, ink, 1.6, true)
			Ink.text(ci, "?", Vector2(17, -14), 13, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		# —— M3 第 4 批：证章 ——
		"rec_letter":
			# 信封半抽出一封信，落款处一个红色签名
			_box(ci, Rect2(-24, -4, 48, 28), Color("#e6d7b4"), ink)
			_box(ci, Rect2(-18, -26, 36, 32), paper, ink)
			for i in 3:
				ci.draw_line(Vector2(-12, -18 + i * 6), Vector2(12, -18 + i * 6), Color(ink, 0.4), 1.2)
			ci.draw_polyline(PackedVector2Array([Vector2(-2, 0), Vector2(3, -4), Vector2(6, 0), Vector2(10, -3), Vector2(13, 0)]), Pal.c("red"), 1.6, true)
			ci.draw_polyline(PackedVector2Array([Vector2(-24, -4), Vector2(0, 12), Vector2(24, -4)]), ink, 1.6, true)
		"grad_promise":
			# 学位帽 + 一张写着“明年”的小纸条
			_poly(ci, [Vector2(-26, -8), Vector2(0, -20), Vector2(26, -8), Vector2(0, 4)], Color("#2b2a28"), ink)
			_box(ci, Rect2(-14, -2, 28, 12), Color("#2b2a28"), ink)
			ci.draw_line(Vector2(18, -10), Vector2(20, 8), Pal.c("gold"), 2.0)
			ci.draw_circle(Vector2(20, 9), 3.0, Pal.c("gold"))
			_box(ci, Rect2(-18, 14, 30, 13), paper, ink)
			Ink.text(ci, "明年", Vector2(-3, 25), 9, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"phd_cert":
			# 证书：红色封皮翻开，姓名处一条空横线
			_box(ci, Rect2(-26, -20, 52, 40), Color("#8a2f2a"), ink)
			_box(ci, Rect2(-22, -16, 44, 32), paper, ink)
			Ink.text(ci, "学位证书", Vector2(0, -6), 8, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			ci.draw_line(Vector2(-14, 6), Vector2(14, 6), Pal.c("red"), 1.4)
			Ink.text(ci, "?", Vector2(0, 5), 9, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			ci.draw_circle(Vector2(12, 11), 4.0, Color(Pal.c("red"), 0.7))
		"dose_card":
			# 剂量卡：胶片窗变了色
			_box(ci, Rect2(-18, -24, 36, 48), Color("#d8dde2"), ink)
			ci.draw_rect(Rect2(-18, -24, 36, 9), Color("#2b2a28"))
			_box(ci, Rect2(-10, -10, 20, 20), Color("#7a5aa0"), ink)
			ci.draw_rect(Rect2(-10, -10, 10, 20), Color("#b088c8"))
			Ink.text(ci, "过期", Vector2(0, 20), 8, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			_box(ci, Rect2(-4, -30, 8, 8), Color("#9aa0a6"), ink)
		"meal_card":
			# 饭卡：蓝色卡片 + 磨花的芯片 + 余额
			ci.draw_set_transform(c, rot - 0.12, Vector2(s, s))
			_box(ci, Rect2(-26, -16, 52, 32), Pal.c("blue"), ink)
			_box(ci, Rect2(-20, -8, 12, 10), Pal.c("gold"), ink)
			Ink.text(ci, "¥3.5", Vector2(10, 10), 11, paper, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			ci.draw_line(Vector2(-20, 8), Vector2(0, 8), Color(paper, 0.6), 1.4)
		"red_flag":
			# 流动红旗：旗杆 + 带金穗的红旗
			ci.draw_line(Vector2(-18, -26), Vector2(-18, 28), Color("#9aa0a6"), 3.0)
			ci.draw_circle(Vector2(-18, -27), 3.0, Pal.c("gold"))
			_poly(ci, [Vector2(-17, -22), Vector2(22, -18), Vector2(18, -2), Vector2(22, 12), Vector2(-17, 8)], Pal.c("red"), ink)
			_star(ci, Vector2(-6, -8), 5.0, Pal.c("gold"))
			for i in 4:
				ci.draw_line(Vector2(-14 + i * 10, 8 + i * 1.0), Vector2(-14 + i * 10, 14 + i * 1.0), Pal.c("gold"), 2.0)
		"crooked_seal":
			# 圆形红章，印面歪着盖
			ci.draw_set_transform(c, rot + 0.35, Vector2(s, s))
			ci.draw_circle(Vector2.ZERO, 22.0, Color(Pal.c("red"), 0.12))
			ci.draw_arc(Vector2.ZERO, 22.0, 0, TAU, 40, Pal.c("red"), 3.0, true)
			ci.draw_arc(Vector2.ZERO, 17.0, 0, TAU, 40, Color(Pal.c("red"), 0.6), 1.0, true)
			_star(ci, Vector2(0, -2), 8.0, Pal.c("red"))
			ci.draw_line(Vector2(-10, 10), Vector2(10, 10), Pal.c("red"), 2.0)
		# —— M3 第 5 批：金属 ——
		"screw":
			# 一颗粗螺丝，螺纹斜线，十字槽头
			ci.draw_set_transform(c, rot - 0.5, Vector2(s, s))
			_box(ci, Rect2(-6, -8, 12, 34), Color("#b8bcc0"), ink)
			for i in 6:
				ci.draw_line(Vector2(-6, -4 + i * 5), Vector2(6, -1 + i * 5), Color(ink, 0.5), 1.2)
			_box(ci, Rect2(-14, -18, 28, 10), Color("#9aa0a6"), ink)
			ci.draw_line(Vector2(-6, -13), Vector2(6, -13), ink, 2.0)
		"lab8_key":
			# 旧铜钥匙，挂着写着“8”的塑料牌
			ci.draw_circle(Vector2(-12, -8), 11.0, Pal.c("gold"))
			ci.draw_arc(Vector2(-12, -8), 11.0, 0, TAU, 24, ink, 1.8, true)
			ci.draw_circle(Vector2(-12, -8), 4.0, paper)
			_box(ci, Rect2(-2, -11, 28, 6), Pal.c("gold"), ink)
			_box(ci, Rect2(16, -5, 4, 7), Pal.c("gold"), ink)
			_box(ci, Rect2(22, -5, 4, 5), Pal.c("gold"), ink)
			_box(ci, Rect2(-22, 6, 18, 20), Pal.c("red"), ink)
			Ink.text(ci, "8", Vector2(-13, 22), 13, paper, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"extinguisher":
			# 红色灭火器，检查卡上一个问号
			_box(ci, Rect2(-11, -14, 22, 40), Pal.c("red"), ink)
			ci.draw_circle(Vector2(0, -14), 11.0, Pal.c("red"))
			ci.draw_arc(Vector2(0, -14), 11.0, PI, TAU, 16, ink, 1.8, true)
			_box(ci, Rect2(-4, -28, 8, 6), Color("#2b2a28"), ink)
			ci.draw_polyline(PackedVector2Array([Vector2(4, -26), Vector2(16, -26), Vector2(20, -18)]), ink, 2.4, true)
			_box(ci, Rect2(-8, 2, 16, 14), paper, ink)
			Ink.text(ci, "?", Vector2(0, 14), 11, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"wrench":
			# 活动扳手，柄上贴着隔壁组的名字条
			ci.draw_set_transform(c, rot - 0.7, Vector2(s, s))
			_box(ci, Rect2(-24, -5, 38, 10), Color("#9aa0a6"), ink)
			_poly(ci, [Vector2(12, -12), Vector2(26, -12), Vector2(26, -4), Vector2(20, -4), Vector2(20, 4), Vector2(26, 4), Vector2(26, 12), Vector2(12, 12)], Color("#b8bcc0"), ink)
			ci.draw_rect(Rect2(-18, -5, 14, 10), paper)
			ci.draw_line(Vector2(-16, 0), Vector2(-7, 0), Pal.c("blue"), 1.6)
		"rf_cavity":
			# 一节铜色射频腔：几个鼓起的腔室
			for i in 3:
				ci.draw_circle(Vector2(-16 + i * 16, 0), 12.0, Color("#c98a4a"))
				ci.draw_arc(Vector2(-16 + i * 16, 0), 12.0, 0, TAU, 24, ink, 1.8, true)
			ci.draw_line(Vector2(-30, 0), Vector2(30, 0), Pal.c("ramp2"), 3.0)
			for i in 3:
				ci.draw_line(Vector2(-16 + i * 16, -12), Vector2(-16 + i * 16, -18), ink, 2.0)
			_box(ci, Rect2(-24, -24, 48, 6), Pal.c("equip"), ink)
		"extractor":
			# 引出器：一节管道把束流拐出去，出口一个箭头
			_box(ci, Rect2(-26, -8, 30, 16), Pal.c("equip"), ink)
			_poly(ci, [Vector2(4, -8), Vector2(18, -22), Vector2(26, -14), Vector2(12, 0), Vector2(4, 8)], Pal.c("equip"), ink)
			ci.draw_line(Vector2(-26, 0), Vector2(6, 0), Pal.c("ramp2"), 3.0)
			ci.draw_line(Vector2(6, 0), Vector2(20, -16), Pal.c("ramp2"), 3.0)
			_poly(ci, [Vector2(20, -24), Vector2(28, -26), Vector2(26, -18)], Pal.c("red"), ink)
		"cryo_magnet":
			# 低温磁体：白霜包着的磁铁 + 一片雪花
			_box(ci, Rect2(-22, -16, 44, 32), Color("#dfe8f0"), ink)
			ci.draw_rect(Rect2(-16, -10, 32, 20), Pal.c("dip_b"))
			for i in 5:
				ci.draw_circle(Vector2(-18 + i * 9, -16), 3.0, Color("#f6f9fb"))
			for i in 3:
				var a := i * PI / 3.0
				ci.draw_line(Vector2.from_angle(a) * -7.0, Vector2.from_angle(a) * 7.0, Color("#f6f9fb"), 2.0)
		"beam_dump":
			# 收集靶：一块厚铁块，正面一个被打出来的坑
			_box(ci, Rect2(-20, -20, 40, 40), Color("#6f747a"), ink)
			_box(ci, Rect2(-14, -14, 28, 28), Color("#878c92"), ink)
			ci.draw_circle(Vector2.ZERO, 7.0, Color("#3a3d42"))
			ci.draw_line(Vector2(-30, 0), Vector2(-14, 0), Pal.c("ramp2"), 3.0)
			Ink.text(ci, "$", Vector2(14, 26), 12, Pal.c("green"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		# —— M3 第 6 批：电子 ——
		"emergency_call":
			# 老式红色电话，听筒搁在上面，一张写着号码的小纸条
			_poly(ci, [Vector2(-22, 22), Vector2(-16, -4), Vector2(16, -4), Vector2(22, 22)], Pal.c("red"), ink)
			ci.draw_circle(Vector2(0, 9), 8.0, paper)
			ci.draw_arc(Vector2(0, 9), 8.0, 0, TAU, 20, ink, 1.4, true)
			_box(ci, Rect2(-24, -16, 48, 9), Pal.c("red"), ink)
			ci.draw_circle(Vector2(-22, -12), 6.0, Pal.c("red"))
			ci.draw_circle(Vector2(22, -12), 6.0, Pal.c("red"))
			_box(ci, Rect2(8, 14, 20, 12), paper, ink)
			Ink.text(ci, "急", Vector2(18, 24), 9, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"red_button":
			# 黄黑底座上一颗大红按钮，掀开的透明盖
			_box(ci, Rect2(-24, 6, 48, 18), Color("#e9c64a"), ink)
			for i in 4:
				ci.draw_line(Vector2(-20 + i * 12, 24), Vector2(-12 + i * 12, 6), Color("#2b2a28"), 3.0)
			ci.draw_circle(Vector2(0, 4), 15.0, Pal.c("red").darkened(0.3))
			ci.draw_circle(Vector2(0, 0), 15.0, Pal.c("red"))
			ci.draw_arc(Vector2(0, 0), 15.0, 0, TAU, 28, ink, 1.8, true)
			_poly(ci, [Vector2(-16, -14), Vector2(16, -14), Vector2(12, -28), Vector2(-12, -28)], Color(1, 1, 1, 0.5), ink)
		"printer":
			# 打印机，出纸口卡着一张皱纸
			_box(ci, Rect2(-24, -8, 48, 24), Color("#d8dde2"), ink)
			_box(ci, Rect2(-18, -18, 36, 10), Color("#b8bcc0"), ink)
			ci.draw_circle(Vector2(16, 8), 2.5, Pal.c("red"))
			_poly(ci, [Vector2(-14, 2), Vector2(14, 2), Vector2(10, 26), Vector2(2, 20), Vector2(-4, 28), Vector2(-12, 22)], paper, ink)
		"last_slide":
			# 投影幕：“谢谢！”
			ci.draw_line(Vector2(-26, -24), Vector2(26, -24), ink, 3.0)
			_box(ci, Rect2(-24, -22, 48, 34), paper, ink)
			Ink.text(ci, "谢谢！", Vector2(0, 0), 12, Pal.c("blue"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			ci.draw_line(Vector2(-14, 6), Vector2(14, 6), Color(ink, 0.4), 1.2)
			ci.draw_line(Vector2(0, 12), Vector2(0, 26), ink, 2.0)
			ci.draw_line(Vector2(-10, 26), Vector2(10, 26), ink, 2.0)
		"calc7":
			# 计算器，屏幕上一个大 7
			_box(ci, Rect2(-18, -26, 36, 52), Color("#3a3d42"), ink)
			_box(ci, Rect2(-13, -21, 26, 13), Color("#c8d6b0"), ink)
			Ink.text(ci, "7", Vector2(8, -10), 12, ink, Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
			for y in 3:
				for x in 3:
					ci.draw_rect(Rect2(-13 + x * 9, -4 + y * 9, 7, 6), Color("#d8dde2") if not (x == 2 and y == 2) else Pal.c("orange"))
		"calorimeter":
			# 量能器：一摞彩色晶体条，越往右越高
			_box(ci, Rect2(-26, -20, 52, 40), Pal.c("equip"), ink)
			for i in 6:
				var hh := 6.0 + i * 4.5
				ci.draw_rect(Rect2(-22 + i * 7.5, 16 - hh, 6, hh), Pal.ramp(i / 5.0))
			ci.draw_line(Vector2(-30, 0), Vector2(-24, 0), Pal.c("ramp2"), 3.0)
		"protect_sys":
			# 盾牌 + 闪电，外面一圈钢框
			_poly(ci, [Vector2(0, -24), Vector2(20, -16), Vector2(18, 6), Vector2(0, 24), Vector2(-18, 6), Vector2(-20, -16)], Pal.c("equip"), ink)
			_poly(ci, [Vector2(3, -14), Vector2(-7, 2), Vector2(1, 2), Vector2(-3, 14), Vector2(8, -3), Vector2(0, -3)], Pal.c("gold"), ink)
		"daq":
			# 数据采集机箱：一排指示灯 + 一条向上的曲线
			_box(ci, Rect2(-26, -18, 52, 36), Color("#3a3d42"), ink)
			_box(ci, Rect2(-22, -14, 44, 20), Pal.c("screen"), ink)
			ci.draw_polyline(PackedVector2Array([Vector2(-20, 4), Vector2(-10, 0), Vector2(-2, 1), Vector2(6, -6), Vector2(14, -8), Vector2(20, -12)]), Pal.c("green"), 2.0, true)
			for i in 5:
				ci.draw_circle(Vector2(-18 + i * 9, 12), 2.2, [Pal.c("green"), Pal.c("green"), Pal.c("gold"), Pal.c("green"), Pal.c("red")][i])
		"lock_loop":
			# 一个闭环箭头 + 锁
			ci.draw_arc(Vector2.ZERO, 18.0, -PI * 0.8, PI * 1.1, 32, Pal.c("lock"), 4.0, true)
			_poly(ci, [Vector2(-14, -18), Vector2(-4, -22), Vector2(-10, -10)], Pal.c("lock"), ink)
			_box(ci, Rect2(-7, -2, 14, 12), Pal.c("gold"), ink)
			ci.draw_arc(Vector2(0, -2), 5.0, PI, TAU, 10, ink, 2.0, true)
		"bpm":
			# 束流管上一圈四个电极，中间一个十字准星
			ci.draw_line(Vector2(-30, 0), Vector2(30, 0), Pal.c("ramp2"), 3.0)
			ci.draw_circle(Vector2.ZERO, 18.0, Pal.c("equip"))
			ci.draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, ink, 1.8, true)
			for i in 4:
				var a := PI / 4 + i * PI / 2
				ci.draw_circle(Vector2.from_angle(a) * 12.0, 3.5, Pal.c("gold"))
			ci.draw_line(Vector2(-6, 0), Vector2(6, 0), Pal.c("red"), 1.6)
			ci.draw_line(Vector2(0, -6), Vector2(0, 6), Pal.c("red"), 1.6)
		# —— M3 第 7 批：书籍 / 吉祥物 ——
		"impossible":
			# 期刊封面，大大的“？！”
			_box(ci, Rect2(-20, -26, 40, 52), Color("#2f5d9e"), ink)
			_box(ci, Rect2(-15, -20, 30, 8), paper, ink)
			Ink.text(ci, "?!", Vector2(0, 14), 22, Pal.c("gold"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"schrodinger":
			# 一个纸箱，盖子半开，露出一双猫眼（? 和 !）
			_poly(ci, [Vector2(-24, -6), Vector2(24, -6), Vector2(20, 24), Vector2(-20, 24)], Color("#c9a26a"), ink)
			_poly(ci, [Vector2(-24, -6), Vector2(-4, -20), Vector2(2, -10)], Color("#d9b47a"), ink)
			_poly(ci, [Vector2(24, -6), Vector2(8, -22), Vector2(2, -10)], Color("#d9b47a"), ink)
			ci.draw_circle(Vector2(-7, 6), 3.0, Pal.c("gold"))
			ci.draw_circle(Vector2(7, 6), 3.0, Pal.c("gold"))
			Ink.text(ci, "50%", Vector2(0, 21), 9, ink, Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
		"qm_book2":
			# 厚书，书脊写着“量子力学 II”
			_box(ci, Rect2(-20, -24, 40, 48), Color("#6a4fb0"), ink)
			ci.draw_rect(Rect2(-20, -24, 8, 48), Color("#4f3a88"))
			_box(ci, Rect2(-8, -14, 24, 14), paper, ink)
			Ink.text(ci, "II", Vector2(4, -3), 11, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
			Ink.text(ci, "ψ", Vector2(4, 18), 14, Pal.c("gold"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		"plant":
			# 陶盆里几片顽强的叶子
			_poly(ci, [Vector2(-14, 6), Vector2(14, 6), Vector2(10, 26), Vector2(-10, 26)], Color("#c0704a"), ink)
			_box(ci, Rect2(-16, 2, 32, 6), Color("#a85a3a"), ink)
			for a in [-0.9, -0.3, 0.3, 0.9]:
				var tip := Vector2.from_angle(-PI / 2 + a) * 24.0 + Vector2(0, 2)
				_poly(ci, [Vector2(0, 2), tip + tip.orthogonal().normalized() * 6.0, tip, tip - tip.orthogonal().normalized() * 6.0], Color("#5a9a5a"), ink)
		"lab_cat":
			# 一只橘猫的脑袋，眯着眼
			ci.draw_circle(Vector2(0, 4), 20.0, Pal.c("orange"))
			_poly(ci, [Vector2(-18, -6), Vector2(-14, -26), Vector2(-4, -14)], Pal.c("orange"), ink)
			_poly(ci, [Vector2(18, -6), Vector2(14, -26), Vector2(4, -14)], Pal.c("orange"), ink)
			ci.draw_arc(Vector2(0, 4), 20.0, 0, TAU, 32, ink, 1.8, true)
			ci.draw_arc(Vector2(-8, 2), 4.0, PI + 0.4, TAU - 0.4, 8, ink, 1.6, true)
			ci.draw_arc(Vector2(8, 2), 4.0, PI + 0.4, TAU - 0.4, 8, ink, 1.6, true)
			ci.draw_line(Vector2(-3, 10), Vector2(3, 10), ink, 1.4)
			for s2 in [-1.0, 1.0]:
				ci.draw_line(Vector2(s2 * 8, 10), Vector2(s2 * 22, 8), Color(ink, 0.6), 1.0)
				ci.draw_line(Vector2(s2 * 8, 12), Vector2(s2 * 22, 14), Color(ink, 0.6), 1.0)
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
