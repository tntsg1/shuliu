extends Node2D
## 实验室剖面：静态部分（只在主题切换时重画）

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

func _draw() -> void:
	_office()
	# 储藏室改成完整房间，由 basement.gd 画（M5a）
	_main_room()
	_main_ring()
	_injector()
	_pipes()
	_magnets()
	_detector()
	_terminal()
	_stairs()

# —— 剖切面排线（工程图惯例：被剖开的楼板画 45° 斜线） ——
func _section(r: Rect2) -> void:
	draw_rect(r, Pal.c("slab"))
	var col := Color(Pal.c("ink"), 0.22 if not Pal.dark else 0.12)
	var x := r.position.x - r.size.y
	while x < r.end.x:
		var a := Vector2(maxf(x, r.position.x), r.end.y - maxf(0.0, r.position.x - x))
		var b := Vector2(minf(x + r.size.y, r.end.x), r.position.y + maxf(0.0, x + r.size.y - r.end.x))
		draw_line(a, b, col, Ink.W4, true)
		x += 12.0
	draw_line(r.position, Vector2(r.end.x, r.position.y), Pal.c("ink"), Ink.W2, true)
	draw_line(Vector2(r.position.x, r.end.y), r.end, Pal.c("ink"), Ink.W2, true)

func _office() -> void:
	var top := Rect2(0, 0, Geo.W, Geo.CEIL - 24)
	draw_rect(top, Pal.c("office"))
	# 台灯光
	if Pal.dark:
		for i in 6:
			Ink.disc(self, Vector2(1338, 104), 60.0 + i * 50.0, Color(Pal.c("lamp"), 0.025))
	# 书架（背景层：旧纸、旧布的底色为主，只有两本带颜色）
	var el2 := Color(Pal.equip_line(), 0.75)
	var off := Pal.c("office")
	var books := [Pal.c("equip_dark"), Pal.c("paper2"), Pal.c("slab"), Pal.c("ink2").lerp(off, 0.45), Pal.c("equip"), Pal.c("equip_dark").lerp(Pal.c("ink2"), 0.3)]
	Ink.box(self, Rect2(800, 52, 440, 6), Pal.c("equip_dark"), el2, Ink.W3, 1)
	Ink.box(self, Rect2(800, 172, 440, 5), Pal.c("equip_dark"), el2, Ink.W3, 2)
	var x := 812.0
	for i in 14:
		var w := 18.0 + float((i * 37) % 13)
		var h := 82.0 + float((i * 53) % 34)
		var col: Color = books[(i * 5) % books.size()]
		if i == 4:
			col = Pal.c("red").lerp(off, 0.55)
		elif i == 11:
			col = Pal.c("blue").lerp(off, 0.55)
		Ink.box(self, Rect2(x, 172 - h, w, h), col, el2, Ink.W2, i)
		draw_rect(Rect2(x + 3, 172 - h + 10, w - 6, 2), Color(Pal.c("paper"), 0.4))
		x += w + 2.0
		if i == 9:
			# 斜靠的一本
			draw_set_transform(Vector2(x + 18, 172), -0.32)
			Ink.box(self, Rect2(0, -96, 20, 96), Pal.c("paper2"), el2, Ink.W2, 99)
			draw_set_transform(Vector2.ZERO)
			x += 40.0
	# 书桌 + 台灯 + 一叠稿纸
	Ink.ground(self, 1292, 1468, 176)
	Ink.box(self, Rect2(1280, 128, 200, 14), Pal.c("equip_dark"), el2, Ink.W2, 3)
	Ink.box(self, Rect2(1292, 142, 10, 34), Pal.c("equip_dark"), el2, Ink.W3, 4)
	Ink.box(self, Rect2(1458, 142, 10, 34), Pal.c("equip_dark"), el2, Ink.W3, 5)
	Ink.poly(self, PackedVector2Array([Vector2(1326, 98), Vector2(1352, 98), Vector2(1344, 82), Vector2(1334, 82)]), Pal.c("lamp"), el2, Ink.W3, 6)
	draw_line(Vector2(1339, 98), Vector2(1339, 128), el2, Ink.W2)
	draw_rect(Rect2(1328, 125, 22, 3), el2)
	for i in 4:
		draw_set_transform(Vector2(1400 + i * 1.5, 126 - i * 2.5), 0.04 * (i - 1.5))
		draw_rect(Rect2(-22, -2, 44, 3), Pal.c("paper"))
		Ink.frame(self, Rect2(-22, -2, 44, 3), el2, Ink.W4)
	draw_set_transform(Vector2.ZERO)
	# 黑板 + 手写公式
	Ink.drop(self, Rect2(200, 40, 420, 120))
	Ink.box(self, Rect2(200, 40, 420, 120), Pal.c("screen").lerp(Pal.c("green"), 0.25), Pal.equip_line(), Ink.W2, 7)
	Ink.box(self, Rect2(194, 158, 432, 6), Pal.c("equip_dark"), el2, Ink.W3, 8)
	draw_rect(Rect2(520, 154, 14, 4), Color(Pal.c("paper"), 0.85))
	Ink.text(self, "E² = (pc)² + (mc²)²", Vector2(222, 82), 22, Color(Pal.c("paper"), 0.85), Pal.hand)
	Ink.text(self, "β = v/c ≈ 0.99999…", Vector2(222, 118), 20, Color(Pal.c("paper"), 0.7), Pal.hand)
	Ink.text(self, "下次一定成功", Vector2(470, 146), 16, Color(Pal.c("gold"), 0.85), Pal.hand)
	# 挂钟（永远快五分钟）
	_clock(Vector2(700, 96), 26.0, 0.42)
	Ink.text(self, "退休教授办公室 · 尚未开放", Vector2(1540, 160), 15, Color(Pal.c("ink2"), 0.5), Pal.hand)
	_section(Rect2(0, Geo.CEIL - 24, Geo.W, 24))

func _clock(p: Vector2, r: float, hrs: float) -> void:
	var el := Pal.equip_line()
	draw_line(p + Vector2(0, -r - 6), p + Vector2(0, -r + 2), el, Ink.W2)
	Ink.disc(self, p + Vector2(0, -r - 6), 2.0, el)
	Ink.disc(self, p + Vector2(4, 5), r, Color(0, 0, 0, 0.12))
	Ink.disc(self, p, r, Pal.c("paper"))
	draw_arc(p, r, 0, TAU, 48, el, Ink.W2, true)
	for i in 12:
		var a := TAU * i / 12.0
		draw_line(p + Vector2.from_angle(a) * (r - 5), p + Vector2.from_angle(a) * (r - 2), el, Ink.W3)
	draw_line(p, p + Vector2.from_angle(TAU * hrs - PI / 2) * r * 0.5, el, Ink.W1, true)
	draw_line(p, p + Vector2.from_angle(TAU * 0.08 - PI / 2) * r * 0.78, el, Ink.W2, true)
	Ink.disc(self, p, 2.0, Pal.c("red"))

func _storage() -> void:
	var y0 := Geo.FLOOR + 22
	draw_rect(Rect2(0, y0, Geo.W, 1080 - y0), Pal.c("storage"))
	# 背景层：线降一档、纸箱色、货架高矮不一，中间留一段空墙
	var el := Color(Pal.equip_line(), 0.7)
	var floor_y := y0 + 218.0
	var card := [Pal.c("equip_dark"), Pal.c("paper2").lerp(Pal.c("equip_dark"), 0.35)]
	if Pal.dark:
		# 暗色模式里储藏室是最暗的一层：纸箱压暗，别比主场景还亮
		card = [Pal.c("equip_dark").lerp(Pal.c("storage"), 0.6), Pal.c("equip").lerp(Pal.c("storage"), 0.65)]
		el = Color(Pal.equip_line(), 0.45)
	var shelves := [[360.0, 3], [500.0, 2], [640.0, 3], [1180.0, 2], [1320.0, 3], [1460.0, 2]]
	for si in shelves.size():
		var x: float = shelves[si][0]
		var tiers: int = shelves[si][1]
		var top := floor_y - tiers * 57.0
		Ink.ground(self, x, x + 104, floor_y)
		draw_rect(Rect2(x, top, 4, floor_y - top), Pal.c("equip_dark"))
		draw_rect(Rect2(x + 100, top, 4, floor_y - top), Pal.c("equip_dark"))
		Ink.frame(self, Rect2(x, top, 104, floor_y - top), el, Ink.W2)
		for k in tiers:
			var sy := top + 57.0 * k
			draw_line(Vector2(x, sy), Vector2(x + 104, sy), el, Ink.W3)
			# 每层放一两个纸箱
			var n := 1 + (si + k) % 2
			for b in n:
				var bw := 30.0 + float((si * 11 + k * 7 + b * 5) % 18)
				var bh := 26.0 + float((si * 5 + k * 3 + b) % 3) * 5.0
				var br := Rect2(x + 8 + b * 48, sy + 57.0 - bh, bw, bh)
				Ink.box(self, br, card[(si + k + b) % 2], el, Ink.W3, si * 7 + k * 3 + b)
				if (si + k + b) % 3 == 0:
					draw_rect(Rect2(br.position.x + bw * 0.5 - 3, br.position.y, 6, bh), Pal.c("gold").lerp(Pal.c("storage"), 0.6))
	# 失物招领箱
	Ink.ground(self, 150, 270, y0 + 220)
	Ink.box(self, Rect2(150, y0 + 150, 120, 70), Pal.c("equip"), el, Ink.W2, 41)
	Ink.text(self, "失物招领", Vector2(210, y0 + 192), 16, el, Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	# 那枚硬币
	Ink.disc(self, Vector2(1003, y0 + 212), 6.0, Pal.c("gold"))
	draw_arc(Vector2(1003, y0 + 212), 6.0, 0, TAU, 20, el, Ink.W3, true)
	Ink.text(self, "地下储藏室 · 尚未开放", Vector2(1640, y0 + 210), 15, Color(Pal.c("ink2"), 0.5), Pal.hand)

func _main_room() -> void:
	var r := Rect2(0, Geo.CEIL, Geo.W, Geo.FLOOR - Geo.CEIL)
	draw_rect(r, Pal.c("wall1"))
	draw_rect(Rect2(0, Geo.CEIL, 700, r.size.y), Color(Pal.c("wall0"), 0.6))
	draw_rect(Rect2(1500, Geo.CEIL, 420, r.size.y), Color(Pal.c("wall2"), 0.6))
	# 墙板
	var pl := Pal.c("panel_line")
	var x := 0.0
	while x < Geo.W:
		Ink.line(self, Vector2(x, Geo.CEIL + 18), Vector2(x, Geo.FLOOR - 40), Color(pl, 0.5), Ink.W4, int(x))
		x += 160.0
	Ink.line(self, Vector2(0, Geo.FLOOR - 40), Vector2(Geo.W, Geo.FLOOR - 40), Color(pl, 0.7), Ink.W3, 11)
	draw_rect(Rect2(0, Geo.FLOOR - 40, Geo.W, 40), Color(Pal.c("ink"), 0.04))
	# 线槽 + 三色电缆
	draw_rect(Rect2(0, Geo.CEIL, Geo.W, 14), Pal.c("slab").lerp(Pal.c("ink"), 0.1))
	var cables := ["red", "blue", "gold"]
	for k in 3:
		var pts := PackedVector2Array()
		var y := Geo.CEIL + 19 + k * 5
		for i in 49:
			var xx := i * 40.0
			pts.append(Vector2(xx, y + 5.0 * sin(xx / 240.0 * PI) * sin(xx / 240.0 * PI)))
		Ink.pl(self, pts, Pal.c(cables[k]), 2.4)
	# 吸顶灯
	for i in 6:
		var lx := 200.0 + i * 320.0
		Ink.box(self, Rect2(lx, Geo.CEIL + 14, 80, 7), Pal.c("equip"), Pal.equip_line(), Ink.W2, i)
		if Pal.dark:
			var cone := PackedVector2Array([Vector2(lx + 4, Geo.CEIL + 21), Vector2(lx + 76, Geo.CEIL + 21), Vector2(lx + 170, Geo.FLOOR), Vector2(lx - 90, Geo.FLOOR)])
			draw_colored_polygon(cone, Color(Pal.c("lamp"), 0.045))
	# 辐射警示牌 + 安全标语
	_trefoil(Vector2(808, 352), 26.0)
	Ink.text(self, "辐射控制区", Vector2(808, 404), 15, Pal.c("ink"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	var sign := Rect2(1232, 312, 176, 40)
	Ink.drop(self, sign)
	Ink.box(self, sign, Pal.c("paper"), Pal.equip_line(), Ink.W3, 21)
	for p in [sign.position + Vector2(5, 5), Vector2(sign.end.x - 5, sign.position.y + 5), sign.end - Vector2(5, 5), Vector2(sign.position.x + 5, sign.end.y - 5)]:
		Ink.rivet(self, p, 1.6)
	Ink.text(self, "束流运行中 · 勿开舱", Vector2(1320, 338), 15, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 灭火器：挂在墙上的托架里（让出审核台右边给储备柜，挪到审核台左边）
	var fx := 1352.0
	Ink.drop(self, Rect2(fx, 712, 20, 38))
	Ink.box(self, Rect2(fx, 712, 20, 38), Pal.c("red"), Pal.equip_line(), Ink.W2, 25)
	draw_rect(Rect2(fx + 2, 715, 3, 32), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(fx + 3, 704, 14, 8), Pal.equip_line())
	Ink.box(self, Rect2(fx - 6, 746, 32, 6), Pal.c("equip_dark"), Pal.equip_line(), Ink.W3, 26)
	Ink.box(self, Rect2(fx - 6, 724, 4, 28), Pal.c("equip_dark"), Pal.equip_line(), Ink.W3, 27)
	# 地板
	draw_rect(Rect2(0, Geo.FLOOR - 4, Geo.W, 4), Color(Pal.c("ink"), 0.06))
	_section(Rect2(0, Geo.FLOOR, Geo.W, 22))
	# 控制台前地面警戒线
	_hazard(Rect2(840, Geo.FLOOR - 8, 240, 6))

func _hazard(r: Rect2) -> void:
	draw_rect(r, Pal.c("gold"))
	var x := r.position.x
	while x < r.end.x:
		var pts := PackedVector2Array([Vector2(x, r.end.y), Vector2(x + 6, r.end.y), Vector2(x + 6 + r.size.y, r.position.y), Vector2(x + r.size.y, r.position.y)])
		draw_colored_polygon(pts, Pal.c("ink"))
		x += 14.0

func _trefoil(p: Vector2, r: float) -> void:
	Ink.disc(self, p + Vector2(4, 5), r + 6, Color(0, 0, 0, 0.12))
	Ink.disc(self, p, r + 6, Pal.c("gold"))
	draw_arc(p, r + 6, 0, TAU, 40, Pal.equip_line(), Ink.W2, true)
	for i in 3:
		var a0 := -PI / 2 + TAU * i / 3.0 - PI / 6
		var pts := PackedVector2Array([p])
		for k in 9:
			pts.append(p + Vector2.from_angle(a0 + PI / 3 * k / 8.0) * r)
		draw_colored_polygon(pts, Pal.c("ink"))
	Ink.disc(self, p, r * 0.22, Pal.c("gold"))
	Ink.disc(self, p, r * 0.14, Pal.c("ink"))

func _gauge(p: Vector2, r: float, v: float) -> void:
	Ink.disc(self, p, r, Pal.c("paper"))
	draw_arc(p, r, 0, TAU, 32, Pal.equip_line(), Ink.W2, true)
	draw_arc(p, r - 3, PI * 0.8, PI * 1.6, 12, Pal.c("red"), 2.0)
	var a := lerpf(PI * 0.8, PI * 2.2, v)
	draw_line(p, p + Vector2.from_angle(a) * (r - 3), Pal.equip_line(), Ink.W2, true)
	Ink.disc(self, p, 1.8, Pal.equip_line())

func _injector() -> void:
	var r := Rect2(150, Geo.BEAMY - 110, 190, 220)
	Ink.ground(self, 190, 300)
	Ink.box(self, r, Pal.c("equip"), Pal.equip_line(), Ink.W1, 31)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 18), Pal.c("equip_dark"))
	draw_line(Vector2(r.position.x, r.position.y + 18), Vector2(r.end.x, r.position.y + 18), Pal.equip_line(), Ink.W2)
	draw_rect(Rect2(r.position.x + 3, r.position.y + 20, 4, r.size.y - 23), Color(1, 1, 1, 0.22))
	for i in 5:
		var tr := Rect2(170 + i * 32, Geo.BEAMY - 76, 20, 150)
		Ink.box(self, tr, Pal.ramp(i / 4.0), Pal.equip_line(), Ink.W2, 32 + i)
		draw_rect(Rect2(tr.position.x + 3, tr.position.y + 6, 3, tr.size.y - 12), Color(1, 1, 1, 0.22))
	_gauge(Vector2(190, Geo.BEAMY + 92), 11.0, 0.62)
	_gauge(Vector2(222, Geo.BEAMY + 92), 11.0, 0.35)
	for k in 6:
		draw_line(Vector2(258 + k * 12, Geo.BEAMY + 82), Vector2(258 + k * 12, Geo.BEAMY + 102), Pal.equip_line(), Ink.W2)
	for p in [Vector2(156, Geo.BEAMY - 104), Vector2(334, Geo.BEAMY - 104), Vector2(156, Geo.BEAMY + 104), Vector2(334, Geo.BEAMY + 104)]:
		Ink.rivet(self, p)
	Ink.box(self, Rect2(190, Geo.BEAMY + 110, 110, Geo.FLOOR - Geo.BEAMY - 110), Pal.c("equip_dark"), Pal.equip_line(), Ink.W1, 36)
	Ink.text(self, "注入器", Vector2(185, Geo.BEAMY - 124), 17, Pal.c("ink2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

func _flange(x: float) -> void:
	Ink.box(self, Rect2(x - 5, Geo.BEAMY - 22, 10, 44), Pal.c("equip_dark"), Pal.equip_line(), Ink.W2, int(x))
	Ink.rivet(self, Vector2(x, Geo.BEAMY - 17), 1.8)
	Ink.rivet(self, Vector2(x, Geo.BEAMY + 17), 1.8)

func _pipe(x1: float, x2: float) -> void:
	Ink.box(self, Rect2(x1, Geo.BEAMY - 13, x2 - x1, 26), Pal.c("pipe"), Pal.equip_line(), Ink.W2, int(x1))
	draw_rect(Rect2(x1, Geo.BEAMY - 9, x2 - x1, 3), Color(1, 1, 1, 0.25))
	draw_rect(Rect2(x1, Geo.BEAMY + 6, x2 - x1, 4), Color(0, 0, 0, 0.08))

func _bellows(x: float, w: float) -> void:
	var pts := PackedVector2Array()
	var n := int(w / 6.0)
	for i in n + 1:
		pts.append(Vector2(x + i * w / n, Geo.BEAMY - 16 if i % 2 == 0 else Geo.BEAMY - 11))
	for i in range(n, -1, -1):
		pts.append(Vector2(x + i * w / n, Geo.BEAMY + 16 if i % 2 == 0 else Geo.BEAMY + 11))
	draw_colored_polygon(pts, Pal.c("pipe").lerp(Pal.c("ink"), 0.08))
	pts.append(pts[0])
	Ink.pl(self, pts, Pal.equip_line(), Ink.W3)

func _pipes() -> void:
	_pipe(340, 820)
	_pipe(1380, 1600)
	for x in [380.0, 470.0, 650.0, 790.0, 1410.0, 1560.0]:
		_flange(x)
	_bellows(600, 36)
	_bellows(1520, 30)
	# 管道支架
	for x in [430.0, 770.0, 1440.0]:
		Ink.ground(self, x - 16, x + 16)
		Ink.box(self, Rect2(x - 4, Geo.BEAMY + 13, 8, Geo.FLOOR - Geo.BEAMY - 13), Pal.c("equip_dark"), Pal.equip_line(), Ink.W2, int(x))
		Ink.box(self, Rect2(x - 16, Geo.FLOOR - 6, 32, 6), Pal.c("equip_dark"), Pal.equip_line(), Ink.W2, int(x) + 1)

func _magnet(x: float, w: float, h: float, a: Color, b: Color, label: String) -> void:
	var r := Rect2(x - w * 0.5, Geo.BEAMY - h * 0.5, w, h)
	Ink.ground(self, x - 22, x + 22)
	Ink.box(self, r, b, Pal.equip_line(), Ink.W1, int(x))
	var coil := Rect2(r.position.x + 5, r.position.y + 6, w - 10, h * 0.24)
	var coil2 := Rect2(r.position.x + 5, r.end.y - 6 - h * 0.24, w - 10, h * 0.24)
	for cr in [coil, coil2]:
		Ink.box(self, cr, a, Pal.equip_line(), Ink.W2, int(cr.position.y))
		var yy: float = cr.position.y + 4
		while yy < cr.end.y - 2:
			draw_line(Vector2(cr.position.x + 2, yy), Vector2(cr.end.x - 2, yy), Color(Pal.c("ink"), 0.2), Ink.W4)
			yy += 4.0
	if label != "":
		Ink.sticker(self, label, Vector2(x, Geo.BEAMY), 0.0, 11)
	Ink.box(self, Rect2(x - 9, r.end.y, 18, Geo.FLOOR - r.end.y), Pal.c("equip_dark"), Pal.equip_line(), Ink.W2, int(x) + 3)
	Ink.box(self, Rect2(x - 22, Geo.FLOOR - 7, 44, 7), Pal.c("equip_dark"), Pal.equip_line(), Ink.W2, int(x) + 4)

func _magnets() -> void:
	_magnet(560, 82, 96, Pal.c("dip_a"), Pal.c("dip_b"), "")
	_magnet(720, 54, 124, Pal.c("quad_a"), Pal.c("quad_b"), "")
	_magnet(1490, 54, 124, Pal.c("quad_a"), Pal.c("quad_b"), "")

func _detector() -> void:
	var x := Geo.DETECTOR_X
	for i in 5:
		var h := 90.0 + i * 42.0
		var r := Rect2(x + i * 24, Geo.BEAMY - h * 0.5, 30, h)
		Ink.box(self, r, Pal.c("det%d" % i), Pal.equip_line(), Ink.W1 if i == 4 else Ink.W2, 50 + i)
		var yy := r.position.y + 10
		while yy < r.end.y - 6:
			draw_line(Vector2(r.position.x + 4, yy), Vector2(r.end.x - 4, yy), Color(Pal.c("ink"), 0.15), Ink.W4)
			yy += 12.0
	Ink.ground(self, x + 20, x + 130)
	Ink.box(self, Rect2(x + 20, Geo.BEAMY + 130, 110, Geo.FLOOR - Geo.BEAMY - 130), Pal.c("equip_dark"), Pal.equip_line(), Ink.W1, 58)
	# 屏幕支架与框（内容由 detector.gd 画）
	var s := Geo.SCREEN
	draw_line(Vector2(s.get_center().x, Geo.CEIL + 14), Vector2(s.get_center().x, s.position.y), Pal.equip_line(), Ink.W2)
	Ink.drop(self, s.grow(8))
	Ink.box(self, s.grow(8), Pal.c("equip"), Pal.equip_line(), Ink.W1, 61)
	for p in [s.position + Vector2(-4, -4), Vector2(s.end.x + 4, s.position.y - 4), s.end + Vector2(4, 4), Vector2(s.position.x - 4, s.end.y + 4)]:
		Ink.rivet(self, p, 2.0)
	# 线束
	for k in 4:
		var pts := PackedVector2Array()
		for i in 12:
			var t := i / 11.0
			pts.append(Vector2(lerpf(x + 130, 1880, t), lerpf(Geo.BEAMY + 60 + k * 8, Geo.FLOOR - 10, t * t) + sin(t * 6 + k) * 3))
		Ink.pl(self, pts, Pal.c(["red", "blue", "gold", "ink2"][k]), 2.0)

func _terminal() -> void:
	var x := Geo.TERMINAL_X
	Ink.ground(self, x, x + 70)
	Ink.box(self, Rect2(x, Geo.FLOOR - 170, 70, 170), Pal.c("equip"), Pal.equip_line(), Ink.W1, 71)
	draw_rect(Rect2(x + 3, Geo.FLOOR - 167, 4, 164), Color(1, 1, 1, 0.22))
	Ink.box(self, Rect2(x + 9, Geo.FLOOR - 156, 52, 42), Pal.c("term"), Pal.equip_line(), Ink.W2, 72)
	Ink.text(self, "$", Vector2(x + 35, Geo.FLOOR - 126), 22, Pal.equip_line(), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	for i in 3:
		Ink.box(self, Rect2(x + 12 + i * 17, Geo.FLOOR - 100, 12, 9), Pal.c("equip_dark"), Pal.equip_line(), Ink.W3, 73 + i)
	draw_rect(Rect2(x + 14, Geo.FLOOR - 70, 42, 4), Pal.equip_line())
	Ink.text(self, "采购终端", Vector2(x + 35, Geo.FLOOR - 182), 15, Pal.c("ink2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

## 墙边固定直梯：两根侧梁 + 横档，穿过楼板检修口通到楼上办公室，墙上每隔一段一个固定卡子
func _stairs() -> void:
	var el := Pal.equip_line()
	var x0 := 34.0
	var x1 := 78.0
	var top := Geo.CEIL - 30.0
	# 楼板检修口
	draw_rect(Rect2(x0 - 8, Geo.CEIL - 24, x1 - x0 + 16, 24), Pal.c("office").darkened(0.18))
	draw_line(Vector2(x0 - 8, Geo.CEIL - 24), Vector2(x0 - 8, Geo.CEIL), el, Ink.W2)
	draw_line(Vector2(x1 + 8, Geo.CEIL - 24), Vector2(x1 + 8, Geo.CEIL), el, Ink.W2)
	Ink.ground(self, x0 - 4, x1 + 4)
	# 墙上的固定卡子
	var y := Geo.FLOOR - 90.0
	while y > Geo.CEIL + 40.0:
		draw_rect(Rect2(x0 - 10, y - 3, x1 - x0 + 20, 6), Pal.c("equip_dark"))
		Ink.frame(self, Rect2(x0 - 10, y - 3, x1 - x0 + 20, 6), el, Ink.W3)
		y -= 190.0
	# 横档（两端插进侧梁）
	y = Geo.FLOOR - 26.0
	while y > top + 10.0:
		draw_rect(Rect2(x0, y - 2, x1 - x0, 4), Pal.c("equip"))
		draw_line(Vector2(x0, y - 2), Vector2(x1, y - 2), el, Ink.W3)
		draw_line(Vector2(x0, y + 2), Vector2(x1, y + 2), el, Ink.W3)
		y -= 28.0
	# 侧梁
	for bx in [x0 - 5.0, x1]:
		Ink.box(self, Rect2(bx, top, 5, Geo.FLOOR - top), Pal.c("equip_dark"), el, Ink.W2, int(bx))

# —— 主环：一根更粗的管道从房间顶部横穿两侧墙壁，这间实验室只是 26.7 km 环上的一个站 ——
const RING_Y := 258.0
func _main_ring() -> void:
	var el := Pal.equip_line()
	var y := RING_Y
	# 墙洞套环
	for x in [0.0, Geo.W]:
		draw_rect(Rect2(x - 22, y - 34, 44, 68), Pal.c("slab"))
		Ink.frame(self, Rect2(x - 22, y - 34, 44, 68), el, Ink.W2)
	Ink.box(self, Rect2(-10, y - 18, Geo.W + 20, 36), Pal.c("pipe").lerp(Pal.c("equip_dark"), 0.3), el, Ink.W1, 501)
	draw_rect(Rect2(0, y - 13, Geo.W, 4), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(0, y + 9, Geo.W, 5), Color(0, 0, 0, 0.08))
	var fx := 60.0
	while fx < Geo.W:
		Ink.box(self, Rect2(fx - 6, y - 26, 12, 52), Pal.c("equip_dark"), el, Ink.W2, int(fx))
		Ink.rivet(self, Vector2(fx, y - 20), 1.8)
		Ink.rivet(self, Vector2(fx, y + 20), 1.8)
		fx += 240.0
	# 主环二极铁（长、蓝）与四极铁（短、红）
	for mx in [520.0, 1260.0]:
		var r := Rect2(mx - 90, y - 30, 180, 60)
		Ink.box(self, r, Pal.c("dip_b"), el, Ink.W1, int(mx))
		Ink.box(self, Rect2(r.position + Vector2(6, 5), Vector2(168, 14)), Pal.c("dip_a"), el, Ink.W2, int(mx) + 1)
		Ink.box(self, Rect2(r.position + Vector2(6, 41), Vector2(168, 14)), Pal.c("dip_a"), el, Ink.W2, int(mx) + 2)
	for mx in [900.0, 1700.0]:
		Ink.box(self, Rect2(mx - 22, y - 34, 44, 68), Pal.c("quad_b"), el, Ink.W1, int(mx))
		Ink.box(self, Rect2(mx - 18, y - 30, 36, 14), Pal.c("quad_a"), el, Ink.W2, int(mx) + 1)
		Ink.box(self, Rect2(mx - 18, y + 16, 36, 14), Pal.c("quad_a"), el, Ink.W2, int(mx) + 2)
	# 吊架
	for hx in [300.0, 760.0, 1100.0, 1500.0]:
		draw_line(Vector2(hx, Geo.CEIL + 14), Vector2(hx, y - 18), el, Ink.W2)
		draw_line(Vector2(hx - 24, y - 18), Vector2(hx + 24, y - 18), el, Ink.W2)
	# 方向与里程
	var tc := Pal.c("ink2")
	Ink.text(self, "◄ 主环 · 周长 26.7 km", Vector2(1548, y + 46), 14, tc, Pal.hand, HORIZONTAL_ALIGNMENT_RIGHT)
	# 引出支线：从主环拐下来接到本站注入器
	var bx := 245.0
	Ink.box(self, Rect2(bx - 9, y + 18, 18, Geo.BEAMY - 110 - y - 18), Pal.c("pipe"), el, Ink.W2, 511)
	Ink.box(self, Rect2(bx - 34, y + 14, 68, 30), Pal.c("equip"), el, Ink.W1, 512)
	for k in 2:
		Ink.rivet(self, Vector2(bx - 26 + k * 52, y + 29), 1.8)
