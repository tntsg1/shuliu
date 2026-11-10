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
# —— 搬瓶手感（用户 2026-11-09：拿、放、装、拆要有手感和音效）——
var flyers: Array = []         # 正在飞的瓶子 {kind, bt, p0, p1, t, dur, arc, spin, done}
var pops: Array = []           # 飘字 {text, p, t, col}
var puffs: Array = []          # 装瓶时阀口喷出的一小团气 {p, v, t}
var bin_wob := 0.0             # 回收站被砸中后晃
var clamp_t := 1.0             # 卡箍：0 松开 → 1 锁紧
var clamp_goal := 1.0
var door_t := 0.0              # 储备柜门开合 0..1
var door_goal := 0.0
var door_close_at := -1.0
var hide_inj := 0.0            # 瓶子还在飞向瓶座：先别画在瓶座上
var hide_cab := 0.0
var fx: Node2D                 # 飞瓶、飘字画在主角上面

func _ready() -> void:
	Pal.changed.connect(queue_redraw)
	fx = Node2D.new()
	fx.z_index = 20
	add_child(fx)
	fx.draw.connect(_draw_fx)

## 一只瓶子从 p0 飞到 p1（世界坐标，瓶底中心）。kind: fresh / empty / full
func fly(kind: String, bt: Dictionary, p0: Vector2, p1: Vector2, dur := 0.28, delay := 0.0, arc := 26.0, spin := 0.0, done := Callable()) -> void:
	flyers.append({"kind": kind, "bt": bt, "p0": p0, "p1": p1, "t": -delay / dur, "dur": dur, "arc": arc, "spin": spin, "done": done})

func pop(text: String, p: Vector2, col: Color) -> void:
	pops.append({"text": text, "p": p, "t": 0.0, "col": col})

## 储备柜第 i 格的瓶底位置
func cab_slot(i: int) -> Vector2:
	var cell_h := (CAB.size.y - 30.0) / CAB_SLOTS
	return Vector2(CAB.get_center().x, CAB.position.y + 22 + i * cell_h + cell_h - 8)

func lock_clamp() -> void:
	clamp_t = 0.0
	clamp_goal = 1.0
	for i in 7:
		puffs.append({"p": Vector2(CRADLE.x + 2, CRADLE.y - 116), "v": Vector2(randf_range(-40, 40), randf_range(-70, -20)), "t": -0.12 - i * 0.02})

func open_clamp() -> void:
	clamp_goal = 0.0

func close_clamp() -> void:
	clamp_goal = 1.0

func open_door(close_after := 0.45) -> void:
	door_goal = 1.0
	door_close_at = t + close_after

func _process(dt: float) -> void:
	t += dt
	hide_inj = maxf(0.0, hide_inj - dt)
	hide_cab = maxf(0.0, hide_cab - dt)
	var anim := not flyers.is_empty() or not pops.is_empty() or not puffs.is_empty() or absf(bin_wob) > 0.002
	anim = anim or absf(clamp_t - clamp_goal) > 0.002 or absf(door_t - door_goal) > 0.002 or hide_inj > 0.0 or hide_cab > 0.0
	for f in flyers:
		f.t += dt / f.dur
		if f.t >= 1.0 and f.done.is_valid():
			var cb: Callable = f.done
			f.done = Callable()
			cb.call()
	flyers = flyers.filter(func(f): return f.t < 1.0)
	for q in pops:
		q.t += dt
	pops = pops.filter(func(q): return q.t < 1.1)
	for q in puffs:
		q.t += dt
		if q.t > 0.0:
			q.p += q.v * dt
			q.v *= 0.9
	puffs = puffs.filter(func(q): return q.t < 0.6)
	bin_wob = bin_wob * exp(-5.0 * dt)
	clamp_t = move_toward(clamp_t, clamp_goal, dt / 0.12)
	if door_close_at >= 0.0 and t >= door_close_at:
		door_goal = 0.0
		door_close_at = -1.0
		Sfx.play("cab_door", -10.0, 1.15)
	door_t = move_toward(door_t, door_goal, dt / 0.14)
	var s := [_inj(), _cab().size(), bin_n, Pal.dark]
	if s != _sig or anim:
		_sig = s
		queue_redraw()
	fx.queue_redraw()

func _draw_fx() -> void:
	for f in flyers:
		if f.t < 0.0:
			continue
		var k: float = clampf(f.t, 0.0, 1.0)
		var e := Ink.ease_in_out(k)
		var p: Vector2 = (f.p0 as Vector2).lerp(f.p1, e) + Vector2(0, -sin(e * PI) * float(f.arc))
		var rot: float = float(f.spin) * e
		if f.kind == "full":
			fx.draw_set_transform(p, rot)
			full_bottle(fx, Vector2.ZERO, 0.62, f.bt)
			fx.draw_set_transform(Vector2.ZERO)
		else:
			draw_bottle(fx, p, f.kind == "empty", 0.66, rot)
	for q in pops:
		var a := 1.0 - clampf((q.t - 0.7) / 0.4, 0.0, 1.0)
		var pp: Vector2 = q.p + Vector2(0, -40.0 * Ink.ease_out_cubic(minf(1.0, q.t / 0.8)))
		Ink.text(fx, q.text, pp, 20, Color(q.col, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	for q in puffs:
		if q.t <= 0.0:
			continue
		var a2: float = 1.0 - q.t / 0.6
		Ink.disc(fx, q.p, 3.0 + q.t * 14.0, Color(Pal.c("paper"), 0.55 * a2))

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
	var bx := Transform2D(bin_wob * sin(t * 38.0), Vector2(BIN.get_center().x, BIN.end.y))
	b = Rect2(BIN.position - Vector2(BIN.get_center().x, BIN.end.y), BIN.size)
	for i in mini(bin_n, 3):
		var x := b.position.x + 14.0 + i * 12.0
		draw_set_transform_matrix(bx * Transform2D(-0.25 + i * 0.22, Vector2(x, b.position.y + 4)))
		draw_rect(Rect2(-5, -18, 10, 22), Color("#9fc9a3").darkened(0.15))
		Ink.frame(self, Rect2(-5, -18, 10, 22), el, Ink.W3)
		draw_rect(Rect2(-3, -24, 6, 6), el)
	draw_set_transform_matrix(bx)
	var drum := PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), Vector2(b.end.x - 4, b.end.y), Vector2(b.position.x + 4, b.end.y)])
	Ink.poly(self, drum, Pal.c("equip_dark"), el, Ink.W1, 701)
	draw_rect(Rect2(b.position.x + 5, b.position.y + 3, 4, b.size.y - 6), Color(1, 1, 1, 0.22))
	for k in 2:
		var yy := b.position.y + 22.0 + k * 26.0
		draw_line(Vector2(b.position.x + 2, yy), Vector2(b.end.x - 2, yy), Color(el, 0.6), Ink.W2)
	Ink.box(self, Rect2(b.position.x - 3, b.position.y - 4, b.size.x + 6, 6), Pal.c("equip"), el, Ink.W2, 702)
	draw_set_transform(Vector2.ZERO)
	Ink.text(self, "空瓶回收", Vector2(BIN.get_center().x + 6, BIN.position.y - 34), 13, Pal.c("ink2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
	# —— 注入器瓶座：一只卡箍 + 软管接到进气口 ——
	var c := CRADLE
	Ink.box(self, Rect2(c.x - 16, c.y - 8, 32, 8), Pal.c("equip_dark"), el, Ink.W2, 703)
	if hide_inj > 0.0:
		pass
	elif inj == "full":
		full_bottle(self, Vector2(c.x, c.y - 8), 1.0, main.run.inj_bt)
	elif inj != "":
		_bottle(c, inj == "empty")
		# 软管：瓶阀 → 注入器底座
		var vt := Vector2(c.x, c.y - 8 - 92 - 11 - 10)
		Ink.pl(self, PackedVector2Array([vt, vt + Vector2(0, -12), Vector2(c.x + 30, vt.y - 12), Vector2(c.x + 30, Geo.BEAMY + 118)]), el, 3.2)
		Ink.pl(self, PackedVector2Array([vt, vt + Vector2(0, -12), Vector2(c.x + 30, vt.y - 12), Vector2(c.x + 30, Geo.BEAMY + 118)]), Pal.c("equip"), 1.4)
	# 卡箍：松开时抬高、张开一点；锁紧时一落到底
	var ck := Ink.ease_out_back(clamp_t)
	var cw := lerpf(34.0, 28.0, ck)
	Ink.box(self, Rect2(c.x - cw * 0.5, c.y - 56 - (1.0 - ck) * 16.0, cw, 6), Pal.c("equip_dark"), el, Ink.W2, 704)
	Ink.rivet(self, Vector2(c.x + cw * 0.5 - 3, c.y - 53 - (1.0 - ck) * 16.0), 1.4)
	# —— 储备柜：铁皮柜，两格玻璃门，满瓶立在里面 ——
	var r := CAB
	Ink.ground(self, r.position.x, r.end.x)
	Ink.box(self, r, Pal.c("equip"), el, Ink.W1, 705)
	draw_rect(Rect2(r.position.x + 3, r.position.y + 3, 4, r.size.y - 6), Color(1, 1, 1, 0.22))
	var cell_h := (r.size.y - 30.0) / CAB_SLOTS
	for i in CAB_SLOTS:
		var cr := Rect2(r.position.x + 8, r.position.y + 22 + i * cell_h, r.size.x - 16, cell_h - 6)
		draw_rect(cr, Pal.c("inner1"))
		if i < cab.size() and not (hide_cab > 0.0 and i == cab.size() - 1):
			var bt: Dictionary = cab[i]
			full_bottle(self, Vector2(cr.get_center().x, cr.end.y - 2), 0.5, bt)
		# 玻璃门：开门时门板往左转开（压成一条），关上时一条斜高光 + 门框
		var dw := cr.size.x * (1.0 - 0.85 * Ink.ease_in_out(door_t))
		var dr := Rect2(cr.position, Vector2(dw, cr.size.y))
		draw_rect(dr, Color(Pal.c("paper"), 0.12 + 0.2 * door_t))
		draw_line(dr.position + Vector2(4, dr.size.y - 6), dr.position + Vector2(maxf(4.0, dr.size.x - 8), 6), Color(1, 1, 1, 0.3), 3.0)
		Ink.frame(self, cr, Color(el, 0.5), Ink.W3)
		Ink.frame(self, dr, el, Ink.W2)
		Ink.rivet(self, Vector2(dr.end.x - 4, dr.get_center().y), 1.6)
	Ink.text(self, "储备柜", Vector2(r.get_center().x, r.position.y + 15), 12, Pal.c("ink2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

## 一只新氢气瓶 / 空瓶（瓶底中心 p）：和气瓶架上的同款，空瓶颜色发灰、瓶肩色环褪掉
func _bottle(p: Vector2, empty: bool) -> void:
	draw_bottle(self, p + Vector2(0, -8), empty, 1.0, 0.0)

## 一只新氢气瓶 / 空瓶（p0 = 瓶底中心，sc 缩放，rot 绕瓶底旋转）：和气瓶架上的同款，空瓶发灰、瓶肩色环褪掉
static func draw_bottle(ci: CanvasItem, p0: Vector2, empty: bool, sc: float, rot: float) -> void:
	var el := Pal.equip_line()
	var w := 22.0
	var h := 92.0
	var body := Color("#9fc9a3")
	if empty:
		body = body.lerp(Pal.c("equip_dark"), 0.6)
	ci.draw_set_transform(p0, rot, Vector2(sc, sc))
	ci.draw_rect(Rect2(-w * 0.5, -h, w, h), body)
	Ink.disc(ci, Vector2(0, -h), w * 0.5, body)
	ci.draw_rect(Rect2(-w * 0.5 + 2, -h, 4, h), Color(1, 1, 1, 0.22))
	Ink.frame(ci, Rect2(-w * 0.5, -h, w, h), el, Ink.W2)
	ci.draw_arc(Vector2(0, -h), w * 0.5, PI, TAU, 14, el, Ink.W2, true)
	if not empty:
		ci.draw_rect(Rect2(-w * 0.5, -h + 6, w, 5), Color(Pal.c("red"), 0.8))
	ci.draw_rect(Rect2(-4, -h - w * 0.5 - 10, 8, 10), el)
	Ink.text(ci, "空" if empty else "氢", Vector2(0, -h * 0.42), 13, Pal.c("ink2") if empty else Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	ci.draw_set_transform(Vector2.ZERO)

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
