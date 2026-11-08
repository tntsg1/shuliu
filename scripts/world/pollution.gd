extends Node2D
## 饰品标签“污染”：观测舱里按持有物品的标签留下痕迹（DECISIONS 视觉硬规则）。
## 只改画面、不进数值；不碰价值通道（亮度/束团/层数）和危险通道（偏心/抖动/红橙/裂纹），
## 所以这里的东西不随能级、丢失概率变化，只随“持有几件该标签物品”变浓。
## 1 件淡、2 件明显、3 件以上满。

var main: Node
var chamber: Node2D
var t := 0.0
var lv := {}          # 标签 -> 当前浓度（弹簧平滑，买卖时慢慢浮现/褪去）
var _lvv := {}
var scraps: Array = []

const LEVELS := [0.0, 0.45, 0.75, 1.0]

func _ready() -> void:
	_init_stains()
	_init_doodles()
	_init_seals()
	for i in 14:
		scraps.append({"ph": randf() * TAU, "sp": randf_range(0.35, 0.6) * (1.0 if i % 3 else -1.0),
			"r": randf_range(0.55, 0.95), "w": randf_range(13, 21), "h": randf_range(9, 15),
			"tone": [Color("#fbf7ee"), Color("#f4e6a6"), Color("#e2ebf2"), Color("#fbf7ee")][i % 4],
			"spin": randf_range(-3, 3), "rest": Vector2(randf_range(-200, 200), randf_range(100, 128)),
			"rest_rot": randf_range(-0.6, 0.6), "lines": 1 + randi() % 3})

func _init_stains() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 7:
		stains.append({"p": Vector2(rng.randf_range(-230, 230), rng.randf_range(-100, 100)), "r": rng.randf_range(14, 30),
			"a0": rng.randf() * TAU, "span": rng.randf_range(4.2, 6.0), "k": i / 7.0, "drip": rng.randf() < 0.4})

func level(tag: String) -> float:
	return lv.get(tag, 0.0)

var hand := 0.0          # 钟表：指针位置（格），弹簧追加速次数
var _vhand := 0.0
var stains: Array = []
var doodles: Array = []     # 文具：铅笔涂鸦 [{pts, k}]
var crumbs: Array = []
var seals: Array = []      # 证章：舱玻璃上的红章

func _process(dt: float) -> void:
	t += dt
	if main == null or main.run == null:
		return
	var cnt := {}
	for id in main.run.devices + main.run.relics:
		var tg: String = Items.tag_of(id)
		if tg != "":
			cnt[tg] = cnt.get(tg, 0) + 1
	for tg in Items.TAGS:
		var target: float = LEVELS[mini(cnt.get(tg, 0), 3)]
		var r := Ink.spring(lv.get(tg, 0.0), _lvv.get(tg, 0.0), target, 3.0, dt)
		lv[tg] = r[0]
		_lvv[tg] = r[1]
	var presses: int = main.run.beam.presses if main.run.beam != null else 0
	var rr := Ink.spring(hand, _vhand, float(presses), 9.0, dt)
	hand = rr[0]
	_vhand = rr[1]
	queue_redraw()

func _draw() -> void:
	if chamber == null:
		return
	var h: Vector2 = Geo.CH_SIZE * 0.5
	var cf := level("咖啡")
	if cf > 0.01:
		_coffee(h, cf)
	var sl := level("证章")
	if sl > 0.01:
		_seals(h, sl)
	var st := level("文具")
	if st > 0.01:
		_stationery(h, st)
	var ck := level("钟表")
	if ck > 0.01:
		_clock(h, ck)
	var p := level("纸张")
	if p > 0.01:
		_paper(h, p)

## 纸张：便签贴在舱玻璃角上；纸屑跟着束流绕圈，舱空时落在舱底
func _paper(h: Vector2, p: float) -> void:
	var ink := Pal.equip_line()
	var paper := Pal.c("paper")
	var live: float = clampf(chamber.appear, 0.0, 1.0)
	# 纸屑
	var n := int(round(4.0 + 10.0 * p))
	for i in mini(n, scraps.size()):
		var s: Dictionary = scraps[i]
		var al := clampf(p * 1.6, 0.0, 1.0) * (0.75 + 0.25 * (1.0 - live))
		# 先画两道拖影（只有束流在转时才有），再画本体
		for g in [2, 1, 0]:
			if g > 0 and live < 0.2:
				continue
			var a: float = s.ph + (t - g * 0.05) * s.sp
			var orbit := Vector2(cos(a) * h.x * 0.78 * s.r, sin(a) * h.y * 0.62 * s.r)
			var pos: Vector2 = s.rest.lerp(orbit, live)
			var rot: float = lerpf(s.rest_rot, a * 1.7 + (t - g * 0.05) * s.spin, live)
			# 纸片在气流里翻面：横向缩放
			var flip := lerpf(1.0, absf(cos((t - g * 0.05) * s.spin * 0.8 + i)), live) * 0.8 + 0.2
			var ga: float = al * (1.0 if g == 0 else 0.22 / float(g))
			draw_set_transform(pos, rot, Vector2(flip, 1.0))
			var r := Rect2(-s.w * 0.5, -s.h * 0.5, s.w, s.h)
			if g == 0:
				draw_rect(Rect2(r.position + Vector2(1.5, 2), r.size), Color(0, 0, 0, 0.1 * ga))
			draw_rect(r, Color(s.tone, ga))
			if g == 0:
				draw_rect(r, Color(ink, ga * 0.75), false, 1.1)
				for k in s.lines:
					var yy: float = -s.h * 0.28 + k * 3.4
					draw_line(Vector2(-s.w * 0.36, yy), Vector2(s.w * (0.3 - 0.12 * k), yy), Color(ink, ga * 0.5), 1.0)
	draw_set_transform(Vector2.ZERO)
	# 便签：贴在玻璃内侧的角落，按浓度 1–3 张
	var notes := [
		{"p": Vector2(-h.x + 110, -h.y + 34), "r": -0.12, "c": Color("#f2d65a"), "k": 0.0},
		{"p": Vector2(h.x - 120, h.y - 40), "r": 0.1, "c": Color("#f0b8a8"), "k": 0.5},
		{"p": Vector2(h.x - 170, -h.y + 40), "r": 0.08, "c": Color("#bfe0c4"), "k": 0.8},
	]
	for i in notes.size():
		var nt: Dictionary = notes[i]
		var a := clampf((p - nt.k) / 0.2, 0.0, 1.0)
		if a <= 0.0:
			continue
		# 边角被舱里的气流吹得轻轻掀动
		var lift := (0.5 + 0.5 * sin(t * 2.3 + i * 1.7)) * live
		draw_set_transform(nt.p, nt.r, Vector2.ONE * (0.6 + 0.4 * a))
		var r := Rect2(-17, -17, 34, 34)
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.12 * a))
		draw_rect(r, Color(nt.c, 0.92 * a))
		draw_rect(Rect2(-17, -17, 34, 6), Color(nt.c.darkened(0.1), 0.92 * a))
		var fold := 7.0 + 4.0 * lift
		_tri(Vector2(17 - fold, 17), Vector2(17, 17 - fold), Vector2(17 - fold * 0.9, 17 - fold * 0.9), Color(nt.c.darkened(0.25), a))
		draw_rect(r, Color(ink, 0.6 * a), false, 1.0)
		for k in 3:
			var y := -6.0 + k * 7.0
			draw_line(Vector2(-11, y), Vector2(7 - k * 4, y + sin(k + i) * 1.5), Color(ink, 0.55 * a), 1.2, true)
	draw_set_transform(Vector2.ZERO)

## 咖啡：玻璃上一圈圈杯底印（不闭合的褐色圆环，环边颜色更深）+ 顺着玻璃往下淌的一道
func _coffee(h: Vector2, p: float) -> void:
	var brown := Color("#8a5a3a")
	for s in stains:
		var a := clampf((p - s.k * 0.85) / 0.15, 0.0, 1.0)
		if a <= 0.0:
			continue
		var c: Vector2 = s.p
		draw_circle(c, s.r, Color(brown, 0.06 * a))
		draw_arc(c, s.r, s.a0, s.a0 + s.span, 40, Color(brown, 0.45 * a), 2.6, true)
		draw_arc(c, s.r - 2.5, s.a0 + 0.3, s.a0 + s.span - 0.4, 40, Color(brown, 0.18 * a), 1.2, true)
		if s.drip:
			var top: Vector2 = c + Vector2(0, s.r)
			var L: float = 24.0 + 16.0 * sin(s.a0 * 3.0)
			draw_line(top, top + Vector2(1.5, L), Color(brown, 0.35 * a), 2.2, true)
			draw_circle(top + Vector2(1.5, L + 1), 2.6, Color(brown, 0.4 * a))

## 钟表：舱玻璃内侧一圈表盘刻度；一枚指针沿刻度走，每加速一次走一格
func _clock(h: Vector2, p: float) -> void:
	var ink := Pal.equip_line()
	var inset := 8.0
	var n := 60
	for i in n:
		var u := float(i) / n
		var a := clampf(p * 1.4 - (0.35 if i % 5 != 0 else 0.0), 0.0, 1.0)
		if a <= 0.0:
			continue
		var big := i % 5 == 0
		var pt := _stadium_pt(h, u, inset)
		var nrm := _stadium_pt(h, u, inset + 1.0) - pt
		var L := 12.0 if big else 6.0
		draw_line(pt, pt + nrm.normalized() * L, Color(ink, (0.8 if big else 0.45) * a), 2.6 if big else 1.3)
		if big and p > 0.6:
			var num := str(12 if i == 0 else i / 5)
			Ink.text(self, num, pt + nrm.normalized() * 24.0 + Vector2(0, 4), 11, Color(ink, 0.6 * clampf((p - 0.6) / 0.25, 0.0, 1.0)), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	# 指针：小红三角，每次加速走一格（满 60 格绕回）
	var u2 := fposmod(hand / 60.0, 1.0)
	var hp := _stadium_pt(h, u2, inset + 12.0)
	var nn := (_stadium_pt(h, u2, inset + 13.0) - hp).normalized()
	var tg := nn.orthogonal()
	var col := Color(Pal.c("red"), clampf(p * 1.6, 0.0, 1.0))
	_tri(hp + nn * 3.0, hp - nn * 14.0 + tg * 7.0, hp - nn * 14.0 - tg * 7.0, col)

## 胶囊形舱壁上的点：u 0..1 顺时针（从顶边中点出发），inset 向内缩进
func _stadium_pt(h: Vector2, u: float, inset: float) -> Vector2:
	var r := h.y - inset
	var hx := h.x - h.y
	var straight := 2.0 * hx
	var arc := PI * r
	var per := 2.0 * straight + 2.0 * arc
	var d := fposmod(u, 1.0) * per
	# 顶边中点 → 顶边右端
	if d < hx:
		return Vector2(d, -r)
	d -= hx
	if d < arc:
		var a := -PI / 2 + d / r
		return Vector2(hx, 0) + Vector2.from_angle(a) * r
	d -= arc
	if d < straight:
		return Vector2(hx - d, r)
	d -= straight
	if d < arc:
		var a2 := PI / 2 + d / r
		return Vector2(-hx, 0) + Vector2.from_angle(a2) * r
	d -= arc
	return Vector2(-hx + d, -r)

## 三角形直接画，不走三角化（小三角在缩放后容易被判为退化）
func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col, col, col]), PackedVector2Array())

func _init_doodles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# 几种手写痕迹：螺旋、划掉的算式、箭头、圈圈
	var spots := [Vector2(-190, -70), Vector2(150, -88), Vector2(205, 40), Vector2(-120, 70), Vector2(40, -105)]
	for i in spots.size():
		var c: Vector2 = spots[i]
		var pts := PackedVector2Array()
		match i % 4:
			0:
				for k in 40:
					var a := k * 0.45
					pts.append(c + Vector2(cos(a), sin(a) * 0.7) * (2.0 + k * 0.45))
			1:
				for k in 9:
					pts.append(c + Vector2(k * 7.0 - 28.0, (6.0 if k % 2 else -6.0) + rng.randf_range(-2, 2)))
			2:
				pts = PackedVector2Array([c + Vector2(-26, 8), c + Vector2(-6, -2), c + Vector2(14, -8), c + Vector2(26, -12), c + Vector2(18, -18), c + Vector2(26, -12), c + Vector2(20, -4)])
			3:
				for k in 26:
					var a := k * TAU / 22.0
					pts.append(c + Vector2(cos(a) * 18.0, sin(a) * 11.0) + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5)))
		doodles.append({"pts": pts, "k": i / float(spots.size())})
	for i in 16:
		crumbs.append({"p": Vector2(rng.randf_range(-210, 210), rng.randf_range(118, 132)), "r": rng.randf_range(-1, 1), "l": rng.randf_range(4, 9)})

## 文具：铅笔涂鸦（一笔一笔描出来）+ 舱底一把透明尺 + 橡皮屑
func _stationery(h: Vector2, p: float) -> void:
	var ink := Pal.equip_line()
	var pencil := Color("#5a5f6a")
	# 涂鸦：按浓度逐个“画出来”
	for d in doodles:
		var a := clampf((p - d.k * 0.8) / 0.25, 0.0, 1.0)
		if a <= 0.0:
			continue
		var pts: PackedVector2Array = d.pts
		var n := int(round(pts.size() * a))
		if n >= 2:
			draw_polyline(pts.slice(0, n), Color(pencil, 0.55), 1.4, true)
	# 透明尺：贴在舱底玻璃上
	var ra := clampf(p * 2.0, 0.0, 1.0)
	var r := Rect2(-170, h.y - 44, 300, 18)
	draw_set_transform(Vector2.ZERO, -0.03)
	draw_rect(r, Color(Color("#e9e2c8"), 0.55 * ra))
	draw_rect(r, Color(ink, 0.5 * ra), false, 1.0)
	for i in 31:
		var x := r.position.x + 8 + i * 9.5
		var L := 8.0 if i % 5 == 0 else 4.0
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + L), Color(ink, 0.55 * ra), 1.0)
	draw_set_transform(Vector2.ZERO)
	# 橡皮屑：浓度高了才有
	var ca := clampf((p - 0.6) / 0.3, 0.0, 1.0)
	if ca > 0.0:
		for c in crumbs:
			var q: Vector2 = c.p
			draw_line(q, q + Vector2.from_angle(c.r) * c.l, Color("#c9a0a0", 0.8 * ca), 2.6, true)

func _init_seals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var words := ["合格", "已审", "同意", "作废", "存档", "加急", "复核", "批准", "待定"]
	# 沿舱玻璃一圈靠边放，别挡中间的束流
	var spots := [Vector2(-200, -88), Vector2(178, 82), Vector2(-60, -104), Vector2(222, -40), Vector2(-226, 50),
		Vector2(90, -100), Vector2(-150, 98), Vector2(40, 104), Vector2(-246, -20)]
	for i in spots.size():
		seals.append({"p": spots[i], "rot": rng.randf_range(-0.6, 0.6), "r": rng.randf_range(17, 25),
			"round": rng.randf() < 0.6, "word": words[i], "k": i / float(spots.size()), "gap": rng.randf() * TAU,
			"ink": rng.randf_range(0.35, 0.6)})

## 证章：歪歪扭扭的红章盖满舱玻璃；浓度上来时一个个“啪”地盖上（先大后小）
func _seals(h: Vector2, p: float) -> void:
	var red := Pal.c("red")
	for sd in seals:
		var a := clampf((p - sd.k * 0.9) / 0.1, 0.0, 1.0)
		if a <= 0.0:
			continue
		var sc := lerpf(1.5, 1.0, Ink.ease_out_cubic(a))
		var col := Color(red, sd.ink * a)
		draw_set_transform(sd.p, sd.rot, Vector2(sc, sc))
		var r: float = sd.r
		if sd.round:
			# 印泥不匀：圆环断开一小段
			draw_arc(Vector2.ZERO, r, sd.gap, sd.gap + TAU - 0.5, 40, col, 2.6, true)
			draw_arc(Vector2.ZERO, r - 4.0, 0, TAU, 40, Color(col, col.a * 0.6), 1.0, true)
			var pts := PackedVector2Array()
			for i in 10:
				var rr := 6.0 if i % 2 == 0 else 2.6
				pts.append(Vector2.from_angle(-PI / 2 + i * PI / 5) * rr + Vector2(0, -5))
			draw_colored_polygon(pts, col)
			Ink.text(self, sd.word, Vector2(0, 11), 9, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var w := r * 2.2
			draw_rect(Rect2(-w * 0.5, -r * 0.55, w, r * 1.1), col, false, 2.4)
			Ink.text(self, sd.word, Vector2(0, 6), 14, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
