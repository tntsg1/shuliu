extends Node2D
## 地下储藏室（M5a）：和主实验室一样高的完整房间。顶上一排管子和吊灯，几排顶到天花板的货架，
## 货梯井旁边是失物招领箱（每局免费抽一件）。没开放时货梯口拦着，墙上贴“尚未开放”。
## 在实验室里只能看到上半截（货架上层、管子、吊灯），坐货梯下来镜头才往下移。

var main: Node
var t := 0.0
var box_bump := 0.0       # 抽完箱子晃一下

const RACKS := [[140.0, 120.0], [290.0, 120.0], [1010.0, 120.0], [1160.0, 120.0], [1330.0, 120.0], [1480.0, 120.0]]
const TIER := 70.0

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

var _sig := ""

func _process(dt: float) -> void:
	t += dt
	if box_bump > 0.0:
		box_bump = maxf(0.0, box_bump - dt * 2.2)
		queue_redraw()
	# 开放、本局领过——状态变了重画
	var sig := "%s%s" % [is_open(), drawn()]
	if sig != _sig:
		_sig = sig
		queue_redraw()

func is_open() -> bool:
	return Meta.storage_open()

func drawn() -> bool:
	return main != null and main.run != null and main.run.lost_drawn

func lost_rect() -> Rect2:
	return Rect2(Geo.LOST_X - 70, Geo.B_FLOOR - 92, 140, 92)

func _draw() -> void:
	var el := Pal.equip_line()
	var el2 := Color(el, 0.75)
	var wall := Pal.c("storage")
	var top := Geo.B_CEIL
	var fl := Geo.B_FLOOR
	draw_rect(Rect2(0, top, Geo.W, fl - top), wall)
	# 墙脚一圈踢脚线 + 墙上浅浅的水渍
	draw_rect(Rect2(0, fl - 26, Geo.W, 26), wall.darkened(0.06))
	draw_line(Vector2(0, fl - 26), Vector2(Geo.W, fl - 26), Color(el, 0.35), Ink.W3)
	for i in 5:
		var wx := 420.0 + i * 310.0
		draw_rect(Rect2(wx, top + 60, 34, 140 + (i % 3) * 40), Color(0, 0, 0, 0.025))
	# 地面楼板 + 下面的土
	_section(Rect2(0, fl, Geo.W, 22))
	draw_rect(Rect2(0, fl + 22, Geo.W, 600), Pal.c("slab").darkened(0.12))
	# 天花板管子：一粗一细，隔一段一个吊卡
	for py in [top + 22.0, top + 40.0]:
		var th := 10.0 if py < top + 30 else 6.0
		draw_rect(Rect2(0, py - th * 0.5, Geo.W, th), Pal.c("equip"))
		draw_line(Vector2(0, py - th * 0.5), Vector2(Geo.W, py - th * 0.5), el2, Ink.W3)
		draw_line(Vector2(0, py + th * 0.5), Vector2(Geo.W, py + th * 0.5), el2, Ink.W3)
	var hx := 80.0
	while hx < Geo.W:
		draw_line(Vector2(hx, top), Vector2(hx, top + 46), el2, Ink.W3)
		hx += 240.0
	# 吊灯：一根线 + 铁皮灯罩，地上一圈暖光（哑光，只是浅色块）
	for lx in [700.0, 1250.0]:
		draw_line(Vector2(lx, top + 46), Vector2(lx, top + 150), el2, Ink.W3)
		var shade := PackedVector2Array([Vector2(lx - 26, top + 172), Vector2(lx - 9, top + 150), Vector2(lx + 9, top + 150), Vector2(lx + 26, top + 172)])
		draw_colored_polygon(shade, Pal.c("equip_dark"))
		draw_polyline(shade, el, Ink.W2, true)
		Ink.disc(self, Vector2(lx, top + 174), 5.0, Pal.c("lamp"))
		draw_colored_polygon(PackedVector2Array([Vector2(lx - 24, top + 174), Vector2(lx + 24, top + 174), Vector2(lx + 190, fl), Vector2(lx - 190, fl)]), Color(Pal.c("lamp"), 0.07))
	# 货架：顶到天花板下面的重型货架，每层摆纸箱，在实验室里能看到上面几层
	var card := [Pal.c("equip_dark"), Pal.c("paper2").lerp(Pal.c("equip_dark"), 0.35)]
	if Pal.dark:
		card = [Pal.c("equip_dark").lerp(wall, 0.6), Pal.c("equip").lerp(wall, 0.65)]
	for si in RACKS.size():
		var x: float = RACKS[si][0]
		var w: float = RACKS[si][1]
		var rtop := top + 70.0 + (si % 2) * 30.0
		Ink.ground(self, x - 4, x + w + 4, fl)
		draw_rect(Rect2(x, rtop, 5, fl - rtop), Pal.c("equip_dark"))
		draw_rect(Rect2(x + w - 5, rtop, 5, fl - rtop), Pal.c("equip_dark"))
		Ink.frame(self, Rect2(x, rtop, w, fl - rtop), el2, Ink.W2)
		var y := fl - 8.0
		var k := 0
		while y - TIER > rtop - 4:
			draw_rect(Rect2(x, y - 4, w, 4), Pal.c("orange").lerp(wall, 0.55))
			draw_line(Vector2(x, y - 4), Vector2(x + w, y - 4), el2, Ink.W3)
			var n := 1 + (si + k) % 3
			var bx := x + 9.0
			for b in n:
				var bw := 26.0 + float((si * 11 + k * 7 + b * 5) % 16)
				var bh := 28.0 + float((si * 5 + k * 3 + b) % 3) * 7.0
				if bx + bw > x + w - 8:
					break
				var br := Rect2(bx, y - 4 - bh, bw, bh)
				Ink.box(self, br, card[(si + k + b) % 2], el2, Ink.W3, si * 7 + k * 3 + b)
				if (si + k + b) % 3 == 0:
					draw_rect(Rect2(br.position.x + bw * 0.5 - 3, br.position.y, 6, bh), Pal.c("gold").lerp(wall, 0.6))
				bx += bw + 6.0
			y -= TIER
			k += 1
	# 墙上的楼层牌
	var sign := Rect2(Geo.LIFT_X + Geo.LIFT_HW + 22, fl - 330, 92, 44)
	Ink.drop(self, sign)
	Ink.box(self, sign, Pal.c("paper"), el, Ink.W2, 77)
	Ink.text(self, "B1", sign.position + Vector2(12, 32), 26, Pal.c("text"), Pal.bold)
	Ink.text(self, "· 地下储藏室", sign.position + Vector2(52, 28), 13, Pal.c("text2"), Pal.font)
	_lost_box(el)
	if not is_open():
		Ink.text(self, "地下储藏室 · 尚未开放", Vector2(1640, top + 210), 15, Color(Pal.c("ink2"), 0.5), Pal.hand)

## 失物招领箱：敞口纸箱，伸出一把伞、一条围巾、一只马克杯；墙上贴手写告示
func _lost_box(el: Color) -> void:
	var r := lost_rect()
	var wob := sin(t * 38.0) * box_bump * 0.05
	var c := Vector2(r.get_center().x, r.end.y)
	# 告示
	var note := Rect2(r.position.x + 6, r.position.y - 200, 128, 74)
	Ink.drop(self, note)
	draw_set_transform(note.get_center(), -0.03)
	var nr := Rect2(-note.size * 0.5, note.size)
	draw_rect(nr, Pal.c("paper"))
	Ink.frame(self, nr, Color(el, 0.7), Ink.W3)
	draw_rect(Rect2(nr.position + Vector2(48, -6), Vector2(32, 12)), Color(Pal.c("gold"), 0.5))
	Ink.text(self, "失物招领", nr.position + Vector2(64, 28), 18, Pal.c("text"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "每局只能领取一件", nr.position + Vector2(64, 52), 13, Pal.c("text2"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	if drawn():
		Ink.text(self, "本局已经领取", nr.position + Vector2(64, 70), 12, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	draw_set_transform(c, wob)
	# 伸出来的东西（在箱子后面）
	draw_line(Vector2(-40, -80), Vector2(-14, -150), Pal.c("equip_dark"), 4.0, true)        # 伞
	draw_arc(Vector2(-42, -76), 8.0, 0, PI, 10, Pal.c("equip_dark"), 4.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -150), Vector2(-36, -132), Vector2(-4, -126)]), Pal.c("blue"))
	draw_colored_polygon(PackedVector2Array([Vector2(8, -86), Vector2(30, -112), Vector2(44, -104), Vector2(24, -80)]), Pal.c("red").lerp(Pal.c("paper"), 0.2))   # 围巾
	Ink.box(self, Rect2(30, -110, 26, 28), Pal.c("paper2"), el, Ink.W3, 9)                   # 马克杯
	draw_arc(Vector2(58, -96), 7.0, -PI * 0.5, PI * 0.5, 8, el, Ink.W3, true)
	# 箱子
	var br := Rect2(-r.size.x * 0.5, -r.size.y, r.size.x, r.size.y)
	Ink.box(self, br, Pal.c("equip").lerp(Pal.c("orange"), 0.25), el, Ink.W2, 41)
	draw_colored_polygon(PackedVector2Array([br.position, br.position + Vector2(-16, -18), br.position + Vector2(30, -14), br.position + Vector2(34, 0)]), Pal.c("equip").lerp(Pal.c("orange"), 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(br.end.x, br.position.y), Vector2(br.end.x + 16, br.position.y - 18), Vector2(br.end.x - 30, br.position.y - 14), Vector2(br.end.x - 34, br.position.y)]), Pal.c("equip").lerp(Pal.c("orange"), 0.15))
	draw_rect(Rect2(br.position.x + br.size.x * 0.5 - 4, br.position.y, 8, br.size.y), Pal.c("gold").lerp(Pal.c("equip"), 0.4))
	Ink.text(self, "LOST & FOUND", Vector2(0, -30), 12, Color(el, 0.8), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

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
