extends Node2D
## 墙上探测屏：引出时“开花”的事件图谱（规整/爆发/污染三种品相，M1）

var tracks: Array = []      # 每条 {pts: PackedVector2Array, col: Color, w: float}
var towers := PackedFloat32Array()
var hits := PackedVector2Array()
var progress := 0.0         # 0..1 绘制进度
var playing := false
var style := "precise"
var idle_t := 0.0

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

## 生成一次事件。energy 越高径迹越多
func bloom(energy: int, kind: String) -> void:
	style = kind
	tracks.clear()
	hits.clear()
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
	# 量能器塔
	for i in towers.size():
		var ang := TAU * i / towers.size()
		var r1 := R * 0.82
		var r2 := r1 + R * 0.55 * towers[i] * e
		var col := (Pal.c("red") if style == "dirty" else ink) if towers[i] > 0.55 else Pal.ramp(0.5)
		if style == "dirty":
			col = Pal.c("orange")
		draw_line(c + Vector2.from_angle(ang) * r1, c + Vector2.from_angle(ang) * r2, Color(col, 0.85), R * 0.075)
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
	draw_string(Pal.mono, Vector2(s.end.x - 92, s.end.y - 6), "EVT %05d" % (int(idle_t * 7) % 99999), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(ink, 0.6))
	if progress >= 1.0:
		playing = false
