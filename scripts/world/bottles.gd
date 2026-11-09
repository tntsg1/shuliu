extends Node2D
## 束流配额气瓶架（DECISIONS Q63）：每次评审，经费处配给 3 瓶离子源氢气——这就是“3 束束流”的来历。
## 注入：架子上取一瓶，沿弧线飞进注入器；提前提交：没用的瓶子退回，折成经费（飘“+$”）；新一次评审：三瓶依次落进架子。
## 架子上的瓶数 = 本阶段剩余实验 −（舱里正在跑的那一束）。

const RACK := Rect2(288, 676, 126, 124)
const INLET := Vector2(262, 668)      # 注入器底座的进气口
const PITCH := 30.0

var main: Node
var shown := 0                 # 架子上稳定显示的瓶数
var drops := {}                # 槽位 -> 落下进度（<0 = 还在等）
var flying: Array = []         # {p0, p1, t, kind, label}
var hold := 0.0                # 退回动画期间，新瓶子晚一点再落
var _sig := []
var t := 0.0

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

func slot_pos(i: int) -> Vector2:
	return Vector2(RACK.position.x + 18.0 + i * PITCH, RACK.end.y - 8.0)

func _want() -> int:
	if main == null or main.run == null:
		return 0
	var r: Run = main.run
	if r.failed or r.won():
		return 0
	return clampi(r.experiments_left - (1 if r.beam != null else 0), 0, 4)

## 提前提交：n 瓶退回，换来 amount 经费（Run.submit 之后马上调）
func refund(n: int, amount: int) -> void:
	for i in mini(n, shown):
		flying.append({"p0": slot_pos(i), "p1": Vector2(RACK.position.x - 40.0 - i * 30.0, RACK.position.y - 260.0), "t": -i * 0.12, "kind": "refund",
			"label": ("+$%d" % amount) if i == 0 else ""})
	shown = 0
	drops.clear()
	hold = 0.9

func _process(dt: float) -> void:
	t += dt
	hold = maxf(0.0, hold - dt)
	var want := _want()
	if want < shown:
		for i in range(shown - 1, want - 1, -1):
			flying.append({"p0": slot_pos(i), "p1": INLET, "t": 0.0, "kind": "take", "label": ""})
			drops.erase(i)
		shown = want
		Sfx.play("metal", -14.0, 1.4)
	elif want > shown and hold <= 0.0:
		for i in range(shown, want):
			drops[i] = -(i - shown) * 0.18
		shown = want
	var anim := not flying.is_empty() or not drops.is_empty()
	for k in drops.keys():
		var before: float = drops[k]
		drops[k] = before + dt / 0.45
		if before < 0.75 and drops[k] >= 0.75:
			Sfx.play("metal", -16.0, 1.6 + k * 0.1)
		if drops[k] >= 1.0:
			drops.erase(k)
	for f in flying:
		f.t += dt / (0.7 if f.kind == "take" else 1.1)
	flying = flying.filter(func(f): return f.t < 1.0)
	var s := [shown, Pal.dark, main.run.stage if main and main.run else 0]
	if anim or s != _sig:
		_sig = s
		queue_redraw()

func _draw() -> void:
	var el := Pal.equip_line()
	# 架子：底板 + 两根立柱 + 一道防倒链
	Ink.box(self, Rect2(RACK.position.x, RACK.end.y - 8, RACK.size.x, 8), Pal.c("equip_dark"), el, 1.2, 501)
	Ink.box(self, Rect2(RACK.position.x, RACK.position.y + 20, 6, RACK.size.y - 28), Pal.c("equip_dark"), el, 1.0, 502)
	Ink.box(self, Rect2(RACK.end.x - 6, RACK.position.y + 20, 6, RACK.size.y - 28), Pal.c("equip_dark"), el, 1.0, 503)
	# 进气管：架子 → 注入器底座
	Ink.pl(self, PackedVector2Array([Vector2(RACK.position.x + 3, RACK.position.y + 40), Vector2(INLET.x + 14, RACK.position.y + 40), Vector2(INLET.x + 14, INLET.y)]), el, 3.0)
	Ink.pl(self, PackedVector2Array([Vector2(RACK.position.x + 3, RACK.position.y + 40), Vector2(INLET.x + 14, RACK.position.y + 40), Vector2(INLET.x + 14, INLET.y)]), Pal.c("equip"), 1.4)
	for i in shown:
		var p := slot_pos(i)
		var k: float = drops.get(i, 1.0)
		if k < 0.0:
			continue
		var e := Ink.ease_out_back(clampf(k, 0.0, 1.0))
		_bottle(p + Vector2(0, -(1.0 - e) * 160.0), 1.0, 0.0, clampf(k * 3.0, 0.0, 1.0))
	# 防倒链（压在瓶子前面）
	draw_line(Vector2(RACK.position.x + 3, RACK.position.y + 62), Vector2(RACK.end.x - 3, RACK.position.y + 62), Color(el, 0.7), 1.6, true)
	Ink.sticker(self, "本轮配额：3 瓶", Vector2(RACK.get_center().x, RACK.position.y + 8), -0.03, 10)
	for f in flying:
		var k: float = f.t
		if k < 0.0:
			continue
		var e := Ink.ease_in_out(k)
		var p: Vector2 = f.p0.lerp(f.p1, e) + Vector2(0, -sin(e * PI) * (90.0 if f.kind == "take" else 40.0))
		var sc := lerpf(1.0, 0.45, e) if f.kind == "take" else 1.0
		var a := 1.0 - clampf((k - 0.75) / 0.25, 0.0, 1.0)
		_bottle(p, sc, (e * 1.2) if f.kind == "take" else -e * 0.4, a)
		if f.label != "":
			Ink.text(self, f.label, f.p0 + Vector2(95, -170 - k * 60.0), 24, Color(Pal.c("green"), a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)

## 一瓶氢气：淡绿瓶身、红字“氢”、黑色瓶阀；p 是瓶底中心
func _bottle(p: Vector2, sc: float, rot: float, a: float) -> void:
	if a <= 0.0:
		return
	var el := Pal.equip_line()
	draw_set_transform(p, rot, Vector2(sc, sc))
	var w := 22.0
	var h := 92.0
	var body := Color("#9fc9a3")
	draw_rect(Rect2(-w * 0.5 + 3, -h + 4, w, h), Color(0, 0, 0, 0.12 * a))
	draw_rect(Rect2(-w * 0.5, -h, w, h), Color(body, a))
	Ink.disc(self, Vector2(0, -h), w * 0.5, Color(body, a))
	draw_rect(Rect2(-w * 0.5, -h, 5, h), Color(1, 1, 1, 0.25 * a))
	Ink.frame(self, Rect2(-w * 0.5, -h, w, h), Color(el, a), 1.2)
	draw_arc(Vector2(0, -h), w * 0.5, PI, TAU, 14, Color(el, a), 1.2, true)
	# 瓶肩色环 + 阀门
	draw_rect(Rect2(-w * 0.5, -h + 6, w, 5), Color(Pal.c("red"), 0.8 * a))
	draw_rect(Rect2(-4, -h - w * 0.5 - 10, 8, 10), Color(el, a))
	draw_rect(Rect2(-8, -h - w * 0.5 - 13, 16, 4), Color(el, a))
	Ink.text(self, "氢", Vector2(0, -h * 0.42), 13, Color(Pal.c("red"), a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
