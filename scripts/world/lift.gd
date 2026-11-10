extends Node2D
## 货梯（M5a）：采购终端和主环平面图之间的小货梯，实验室 ↔ 地下储藏室。
## 两根立柱 + 顶上的电机箱 + 两根钢缆吊着一块带警示条的平台；平台下去以后楼板上露出黑洞洞的井口。
## 没开放时立柱之间拉一条铁链，挂“维修中”的纸牌。plat_y 由 main 推动（坐货梯时主角站在平台上一起走）。

var main: Node
var plat_y := Geo.FLOOR         # 平台上表面的 y
var t := 0.0
var lamp := 0.0                 # 运行指示灯（运行时闪）
var running := false

const HEAD := 196.0             # 电机箱离实验室地面的高度

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func rect_lab() -> Rect2:
	return Rect2(Geo.LIFT_X - Geo.LIFT_HW - 6, Geo.FLOOR - HEAD - 20, Geo.LIFT_HW * 2 + 12, HEAD + 20)

func rect_b1() -> Rect2:
	return Rect2(Geo.LIFT_X - Geo.LIFT_HW - 6, Geo.B_FLOOR - HEAD, Geo.LIFT_HW * 2 + 12, HEAD)

func _draw() -> void:
	var el := Pal.equip_line()
	var x0 := Geo.LIFT_X - Geo.LIFT_HW
	var x1 := Geo.LIFT_X + Geo.LIFT_HW
	var open := Meta.storage_open()
	# 井：楼板开口 + 储藏室里的井道（平台不在上面时才看得见楼板上的洞）
	if plat_y > Geo.FLOOR + 1.0:
		draw_rect(Rect2(x0, Geo.FLOOR, x1 - x0, Geo.B_CEIL - Geo.FLOOR), Pal.c("equip_dark").darkened(0.35))
	draw_rect(Rect2(x0, Geo.B_CEIL, x1 - x0, Geo.B_FLOOR - Geo.B_CEIL), Color(0, 0, 0, 0.05))
	# 立柱：实验室一段、储藏室一段
	for seg in [[Geo.FLOOR - HEAD, Geo.FLOOR], [Geo.B_CEIL, Geo.B_FLOOR]]:
		for px in [x0 - 6.0, x1]:
			Ink.box(self, Rect2(px, seg[0], 6, seg[1] - seg[0]), Pal.c("equip_dark"), el, Ink.W2, int(px + seg[0]))
	# 电机箱 + 楼层牌
	var head := Rect2(x0 - 12, Geo.FLOOR - HEAD - 22, x1 - x0 + 24, 26)
	Ink.drop(self, head)
	Ink.box(self, head, Pal.c("equip"), el, Ink.W2, 5)
	Ink.disc(self, Vector2(Geo.LIFT_X - 18, head.get_center().y), 7.0, Pal.c("equip_dark"))
	Ink.disc(self, Vector2(Geo.LIFT_X + 18, head.get_center().y), 7.0, Pal.c("equip_dark"))
	var on := running and fmod(t, 0.5) < 0.25
	Ink.disc(self, Vector2(x1 + 2, head.position.y + 6), 3.0, Pal.c("orange") if on else Pal.c("equip_dark"))
	Ink.sticker(self, "货梯 ↓ B1", Vector2(Geo.LIFT_X, head.position.y - 14), -0.02, 11)
	# 钢缆
	for cx in [Geo.LIFT_X - 18.0, Geo.LIFT_X + 18.0]:
		draw_line(Vector2(cx, head.end.y), Vector2(cx, plat_y - 4), el, Ink.W3)
	# 平台：钢板 + 黄黑警示条 + 两侧扶手
	var pr := Rect2(x0 + 2, plat_y, x1 - x0 - 4, 12)
	draw_rect(Rect2(pr.position + Vector2(0, 4), pr.size), Color(0, 0, 0, 0.12))
	draw_rect(pr, Pal.c("equip"))
	var sx := pr.position.x
	var k := 0
	while sx < pr.end.x:
		if k % 2 == 0:
			draw_rect(Rect2(sx, pr.position.y + 7, minf(10.0, pr.end.x - sx), 5), Pal.c("gold"))
		sx += 10.0
		k += 1
	Ink.frame(self, pr, el, Ink.W2)
	for rx in [pr.position.x + 3.0, pr.end.x - 3.0]:
		draw_line(Vector2(rx, plat_y), Vector2(rx, plat_y - 44), el, Ink.W2)
	draw_line(Vector2(pr.position.x + 3, plat_y - 44), Vector2(pr.end.x - 3, plat_y - 44), Color(el, 0.5), Ink.W3)
	# 呼叫按钮（实验室和储藏室各一个，在右立柱外侧）
	for by in [Geo.FLOOR - 112.0, Geo.B_FLOOR - 112.0]:
		var b := Rect2(x1 + 8, by, 14, 22)
		Ink.box(self, b, Pal.c("paper2"), el, Ink.W3, int(by))
		Ink.disc(self, b.get_center(), 3.6, Pal.c("red") if open else Pal.c("equip_dark"))
	if not open:
		# 没开放：铁链 + 维修牌
		var cy := Geo.FLOOR - 92.0
		var p0 := Vector2(x0 - 3, cy)
		var p1 := Vector2(x1 + 3, cy)
		var n := 9
		for i in n:
			var a := p0.lerp(p1, float(i) / n) + Vector2(0, sin(PI * i / n) * 14.0)
			var b2 := p0.lerp(p1, float(i + 1) / n) + Vector2(0, sin(PI * (i + 1) / n) * 14.0)
			draw_line(a, b2, Pal.c("equip_dark"), 3.0, true)
		var tag := Rect2(Geo.LIFT_X - 34, cy + 12, 68, 40)
		draw_set_transform(tag.get_center(), 0.05)
		var tr := Rect2(-tag.size * 0.5, tag.size)
		draw_rect(Rect2(tr.position + Vector2(2, 3), tr.size), Color(0, 0, 0, 0.12))
		draw_rect(tr, Pal.c("paper"))
		Ink.frame(self, tr, el, Ink.W3)
		Ink.text(self, "正在维修", Vector2(0, -2), 14, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, "暂未开放", Vector2(0, 15), 11, Pal.c("text2"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform(Vector2.ZERO)
