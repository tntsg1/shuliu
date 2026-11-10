extends Node2D
## 氢气瓶流程的道具（Q70）：注入器旁的空瓶回收站、注入器上的瓶座、审核台旁的储备柜。
## 回收站 · 注入器 · 气瓶架挨在左边一排（全手动换瓶，走一两步就到）；储备柜放审核台右边。
## 满瓶的画法 full_bottle() 也放这里：透明玻璃瓶里装着这一束的缩小形态，贴纸写科研点。

const BIN := Rect2(90, 728, 52, 72)          # 空瓶回收站（注入器左边）
const CRADLE := Vector2(246, 800)            # 注入器瓶座（瓶底中心）
const CAB := Rect2(1556, 640, 60, 160)       # 储备柜（审核台右边），两格
const CAB_SLOTS := 2

var main: Node
var bin_n := 0           # 回收站里堆了几个空瓶（只是好看）
var t := 0.0
var _sig := []

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

func _process(dt: float) -> void:
	t += dt
	var s := [_inj(), _cab().size(), bin_n, Pal.dark]
	if s != _sig:
		_sig = s
		queue_redraw()

func _inj() -> String:
	return main.run.inj if main != null and main.run != null else ""

func _cab() -> Array:
	return main.run.cab if main != null and main.run != null else []

func _draw() -> void:
	var el := Pal.equip_line()
	var inj := _inj()
	var cab := _cab()
	# —— 空瓶回收站：一只铁皮桶，桶口露出几只空瓶的瓶颈 ——
	var b := BIN
	Ink.ground(self, b.position.x, b.end.x)
	for i in mini(bin_n, 3):
		var x := b.position.x + 14.0 + i * 12.0
		draw_set_transform(Vector2(x, b.position.y + 4), -0.25 + i * 0.22)
		draw_rect(Rect2(-5, -18, 10, 22), Color("#9fc9a3").darkened(0.15))
		Ink.frame(self, Rect2(-5, -18, 10, 22), el, Ink.W3)
		draw_rect(Rect2(-3, -24, 6, 6), el)
		draw_set_transform(Vector2.ZERO)
	var drum := PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), Vector2(b.end.x - 4, b.end.y), Vector2(b.position.x + 4, b.end.y)])
	Ink.poly(self, drum, Pal.c("equip_dark"), el, Ink.W1, 701)
	draw_rect(Rect2(b.position.x + 5, b.position.y + 3, 4, b.size.y - 6), Color(1, 1, 1, 0.22))
	for k in 2:
		var yy := b.position.y + 22.0 + k * 26.0
		draw_line(Vector2(b.position.x + 2, yy), Vector2(b.end.x - 2, yy), Color(el, 0.6), Ink.W2)
	Ink.box(self, Rect2(b.position.x - 3, b.position.y - 4, b.size.x + 6, 6), Pal.c("equip"), el, Ink.W2, 702)
	Ink.text(self, "空瓶回收", Vector2(b.get_center().x + 6, b.position.y - 34), 13, Pal.c("ink2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
	# —— 注入器瓶座：一只卡箍 + 软管接到进气口 ——
	var c := CRADLE
	Ink.box(self, Rect2(c.x - 16, c.y - 8, 32, 8), Pal.c("equip_dark"), el, Ink.W2, 703)
	if inj == "full":
		full_bottle(self, Vector2(c.x, c.y - 8), 1.0, main.run.inj_bt)
	elif inj != "":
		_bottle(c, inj == "empty")
		# 软管：瓶阀 → 注入器底座
		var vt := Vector2(c.x, c.y - 8 - 92 - 11 - 10)
		Ink.pl(self, PackedVector2Array([vt, vt + Vector2(0, -12), Vector2(c.x + 30, vt.y - 12), Vector2(c.x + 30, Geo.BEAMY + 118)]), el, 3.2)
		Ink.pl(self, PackedVector2Array([vt, vt + Vector2(0, -12), Vector2(c.x + 30, vt.y - 12), Vector2(c.x + 30, Geo.BEAMY + 118)]), Pal.c("equip"), 1.4)
	Ink.box(self, Rect2(c.x - 14, c.y - 56, 28, 6), Pal.c("equip_dark"), el, Ink.W2, 704)
	# —— 储备柜：铁皮柜，两格玻璃门，满瓶立在里面 ——
	var r := CAB
	Ink.ground(self, r.position.x, r.end.x)
	Ink.box(self, r, Pal.c("equip"), el, Ink.W1, 705)
	draw_rect(Rect2(r.position.x + 3, r.position.y + 3, 4, r.size.y - 6), Color(1, 1, 1, 0.22))
	var cell_h := (r.size.y - 30.0) / CAB_SLOTS
	for i in CAB_SLOTS:
		var cr := Rect2(r.position.x + 8, r.position.y + 22 + i * cell_h, r.size.x - 16, cell_h - 6)
		draw_rect(cr, Pal.c("inner1"))
		if i < cab.size():
			var bt: Dictionary = cab[i]
			full_bottle(self, Vector2(cr.get_center().x, cr.end.y - 2), 0.5, bt)
		# 玻璃门：一条斜高光 + 门框
		draw_line(cr.position + Vector2(6, cr.size.y - 6), cr.position + Vector2(cr.size.x - 10, 6), Color(1, 1, 1, 0.3), 3.0)
		Ink.frame(self, cr, el, Ink.W2)
		Ink.rivet(self, Vector2(cr.end.x - 4, cr.get_center().y), 1.6)
	Ink.text(self, "储备柜", Vector2(r.get_center().x, r.position.y + 15), 12, Pal.c("ink2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

## 一只新氢气瓶 / 空瓶（瓶底中心 p）：和气瓶架上的同款，空瓶颜色发灰、瓶肩色环褪掉
func _bottle(p: Vector2, empty: bool) -> void:
	var el := Pal.equip_line()
	var w := 22.0
	var h := 92.0
	var body := Color("#9fc9a3")
	if empty:
		body = body.lerp(Pal.c("equip_dark"), 0.6)
	draw_rect(Rect2(p.x - w * 0.5, p.y - 8 - h, w, h), body)
	Ink.disc(self, Vector2(p.x, p.y - 8 - h), w * 0.5, body)
	draw_rect(Rect2(p.x - w * 0.5 + 2, p.y - 8 - h, 4, h), Color(1, 1, 1, 0.22))
	Ink.frame(self, Rect2(p.x - w * 0.5, p.y - 8 - h, w, h), el, Ink.W2)
	draw_arc(Vector2(p.x, p.y - 8 - h), w * 0.5, PI, TAU, 14, el, Ink.W2, true)
	if not empty:
		draw_rect(Rect2(p.x - w * 0.5, p.y - 8 - h + 6, w, 5), Color(Pal.c("red"), 0.8))
	draw_rect(Rect2(p.x - 4, p.y - 8 - h - w * 0.5 - 10, 8, 10), el)
	Ink.text(self, "空" if empty else "氢", Vector2(p.x, p.y - 8 - h * 0.42), 13, Pal.c("ink2") if empty else Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)

## 满瓶（Q4）：透明玻璃瓶，里面是这一束的缩小形态（束芯 + 两道轨道），瓶身贴纸写科研点。
## bt = {value, energy, col}；p 是瓶底中心，sc 缩放
static func full_bottle(ci: CanvasItem, p: Vector2, sc: float, bt: Dictionary) -> void:
	var el := Pal.equip_line()
	var w := 26.0 * sc
	var h := 96.0 * sc
	var top := p.y - h
	var e: int = int(bt.get("energy", 5))
	var col: Color = Pal.ramp(clampf((e - 1) / 12.0, 0.0, 1.0))
	# 玻璃：很淡的冷色 + 左侧高光
	ci.draw_rect(Rect2(p.x - w * 0.5, top, w, h), Color(Pal.c("paper"), 0.55))
	Ink.disc(ci, Vector2(p.x, top), w * 0.5, Color(Pal.c("paper"), 0.55))
	# 缩小形态：束芯随能级变大，两道轨道
	var cc := Vector2(p.x, top + h * 0.45)
	var cr := (3.0 + minf(e, 15) * 0.45) * sc
	var orb := Color(col, 0.8)
	ci.draw_arc(cc, cr * 2.2, 0, TAU, 24, orb, maxf(1.0, 1.4 * sc), true)
	ci.draw_set_transform(cc, 0.9, Vector2(1.0, 0.45))
	ci.draw_arc(Vector2.ZERO, cr * 2.6, 0, TAU, 24, orb, maxf(1.0, 1.6 * sc), true)
	ci.draw_set_transform(Vector2.ZERO)
	Ink.disc(ci, cc, cr, col)
	Ink.disc(ci, cc + Vector2(-cr * 0.35, -cr * 0.35), cr * 0.35, Color(1, 1, 1, 0.45))
	ci.draw_rect(Rect2(p.x - w * 0.5 + 2, top, 3.0 * sc + 1, h), Color(1, 1, 1, 0.3))
	Ink.frame(ci, Rect2(p.x - w * 0.5, top, w, h), el, Ink.W2)
	ci.draw_arc(Vector2(p.x, top), w * 0.5, PI, TAU, 14, el, Ink.W2, true)
	ci.draw_rect(Rect2(p.x - 4 * sc, top - w * 0.5 - 10 * sc, 8 * sc, 10 * sc), el)
	# 贴纸：科研点
	var lab := Rect2(p.x - w * 0.5 - 2, top + h * 0.72, w + 4, 13.0 * sc + 4)
	ci.draw_rect(lab, Pal.c("paper"))
	Ink.frame(ci, lab, el, Ink.W3)
	Ink.text(ci, str(bt.get("value", 0)), Vector2(p.x, lab.end.y - 3), int(maxf(8.0, 12.0 * sc)), Pal.c("ink"), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
