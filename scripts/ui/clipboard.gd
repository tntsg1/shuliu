extends Control
## 纸质夹板：左=科研考核（累计曲线），右=实验日志 + 显示/实际频率。从屏幕边缘滑入

var main: Node
var side := -1          # -1 左, 1 右
var show_t := 0.0
var show_v := 0.0
var _vs := 0.0
var stamp_t := 0.0      # 通过阶段时的印章动画
var stamp_text := ""
var total_disp := 0.0
var _vt := 0.0

const W := 400.0
const HGT := 560.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func stamp(s: String) -> void:
	stamp_text = s
	stamp_t = 0.001

func _process(dt: float) -> void:
	var r := Ink.spring(show_v, _vs, show_t, 8.0, dt); show_v = r[0]; _vs = r[1]
	if main and main.run:
		r = Ink.spring(total_disp, _vt, float(main.run.total), 6.0, dt); total_disp = r[0]; _vt = r[1]
	if stamp_t > 0.0:
		stamp_t += dt
		if stamp_t > 3.0:
			stamp_t = 0.0
	if show_v > 0.002 or show_t > 0.0:
		queue_redraw()

func _draw() -> void:
	if show_v < 0.002 or main == null or main.run == null:
		return
	var vp := get_viewport_rect().size
	var x := lerpf(-W - 40.0, 26.0, show_v) if side < 0 else lerpf(vp.x + 40.0, vp.x - W - 26.0, show_v)
	var y := 90.0
	var rot := -0.018 if side < 0 else 0.022
	draw_set_transform(Vector2(x + W * 0.5, y + HGT * 0.5), rot)
	var o := Vector2(-W * 0.5, -HGT * 0.5)
	var el := Pal.equip_line()
	# 硬纸板
	draw_rect(Rect2(o + Vector2(6, 8), Vector2(W, HGT)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(o, Vector2(W, HGT)), Color("#b58a5a") if not Pal.dark else Color("#7a5a3a"))
	draw_rect(Rect2(o, Vector2(W, HGT)), el, false, 1.8)
	# 纸
	var pr := Rect2(o + Vector2(16, 40), Vector2(W - 32, HGT - 56))
	draw_rect(pr, Pal.c("paper"))
	draw_rect(Rect2(pr.position + Vector2(3, -3), pr.size), Color(Pal.c("paper2"), 0.9))
	draw_rect(pr, Pal.c("paper"))
	draw_rect(pr, Color(el, 0.4), false, 1.0)
	# 横格线
	var yy := pr.position.y + 64
	while yy < pr.end.y - 10:
		draw_line(Vector2(pr.position.x + 10, yy), Vector2(pr.end.x - 10, yy), Color(Pal.c("blue"), 0.12), 1.0)
		yy += 26.0
	draw_line(Vector2(pr.position.x + 40, pr.position.y + 4), Vector2(pr.position.x + 40, pr.end.y - 4), Color(Pal.c("red"), 0.18), 1.0)
	# 金属夹
	var cx := 0.0
	draw_rect(Rect2(Vector2(cx - 70, o.y + 10), Vector2(140, 46)), Color("#9aa0a6"))
	draw_rect(Rect2(Vector2(cx - 70, o.y + 10), Vector2(140, 46)), el, false, 1.6)
	draw_rect(Rect2(Vector2(cx - 54, o.y + 16), Vector2(108, 10)), Color(1, 1, 1, 0.35))
	draw_circle(Vector2(cx, o.y + 12), 9.0, Color("#9aa0a6"))
	draw_arc(Vector2(cx, o.y + 12), 9.0, 0, TAU, 20, el, 1.4, true)
	draw_circle(Vector2(cx - 50, o.y + 44), 3.0, el)
	draw_circle(Vector2(cx + 50, o.y + 44), 3.0, el)
	if side < 0:
		_left(pr)
	else:
		_right(pr)
	# 阶段通过印章
	if stamp_t > 0.0 and side < 0:
		var k := minf(1.0, stamp_t / 0.16)
		var sc := lerpf(1.8, 1.0, Ink.ease_out_back(k))
		var a := clampf((3.0 - stamp_t) / 0.4, 0.0, 1.0)
		draw_set_transform(Vector2(x + W * 0.5, y + 330), -0.16, Vector2(sc, sc))
		var col := Color(Pal.c("red"), 0.85 * a)
		draw_rect(Rect2(-130, -36, 260, 72), col, false, 4.0)
		draw_rect(Rect2(-122, -28, 244, 56), col, false, 1.6)
		Ink.text(self, stamp_text, Vector2(0, 12), 32, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

func _left(pr: Rect2) -> void:
	var run: Run = main.run
	var ink := Pal.c("text")
	var p := pr.position + Vector2(52, 40)
	Ink.text(self, "科研考核", p, 24, ink, Pal.bold)
	Ink.text(self, "第 %d / %d 阶段" % [mini(run.stage + 1, Run.LINES.size()), Run.LINES.size()], p + Vector2(150, 0), 17, Pal.c("text2"))
	# 累计总分
	Ink.text(self, "累计科研点数", p + Vector2(0, 46), 15, Pal.c("text2"))
	Ink.text(self, "%s" % _fmt(int(round(total_disp))), p + Vector2(0, 86), 34, ink, Pal.mono)
	Ink.text(self, "/ %s" % _fmt(run.line()), p + Vector2(180, 86), 20, Pal.c("text2"), Pal.mono)
	# 图：阶梯考核线 + 累计曲线
	var g := Rect2(pr.position + Vector2(20, 150), Vector2(pr.size.x - 40, 170))
	draw_rect(g, Color(Pal.c("paper2"), 0.5))
	draw_rect(g, Color(ink, 0.5), false, 1.0)
	var vmax := float(Run.LINES[-1]) * 1.15
	var steps := Run.LINES.size()
	var prev := Vector2(g.position.x, g.end.y)
	var dash := Color(Pal.c("red"), 0.8)
	for i in steps:
		var x0 := g.position.x + g.size.x * i / steps
		var x1 := g.position.x + g.size.x * (i + 1) / steps
		var ly: float = g.end.y - g.size.y * float(Run.LINES[i]) / vmax
		_dashed(Vector2(x0, ly), Vector2(x1, ly), dash)
		_dashed(prev, Vector2(x0, ly), dash)
		prev = Vector2(x1, ly)
		Ink.text(self, _fmt(Run.LINES[i]), Vector2(x0 + 4, ly - 4), 12, dash, Pal.mono)
		if i < run.stage:
			Ink.text(self, "✓", Vector2(x1 - 18, ly - 4), 16, Pal.c("green"), Pal.bold)
	var tot_y := g.end.y - g.size.y * minf(total_disp, vmax) / vmax
	var cur_x := g.position.x + g.size.x * (mini(run.stage, steps - 1) + 0.5) / steps
	draw_line(Vector2(g.position.x, tot_y), Vector2(cur_x, tot_y), Pal.c("blue"), 2.2, true)
	draw_circle(Vector2(cur_x, tot_y), 4.0, Pal.c("blue"))
	# 剩余实验
	var q := pr.position + Vector2(52, 370)
	Ink.text(self, "本阶段剩余实验", q, 16, Pal.c("text2"))
	for i in Run.PER_STAGE:
		var c := q + Vector2(150 + i * 30, -6)
		if i < run.experiments_left:
			draw_circle(c, 9.0, Pal.c("ramp2"))
		draw_arc(c, 9.0, 0, TAU, 20, ink, 1.6, true)
	Ink.text(self, "大爆分可以直接垫过后面的阶段。", pr.position + Vector2(52, 420), 17, Pal.c("blue"), Pal.hand)
	Ink.text(self, "—— 系主任", pr.position + Vector2(220, 448), 15, Pal.c("text2"), Pal.hand)

func _right(pr: Rect2) -> void:
	var run: Run = main.run
	var ink := Pal.c("text")
	var p := pr.position + Vector2(52, 40)
	Ink.text(self, "实验日志", p, 24, ink, Pal.bold)
	Ink.text(self, "种子 " + run.seed_text(), p + Vector2(150, 0), 14, Pal.c("text2"), Pal.mono)
	var n := mini(run.log.size(), 9)
	for i in n:
		var e: Dictionary = run.log[i]
		var yy := p.y + 40 + i * 26
		var a := 1.0 - i * 0.07
		draw_rect(Rect2(Vector2(p.x, yy - 12), Vector2(12, 12)), Color(Pal.outcome(e.outcome), a))
		draw_rect(Rect2(Vector2(p.x, yy - 12), Vector2(12, 12)), Color(ink, 0.5 * a), false, 1.0)
		Ink.text(self, Odds.NAMES[e.outcome], Vector2(p.x + 20, yy), 16, Color(ink, a))
		var tx := "E%d→E%d" % [e.from, e.to] if e.outcome != Odds.LOSS else "E%d ✕" % e.from
		Ink.text(self, tx, Vector2(p.x + 120, yy), 15, Color(Pal.c("text2"), a), Pal.mono)
		Ink.text(self, "#%d" % e.exp, Vector2(pr.end.x - 24, yy), 13, Color(Pal.c("text2"), a * 0.8), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
	# 显示概率 vs 实际频率
	var q := pr.position + Vector2(20, 300)
	draw_line(q + Vector2(0, -8), q + Vector2(pr.size.x - 40, -8), Color(ink, 0.4), 1.0)
	Ink.text(self, "显示概率 · 实际频率（本局）", q + Vector2(32, 18), 15, Pal.c("text2"))
	var tot := 0
	for k in 5:
		tot += run.actual[k]
	for k in 5:
		var yy := q.y + 46 + k * 26
		Ink.text(self, Odds.NAMES[k], Vector2(q.x + 32, yy), 15, ink)
		var ex := run.expected[k] / maxf(1.0, tot) * 100.0
		var ac := run.actual[k] / maxf(1.0, tot) * 100.0
		Ink.text(self, "%.1f%%" % ex, Vector2(q.x + 230, yy), 15, Pal.c("text2"), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
		Ink.text(self, "%.1f%%" % ac, Vector2(q.x + 320, yy), 15, ink, Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
	Ink.text(self, "共 %d 次加速" % tot, Vector2(q.x + 32, q.y + 186), 14, Pal.c("text2"), Pal.hand)

func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var L := a.distance_to(b)
	var n := int(L / 7.0)
	for i in range(0, n, 2):
		draw_line(a.lerp(b, float(i) / maxf(1, n)), a.lerp(b, float(i + 1) / maxf(1, n)), col, 1.4)

static func _fmt(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if v < 0 else "") + s + out
