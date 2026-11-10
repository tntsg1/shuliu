extends Node2D
## 楼上的退休教授办公室（M5b）：和主实验室一样高的完整房间，爬墙边直梯穿过舱口上来。
## 左边一整面教授书架（按稀有度四格：普通 / 精良 / 稀有 / 传说，传说那格玻璃门挂锁，第一次通关后打开），
## 书脊就是还没借阅的饰品和设备，借走的书只剩一张借书卡插在空位上；右边办公桌上摊着合同，墙上挂教授的照片。
## 在实验室里只看得到书架和书桌的下半截（原来那条矮带），爬上来镜头才往上移。

var main: Node
var t := 0.0
var hot := ""             # 鼠标 / 站位指着的东西：shelf / desk
var _sig := ""

const SHELF := Rect2(300, Geo.O_CEIL + 120, 860, Geo.O_FLOOR - Geo.O_CEIL - 120)
const DESK := Rect2(1280, Geo.O_FLOOR - 64, 220, 64)
const ARCHIVE := Rect2(1580, Geo.O_FLOOR - 250, 110, 250)
const COLS := 4

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

func _process(dt: float) -> void:
	t += dt
	var sig := "%s|%s|%s|%s|%s" % [Meta.get_v("office_open", false), (Meta.get_v("unlocked", []) as Array).size(), Meta.get_v("clears", 0), hot, _contract_sig()]
	if sig != _sig:
		_sig = sig
		queue_redraw()

func _contract_sig() -> String:
	if main == null or main.run == null:
		return ""
	return main.run.group + main.run.challenge + str(main.run.can_sign())

## 书架上的 40 本（不在首局池里的物品），按稀有度分四格
static func shelf_items() -> Array:
	var cols: Array = [[], [], [], []]
	for id in Items.ALL:
		if Items.BASE.has(id) or id == "screw":
			continue
		cols[Items.ALL[id].rarity].append(id)
	return cols

func col_rect(c: int) -> Rect2:
	var w := SHELF.size.x / COLS
	return Rect2(SHELF.position.x + c * w, SHELF.position.y, w, SHELF.size.y)

func _draw() -> void:
	var el := Pal.equip_line()
	var el2 := Color(el, 0.75)
	var off := Pal.c("office")
	var top := Geo.O_CEIL
	var fl := Geo.O_FLOOR
	# 屋顶楼板 + 房间
	draw_rect(Rect2(0, top - 400, Geo.W, 400), Pal.c("bg"))
	_section(Rect2(0, top - 22, Geo.W, 22))
	draw_rect(Rect2(0, top, Geo.W, fl - top), off)
	# 护墙板
	draw_rect(Rect2(0, fl - 120, Geo.W, 120), off.darkened(0.05))
	draw_line(Vector2(0, fl - 120), Vector2(Geo.W, fl - 120), Color(el, 0.35), Ink.W3)
	if Pal.dark:
		for i in 6:
			Ink.disc(self, Vector2(1338, fl - 72), 60.0 + i * 50.0, Color(Pal.c("lamp"), 0.025))
	# 窗：一扇高窗，外面是夜空 / 白天的纸色
	var win := Rect2(1720, top + 90, 120, 200)
	Ink.box(self, win, Pal.c("screen") if Pal.dark else Pal.c("paper2"), el, Ink.W2, 11)
	draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), el2, Ink.W2)
	draw_line(Vector2(win.position.x, win.get_center().y), Vector2(win.end.x, win.get_center().y), el2, Ink.W2)
	_shelf(el, el2, off)
	_desk(el, el2)
	_archive(el, el2)
	# 天花板吊扇
	var fc := Vector2(860, top + 40)
	draw_line(Vector2(fc.x, top), fc, el2, Ink.W2)
	var sw := sin(t * 0.0) * 0.0
	Ink.box(self, Rect2(fc.x - 70, fc.y, 140, 6), Pal.c("equip_dark"), el2, Ink.W3, 3)
	Ink.disc(self, fc + Vector2(0, 3), 8.0 + sw, Pal.c("equip"))
	# 楼板（实验室天花板）+ 直梯穿过的检修口
	_section(Rect2(0, fl, Geo.W, 24))
	draw_rect(Rect2(Geo.LADDER_X - 30, fl, 60, 24), off.darkened(0.25))
	draw_line(Vector2(Geo.LADDER_X - 30, fl), Vector2(Geo.LADDER_X - 30, fl + 24), el, Ink.W2)
	draw_line(Vector2(Geo.LADDER_X + 30, fl), Vector2(Geo.LADDER_X + 30, fl + 24), el, Ink.W2)
	for hx in [Geo.LADDER_X - 27.0, Geo.LADDER_X + 22.0]:
		draw_rect(Rect2(hx, fl - 6, 5, 30), Pal.c("equip_dark"))
	# 舱口上方的扶手
	for hx in [Geo.LADDER_X - 22.0, Geo.LADDER_X + 22.0]:
		draw_line(Vector2(hx, fl), Vector2(hx, fl - 70), el, Ink.W2)
	draw_arc(Vector2(Geo.LADDER_X, fl - 70), 22.0, PI, TAU, 14, el, Ink.W2, true)
	if not Meta.get_v("office_open", false):
		Ink.text(self, "退休教授办公室 · 尚未开放", Vector2(1540, fl - 16), 15, Color(Pal.c("ink2"), 0.5), Pal.hand)
		# 实验室这边：梯子顶上挂一块“尚未开放”的牌子
		var tag := Rect2(Geo.LADDER_X - 30, fl + 40, 60, 34)
		draw_line(Vector2(Geo.LADDER_X - 14, fl + 24), tag.position + Vector2(16, 0), el, Ink.W3)
		draw_line(Vector2(Geo.LADDER_X + 14, fl + 24), tag.position + Vector2(44, 0), el, Ink.W3)
		draw_rect(tag, Pal.c("paper"))
		Ink.frame(self, tag, el, Ink.W3)
		Ink.text(self, "楼上", tag.position + Vector2(30, 15), 11, Pal.c("text2"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, "未开放", tag.position + Vector2(30, 29), 11, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)

func _shelf(el: Color, el2: Color, off: Color) -> void:
	var cols := shelf_items()
	var names := ["普通", "精良", "稀有", "传说"]
	var legend_open: bool = int(Meta.get_v("clears", 0)) >= 1
	var sh := SHELF
	Ink.drop(self, sh)
	draw_rect(sh, Pal.c("equip_dark").lerp(off, 0.35))
	Ink.frame(self, sh, el, Ink.W1)
	if hot == "shelf":
		Ink.frame(self, sh.grow(4), Color(Pal.c("gold"), 0.8), Ink.W2)
	var rows := 5
	var rh := (sh.size.y - 12) / rows
	for c in COLS:
		var cr := col_rect(c)
		if c > 0:
			draw_rect(Rect2(cr.position.x - 3, cr.position.y, 6, cr.size.y), Pal.c("equip_dark"))
		Ink.sticker(self, names[c], Vector2(cr.get_center().x, cr.position.y - 12), 0.0, 11, Icons.rarity_col(c).lerp(Pal.c("paper"), 0.55))
		var list: Array = cols[c]
		var per := int(ceil(list.size() / float(rows)))
		for r in rows:
			var shelf_y := cr.position.y + 6 + (r + 1) * rh
			var bx := cr.position.x + 12
			for k in per:
				var i := r * per + k
				if i >= list.size():
					break
				var id: String = list[i]
				var bw := 22.0 + float((i * 13 + c * 7) % 10)
				var h := rh * (0.62 + 0.04 * float((i * 37 + c * 11) % 7))
				if Meta.unlocked(id):
					# 借走了：空位上插一张借书卡
					var card := Rect2(bx + 2, shelf_y - 40, bw - 4, 34)
					draw_rect(card, Pal.c("paper"))
					Ink.frame(self, card, el2, Ink.W4)
					draw_line(card.position + Vector2(3, 10), card.position + Vector2(card.size.x - 3, 10), Color(Pal.c("red"), 0.6), 1.0)
				else:
					var col := Icons.rarity_col(c).lerp(off, 0.42 + 0.1 * ((i * 5) % 3))
					Ink.box(self, Rect2(bx, shelf_y - h, bw, h), col, el2, Ink.W3, i * 7 + c)
					draw_rect(Rect2(bx + 4, shelf_y - h + 10, bw - 8, 2), Color(Pal.c("paper"), 0.45))
					draw_rect(Rect2(bx + 4, shelf_y - 16, bw - 8, 2), Color(Pal.c("paper"), 0.3))
				bx += bw + 3.0
			# 剩下的空当：平放的一叠旧期刊 / 一个文件盒，书架不显得空
			var room := cr.end.x - 12 - bx
			if room > 60:
				var sx := bx + 10
				var sk := (r + c) % 3
				if sk == 0:
					for j in 3:
						var jw := room * (0.7 - j * 0.08)
						Ink.box(self, Rect2(sx + j * 3, shelf_y - 10 - j * 10, minf(jw, 110.0), 10), Pal.c("paper2").lerp(off, 0.3 + j * 0.1), el2, Ink.W4, r * 3 + j + c)
				elif sk == 1:
					Ink.box(self, Rect2(sx, shelf_y - rh * 0.55, minf(room - 20, 70.0), rh * 0.55), Pal.c("equip").lerp(off, 0.3), el2, Ink.W3, r + c * 5)
					draw_rect(Rect2(sx + 8, shelf_y - rh * 0.4, minf(room - 36, 40.0), 12), Pal.c("paper"))
				else:
					draw_set_transform(Vector2(sx + 6, shelf_y), -0.28)
					Ink.box(self, Rect2(0, -rh * 0.6, 24, rh * 0.6), Pal.c("equip_dark").lerp(off, 0.4), el2, Ink.W3, r + c)
					draw_set_transform(Vector2.ZERO)
		for r in rows:
			var y := cr.position.y + 6 + (r + 1) * rh
			Ink.box(self, Rect2(cr.position.x, y, cr.size.x, 6), Pal.c("equip_dark"), el2, Ink.W3, r + c * 9)
		if c == 3 and not legend_open:
			# 传说格：玻璃门 + 挂锁
			draw_rect(cr.grow(-6), Color(Pal.c("paper"), 0.28))
			Ink.frame(self, cr.grow(-6), el, Ink.W2)
			draw_line(cr.position + Vector2(18, 30), cr.position + Vector2(60, 120), Color(Pal.c("paper"), 0.6), 3.0)
			var lp := Vector2(cr.position.x + 10, cr.get_center().y)
			draw_arc(lp + Vector2(0, -8), 7.0, PI, TAU, 10, el, 2.4, true)
			Ink.box(self, Rect2(lp.x - 10, lp.y - 8, 20, 16), Pal.c("gold"), el, Ink.W3, 4)
			Ink.sticker(self, "首次通关后开放", Vector2(cr.get_center().x, cr.end.y - 26), 0.03, 10)
	Ink.sticker(self, "教授书架 · 使用声望借阅", Vector2(sh.get_center().x, sh.position.y - 44), -0.01, 13)

func _desk(el: Color, el2: Color) -> void:
	var d := DESK
	var fl := Geo.O_FLOOR
	# 墙上教授的照片（只画一个剪影，退休了）
	var ph := Rect2(d.position.x + 50, fl - 360, 110, 130)
	Ink.drop(self, ph)
	Ink.box(self, ph, Pal.c("paper"), el, Ink.W2, 21)
	var pc := ph.get_center() + Vector2(0, 10)
	Ink.disc(self, pc + Vector2(0, -22), 18.0, Pal.c("equip_dark"))
	draw_colored_polygon(PackedVector2Array([pc + Vector2(-34, 50), pc + Vector2(-26, 4), pc + Vector2(26, 4), pc + Vector2(34, 50)]), Pal.c("equip_dark"))
	Ink.text(self, "荣誉退休", ph.position + Vector2(ph.size.x * 0.5, ph.size.y + 18), 12, Pal.c("text2"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	# 书桌
	Ink.ground(self, d.position.x + 12, d.end.x - 12, fl)
	Ink.box(self, Rect2(d.position.x, d.position.y, d.size.x, 14), Pal.c("equip_dark"), el2, Ink.W2, 3)
	Ink.box(self, Rect2(d.position.x + 12, d.position.y + 14, 10, d.size.y - 14), Pal.c("equip_dark"), el2, Ink.W3, 4)
	Ink.box(self, Rect2(d.end.x - 22, d.position.y + 14, 10, d.size.y - 14), Pal.c("equip_dark"), el2, Ink.W3, 5)
	Ink.box(self, Rect2(d.end.x - 90, d.position.y + 14, 68, 30), Pal.c("equip"), el2, Ink.W3, 6)
	# 台灯
	var lx := d.position.x + 46
	Ink.poly(self, PackedVector2Array([Vector2(lx - 13, d.position.y - 30), Vector2(lx + 13, d.position.y - 30), Vector2(lx + 5, d.position.y - 46), Vector2(lx - 5, d.position.y - 46)]), Pal.c("lamp"), el2, Ink.W3, 6)
	draw_line(Vector2(lx, d.position.y - 30), Vector2(lx, d.position.y), el2, Ink.W2)
	# 合同：两叠文件夹（课题组 / 挑战），签了的盖红章
	var run: Run = main.run if main != null else null
	var signed := run != null and (run.group != "base" or run.challenge != "")
	for i in 2:
		var fr := Rect2(d.position.x + 84 + i * 56, d.position.y - 10 - i * 3, 50, 10)
		Ink.box(self, fr, Pal.c("paper2") if i == 0 else Pal.c("gold").lerp(Pal.c("paper"), 0.5), el2, Ink.W3, 30 + i)
	if signed:
		Ink.disc(self, Vector2(d.position.x + 150, d.position.y - 16), 6.0, Pal.c("red"))
	Ink.sticker(self, "合同", Vector2(d.position.x + 134, d.position.y - 30), -0.04, 11)
	if hot == "desk":
		Ink.frame(self, Rect2(d.position.x - 6, d.position.y - 50, d.size.x + 12, 56), Color(Pal.c("gold"), 0.8), Ink.W2)
	# 椅子
	Ink.box(self, Rect2(d.position.x + 110, fl - 46, 46, 8), Pal.c("equip"), el2, Ink.W3, 8)
	draw_line(Vector2(d.position.x + 133, fl - 38), Vector2(d.position.x + 133, fl), el2, Ink.W2)

func _archive(el: Color, el2: Color) -> void:
	var a := ARCHIVE
	Ink.drop(self, a)
	Ink.box(self, a, Pal.c("equip"), el, Ink.W2, 51)
	for i in 4:
		var dr := Rect2(a.position.x + 8, a.position.y + 10 + i * 59, a.size.x - 16, 52)
		Ink.frame(self, dr, el2, Ink.W3)
		draw_rect(Rect2(dr.get_center().x - 12, dr.position.y + 10, 24, 5), Pal.c("equip_dark"))
	Ink.sticker(self, "档案柜 · 整理中", Vector2(a.get_center().x, a.position.y - 12), 0.02, 10)

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
