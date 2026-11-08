extends Node2D
## 墙上探测屏：引出时“开花”的事件图谱（规整/爆发/污染三种品相，M1）

var tracks: Array = []      # 每条 {pts: PackedVector2Array, col: Color, w: float}
var towers := PackedFloat32Array()
var hits := PackedVector2Array()
var progress := 0.0         # 0..1 绘制进度
var playing := false
var style := "precise"
var idle_t := 0.0
var form := {}              # 这一束的形态：探测屏按它“重建成像”（和成果卡同一画法）
var art := FormArt.new()

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

## 生成一次事件。energy 越高径迹越多
func bloom(energy: int, kind: String, meme_id := "") -> void:
	style = kind
	tracks.clear()
	hits.clear()
	meme = meme_id
	meme_t = 0.0
	if meme != "":
		style = "precise"
		_bloom_meme(energy)
		towers.resize(48)
		for i in 48:
			towers[i] = 0.15 + 0.4 * pow(absf(sin(TAU * i / 48.0 * 2.0)), 6.0)
		progress = 0.0
		playing = true
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var R := Geo.SCREEN.size.y * 0.30
	var n := 14 + energy * 4
	if kind == "burst":
		n = 40 + energy * 7
	elif kind == "dirty":
		n = 24 + energy * 4
	for i in n:
		var a := 0.0
		var k := 0.0
		if kind == "precise":
			a = TAU * i / n
			k = (0.022 if i % 2 == 0 else -0.022) * (1.0 + (i % 3) * 0.3)
		elif kind == "burst":
			var jet := rng.randf() < 0.6
			a = (PI * 0.5 if rng.randf() < 0.5 else -PI * 0.5 + 0.6) + rng.randf_range(-0.45, 0.45) if jet else rng.randf() * TAU
			k = rng.randf_range(-0.05, 0.05)
		else:
			a = rng.randf() * TAU
			k = rng.randf_range(-0.09, 0.09)
		var pts := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		var th := a
		var steps := rng.randi_range(20, 55) if kind == "dirty" else 60
		for s in steps:
			th += k
			p += Vector2.from_angle(th) * R * 0.018
			if p.length() > R * 0.80:
				break
			pts.append(p)
		var col := Pal.ramp(clampf((energy - 1) / 12.0, 0.0, 1.0))
		if kind == "burst":
			col = [Pal.c("orange"), Pal.c("paper"), col][rng.randi() % 3]
		elif kind == "dirty":
			col = Pal.c("red") if rng.randf() < 0.5 else Pal.c("orange")
		tracks.append({"pts": pts, "col": col, "w": 0.9 if kind == "burst" else 0.7})
	towers.resize(48)
	for i in 48:
		var ang := TAU * i / 48.0
		var e := 0.0
		match kind:
			"precise": e = 0.15 + 0.5 * pow(absf(cos(ang * 3.0)), 8.0)
			"burst": e = 0.1 + rng.randf() * 0.3 + (0.7 if absf(sin(ang)) > 0.95 else 0.0) + (0.6 if absf(cos(ang + 0.6)) > 0.97 else 0.0)
			_: e = rng.randf() * 0.45
		towers[i] = e * clampf(0.5 + energy / 16.0, 0.5, 1.2)
	if kind == "dirty":
		for i in 220:
			hits.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf() * R * 0.8)
	progress = 0.0
	playing = true

func _process(dt: float) -> void:
	idle_t += dt
	meme_t += dt
	if meme != "" or not form.is_empty():
		queue_redraw()
	if playing:
		progress = minf(1.0, progress + dt / 1.35)
		queue_redraw()
	elif int(idle_t * 2.0) != int((idle_t - dt) * 2.0):
		queue_redraw()

func _draw() -> void:
	var s := Geo.SCREEN
	var bg := Pal.c("screen") if Pal.dark else Pal.c("paper")
	draw_rect(s, bg)
	var c := s.get_center()
	var R := s.size.y * 0.30
	var ink := Pal.c("paper") if Pal.dark else Pal.c("ink")
	# 探测器层
	for i in range(1, 5):
		draw_arc(c, R * 0.18 * i, 0, TAU, 64, Color(ink, 0.18), 0.5, true)
	draw_arc(c, R * 0.95, 0, TAU, 96, Color(ink, 0.2), 0.5, true)
	if tracks.is_empty():
		# 待机：扫描线 + 闪烁光标
		var y := s.position.y + fmod(idle_t * 30.0, s.size.y)
		draw_line(Vector2(s.position.x, y), Vector2(s.end.x, y), Color(ink, 0.12), 0.6)
		if int(idle_t * 2.0) % 2 == 0:
			draw_rect(Rect2(s.position.x + 10, s.end.y - 18, 6, 9), Color(ink, 0.6))
		draw_string(Pal.mono, Vector2(s.position.x + 20, s.end.y - 9), "DET-A READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(ink, 0.6))
		return
	var e := Ink.ease_out_cubic(progress)
	if meme == "" and not form.is_empty():
		_form_view(s, c, R, ink, e)
		return
	# 量能器塔
	for i in towers.size():
		var ang := TAU * i / towers.size()
		var r1 := R * 0.82
		var r2 := r1 + R * 0.55 * towers[i] * e
		var col := (Pal.c("red") if style == "dirty" else ink) if towers[i] > 0.55 else Pal.ramp(0.5)
		if style == "dirty":
			col = Pal.c("orange")
		draw_line(c + Vector2.from_angle(ang) * r1, c + Vector2.from_angle(ang) * r2, Color(col, 0.3 if meme != "" else 0.85), R * 0.075)
	# 径迹逐步生长
	for tr in tracks:
		var pts: PackedVector2Array = tr.pts
		var m := int(pts.size() * e)
		if m < 2:
			continue
		var sub := PackedVector2Array()
		for i in m:
			sub.append(c + pts[i])
		draw_polyline(sub, tr.col, tr.w, true)
	for hp in hits:
		if hp.length() < R * 0.8 * e:
			draw_rect(Rect2(c + hp, Vector2(1, 1)), Color(Pal.c("red"), 0.6))
	draw_circle(c, 3.0 + 3.0 * (1.0 - e), ink)
	if meme != "":
		_meme_extras(s, c, R, ink)
	draw_string(Pal.mono, Vector2(s.end.x - 92, s.end.y - 6), "EVT %05d" % (int(idle_t * 7) % 99999), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(ink, 0.6))
	if progress >= 1.0:
		playing = false

# —— 奇葩事件：径迹拼成梗图 ——
var meme := ""
var meme_t := 0.0

## 字形：在 [0,1]×[0,1] 的格子里用几笔折线写字（y 向下）
const GLYPH := {
	"6": [[[0.85, 0.08], [0.45, 0.02], [0.12, 0.3], [0.08, 0.7], [0.3, 0.97], [0.7, 0.97], [0.92, 0.72], [0.8, 0.5], [0.45, 0.45], [0.12, 0.62]]],
	"2": [[[0.1, 0.28], [0.3, 0.04], [0.7, 0.04], [0.9, 0.28], [0.85, 0.48], [0.1, 1.0], [0.95, 1.0]]],
	"0": [[[0.5, 0.0], [0.15, 0.2], [0.08, 0.5], [0.15, 0.82], [0.5, 1.0], [0.85, 0.82], [0.92, 0.5], [0.85, 0.2], [0.5, 0.0]]],
	"5": [[[0.9, 0.02], [0.18, 0.02], [0.12, 0.45], [0.55, 0.38], [0.88, 0.6], [0.78, 0.92], [0.4, 1.0], [0.08, 0.88]]],
	".": [[[0.4, 0.92], [0.6, 0.92], [0.6, 1.0], [0.4, 1.0], [0.4, 0.92]]],
	"<": [[[0.9, 0.25], [0.1, 0.6], [0.9, 0.95]]],
	"p": [[[0.15, 0.35], [0.15, 1.15]], [[0.15, 0.45], [0.45, 0.32], [0.8, 0.45], [0.82, 0.7], [0.5, 0.85], [0.15, 0.72]]],
	"Y": [[[0.0, 0.0], [0.5, 0.5], [1.0, 0.0]], [[0.5, 0.5], [0.5, 1.0]]],
	"D": [[[0.1, 0.0], [0.1, 1.0]], [[0.1, 0.0], [0.6, 0.05], [0.92, 0.5], [0.6, 0.95], [0.1, 1.0]]],
	"S": [[[0.9, 0.15], [0.5, 0.0], [0.12, 0.18], [0.25, 0.45], [0.75, 0.55], [0.9, 0.8], [0.5, 1.0], [0.08, 0.85]]],
	"Q": [[[0.5, 0.0], [0.12, 0.2], [0.05, 0.5], [0.12, 0.8], [0.5, 0.97], [0.88, 0.8], [0.95, 0.5], [0.88, 0.2], [0.5, 0.0]], [[0.6, 0.7], [1.05, 1.08]]],
	"H": [[[0.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [1.0, 1.0]], [[0.0, 0.5], [1.0, 0.5]]],
}

## 一串字 → 折线（中心 c、字高 h；坐标以 R 为单位）
func _text(s: String, c: Vector2, h: float) -> Array:
	var out: Array = []
	var w := h * 0.62
	var gap := h * 0.22
	var total := s.length() * w + (s.length() - 1) * gap
	var x0 := c.x - total * 0.5
	for i in s.length():
		var g: Array = GLYPH.get(s[i], [])
		for stroke in g:
			var pl := PackedVector2Array()
			for q in stroke:
				pl.append(Vector2(x0 + i * (w + gap) + q[0] * w, c.y - h * 0.5 + q[1] * h))
			out.append(pl)
	return out

func _ell(c: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, n := 28) -> PackedVector2Array:
	var pl := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pl.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pl

func _pl(pts: Array) -> PackedVector2Array:
	var pl := PackedVector2Array()
	for q in pts:
		pl.append(Vector2(q[0], q[1]))
	return pl

## 每种梗的笔画（单位：R；原点是屏幕中心）
func _meme_strokes(id: String) -> Array:
	match id:
		"woodfish":
			return [_ell(Vector2(-0.1, 0.1), 0.62, 0.42), _ell(Vector2(-0.45, 0.0), 0.07, 0.07), _pl([[0.05, 0.12], [0.45, 0.12]]),
				_pl([[0.95, -0.85], [0.35, -0.2]]), _ell(Vector2(0.98, -0.9), 0.1, 0.07)]
		"six":
			return _text("666", Vector2.ZERO, 1.0)
		"yyds":
			return _text("YYDS", Vector2.ZERO, 0.8)
		"thankq":
			return _text("Q", Vector2.ZERO, 1.3)
		"clam":
			return [_ell(Vector2(0, 0.15), 0.75, 0.45, 0.0, PI), _ell(Vector2(0, 0.1), 0.75, 0.6, PI + 0.35, TAU + 0.35),
				_ell(Vector2(0.05, 0.2), 0.14, 0.14)]
		"zundu":
			return [_ell(Vector2(-0.4, -0.15), 0.28, 0.28), _ell(Vector2(0.45, -0.1), 0.1, 0.1), _ell(Vector2(0.0, 0.55), 0.12, 0.1)]
		"rocket":
			return [_pl([[0.0, -0.95], [0.22, -0.55], [0.22, 0.35], [-0.22, 0.35], [-0.22, -0.55], [0.0, -0.95]]),
				_pl([[-0.22, 0.1], [-0.45, 0.45], [-0.22, 0.35]]), _pl([[0.22, 0.1], [0.45, 0.45], [0.22, 0.35]]),
				_ell(Vector2(0, -0.35), 0.09, 0.09), _pl([[-0.1, 0.4], [0.0, 0.95], [0.1, 0.4]])]
		"cpu":
			var cs: Array = [_pl([[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5], [-0.5, -0.5]]), _pl([[-0.22, -0.22], [0.22, -0.22], [0.22, 0.22], [-0.22, 0.22], [-0.22, -0.22]])]
			for i in 4:
				var o := -0.3 + i * 0.2
				cs.append(_pl([[o, -0.5], [o, -0.72]]))
				cs.append(_pl([[o, 0.5], [o, 0.72]]))
				cs.append(_pl([[-0.5, o], [-0.72, o]]))
				cs.append(_pl([[0.5, o], [0.72, o]]))
			return cs
		"retreat":
			var rs: Array = []
			for i in 6:
				var a := i * TAU / 6.0
				var d := Vector2.from_angle(a)
				var t2 := d.orthogonal()
				rs.append(PackedVector2Array([d * 0.95, d * 0.3]))
				rs.append(PackedVector2Array([d * 0.3 + (d + t2) * 0.15, d * 0.3, d * 0.3 + (d - t2) * 0.15]))
			return rs
		"sad":
			return [_ell(Vector2.ZERO, 0.8, 0.8), _ell(Vector2(-0.3, -0.2), 0.06, 0.06), _ell(Vector2(0.3, -0.2), 0.06, 0.06),
				_ell(Vector2(0, 0.55), 0.32, 0.2, PI + 0.4, TAU - 0.4), _pl([[0.32, -0.05], [0.28, 0.12], [0.34, 0.2], [0.38, 0.12], [0.32, -0.05]])]
		"champagne":
			return [_pl([[-0.18, 0.95], [-0.18, 0.0], [-0.08, -0.35], [-0.08, -0.6], [0.08, -0.6], [0.08, -0.35], [0.18, 0.0], [0.18, 0.95], [-0.18, 0.95]]),
				_pl([[-0.18, 0.35], [0.18, 0.35]]), _pl([[-0.1, -0.85], [0.1, -0.85], [0.08, -0.7], [-0.08, -0.7], [-0.1, -0.85]])]
		"broken":
			return [_pl([[0.0, -0.85], [0.65, -0.6], [0.6, 0.15], [0.0, 0.85], [-0.6, 0.15], [-0.65, -0.6], [0.0, -0.85]]),
				_pl([[0.05, -0.85], [-0.1, -0.4], [0.12, -0.1], [-0.08, 0.3], [0.05, 0.85]])]
		"p005":
			return _text("p<0.05", Vector2(0, 0.0), 0.62)
		"reviewer2":
			var r2: Array = _text("2", Vector2(-0.3, 0.0), 1.3)
			r2.append(_pl([[0.25, -0.35], [0.85, 0.35]]))
			r2.append(_pl([[0.85, -0.35], [0.25, 0.35]]))
			return r2
		"bug":
			var bs: Array = [_ell(Vector2(0, 0.1), 0.35, 0.55), _ell(Vector2(0, -0.58), 0.18, 0.15), _pl([[0.0, -0.45], [0.0, 0.65]]),
				_pl([[-0.08, -0.7], [-0.3, -0.95]]), _pl([[0.08, -0.7], [0.3, -0.95]])]
			for i in 3:
				var y := -0.15 + i * 0.3
				bs.append(_pl([[-0.33, y], [-0.7, y - 0.15]]))
				bs.append(_pl([[0.33, y], [0.7, y - 0.15]]))
			return bs
		"cat":
			return [_pl([[-0.75, -0.1], [0.75, -0.1], [0.75, 0.85], [-0.75, 0.85], [-0.75, -0.1]]),
				_pl([[-0.4, -0.1], [-0.45, -0.75], [-0.18, -0.48], [0.18, -0.48], [0.45, -0.75], [0.4, -0.1]]),
				_ell(Vector2(-0.18, -0.3), 0.05, 0.05), _ell(Vector2(0.18, -0.3), 0.05, 0.05)]
		"higgs":
			var hs: Array = _text("H", Vector2.ZERO, 0.9)
			hs.append(_ell(Vector2.ZERO, 0.85, 0.85))
			return hs
		"chicken":
			return [_ell(Vector2(0, 0.1), 0.62, 0.62), _pl([[-0.2, -0.5], [-0.1, -0.75], [0.0, -0.52], [0.1, -0.78], [0.2, -0.5]]),
				_pl([[0.6, -0.05], [0.88, 0.05], [0.6, 0.15]]), _ell(Vector2(0.3, -0.15), 0.05, 0.05),
				_pl([[-0.2, 0.7], [-0.25, 0.95]]), _pl([[0.2, 0.7], [0.25, 0.95]])]
		"ftl":
			return [PackedVector2Array([Vector2.ZERO, Vector2(3.4, -0.6)])]
		"heart":
			var hp := PackedVector2Array()
			for i in 61:
				var tt := TAU * i / 60.0
				hp.append(Vector2(16.0 * pow(sin(tt), 3), -(13.0 * cos(tt) - 5.0 * cos(2 * tt) - 2.0 * cos(3 * tt) - cos(4 * tt))) * 0.05)
			return [hp]
	return []

## 生成梗图径迹：主体笔画用亮色，外加几条淡淡的普通径迹当背景
func _bloom_meme(energy: int) -> void:
	var R := Geo.SCREEN.size.y * 0.30
	var col := Pal.c("gold") if not Pal.dark else Pal.c("ramp4")
	for st in _meme_strokes(meme):
		var pts := PackedVector2Array()
		# 笔画加密：让“生长”更顺
		for i in st.size() - 1:
			var a: Vector2 = st[i] * R
			var b: Vector2 = st[i + 1] * R
			var n := maxi(2, int(a.distance_to(b) / 2.0))
			for k in n:
				pts.append(a.lerp(b, float(k) / n))
		pts.append(st[st.size() - 1] * R)
		tracks.append({"pts": pts, "col": col, "w": 1.4})
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 10:
		var a := rng.randf() * TAU
		tracks.append({"pts": PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a) * R * 0.35, Vector2.from_angle(a + 0.2) * R * 0.7]), "col": Color(Pal.ramp(0.5), 0.35), "w": 0.6})

## 梗图的屏幕文字与小动画
func _meme_extras(s: Rect2, c: Vector2, R: float, ink: Color) -> void:
	var m: Dictionary = Memes.LIST.get(meme, {})
	if m.is_empty():
		return
	# 屏幕边框金色闪三下
	if meme_t < 1.6 and int(meme_t * 6.0) % 2 == 0:
		draw_rect(s.grow(-1.5), Pal.c("gold"), false, 2.0)
	# 左上角像终端一样打字：“奇葩事件 · ……”
	var full: String = m.name
	var n := clampi(int((meme_t - 1.0) * 10.0), 0, full.length())
	draw_string(Pal.mono, s.position + Vector2(6, 12), "ANOMALY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(Pal.c("red"), 0.9))
	if n > 0:
		draw_string(Pal.bold, s.position + Vector2(6, 26), full.substr(0, n), HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 12, 12, ink)
	match meme:
		"woodfish":
			# 每敲一下飘一个“功德+1”
			if progress >= 1.0:
				for k in 3:
					var ph := fmod(meme_t * 0.9 + k / 3.0, 1.0)
					draw_string(Pal.bold, c + Vector2(-R * 0.6 + k * 6.0, -R * 0.2 - ph * R * 0.9), "功德+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Pal.c("gold"), 1.0 - ph))
				var hit := absf(sin(meme_t * PI * 0.9 * 2.0))
				draw_line(c + Vector2(R * 0.95, -R * 0.85), c + Vector2(R * 0.35, -R * 0.2) + Vector2(0, -6.0 * hit), Color(Pal.c("gold"), 0.6), 1.0)
		"champagne":
			if progress >= 1.0:
				for k in 8:
					var ph := fmod(meme_t * 0.7 + k / 8.0, 1.0)
					draw_arc(c + Vector2(sin(k * 1.7 + meme_t * 2.0) * R * 0.12, -R * 0.75 - ph * R * 0.6), 1.5 + ph * 1.5, 0, TAU, 8, Color(Pal.c("gold"), 1.0 - ph), 0.8, true)
		"six":
			if progress >= 1.0:
				draw_set_transform(Vector2(sin(meme_t * 30.0) * 0.6, 0))
		"heart":
			var beat := 1.0 + 0.08 * maxf(0.0, sin(meme_t * 7.0))
			draw_arc(c, R * 0.95 * beat, 0, TAU, 48, Color(Pal.c("red"), 0.25), 1.0, true)
	draw_set_transform(Vector2.ZERO)

## 形态成像：淡淡的径迹打底，扫描线从左往右扫过去，扫过的地方显出这一束长成的样子；细刻度环代替粗量能器塔
func _form_view(s: Rect2, c: Vector2, R: float, ink: Color, e: float) -> void:
	var col: Color = Pal.ramp(clampf((form.peak - 1) / 12.0, 0.0, 1.0))
	# 底：细网格
	for i in range(1, 16):
		var x := s.position.x + i * s.size.x / 16.0
		draw_line(Vector2(x, s.position.y), Vector2(x, s.end.y), Color(ink, 0.06), 0.5)
	for i in range(1, 9):
		var y := s.position.y + i * s.size.y / 9.0
		draw_line(Vector2(s.position.x, y), Vector2(s.end.x, y), Color(ink, 0.06), 0.5)
	# 径迹打底（很淡）
	for tr in tracks:
		var pts: PackedVector2Array = tr.pts
		var m := int(pts.size() * e)
		if m < 2:
			continue
		var sub := PackedVector2Array()
		for i in m:
			sub.append(c + pts[i] * 1.25)
		draw_polyline(sub, Color(col, 0.16), 0.5, true)
	# 刻度环：48 根细刻度，跟着能量分布起伏
	for i in towers.size():
		var ang := TAU * i / towers.size()
		var r1 := R * 1.42
		var h: float = R * (0.06 + 0.22 * clampf(towers[i], 0.0, 1.0)) * e
		var hot: bool = towers[i] > 0.5
		draw_line(c + Vector2(cos(ang), sin(ang) * 0.92) * r1, c + Vector2(cos(ang), sin(ang) * 0.92) * (r1 + h), Color(col if hot else ink, 0.75 if hot else 0.35), 1.2 if hot else 0.7)
	draw_arc(c, R * 1.4, 0, TAU, 96, Color(ink, 0.25), 0.6, true)
	# 成像：扫描线扫过的部分才显出来（左 → 右），之后一直轻轻动着
	var sweep := s.position.x + s.size.x * clampf(progress * 1.25, 0.0, 1.0)
	var st := form.duplicate()
	st["g"] = float(form.peak)
	st["t"] = idle_t
	st["dmg"] = 0.6 if form.damaged else 0.0
	st["col"] = col
	st["core_r"] = 9.0 + clampf((form.peak - 1) / 12.0, 0.0, 1.0) * 16.0
	st["card"] = true
	st["omen"] = 0.0
	st["grow"] = 0.85 + 0.15 * e
	var clip := Rect2(s.position, Vector2(sweep - s.position.x, s.size.y))
	if clip.size.x > 1.0:
		art.draw(self, c + Vector2(0, 4), 0.36, st)
	# 扫描线没到的地方盖回屏幕底色（只在扫描过程中）
	if sweep < s.end.x:
		var bg := Pal.c("screen") if Pal.dark else Pal.c("paper")
		draw_rect(Rect2(Vector2(sweep, s.position.y), Vector2(s.end.x - sweep, s.size.y)), bg)
		draw_line(Vector2(sweep, s.position.y), Vector2(sweep, s.end.y), Color(col, 0.9), 1.4)
	# 角标：重建结果
	var a := clampf((progress - 0.75) / 0.2, 0.0, 1.0)
	draw_string(Pal.mono, Vector2(s.position.x + 8, s.position.y + 12), "RECON · E%d" % form.energy, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(ink, 0.6))
	if a > 0.0:
		draw_string(Pal.bold, Vector2(s.position.x + 8, s.end.y - 8), form.name, HORIZONTAL_ALIGNMENT_LEFT, s.size.x * 0.6, 11, Color(ink, a))
	draw_string(Pal.mono, Vector2(s.end.x - 60, s.end.y - 6), "EVT %05d" % (int(idle_t * 7) % 99999), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(ink, 0.5))
	if progress >= 1.0:
		playing = false
