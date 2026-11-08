class_name FormArt
extends RefCounted
## 束流形态的画法（观测舱和成果卡共用）。原则：饰品塑造束流，不替换束流——
## 主体永远是束芯 + 粒子 + 轨迹，路线只改轨迹形状、外围结构和散落的小东西。哑光平涂、墨线、不发光。
## 用法：FormArt.new().draw(画布, 中心, 缩放, 状态)
## 状态：route, tier, g(连续能级), t(秒), dmg(受损 0..1), legend, omen, traits, col(束流色), core_r, grow(变身弹出 0..1), card(成果卡里画，自带束芯)

var ci: CanvasItem
var o := Vector2.ZERO
var s := 1.0
var st: Dictionary
var t := 0.0
var dmg := 0.0
var ink := Color.BLACK
var col := Color.WHITE
var tilt := 0.0

const YARN := Color("#d9822b")
const YARN_D := Color("#a85a1c")
const TAN := Color("#e8c79a")
const NOTE := Color("#f2d45c")

func draw(canvas: CanvasItem, origin: Vector2, scale: float, state: Dictionary) -> void:
	ci = canvas
	o = origin
	st = state
	t = state.get("t", 0.0)
	dmg = state.get("dmg", 0.0)
	ink = Pal.c("ink")
	col = state.get("col", Pal.c("green"))
	var grow: float = state.get("grow", 1.0)
	s = scale * (0.55 + 0.45 * grow)
	tilt = dmg * 0.16 * sin(t * 1.3)
	var leg: String = state.get("legend", "")
	if state.get("card", false):
		_card_core()
	if leg != "":
		_legend(leg)
	else:
		match state.get("route", "std"):
			"paper": _paper(state.tier)
			"mascot": _mascot(state.tier)
			_: _std(state.tier)
	var om: float = state.get("omen", 0.0)
	if om > 0.01 and leg == "":
		_omen(om)
	for tr in state.get("traits", []):
		match tr:
			"saved": _saved()
			"synced": _synced()
			"crowned": _crowned()

# —— 坐标：局部 → 画布（受损时歪斜 + 抖动）——
func P(q: Vector2) -> Vector2:
	if dmg > 0.0:
		q = q.rotated(tilt) + Vector2(sin(q.y * 0.06 + t * 9.0) * 5.0, cos(q.x * 0.05 + t * 7.0) * 3.0) * dmg
	return o + q * s

func _poly(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(P(q))
	return out

func line(pts: PackedVector2Array, c: Color, w: float, outline := true) -> void:
	if pts.size() < 2:
		return
	var pp := _poly(pts)
	if outline:
		ci.draw_polyline(pp, Color(ink, c.a), (w + 2.2) * s, true)
	ci.draw_polyline(pp, c, w * s, true)

func fill(pts: PackedVector2Array, c: Color, ow := 1.6) -> void:
	var pp := _poly(pts)
	if Geometry2D.triangulate_polygon(pp).is_empty():
		return
	ci.draw_colored_polygon(pp, c)
	if ow > 0.0:
		var cl := pp.duplicate()
		cl.append(pp[0])
		ci.draw_polyline(cl, Color(ink, minf(1.0, c.a * 2.0)), ow * s, true)

func dot(q: Vector2, r: float, c: Color, ow := 1.0) -> void:
	ci.draw_circle(P(q), r * s, c)
	if ow > 0.0:
		ci.draw_arc(P(q), r * s, 0, TAU, 16, ink, ow * s, true)

func ellipse(c: Vector2, rx: float, ry: float, rot: float, n := 48, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts

func g() -> float:
	return st.get("g", 1.0)

## 档内成长 0..1
func inner(tier: int) -> float:
	match tier:
		0: return clampf((g() - 1.0) / 6.0, 0.0, 1.0)
		1: return clampf((g() - 7.0) / 6.0, 0.0, 1.0)
		_: return clampf((g() - 13.0) / 8.0, 0.0, 1.0)

# —— 成果卡：没有着色器，自己画一个束芯和两圈轨迹 ——
func _card_core() -> void:
	var v: float = clampf((g() - 1.0) / 12.0, 0.0, 1.0)
	for i in 2 + int(v * 2.0):
		line(ellipse(Vector2.ZERO, 70.0 + i * 26.0, 26.0 + i * 9.0, 0.5 + i * 0.9, 48), Color(col, 0.55), 1.4, false)
	var cr := 9.0 + v * 16.0
	dot(Vector2.ZERO, cr, col.lerp(Pal.c("paper"), 0.5), 1.6)
	ci.draw_arc(P(Vector2.ZERO), cr * 0.5 * s, 0, TAU, 20, Color(ink, 0.5), 1.0 * s, true)

# —— 标准：标准束团（着色器本身）→ 同步束 → 对撞之花 ——
func _std(tier: int) -> void:
	if tier == 0:
		return
	if tier == 1:
		var k := inner(1)
		var R := 150.0 + 40.0 * k
		var tw := 3 + int(k * 5.0)
		for side in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			for i in 97:
				var a := i / 96.0 * TAU
				var off: float = side * 11.0 * sin(tw * a + t * 2.2)
				pts.append(Vector2(cos(a) * (R + off), sin(a) * (R * 0.42 + off * 0.6)).rotated(-0.28))
			line(pts, Color(col, 0.9), 2.2)
			for j in 3:
				var a2: float = fmod(t * 0.9 * side + j * TAU / 3.0 + (0.0 if side > 0 else 0.5), TAU)
				var off2: float = side * 11.0 * sin(tw * a2 + t * 2.2)
				dot(Vector2(cos(a2) * (R + off2), sin(a2) * (R * 0.42 + off2 * 0.6)).rotated(-0.28), 4.0, col.lerp(Pal.c("paper"), 0.35))
		return
	# 对撞之花：k 片花瓣，越高能越多；成熟后期长出第二层
	var k2 := inner(2)
	var n := 5 + int(k2 * 4.0)
	var L := 112.0 + 18.0 * k2
	_petals(n, L, 34.0, t * 0.15, 0.32)
	if g() >= 16.0:
		_petals(n, L * 0.6, 22.0, t * 0.15 + PI / n, 0.45)

func _petals(n: int, L: float, W: float, rot: float, a: float) -> void:
	for i in n:
		var ang := rot + i * TAU / n
		var breath := 1.0 + 0.05 * sin(t * 2.0 + i)
		var pts := PackedVector2Array()
		for j in 13:
			var u := j / 12.0
			pts.append(Vector2(u * L * breath, W * sin(PI * u)))
		for j in range(11, 0, -1):
			var u := j / 12.0
			pts.append(Vector2(u * L * breath, -W * sin(PI * u)))
		var rp := PackedVector2Array()
		for q in pts:
			rp.append(Vector2(q.x, q.y).rotated(ang) * Vector2(1.0, 0.82))
		fill(rp, Color(col.lerp(Pal.c("paper"), 0.55), a), 1.5)
		# 花瓣中脉 = 一条轨迹，粒子沿着跑
		line(PackedVector2Array([Vector2.ZERO, (Vector2(L * breath * 0.92, 0).rotated(ang)) * Vector2(1.0, 0.82)]), Color(col, 0.8), 1.2, false)
		var u2 := fmod(t * 0.6 + i * 0.37, 1.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		dot(Vector2(u2 * L * breath, side * W * sin(PI * u2)).rotated(ang) * Vector2(1.0, 0.82), 3.4, col.lerp(Pal.c("paper"), 0.3))

# —— 纸张：纸团束 → 纸鹤束流 → 论文风暴 ——
func _page(c: Vector2, rot: float, sz: float, a := 1.0, tone := Color.WHITE) -> void:
	var w := 13.0 * sz
	var h := 17.0 * sz
	var squash := 0.35 + 0.65 * absf(cos(rot * 1.7))   # 翻滚：看起来一会儿正一会儿侧
	var pts := PackedVector2Array()
	for q in [Vector2(-w, -h), Vector2(w * 0.6, -h), Vector2(w, -h * 0.7), Vector2(w, h), Vector2(-w, h)]:
		pts.append(c + Vector2(q.x * squash, q.y).rotated(rot))
	var paper := Pal.c("paper") if tone == Color.WHITE else tone
	fill(pts, Color(paper, a), 1.2)
	if sz >= 0.8 and squash > 0.5:
		for i in 3:
			var y := -h * 0.5 + i * h * 0.4
			line(PackedVector2Array([c + Vector2(-w * 0.6 * squash, y).rotated(rot), c + Vector2(w * 0.6 * squash, y).rotated(rot)]), Color(ink, 0.45 * a), 0.8, false)

func _paper(tier: int) -> void:
	var k := inner(tier)
	if tier == 0:
		var n := clampi(int(round(g())), 1, 6)
		for i in n:
			var a := t * 0.7 + i * TAU / n
			var c := Vector2(cos(a) * 150.0, sin(a) * 62.0).rotated(-0.22)
			line(ellipse(Vector2.ZERO, 150.0, 62.0, -0.22, 10, a - 0.5, a - 0.05), Color(col, 0.5), 1.4, false)
			_page(c, t * (1.2 + i * 0.2) + i, 1.0 + 0.2 * k)
		return
	if tier == 1:
		_crane(1.0 + 0.3 * k)
		var n2 := 3 + int(k * 4.0)
		for i in n2:
			var a := -t * 0.8 + i * TAU / n2
			_page(Vector2(cos(a) * 205.0, sin(a) * 88.0).rotated(-0.15), t * 1.5 + i, 0.75)
		return
	# 论文风暴：漏斗形龙卷，远处的纸先画
	var N := 26 + int(k * 30.0)
	var back: Array = []
	var front: Array = []
	for i in N:
		var hh := float(i) / N
		var y := 118.0 - hh * 236.0
		var r := 34.0 + hh * (170.0 + 30.0 * k)
		var ph := t * (2.4 - hh * 0.9) + i * 2.39996
		var z := sin(ph)
		var e := {"c": Vector2(cos(ph) * r, y + z * 10.0), "rot": ph * 1.3 + i, "sz": 0.55 + 0.25 * (z + 1.0) * 0.5 + hh * 0.35, "z": z}
		(front if z > 0.0 else back).append(e)
	for e in back:
		_page(e.c, e.rot, e.sz, 0.75)
	for i in 4:
		var hh := (i + 0.5) / 4.0
		line(ellipse(Vector2(0, 118.0 - hh * 236.0), 34.0 + hh * (170.0 + 30.0 * k), 12.0 + hh * 8.0, 0.0, 40), Color(col, 0.55), 1.3, false)
	for e in front:
		_page(e.c, e.rot, e.sz, 1.0)

## 纸鹤：几块折面拼成，翅膀随加速扇动；一个束团沿着外轮廓跑
func _crane(sc: float) -> void:
	var flap := sin(t * 3.2)
	var body := PackedVector2Array([Vector2(-60, 6), Vector2(0, -16), Vector2(70, 4), Vector2(0, 30)])
	var neck := PackedVector2Array([Vector2(-40, 4), Vector2(-108, -58), Vector2(-96, -60), Vector2(-20, -6)])
	var head := PackedVector2Array([Vector2(-108, -58), Vector2(-130, -50), Vector2(-100, -66)])
	var tail := PackedVector2Array([Vector2(40, 0), Vector2(122, -54), Vector2(60, 12)])
	var wy := -78.0 - 34.0 * flap
	var wing1 := PackedVector2Array([Vector2(-26, -8), Vector2(10 + 6 * flap, wy), Vector2(36, -6)])
	var wing2 := PackedVector2Array([Vector2(-10, -4), Vector2(-40, wy * 0.7 + 10.0), Vector2(20, -10)])
	var pc := Pal.c("paper")
	for part in [wing2, tail, body, neck, head, wing1]:
		var q := PackedVector2Array()
		for p in part:
			q.append(p * sc)
		var shade := pc.darkened(0.08) if part == wing2 or part == tail else pc
		fill(q, Color(shade, 0.62), 1.6)
	# 折痕
	line(PackedVector2Array([Vector2(-60, 6) * sc, Vector2(70, 4) * sc]), Color(ink, 0.4), 0.8, false)
	# 轮廓上跑的束团
	var outline := PackedVector2Array([Vector2(-130, -50), Vector2(-108, -58), Vector2(-20, -6), Vector2(10 + 6 * flap, wy), Vector2(70, 4), Vector2(122, -54), Vector2(60, 12), Vector2(0, 30), Vector2(-60, 6), Vector2(-130, -50)])
	var u := fmod(t * 0.35, 1.0) * (outline.size() - 1)
	var i0 := int(u)
	dot(outline[i0].lerp(outline[i0 + 1], u - i0) * sc, 4.5, col.lerp(Pal.c("paper"), 0.3))

# —— 吉祥物：毛线球束 → 猫形轨迹 → 橘猫束流 ——
func yarn(pts: PackedVector2Array, w := 3.0, a := 1.0) -> void:
	line(pts, Color(YARN, a), w)
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(p + Vector2(-0.6, -0.8))
	line(hi, Color(YARN.lightened(0.35), 0.6 * a), w * 0.3, false)

func _ball(r: float, wraps: int) -> void:
	dot(Vector2.ZERO, r, Color(YARN, 0.28), 0.0)
	for i in wraps:
		var rot := i * 0.72 + t * 0.35 * (1.0 if i % 2 == 0 else -1.0)
		var asp := 0.3 + 0.7 * fmod(i * 0.618, 1.0)
		yarn(ellipse(Vector2.ZERO, r, r * asp, rot, 40), 2.2, 0.9)

func _strand(from: Vector2, length: float, wav: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 25:
		var u := i / 24.0
		pts.append(from + Vector2(u * length, sin(u * 9.0 + t * 2.5) * wav * u + u * u * 30.0))
	return pts

func _mascot(tier: int) -> void:
	var k := inner(tier)
	if tier == 0:
		var r := 30.0 + g() * 5.0
		_ball(r, 2 + int(round(g() * 1.2)))
		yarn(_strand(Vector2(r * 0.9, r * 0.3), 50.0 + g() * 18.0, 10.0), 2.4)
		return
	if tier == 1:
		# 毛线绕出猫头：圆脸 + 两只耳朵，尾巴从右下甩出来
		var R := 74.0 + 12.0 * k
		_ball(R * 0.42, 4)
		var head := PackedVector2Array()
		for i in 49:
			var a := i / 48.0 * TAU
			var bump := 0.0
			var p := Vector2(cos(a), sin(a) * 0.86) * R
			# 耳朵：在 -2.2 和 -0.95 附近把轮廓拉尖
			for ea in [-2.2, -0.95]:
				var d := absf(wrapf(a - ea, -PI, PI))
				bump += maxf(0.0, 1.0 - d / 0.32) * (34.0 + 8.0 * k)
			head.append(p + p.normalized() * bump)
		yarn(head, 3.0)
		# 胡须
		for sd in [-1.0, 1.0]:
			for j in 3:
				var y0 := 12.0 + j * 9.0
				yarn(PackedVector2Array([Vector2(sd * R * 0.45, y0), Vector2(sd * (R * 0.45 + 40.0 + 10 * k), y0 - 8.0 + j * 8.0)]), 1.2, 0.8)
		# 眼睛 = 两个束团，偶尔眨眼
		var blink := 1.0 if fmod(t, 3.4) > 0.12 else 0.15
		for sd in [-1.0, 1.0]:
			fill(ellipse(Vector2(sd * 26.0, -10.0), 6.0, 6.0 * blink, 0.0, 14), col.lerp(Pal.c("paper"), 0.3), 1.2)
		yarn(_tail(Vector2(R * 0.8, R * 0.5), 60.0 + 70.0 * k), 3.0)
		return
	# 橘猫束流：一只团着的橘猫（半透明，看得见底下的轨迹），尾巴是束流
	var sc := 1.0 + 0.15 * k
	var body := ellipse(Vector2(28, 34) * sc, 140.0 * sc, 72.0 * sc, 0.0, 40)
	fill(body, Color(YARN, 0.42), 2.2)
	for i in 3:
		line(ellipse(Vector2(40 + i * 34, 34) * sc, 26.0 * sc, 60.0 * sc, 0.0, 16, -2.3, -1.2), Color(YARN_D, 0.7), 2.4, false)
	var hc := Vector2(-104, -12) * sc
	var hr := 58.0 * sc
	var ear := PackedVector2Array()
	for sd in [-1.0, 1.0]:
		ear = PackedVector2Array([hc + Vector2(sd * 46 - 18, -30) * sc, hc + Vector2(sd * 40 - 2, -78) * sc, hc + Vector2(sd * 18 + 6, -44) * sc])
		fill(ear, Color(YARN, 0.6), 2.0)
	fill(ellipse(hc, hr, hr * 0.84, 0.0, 36), Color(YARN, 0.55), 2.2)
	# 眯眼、鼻子、胡须
	for sd in [-1.0, 1.0]:
		line(ellipse(hc + Vector2(sd * 22, -6) * sc, 9.0 * sc, 6.0 * sc, 0.0, 10, 0.2, PI - 0.2), Color(ink, 0.9), 1.4, false)
		for j in 2:
			line(PackedVector2Array([hc + Vector2(sd * 30, 14 + j * 8) * sc, hc + Vector2(sd * 76, 8 + j * 14) * sc]), Color(ink, 0.6), 1.0, false)
	dot(hc + Vector2(0, 8) * sc, 3.5 * sc, Pal.c("red").lightened(0.2), 1.0)
	# 前爪
	for j in 2:
		fill(ellipse(Vector2(-60 + j * 30, 96) * sc, 16.0 * sc, 9.0 * sc, 0.0, 16), Color(YARN, 0.75), 1.6)
	# 尾巴 = 束流：一路粒子往尾尖跑
	var tail := _tail(Vector2(150, 40) * sc, 120.0 + 40.0 * k)
	line(tail, Color(col, 0.95), 7.0 * sc)
	for j in 5:
		var u := fmod(t * 0.8 + j * 0.2, 1.0)
		var idx := int(u * (tail.size() - 1))
		dot(tail[idx], 3.6, col.lerp(Pal.c("paper"), 0.4))

func _tail(from: Vector2, length: float) -> PackedVector2Array:
	var sw := sin(t * 2.4)
	var pts := PackedVector2Array()
	for i in 25:
		var u := i / 24.0
		var a := -1.1 - u * 2.2 * (1.0 + 0.25 * sw)
		pts.append(from + Vector2(u * length * 0.55, -u * length * 0.5) + Vector2(cos(a), sin(a)) * u * u * 26.0)
	return pts

# —— 附加称号 ——
func _saved() -> void:
	var cr: float = st.get("core_r", 20.0)
	for sd in [-1.0, 1.0]:
		var rot: float = sd * 0.62
		var w := cr * 1.25
		var h := cr * 0.42
		var pts := PackedVector2Array([Vector2(-w, -h).rotated(rot), Vector2(w, -h).rotated(rot), Vector2(w, h).rotated(rot), Vector2(-w, h).rotated(rot)])
		fill(pts, Color(TAN, 0.95), 1.4)
		fill(PackedVector2Array([Vector2(-h, -h * 0.7).rotated(rot), Vector2(h, -h * 0.7).rotated(rot), Vector2(h, h * 0.7).rotated(rot), Vector2(-h, h * 0.7).rotated(rot)]), Color(TAN.darkened(0.15), 0.95), 0.0)
		for j in 2:
			ci.draw_circle(P(Vector2(-w * 0.62 + j * w * 1.24, 0).rotated(rot)), 1.3 * s, Color(ink, 0.5))

func _synced() -> void:
	var a := t * 0.8
	for i in 3:
		var rx := 246.0 - i * 13.0
		var ry := 128.0 - i * 9.0
		line(ellipse(Vector2.ZERO, rx, ry, 0.0, 72), Color(Pal.c("lock"), 0.7), 1.2, false)
		for j in 24:
			var th := a + j * TAU / 24.0
			var p := Vector2(cos(th) * rx, sin(th) * ry)
			var n := Vector2(cos(th) * rx, sin(th) * ry).normalized()
			line(PackedVector2Array([p - n * 3.5, p + n * 3.5]), Color(Pal.c("lock"), 0.85), 1.6, false)

func _crowned() -> void:
	var cr: float = st.get("core_r", 20.0)
	var y := -cr - 30.0 + sin(t * 2.0) * 3.0
	var pts := PackedVector2Array([Vector2(-22, 10), Vector2(-24, -10), Vector2(-12, 0), Vector2(0, -16), Vector2(12, 0), Vector2(24, -10), Vector2(22, 10)])
	var q := PackedVector2Array()
	for p in pts:
		q.append(p + Vector2(0, y))
	fill(q, Pal.c("gold"), 1.6)
	for x in [-12.0, 0.0, 12.0]:
		dot(Vector2(x, y + 4), 2.2, Pal.c("red"), 0.8)

# —— 预兆：越接近传说，轨迹越往里弯，中心多一个暗点 ——
func _omen(om: float) -> void:
	for i in 10:
		var pts := PackedVector2Array()
		for j in 21:
			var u := j / 20.0
			var r := lerpf(230.0, 30.0, u)
			var a := i * TAU / 10.0 + u * 2.4 * om - t * 0.5
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.5))
		line(pts, Color(ink, 0.45 * om), 1.4, false)
	dot(Vector2.ZERO, 3.0 + 9.0 * om, Color(ink, 0.7 * om), 0.0)

# —— 传说 ——
func _legend(id: String) -> void:
	match id:
		"blackhole": _blackhole()
		"bigbang": _bigbang()
		"foil": _foil()
		"door": _door()

func _blackhole() -> void:
	for i in 14:
		var pts := PackedVector2Array()
		for j in 25:
			var u := j / 24.0
			var r := lerpf(240.0, 26.0, u)
			var a := i * TAU / 14.0 + u * 3.4 - t * 0.7
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.5))
		line(pts, Color(col, 0.55), 1.3, false)
	for i in 3:
		line(ellipse(Vector2.ZERO, 64.0 + i * 16.0, 14.0 + i * 4.0, -0.18, 48), Color(col.lerp(Pal.c("orange"), 0.5), 0.8 - i * 0.2), 2.0 - i * 0.4, false)
	dot(Vector2.ZERO, 28.0, Color("#15130f"), 2.0)
	ci.draw_arc(P(Vector2.ZERO), 31.0 * s, 0, TAU, 32, Pal.c("paper"), 1.4 * s, true)
	# 便条
	var nc := Vector2(176, -84)
	var note := PackedVector2Array([nc + Vector2(-38, -32).rotated(0.12), nc + Vector2(38, -32).rotated(0.12), nc + Vector2(38, 32).rotated(0.12), nc + Vector2(-38, 32).rotated(0.12)])
	fill(note, NOTE, 1.2)
	Ink.text(ci, "别担心", P(nc + Vector2(0, 8)), int(19 * s), Pal.c("blue") if not Pal.dark else Color("#2f5d9e"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)

func _bigbang() -> void:
	var u := fmod(t / 2.4, 1.0)
	var a := 1.0 - u
	for i in 28:
		var ang := i * TAU / 28.0 + 0.1 * sin(i * 3.0)
		var r0 := u * 50.0
		var r1 := 40.0 + u * 230.0 * (0.7 + 0.3 * fmod(i * 0.618, 1.0))
		line(PackedVector2Array([Vector2(cos(ang), sin(ang) * 0.55) * r0, Vector2(cos(ang), sin(ang) * 0.55) * r1]), Color(col if i % 2 == 0 else Pal.c("gold"), 0.35 + 0.6 * a), 2.6, false)
	# 星系：小漩涡，炸开以后慢慢转
	for i in 12:
		var ang := i * 2.39996
		var rr := 60.0 + fmod(i * 47.0, 170.0)
		var c := Vector2(cos(ang) * rr, sin(ang) * rr * 0.5) * (0.7 + 0.3 * u)
		for arm in 2:
			var pts := PackedVector2Array()
			for j in 9:
				var v := j / 8.0
				var aa := arm * PI + v * 3.0 + t * 0.8
				pts.append(c + Vector2(cos(aa), sin(aa) * 0.6) * v * 9.0)
			line(pts, Color(col, 0.75), 1.0, false)
	dot(Vector2.ZERO, 6.0 + 26.0 * a * a, Pal.c("paper"), 1.6)

func _foil() -> void:
	# 舱里的立体束流被“抹平”：先盖一层舱底色，再画一张印着束流的纸片
	var cap := PackedVector2Array()
	for i in 41:
		var a := i / 40.0 * TAU
		cap.append(Vector2(cos(a) * 262.0, sin(a) * 138.0))
	fill(cap, Color(Pal.c("inner0"), 0.82), 0.0)
	var wv := sin(t * 1.6) * 8.0
	var sheet := PackedVector2Array([Vector2(-190, -16 + wv), Vector2(190, -26 - wv), Vector2(190, 14 - wv), Vector2(-190, 26 + wv)])
	fill(PackedVector2Array([sheet[0] + Vector2(6, 8), sheet[1] + Vector2(6, 8), sheet[2] + Vector2(6, 8), sheet[3] + Vector2(6, 8)]), Color(0, 0, 0, 0.15), 0.0)
	fill(sheet, Pal.c("paper"), 1.8)
	for i in 4:
		line(ellipse(Vector2(0, 0), 60.0 + i * 30.0, 4.0 + i, -0.03, 40), Color(col, 0.75), 1.2, false)
	dot(Vector2.ZERO, 6.0, col, 1.0)
	Ink.text(ci, "（二维）", P(Vector2(150, 44)), int(14 * s), Pal.c("text2"), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)

func _door() -> void:
	var fr := PackedVector2Array([Vector2(-54, -118), Vector2(54, -118), Vector2(54, 118), Vector2(-54, 118)])
	fill(fr, Color("#15130f"), 3.0)
	# 门缝里的光：黄色斜线
	for i in 9:
		var y := -110.0 + i * 26.0
		line(PackedVector2Array([Vector2(30, y), Vector2(52, y + 18)]), Color(NOTE, 0.9), 2.0, false)
	var open := 0.35 + 0.05 * sin(t * 0.9)
	var panel := PackedVector2Array([Vector2(-54, -118), Vector2(-54 + 108 * (1.0 - open), -108), Vector2(-54 + 108 * (1.0 - open), 108), Vector2(-54, 118)])
	fill(panel, Pal.c("paper2").darkened(0.15), 2.2)
	dot(Vector2(-54 + 108 * (1.0 - open) - 12, 6), 4.0, Pal.c("gold"), 1.2)
	fill(PackedVector2Array([Vector2(-30, -88), Vector2(-4, -88), Vector2(-4, -64), Vector2(-30, -64)]), Pal.c("paper"), 1.2)
	Ink.text(ci, "8", P(Vector2(-17, -69)), int(20 * s), Pal.c("ink"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
