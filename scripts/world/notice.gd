extends Node2D
## 墙上的两张纸（DECISIONS Q62）：
##  评审日程表——8 格，过一关红笔划掉，当前一格画圈，大考格红框（像锻刀模拟器的日历，走动时也一直提醒还剩几关）；
##  经费处理决定——开场那封信的张贴版，红章；点它重读整封信。
## 只在阶段变化 / 鼠标悬停变化时重画。

const SCHED := Rect2(352, 306, 278, 146)
const NOTE := Rect2(648, 318, 100, 150)

var main: Node
var hot := 0.0
var _sig := []

func rect() -> Rect2:
	return NOTE.grow(6)

func _process(_dt: float) -> void:
	if main == null or main.run == null:
		return
	var r: Run = main.run
	var s := [r.stage, r.endless, r.won(), r.failed, snappedf(hot, 0.05), Pal.dark]
	if s != _sig:
		_sig = s
		queue_redraw()

func _draw() -> void:
	if main == null or main.run == null:
		return
	var run: Run = main.run
	var el := Pal.equip_line()
	var ink := Color("#2b2a28")
	var red := Pal.c("red")
	# —— 评审日程表 ——
	draw_set_transform(SCHED.position, -0.012)
	var sz := SCHED.size
	draw_rect(Rect2(Vector2(4, 5), sz), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(Vector2.ZERO, sz), Color("#f7f2e6"))
	Ink.frame(self, Rect2(Vector2.ZERO, sz), Color(el, 0.6), Ink.W3)
	draw_rect(Rect2(Vector2(sz.x * 0.5 - 22, -7), Vector2(44, 14)), Color(Pal.c("gold"), 0.45))
	Ink.text(self, "第七实验站评审安排", Vector2(12, 22), 13, ink, Pal.bold)
	var first := maxi(0, run.stage - 7) if run.endless else 0
	Ink.text(self, ("无尽 · 第 %d 次" % (run.stage + 1)) if run.endless else "共 8 次", Vector2(sz.x - 10, 22), 11, Color(ink, 0.6), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
	var bw := 30.0
	var gap := (sz.x - 20.0 - bw * 8.0) / 7.0
	for i in 8:
		var si := first + i
		var b := Rect2(10.0 + i * (bw + gap), 36, bw, 40)
		var big := Run.is_big(si)
		draw_rect(b, Color("#ffffff", 0.5))
		Ink.frame(self, b, red if big else Color(el, 0.7), 2.0 if big else 1.0)
		Ink.text(self, str(si + 1), b.position + Vector2(bw * 0.5, 27), 17, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		if big:
			Ink.text(self, "大考", b.position + Vector2(bw * 0.5, -3), 9, red, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, _short(Run.line_at(si)), b.position + Vector2(bw * 0.5, 54), 9, Color(ink, 0.65), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
		if si < run.stage or (run.won() and si < Run.LINES.size()):
			# 过了：红笔打叉
			draw_line(b.position + Vector2(4, 4), b.end - Vector2(4, 4), Color(red, 0.85), 2.4, true)
			draw_line(Vector2(b.end.x - 4, b.position.y + 4), Vector2(b.position.x + 4, b.end.y - 4), Color(red, 0.85), 2.4, true)
		elif si == run.stage and not run.failed:
			# 现在这一关：红笔圈起来
			var pts := PackedVector2Array()
			for k in 25:
				var a := TAU * k / 24.0 + 0.3
				pts.append(b.get_center() + Vector2(cos(a) * (bw * 0.5 + 6.0 + sin(a * 3.0)), sin(a) * (26.0 + cos(a * 2.0))))
			Ink.pl(self, pts, red, 2.0)
	Ink.para(self, Pal.hand, Vector2(12, sz.y - 30), "本期共 8 次评审。任何一次未达标，学校将终止资助，并出售实验站。", sz.x - 24, 11, 2, red)
	draw_set_transform(Vector2.ZERO)
	# —— 经费处理决定（点开重读整封信）——
	draw_set_transform(NOTE.position, 0.05)
	var nz := NOTE.size
	var lift := hot * 3.0
	draw_rect(Rect2(Vector2(4, 6 + lift), nz), Color(0, 0, 0, 0.14 + 0.08 * hot))
	draw_rect(Rect2(Vector2(0, -lift), nz), Color("#fbf7ec"))
	Ink.frame(self, Rect2(Vector2(0, -lift), nz), red.lerp(el, 0.3) if hot > 0.3 else Color(el, 0.6), Ink.W3 + hot)
	Ink.disc(self, Vector2(nz.x * 0.5 + 1.5, 8 - lift), 3.2, Color(0, 0, 0, 0.15))
	Ink.disc(self, Vector2(nz.x * 0.5, 6 - lift), 3.2, red)
	Ink.disc(self, Vector2(nz.x * 0.5 - 1.0, 5 - lift), 1.0, Color(1, 1, 1, 0.5))
	Ink.text(self, "经费处理决定", Vector2(nz.x * 0.5, 22 - lift), 11, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	var ly := 40.0 - lift
	for l in ["经校董会决定，本站还有最后 8 次评审机会。", "每轮配给 3 瓶束流气瓶。评审未通过，实验站将交由星汇数据公司收购。"]:
		Ink.para(self, Pal.font, Vector2(8, ly), l, nz.x - 16, 9, -1, Color(ink, 0.8))
		ly += Ink.para_size(Pal.font, l, nz.x - 16, 9).y + 4.0
	# 红章
	var sc := Vector2(nz.x - 24, nz.y - 22 - lift)
	draw_arc(sc, 15.0, 0, TAU, 24, Color(red, 0.75), 1.6, true)
	Ink.text(self, "校长", sc + Vector2(0, 4), 9, Color(red, 0.85), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

func _short(v: int) -> String:
	if v >= 10000:
		var w := v / 10000.0
		return ("%.1f万" % w) if w < 100 else ("%d万" % int(w))
	return str(v)
