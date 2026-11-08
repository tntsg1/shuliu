extends Control
## 阶段通过的庆祝（约 4.5 秒，之后纸屑继续飘到玩家点“好的”）：
## 闪白 → 大红“通过”章砸下 → 两边礼炮喷彩带和纸屑 → 同事们从屏幕下沿冒出来跳着欢呼、抛帽子 →
## “恭 喜 通 过 ！”一个字一个字砸下来 → 天上连放礼花 → 章盖到标题角上 → 升起下一阶段目标卡。
## 声音全部真实录音：欢呼、鼓掌、礼炮、烟花。哑光平涂，不发光。

var main: Node
var t := -1.0
var stage_no := 1
var quip := ""
var confetti: Array = []
var streamers: Array = []     # 彩带：一串点（verlet 绳子）
var rockets: Array = []       # 礼花：先升空再炸开
var sparks: Array = []
var people: Array = []
var hats: Array = []
var _fired := {}

const TITLE := "恭喜通过！"

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

func start(stage: int, q: String) -> void:
	t = 0.0
	stage_no = stage
	quip = q
	_fired.clear()
	confetti.clear()
	streamers.clear()
	rockets.clear()
	sparks.clear()
	hats.clear()
	people.clear()
	var vp := get_viewport_rect().size
	# 同事们：一排站在屏幕下沿外，依次冒出来
	var n := 11
	for i in n:
		people.append({"x": 90.0 + i * (vp.x - 180.0) / (n - 1) + randf_range(-30, 30), "delay": 0.35 + absf(i - n / 2.0) * 0.06 + randf() * 0.1,
			"ph": randf() * TAU, "hop": randf_range(5.0, 7.5), "coat": [Pal.c("paper"), Color("#e8e2d2"), Color("#d8e2ea")][i % 3],
			"hair": [Color("#2b2a28"), Color("#5a3a2a"), Color("#7a6a5a"), Color("#2b2a28")][i % 4], "throw": i % 3 == 1, "thrown": false, "h": randf_range(0.9, 1.1)})

## 玩家点了“好的”：快速收尾
func finish() -> void:
	if t >= 0.0:
		t = maxf(t, 9.0)

func active() -> bool:
	return t >= 0.0

func _once(key: String, at: float) -> bool:
	if t >= at and not _fired.has(key):
		_fired[key] = true
		return true
	return false

func _popper(side: float) -> void:
	var vp := get_viewport_rect().size
	var origin := Vector2(0.0 if side < 0 else vp.x, vp.y - 40.0)
	var cols := [Pal.c("red"), Pal.c("gold"), Pal.c("blue"), Pal.c("green"), Pal.c("orange"), Pal.c("lock"), Color("#e86aa0")]
	for i in 90:
		var a := deg_to_rad(-90.0 - side * randf_range(15.0, 62.0))
		var sp := randf_range(800.0, 1500.0)
		confetti.append({"p": origin, "v": Vector2.from_angle(a) * sp, "r": randf() * TAU, "w": randf_range(-10, 10),
			"s": Vector2(randf_range(8, 16), randf_range(5, 9)), "c": cols[i % cols.size()], "f": randf_range(2.0, 5.0), "ph": randf() * TAU})
	# 彩带：每根是一串点，头部带着初速度，后面的点被拖着走
	for i in 9:
		var a := deg_to_rad(-90.0 - side * randf_range(20.0, 55.0))
		var sp := randf_range(1100.0, 1700.0)
		var pts: Array = []
		for k in 16:
			pts.append({"p": origin, "o": origin})
		streamers.append({"pts": pts, "v": Vector2.from_angle(a) * sp, "c": cols[(i * 2 + (0 if side < 0 else 1)) % cols.size()], "life": 0.0, "curl": randf_range(-6, 6)})

func _rocket(x: float, y: float, col: Color, col2: Color) -> void:
	var vp := get_viewport_rect().size
	rockets.append({"p": Vector2(x, vp.y + 10), "to": Vector2(x + randf_range(-60, 60), y), "t": 0.0, "c": col, "c2": col2})

func _burst(p: Vector2, col: Color, col2: Color) -> void:
	for i in 72:
		var a := TAU * i / 72.0 + randf_range(-0.05, 0.05)
		var sp := randf_range(420.0, 620.0) * (1.0 if i % 2 == 0 else 0.68)
		sparks.append({"p": p, "v": Vector2.from_angle(a) * sp, "c": col if i % 2 == 0 else col2, "life": randf_range(1.0, 1.5), "age": 0.0, "trail": []})
	Sfx.play("firework", -6.0, randf_range(0.9, 1.1))
	Sfx.play("crackle_fw", -8.0, randf_range(0.95, 1.1))

func _process(dt: float) -> void:
	if t < 0.0:
		return
	t += dt
	var vp := get_viewport_rect().size
	# —— 时间线 ——
	if _once("pop", 0.12):
		_popper(-1.0)
		_popper(1.0)
		Sfx.play("confetti", 0.0, 1.0)
		Sfx.play("confetti", -2.0, 0.9)
		Sfx.play("boom", -8.0, 1.6)
	if _once("cheer", 0.3):
		Sfx.play("cheer", -1.0)
	if _once("clap", 0.7):
		Sfx.play("applause", -3.0)
	var shots := [[0.55, 0.16, 0.3], [0.95, 0.84, 0.26], [1.35, 0.3, 0.12], [1.8, 0.7, 0.1], [2.3, 0.1, 0.5], [3.0, 0.9, 0.45], [3.6, 0.22, 0.15], [4.2, 0.78, 0.18]]
	var pal := [[Pal.c("gold"), Pal.c("red")], [Pal.c("blue"), Pal.c("paper")], [Pal.c("green"), Pal.c("gold")], [Pal.c("red"), Pal.c("orange")], [Pal.c("lock"), Pal.c("paper")]]
	for i in shots.size():
		if _once("fw%d" % i, shots[i][0]):
			var cc: Array = pal[i % pal.size()]
			_rocket(vp.x * shots[i][1], vp.y * shots[i][2], cc[0], cc[1])
	for i in TITLE.length():
		if _once("ch%d" % i, 0.9 + i * 0.14):
			Sfx.play("hit", -8.0, 1.2 + i * 0.08)
	# 持续的纸屑雨
	if t < 7.5 and randf() < 0.6:
		var cols := [Pal.c("red"), Pal.c("gold"), Pal.c("blue"), Pal.c("green"), Pal.c("orange")]
		confetti.append({"p": Vector2(randf() * vp.x, -20.0), "v": Vector2(randf_range(-40, 40), randf_range(60, 140)), "r": randf() * TAU,
			"w": randf_range(-6, 6), "s": Vector2(randf_range(7, 13), randf_range(4, 8)), "c": cols[randi() % cols.size()], "f": randf_range(2.0, 4.0), "ph": randf() * TAU})
	# —— 物理 ——
	for q in confetti:
		q.v.y += 900.0 * dt
		q.v *= 1.0 - 2.2 * dt
		q.v.y = minf(q.v.y, 170.0)
		q.p += q.v * dt + Vector2(sin(t * q.f + q.ph) * 50.0 * dt, 0)
		q.r += q.w * dt
	confetti = confetti.filter(func(q): return q.p.y < vp.y + 40)
	for s in streamers:
		s.life += dt
		var head: Dictionary = s.pts[0]
		s.v.y += 700.0 * dt
		s.v *= 1.0 - 1.8 * dt
		s.v.y = minf(s.v.y, 120.0)
		s.v = s.v.rotated(s.curl * dt * 0.2)
		head.p += s.v * dt
		# 绳子：每个点追前一个点，保持段长
		for k in range(1, s.pts.size()):
			var a: Dictionary = s.pts[k - 1]
			var b: Dictionary = s.pts[k]
			var vel: Vector2 = (b.p - b.o) * 0.96
			b.o = b.p
			b.p += vel + Vector2(0, 160.0 * dt * dt * 60.0 * 0.15)
			var d: Vector2 = b.p - a.p
			var L := 18.0
			if d.length() > L:
				b.p = a.p + d.normalized() * L
	streamers = streamers.filter(func(s): return s.pts[s.pts.size() - 1].p.y < vp.y + 200 or s.life < 2.0)
	for r in rockets:
		r.t += dt
		var k: float = r.t / 0.55
		r.p = Vector2(r.p.x, r.p.y).lerp(r.to, 1.0 - pow(1.0 - minf(1.0, k), 2.0)) if k < 1.0 else r.to
		if k >= 1.0 and not r.has("done"):
			r["done"] = true
			_burst(r.to, r.c, r.c2)
	rockets = rockets.filter(func(r): return not r.has("done"))
	for s in sparks:
		s.age += dt
		s.trail.push_front(s.p)
		if s.trail.size() > 6:
			s.trail.pop_back()
		s.v *= 1.0 - 1.9 * dt
		s.v.y += 160.0 * dt
		s.p += s.v * dt
	sparks = sparks.filter(func(s): return s.age < s.life)
	for p in people:
		var pt: float = t - p.delay
		if p.throw and not p.thrown and pt > 0.55:
			p.thrown = true
			hats.append({"p": Vector2(p.x, vp.y - 150.0), "v": Vector2(randf_range(-120, 120), -randf_range(900, 1150)), "r": 0.0, "w": randf_range(-8, 8), "paper": randf() < 0.4})
	for h in hats:
		h.v.y += 1500.0 * dt
		h.p += h.v * dt
		h.r += h.w * dt
	hats = hats.filter(func(h): return h.p.y < vp.y + 80)
	if t > 9.6:
		t = -1.0
	queue_redraw()

func _draw() -> void:
	if t < 0.0:
		return
	var vp := get_viewport_rect().size
	var fade := clampf((9.6 - t) / 0.6, 0.0, 1.0)
	var el := Pal.equip_line()
	# 闪白 + 背景压暗
	if t < 0.18:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(Pal.c("paper"), 0.85 * (1.0 - t / 0.18)))
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.3 * clampf(t / 0.25, 0.0, 1.0) * fade))
	var c := Vector2(vp.x * 0.5, 430.0)
	# 背后的射线：金纸相间，慢慢转
	var ra := clampf((t - 0.1) / 0.3, 0.0, 1.0) * fade
	for i in 24:
		var ang := i * TAU / 24.0 + t * 0.22
		var col: Color = Pal.c("gold") if i % 2 == 0 else Pal.c("paper")
		draw_line(c + Vector2.from_angle(ang) * 140.0, c + Vector2.from_angle(ang) * 1400.0, Color(col, 0.24 * ra), 80.0)
	# 标题横幅底 + 逐字砸下来的大字
	var bo := Ink.ease_out_back(clampf((t - 0.75) / 0.35, 0.0, 1.0))
	if bo > 0.0:
		var bw := 940.0 * bo
		var br := Rect2(vp.x * 0.5 - bw * 0.5, 130.0, bw, 150.0)
		draw_rect(Rect2(br.position + Vector2(10, 12), br.size), Color(0, 0, 0, 0.22 * fade))
		draw_rect(br, Color(Pal.c("red"), fade))
		Ink.frame(self, br.grow(-9), Color(Pal.c("gold"), fade), 4.0)
		for sd in [-1.0, 1.0]:
			var ex := br.position.x if sd < 0 else br.end.x
			draw_colored_polygon(PackedVector2Array([Vector2(ex, br.position.y + 22), Vector2(ex + sd * 90.0 * bo, br.position.y + 36), Vector2(ex + sd * 52.0 * bo, br.get_center().y + 14), Vector2(ex + sd * 90.0 * bo, br.end.y + 8), Vector2(ex, br.end.y - 22)]), Color(Pal.c("red").darkened(0.28), fade))
	var cw := 150.0
	var x0 := vp.x * 0.5 - cw * (TITLE.length() - 1) * 0.5
	for i in TITLE.length():
		var ct := t - (0.9 + i * 0.14)
		if ct <= 0.0:
			continue
		var k := clampf(ct / 0.18, 0.0, 1.0)
		var sc := lerpf(2.6, 1.0, Ink.ease_out_back(k))
		var bob := sin(t * 3.0 + i * 0.8) * 4.0 * clampf(ct - 0.3, 0.0, 1.0)
		var p := Vector2(x0 + i * cw, 236.0 + bob)
		draw_set_transform(p, (0.12 if i % 2 == 0 else -0.1) * (1.0 - k), Vector2(sc, sc))
		Ink.text(self, TITLE[i], Vector2(4, 6), 112, Color(0, 0, 0, 0.3 * fade), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, TITLE[i], Vector2.ZERO, 112, Color(Pal.c("paper"), fade), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform(Vector2.ZERO)
	# 副标题
	var sa := clampf((t - 1.7) / 0.3, 0.0, 1.0) * fade
	if sa > 0.0:
		var sub := "第 %d 阶段审核 · 评审委员会一致通过" % stage_no
		var sw := Ink.size(Pal.bold, sub, 26).x + 60.0
		draw_rect(Rect2(vp.x * 0.5 - sw * 0.5, 292.0, sw, 46.0), Color(Pal.c("paper"), 0.95 * sa))
		Ink.frame(self, Rect2(vp.x * 0.5 - sw * 0.5, 292.0, sw, 46.0), Color(el, 0.6 * sa), 1.4)
		Ink.text(self, sub, Vector2(vp.x * 0.5, 324.0), 26, Color(Pal.c("red"), sa), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	var qa := clampf((t - 2.1) / 0.4, 0.0, 1.0) * fade
	if qa > 0.0 and quip != "":
		var qw := Ink.size(Pal.hand, quip, 26).x + 60.0
		draw_rect(Rect2(vp.x * 0.5 - qw * 0.5, 350.0, qw, 44.0), Color(Pal.c("paper"), 0.9 * qa))
		Ink.text(self, quip, Vector2(vp.x * 0.5, 381.0), 26, Color(Pal.c("blue"), qa), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	# 大红“通过”章：砸在中间，之后缩到标题右上角
	var drop := clampf(t / 0.22, 0.0, 1.0)
	var mv := Ink.ease_in_out(clampf((t - 0.75) / 0.45, 0.0, 1.0))
	var sp := c.lerp(Vector2(vp.x * 0.5 + 520.0, 150.0), mv)
	var ssc := lerpf(3.4, 1.0, Ink.ease_out_cubic(drop)) * lerpf(1.25, 0.55, mv)
	var sa2 := drop * fade
	draw_set_transform(sp, -0.18, Vector2(ssc, ssc))
	Ink.disc(self, Vector2.ZERO, 120.0, Color(Pal.c("paper"), 0.88 * sa2))
	draw_arc(Vector2.ZERO, 120.0, 0.3, TAU - 0.1, 64, Color(Pal.c("red"), sa2), 10.0, true)
	draw_arc(Vector2.ZERO, 100.0, 0, TAU, 64, Color(Pal.c("red"), sa2), 3.0, true)
	var star := PackedVector2Array()
	for i in 10:
		star.append(Vector2.from_angle(-PI / 2 + i * PI / 5) * (26.0 if i % 2 == 0 else 11.0) + Vector2(0, -52))
	draw_colored_polygon(star, Color(Pal.c("red"), sa2))
	Ink.text(self, "通过", Vector2(0, 30), 64, Color(Pal.c("red"), sa2), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "第七实验站 · 评审委员会", Vector2(0, 70), 14, Color(Pal.c("red"), sa2), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	if t > 0.2 and t < 0.75:
		var ik := (t - 0.2) / 0.55
		for ri in 2:
			draw_arc(c, 150.0 + (300.0 + ri * 160.0) * Ink.ease_out_cubic(ik), 0, TAU, 80, Color(Pal.c("red") if ri == 0 else Pal.c("gold"), 0.7 * (1.0 - ik)), 9.0 * (1.0 - ik) + 1.0, true)
	# 礼花：升空的火箭 + 炸开的火花（带短拖尾）
	for r in rockets:
		draw_line(r.p, r.p + Vector2(0, 26), Color(r.c, fade), 3.0)
		Ink.disc(self, r.p, 4.0, Color(r.c, fade))
	for s in sparks:
		var a: float = (1.0 - s.age / s.life) * fade
		if s.trail.size() > 1:
			Ink.pl(self, PackedVector2Array(s.trail), Color(s.c, a * 0.7), 3.0)
		Ink.disc(self, s.p, 4.5 * (1.0 - 0.5 * s.age / s.life), Color(s.c, a))
	# 同事们：从屏幕下沿冒出来，跳着欢呼、挥手
	for p in people:
		var pt: float = t - p.delay
		if pt <= 0.0:
			continue
		var rise := Ink.ease_out_back(clampf(pt / 0.35, 0.0, 1.0))
		var exit := clampf((t - 8.6) / 0.6, 0.0, 1.0)
		var jump := absf(sin(pt * p.hop)) * 26.0 * clampf(pt - 0.3, 0.0, 1.0)
		var base := Vector2(p.x, vp.y + 150.0 - 260.0 * rise * (1.0 - exit) - jump)
		_person(base, p, pt)
	# 抛起来的学位帽和文件
	for h in hats:
		draw_set_transform(h.p, h.r, Vector2.ONE)
		if h.paper:
			draw_rect(Rect2(-14, -18, 28, 36), Color(Pal.c("paper"), fade))
			Ink.frame(self, Rect2(-14, -18, 28, 36), Color(el, fade), 1.4)
			for k in 3:
				draw_line(Vector2(-9, -9 + k * 7), Vector2(9, -9 + k * 7), Color(el, 0.4 * fade), 1.0)
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-26, -4), Vector2(0, -16), Vector2(26, -4), Vector2(0, 8)]), Color(Color("#2b2a28"), fade))
			draw_rect(Rect2(-12, 2, 24, 10), Color(Color("#2b2a28"), fade))
			draw_line(Vector2(18, -6), Vector2(20, 12), Color(Pal.c("gold"), fade), 2.0)
		draw_set_transform(Vector2.ZERO)
	# 彩带
	for s in streamers:
		var pts := PackedVector2Array()
		for q in s.pts:
			pts.append(q.p)
		Ink.pl(self, pts, Color(s.c, fade), 6.0)
		Ink.pl(self, pts, Color(s.c.lightened(0.25), fade), 2.0)
	# 纸屑
	for q in confetti:
		draw_set_transform(q.p, q.r, Vector2(absf(cos(q.r * 1.7)) * 0.85 + 0.15, 1.0))
		draw_rect(Rect2(-q.s * 0.5, q.s), Color(q.c, fade))
		draw_set_transform(Vector2.ZERO)

## 一个同事（和主角同一画法：白大褂、圆脑袋），双手举过头顶欢呼
func _person(b: Vector2, p: Dictionary, pt: float) -> void:
	var el := Pal.equip_line()
	var s: float = p.h
	var wave := sin(pt * 9.0 + p.ph)
	draw_set_transform(b, 0.0, Vector2(s, s))
	# 手臂：举起来挥
	for side in [-1.0, 1.0]:
		var sh := Vector2(side * 22.0, -96.0)
		var hand := sh + Vector2(side * (26.0 + 10.0 * wave), -58.0 - 8.0 * wave * side)
		var elbow := sh + Vector2(side * 30.0, -24.0)
		Ink.pl(self, PackedVector2Array([sh, elbow, hand]), el, 11.0)
		Ink.pl(self, PackedVector2Array([sh, elbow, hand]), p.coat, 7.5)
		Ink.disc(self, hand, 6.0, Pal.c("skin"))
	# 白大褂
	var body := PackedVector2Array([Vector2(-24, -104), Vector2(24, -104), Vector2(30, 40), Vector2(-30, 40)])
	draw_colored_polygon(body, p.coat)
	body.append(body[0])
	Ink.pl(self, body, el, 2.2)
	draw_line(Vector2(0, -96), Vector2(0, 40), Color(el, 0.4), 1.2)
	# 头
	Ink.disc(self, Vector2(0, -128), 22.0, Pal.c("skin"))
	draw_arc(Vector2(0, -128), 22.0, 0, TAU, 32, el, 2.0, true)
	var hair := PackedVector2Array()
	for i in 13:
		hair.append(Vector2(0, -128) + Vector2.from_angle(PI + PI * i / 12.0) * 23.0)
	draw_colored_polygon(hair, p.hair)
	# 张大嘴笑
	draw_arc(Vector2(0, -122), 8.0, 0.2, PI - 0.2, 12, el, 2.2, true)
	Ink.disc(self, Vector2(-7, -132), 2.0, el)
	Ink.disc(self, Vector2(7, -132), 2.0, el)
	draw_set_transform(Vector2.ZERO)
