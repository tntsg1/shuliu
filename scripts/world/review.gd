extends Node2D
## 考核审核台（世界里，观测舱右侧）：桌上收件盘里的实验报告一张张摞起来，墙上一块进度牌。
## 够线时台灯变绿、插一面“可提交”小旗；束流用完时红灯闪，提醒必须来提交。

const X := 1400.0          # 桌子左缘
const STAND := 1478.0      # 玩家站位
const W := 150.0
const STASH := preload("res://scripts/world/stash.gd")

var main: Node
var t := 0.0
var hot := 0.0             # 悬停/靠近高亮
var bump := 0.0            # 新报告落进收件盘时弹一下
var _last_n := 0

func rect() -> Rect2:
	return Rect2(X - 10, Geo.FLOOR - 252, W + 20, 252)

## 收件盘的位置（实验报告纸条飞进这里）
func inbox() -> Vector2:
	return Vector2(X + 39, Geo.FLOOR - 82)

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
	# 像锻刀模拟器的献上窗口：要求多少、已经攒了多少，一眼看清
	var br := Rect2(X + 4, y - 252, W - 8, 92)
	Ink.drop(self, br)
	draw_rect(br, Pal.c("paper"))
	Ink.frame(self, br, el, Ink.W2)
	draw_rect(Rect2(br.position, Vector2(br.size.x, 16)), Pal.c("red") if must else (Pal.c("green") if can else Pal.c("blue")))
	Ink.text(self, "考核审核台", br.position + Vector2(br.size.x * 0.5, 13), 12, Pal.c("paper"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	if not run.won():
		var big := Run.is_big(run.stage)
		Ink.text(self, ("第 %d 次评审 · 大考" if big else "第 %d 次评审") % (run.stage + 1), br.position + Vector2(10, 33), 12, Pal.c("red") if big else Pal.c("text2"), Pal.bold if big else Pal.font)
		Ink.text(self, "要求", br.position + Vector2(10, 52), 12, Pal.c("text2"))
		Ink.text(self, main.fmt(run.line()), Vector2(br.end.x - 10, br.position.y + 52), 14, Pal.c("text"), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
		Ink.text(self, "已攒", br.position + Vector2(10, 70), 12, Pal.c("text2"))
		Ink.text(self, main.fmt(run.total), Vector2(br.end.x - 10, br.position.y + 70), 14, Pal.c("green") if can else Pal.c("text"), Pal.mono if not can else Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
		var pr := Rect2(br.position.x + 8, br.end.y - 14, br.size.x - 16, 7)
		draw_rect(pr, Pal.c("paper2"))
		var k := clampf(float(run.total) / maxf(1.0, run.line()), 0.0, 1.0)
		draw_rect(Rect2(pr.position, Vector2(pr.size.x * k, pr.size.y)), Pal.c("green") if can else Pal.c("ramp2"))
		Ink.frame(self, pr, el, 1.0)
	Ink.rivet(self, br.position + Vector2(6, 22), 1.8)
	Ink.rivet(self, Vector2(br.end.x - 6, br.position.y + 22), 1.8)
	# —— 桌子 ——
	var top := y - 74.0
	Ink.ground(self, X + 8, X + 18)
	Ink.ground(self, X + W - 18, X + W - 8)
	Ink.box(self, Rect2(X, top, W, 10), Pal.c("equip"), el, Ink.W1, 611)
	Ink.box(self, Rect2(X + 8, top + 10, 10, 64), Pal.c("equip_dark"), el, Ink.W2, 612)
	Ink.box(self, Rect2(X + W - 18, top + 10, 10, 64), Pal.c("equip_dark"), el, Ink.W2, 613)
	Ink.box(self, Rect2(X + W - 60, top + 10, 42, 34), Pal.c("equip_dark"), el, Ink.W2, 614)
	draw_rect(Rect2(X + W - 46, top + 24, 14, 3), el)
	# 考核篮子（Q70）：这次评审交进来的满瓶立在铁丝篮里，篮子满了就挤着放
	var bk := Rect2(X + 6, top - 34, 70, 34)
	var basket: Array = run.basket
	var nb := basket.size()
	var gap := minf(14.0, 58.0 / maxf(1.0, nb))
	for i in nb:
		var lift := -sin(bump * PI) * 6.0 if i == nb - 1 else 0.0
		STASH.full_bottle(self, Vector2(bk.position.x + 10 + i * gap, top - 2 + lift), 0.42, basket[i])
	# 铁丝篮：前面几根竖丝 + 上下沿
	draw_line(Vector2(bk.position.x, bk.position.y + 14), Vector2(bk.end.x, bk.position.y + 14), el, Ink.W2)
	draw_line(Vector2(bk.position.x + 2, top), Vector2(bk.end.x - 2, top), el, Ink.W2)
	for k in 7:
		var xx := bk.position.x + 3 + k * (bk.size.x - 6) / 6.0
		draw_line(Vector2(xx, bk.position.y + 14), Vector2(xx + (1.0 if k < 3 else -1.0), top), Color(el, 0.7), Ink.W3)
	draw_line(Vector2(bk.position.x + 3, bk.position.y + 24), Vector2(bk.end.x - 3, bk.position.y + 24), Color(el, 0.5), Ink.W3)
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
		# 牌子上方插一张纸条（纸底，背后是红色磁铁也看得清）
		var my := y - 262.0 - sin(t * 5.0) * 2.0
		var mw := Ink.size(Pal.bold, "束流用完 · 请提交", 13).x + 16.0
		var mr := Rect2(X + W * 0.5 - mw * 0.5, my - 16, mw, 22)
		Ink.drop(self, mr)
		draw_rect(mr, Pal.c("paper"))
		Ink.frame(self, mr, Pal.c("red"), Ink.W2)
		Ink.text(self, "束流用完 · 请提交", Vector2(X + W * 0.5, my), 13, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 悬停描边
	if hot > 0.01:
		Ink.frame(self, rect().grow(4), Color(Pal.c("red"), 0.6 * hot), 2.0)
