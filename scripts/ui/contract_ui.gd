extends Control
## 教授办公桌上的合同（M5-11/15/16）：左边课题组合同（5 个组，没解锁的写解锁条件），
## 右边本局的 3 份挑战合同 + “不签”。只能在本局第一束实验开始之前签 / 改签。
## 键盘：← → 换栏、↑ ↓ 选、E / 空格签、Esc 离开；鼠标：悬停选、点击签。

signal closed

var main: Node
var open := false
var t := 0.0
var side := 0             # 0 课题组 / 1 挑战
var row := 0
var rects: Array = []     # [[side, row, Rect2]]
var msg := ""
var msg_t := 0.0
var stamp_t := -9.0
var stamp_at := Vector2i(-1, -1)

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

func show_ui() -> void:
	open = true
	visible = true
	t = 0.0
	msg = ""
	side = 0
	row = Contracts.GROUP_ORDER.find(main.run.group)
	Sfx.play("paper", -4.0, 0.8)

func close() -> void:
	open = false
	visible = false
	Sfx.play("paper", -8.0, 1.1)
	closed.emit()

func _rows(s: int) -> int:
	return Contracts.GROUP_ORDER.size() if s == 0 else main.run.challenge_offers.size() + 1

func handle(ev: InputEvent) -> void:
	if not open or t < 0.25:
		return
	if ev.is_action("back"):
		close()
	elif ev.is_action("move_left") or ev.is_action("ui_left"):
		side = 0
		row = mini(row, _rows(0) - 1)
		_tick()
	elif ev.is_action("move_right") or ev.is_action("ui_right"):
		side = 1
		row = mini(row, _rows(1) - 1)
		_tick()
	elif ev.is_action("ui_up"):
		row = maxi(0, row - 1)
		_tick()
	elif ev.is_action("ui_down"):
		row = mini(_rows(side) - 1, row + 1)
		_tick()
	elif ev.is_action("interact") or ev.is_action("accelerate"):
		_sign(side, row)

func _tick() -> void:
	Sfx.play("tick", -12.0, 1.3)

func mouse(ev: InputEventMouse) -> void:
	if not open:
		return
	for x in rects:
		if (x[2] as Rect2).has_point(ev.position):
			if ev is InputEventMouseMotion and (side != x[0] or row != x[1]):
				side = x[0]
				row = x[1]
				_tick()
			elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_sign(x[0], x[1])
			return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		close()

func _sign(s: int, r: int) -> void:
	var run: Run = main.run
	var err := ""
	if s == 0:
		var gid: String = Contracts.GROUP_ORDER[r]
		if not Meta.group_open(gid):
			err = "还没有解锁「%s」合同，需要先完成对应的解锁条件。" % Contracts.GROUPS[gid].name
		else:
			err = run.sign_group(gid)
	else:
		var cid: String = run.challenge_offers[r] if r < run.challenge_offers.size() else ""
		err = run.sign_challenge(cid)
	if err != "":
		msg = err
		msg_t = t
		Sfx.play("hit_low", -10.0, 1.3)
		return
	stamp_t = t
	stamp_at = Vector2i(s, r)
	msg = "签好了"
	msg_t = t
	Sfx.play("btn", -2.0, 0.6)
	Sfx.play("paper", -6.0, 1.2)

func _process(dt: float) -> void:
	if open:
		t += dt
		queue_redraw()

func _draw() -> void:
	if not open:
		return
	var run: Run = main.run
	var vp := get_viewport_rect().size
	var a := clampf(t / 0.2, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.45 * a))
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	var pr := Rect2(170, 120 + (1.0 - Ink.ease_out_cubic(a)) * 60.0, vp.x - 340, vp.y - 240)
	draw_rect(Rect2(pr.position + Vector2(6, 9), pr.size), Color(0, 0, 0, 0.18))
	draw_rect(pr, Pal.c("paper"))
	Ink.frame(self, pr, el, Ink.W1)
	Ink.text(self, "合同", pr.position + Vector2(40, 58), 34, ink, Pal.bold)
	var can := run.can_sign()
	Ink.text(self, "合同需要在第一束实验开始之前签订，开始实验后就不能再修改了。" if can else "本局实验已经开始，下一局才能重新选择合同。", pr.position + Vector2(130, 56), 15, Pal.c("text2") if can else Pal.c("red"), Pal.bold if not can else Pal.font)
	draw_line(pr.position + Vector2(30, 80), Vector2(pr.end.x - 30, pr.position.y + 80), Color(el, 0.4), Ink.W2)
	rects.clear()
	var colw := (pr.size.x - 120) * 0.5
	for s in 2:
		var x0 := pr.position.x + 40 + s * (colw + 40)
		Ink.text(self, "课题组合同 · 决定开局配置" if s == 0 else "挑战合同 · 多拿声望（3 选 1，可以不签）", Vector2(x0, pr.position.y + 118), 18, ink, Pal.bold)
		var n := _rows(s)
		var rh := 92.0 if s == 0 else 104.0
		for r in n:
			var rr := Rect2(x0, pr.position.y + 140 + r * (rh + 10), colw, rh)
			rects.append([s, r, rr])
			var is_sel := side == s and row == r
			var title := ""
			var desc := ""
			var tag := ""
			var on := false
			var locked := false
			if s == 0:
				var gid: String = Contracts.GROUP_ORDER[r]
				var g: Dictionary = Contracts.GROUPS[gid]
				title = g.name
				desc = g.desc
				on = run.group == gid
				locked = not Meta.group_open(gid)
				if locked:
					desc = "解锁条件：" + g.unlock
			else:
				if r < run.challenge_offers.size():
					var cid: String = run.challenge_offers[r]
					var c: Dictionary = Contracts.CHALLENGES[cid]
					title = c.name
					desc = c.desc
					tag = "声望 +%d%%" % int(round(float(c.bonus) * 100.0))
					on = run.challenge == cid
				else:
					title = "不签"
					desc = "不签订合同，继续正常实验，本局不会获得额外的科研声望加成。"
					on = run.challenge == ""
			draw_rect(rr, Pal.c("paper2") if not on else Pal.c("gold").lerp(Pal.c("paper"), 0.55))
			Ink.frame(self, rr, Pal.c("red") if is_sel else Color(el, 0.55), 3.0 if is_sel else Ink.W3)
			var ta := 0.45 if locked else 1.0
			Ink.text(self, title, rr.position + Vector2(18, 34), 21, Color(ink, ta), Pal.bold)
			Ink.para(self, Pal.font, rr.position + Vector2(18, 64), desc, rr.size.x - 170, 15, 2, Color(Pal.c("text2"), ta))
			if tag != "":
				Ink.text(self, tag, Vector2(rr.end.x - 18, rr.position.y + 34), 18, Pal.c("green").darkened(0.15), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
			if locked:
				Ink.text(self, "未解锁", Vector2(rr.end.x - 18, rr.position.y + 34), 16, Pal.c("text2"), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
			if on:
				# 签了：红章（刚签的从大到小盖下去）
				var k := clampf((t - stamp_t) / 0.16, 0.0, 1.0) if stamp_at == Vector2i(s, r) else 1.0
				var sc := lerpf(1.9, 1.0, Ink.ease_out_back(k))
				draw_set_transform(Vector2(rr.end.x - 64, rr.end.y - 30), -0.22, Vector2(sc, sc))
				Ink.frame(self, Rect2(-40, -15, 80, 30), Pal.c("red"), 3.0)
				Ink.text(self, "已签", Vector2(0, 8), 18, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
				draw_set_transform(Vector2.ZERO)
	if msg != "" and t - msg_t < 3.0:
		Ink.text(self, msg, Vector2(pr.position.x + 40, pr.end.y - 30), 16, Pal.c("green").darkened(0.2) if msg == "签好了" else Pal.c("red"), Pal.bold)
	else:
		Ink.text(self, "← → 换栏    ↑ ↓ 选    E / 空格 签    Esc / 右键 离开", Vector2(pr.position.x + 40, pr.end.y - 30), 14, Pal.c("text2"), Pal.font)
