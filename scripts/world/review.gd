extends Node2D
## 考核审核台（世界里，观测舱右侧）：桌上收件盘里的实验报告一张张摞起来，墙上一块进度牌。
## 够线时台灯变绿、插一面“可提交”小旗；束流用完时红灯闪，提醒必须来提交。

const X := 1400.0          # 桌子左缘
const STAND := 1478.0      # 玩家站位
const W := 150.0

var main: Node
var t := 0.0
var hot := 0.0             # 悬停/靠近高亮
var bump := 0.0            # 新报告落进收件盘时弹一下
var _last_n := 0

func rect() -> Rect2:
	return Rect2(X - 10, Geo.FLOOR - 230, W + 20, 230)

func _process(dt: float) -> void:
	t += dt
	bump = maxf(0.0, bump - dt * 2.5)
	if main != null and main.run != null:
		var n: int = main.run.experiment_no - (1 if main.run.beam != null else 0)
		if n > _last_n:
			bump = 1.0
		_last_n = n
	queue_redraw()

func _draw() -> void:
	if main == null or main.run == null:
		return
	var run: Run = main.run
	var el := Pal.equip_line()
	var y := Geo.FLOOR
	var can: bool = run.can_submit()
	var must: bool = run.beam == null and run.experiments_left <= 0 and not run.won() and not run.failed
	# —— 墙上的进度牌 ——
	var br := Rect2(X + 8, y - 232, W - 16, 74)
	draw_rect(Rect2(br.position + Vector2(3, 4), br.size), Color(0, 0, 0, 0.12))
	draw_rect(br, Pal.c("paper"))
	Ink.frame(self, br, el, 1.6)
	draw_rect(Rect2(br.position, Vector2(br.size.x, 16)), Pal.c("red") if must else (Pal.c("green") if can else Pal.c("blue")))
	Ink.text(self, "考核审核台", br.position + Vector2(br.size.x * 0.5, 13), 12, Pal.c("paper"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	if not run.won():
		Ink.text(self, "第 %d 阶段" % (run.stage + 1), br.position + Vector2(8, 34), 12, Pal.c("text2"))
		Ink.text(self, "%d / %d" % [run.total, run.line()], br.end - Vector2(8, 38), 13, Pal.c("text"), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
		var pr := Rect2(br.position.x + 8, br.end.y - 18, br.size.x - 16, 8)
		draw_rect(pr, Pal.c("paper2"))
		var k := clampf(float(run.total) / maxf(1.0, run.line()), 0.0, 1.0)
		draw_rect(Rect2(pr.position, Vector2(pr.size.x * k, pr.size.y)), Pal.c("green") if can else Pal.c("ramp2"))
		Ink.frame(self, pr, el, 1.0)
	Ink.rivet(self, br.position + Vector2(6, 22), 1.8)
	Ink.rivet(self, Vector2(br.end.x - 6, br.position.y + 22), 1.8)
	# —— 桌子 ——
	var top := y - 74.0
	Ink.box(self, Rect2(X, top, W, 10), Pal.c("equip"), el, 1.6, 611)
	Ink.box(self, Rect2(X + 8, top + 10, 10, 64), Pal.c("equip_dark"), el, 1.2, 612)
	Ink.box(self, Rect2(X + W - 18, top + 10, 10, 64), Pal.c("equip_dark"), el, 1.2, 613)
	Ink.box(self, Rect2(X + W - 60, top + 10, 42, 34), Pal.c("equip_dark"), el, 1.2, 614)
	draw_rect(Rect2(X + W - 46, top + 24, 14, 3), el)
	# 收件盘：每做完一次实验多一张报告
	var tray := Rect2(X + 10, top - 16, 58, 16)
	var n := mini(_last_n, 12)
	for i in n:
		var lift := -sin(bump * PI) * 6.0 if i == n - 1 else 0.0
		draw_rect(Rect2(tray.position.x + 4 + (i % 2) * 1.5, tray.end.y - 4 - i * 1.6 + lift, 50, 3), Pal.c("paper"))
		draw_line(Vector2(tray.position.x + 4, tray.end.y - 4 - i * 1.6 + lift), Vector2(tray.position.x + 54, tray.end.y - 4 - i * 1.6 + lift), Color(el, 0.4), 0.8)
	Ink.pl(self, PackedVector2Array([tray.position, Vector2(tray.position.x, tray.end.y), tray.end, Vector2(tray.end.x, tray.position.y)]), el, 1.8)
	# 印章 + 印台
	Ink.box(self, Rect2(X + 82, top - 8, 26, 8), Color("#3a3d42"), el, 1.0, 615)
	draw_rect(Rect2(X + 85, top - 6, 20, 4), Pal.c("red"))
	Ink.box(self, Rect2(X + 112, top - 26, 12, 18), Color("#8a5a3a"), el, 1.0, 616)
	Ink.box(self, Rect2(X + 108, top - 8, 20, 8), Pal.c("red"), el, 1.0, 617)
	# 台灯：够线绿、用完红闪、平时暖黄
	var lamp_on := Pal.c("green") if can else (Pal.c("red") if must and int(t * 3.0) % 2 == 0 else Pal.c("gold"))
	draw_line(Vector2(X + 136, top), Vector2(X + 136, top - 40), el, 2.0)
	draw_line(Vector2(X + 136, top - 40), Vector2(X + 120, top - 52), el, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(X + 108, top - 46), Vector2(X + 128, top - 60), Vector2(X + 132, top - 50), Vector2(X + 116, top - 40)]), lamp_on)
	Ink.pl(self, PackedVector2Array([Vector2(X + 108, top - 46), Vector2(X + 128, top - 60), Vector2(X + 132, top - 50), Vector2(X + 116, top - 40), Vector2(X + 108, top - 46)]), el, 1.4)
	# 够线：收件盘上插一面小旗
	if can:
		var wv := sin(t * 4.0) * 2.0
		draw_line(Vector2(X + 60, top - 16), Vector2(X + 60, top - 46), el, 1.6)
		draw_colored_polygon(PackedVector2Array([Vector2(X + 61, top - 46), Vector2(X + 84, top - 41 + wv), Vector2(X + 61, top - 34)]), Pal.c("green"))
		Ink.text(self, "可提交", Vector2(X + 64, top - 50), 11, Pal.c("green"), Pal.bold)
	if must:
		Ink.text(self, "束流用完 · 请提交", Vector2(X + W * 0.5, top - 98 - sin(t * 5.0) * 2.0), 13, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 悬停描边
	if hot > 0.01:
		Ink.frame(self, rect().grow(4), Color(Pal.c("red"), 0.6 * hot), 2.0)
