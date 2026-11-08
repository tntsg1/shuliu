extends Control
## 科研计划书三选一：三份文件从下面发上来；悬停抬起；点一份 → 它挪到中间、签字一笔一笔写上、盖红色“批准”章，
## 另外两份掉下去。键盘 ← → 选，E / 空格确定。

signal chosen(id: String)

var main: Node
var open := false
var t := 0.0
var offers: Array = []
var hover := -1
var pick := -1
var pick_t := 0.0
var rects: Array = []
var lift := PackedFloat32Array([0, 0, 0])
var lift_v := PackedFloat32Array([0, 0, 0])
var kb := false
var mouse_p := Vector2.ZERO
var stage_no := 2
var _stamped := false
var _sign_tick := 0

const CW := 380.0
const CH := 520.0
const GAP := 44.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

func show_plans(ids: Array, stage: int) -> void:
	offers = ids.duplicate()
	stage_no = stage
	open = true
	t = 0.0
	hover = -1
	pick = -1
	pick_t = 0.0
	_stamped = false
	_sign_tick = 0
	for i in 3:
		lift[i] = 0.0
		lift_v[i] = 0.0
	Sfx.play("paper", -2.0, 0.8)
	Sfx.play("whoosh", -8.0, 1.1)

func _card_center(i: int) -> Vector2:
	var vp := get_viewport_rect().size
	var x0 := vp.x * 0.5 - (CW + GAP)
	return Vector2(x0 + i * (CW + GAP), vp.y * 0.5 + 40.0)

func handle(ev: InputEvent) -> void:
	if pick >= 0 or t < 0.6:
		return
	kb = true
	if ev.is_action("ui_left") or ev.is_action("move_left"):
		hover = maxi(0, hover - 1) if hover >= 0 else 0
		Sfx.play("tick", -10.0, 1.2)
	elif ev.is_action("ui_right") or ev.is_action("move_right"):
		hover = mini(offers.size() - 1, hover + 1) if hover >= 0 else 0
		Sfx.play("tick", -10.0, 1.2)
	elif (ev.is_action("interact") or ev.is_action("accelerate")) and hover >= 0:
		_choose(hover)

func mouse(ev: InputEventMouse) -> void:
	if not open or pick >= 0:
		return
	mouse_p = ev.position
	if ev is InputEventMouseMotion:
		kb = false
		var h := -1
		for i in rects.size():
			if rects[i].has_point(ev.position):
				h = i
		if h != hover and h >= 0:
			Sfx.play("tick", -12.0, 1.3)
		hover = h
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover >= 0 else Input.CURSOR_ARROW)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and t > 0.6:
		for i in rects.size():
			if rects[i].has_point(ev.position):
				_choose(i)

func _choose(i: int) -> void:
	pick = i
	pick_t = 0.0
	Sfx.play("paper", -3.0, 1.1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _process(dt: float) -> void:
	if not open:
		return
	t += dt
	for i in 3:
		var tg := 1.0 if (i == hover and pick < 0) else 0.0
		lift_v[i] += (280.0 * (tg - lift[i]) - 20.0 * lift_v[i]) * minf(dt, 1.0 / 30.0)
		lift[i] += lift_v[i] * minf(dt, 1.0 / 30.0)
	if pick >= 0:
		pick_t += dt
		# 签字：一笔一笔，沙沙声
		var n := int(pick_t * 14.0)
		if pick_t > 0.35 and pick_t < 0.95 and n != _sign_tick:
			_sign_tick = n
			Sfx.play("tick", -18.0, 2.2 + randf() * 0.4)
		if not _stamped and pick_t > 1.0:
			_stamped = true
			Sfx.play("btn", 0.0, 0.6)
			Sfx.play("metal", -4.0, 0.8)
			if main:
				main.shake = maxf(main.shake, 0.6)
				main.hitstop(0.08)
		if pick_t > 2.1:
			open = false
			chosen.emit(offers[pick])
	queue_redraw()

func _draw() -> void:
	rects.clear()
	if not open:
		return
	var vp := get_viewport_rect().size
	var fade := clampf(t / 0.3, 0.0, 1.0) * (1.0 - clampf((pick_t - 1.8) / 0.3, 0.0, 1.0) if pick >= 0 else 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.42 * fade))
	# 标题
	var ha := clampf(t / 0.4, 0.0, 1.0) * fade
	Ink.text(self, "科研计划书 · 第 %d 阶段" % stage_no, Vector2(vp.x * 0.5 + 3, 110 + 3), 46, Color(0, 0, 0, 0.3 * ha), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "科研计划书 · 第 %d 阶段" % stage_no, Vector2(vp.x * 0.5, 110), 46, Color(Pal.c("paper"), ha), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "挑一份签字。每份都有好处，也都有代价。", Vector2(vp.x * 0.5, 156), 22, Color(Pal.c("paper"), 0.85 * ha), Pal.hand, HORIZONTAL_ALIGNMENT_CENTER)
	for i in offers.size():
		if i == pick:
			continue
		_card(i, vp)
	if pick >= 0:
		_card(pick, vp)
	if pick < 0 and t > 0.6:
		Ink.text(self, "鼠标点选 · ← → 选择  E / 空格 确定", Vector2(vp.x * 0.5, vp.y - 40), 16, Color(Pal.c("paper"), 0.8 * fade), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

func _card(i: int, vp: Vector2) -> void:
	var id: String = offers[i]
	var d: Dictionary = Plans.LIST[id]
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	# 发牌：从下面转着飞上来
	var deal := Ink.ease_out_back(clampf((t - i * 0.12) / 0.5, 0.0, 1.0))
	var c := _card_center(i)
	var p := Vector2(c.x, lerpf(vp.y + CH, c.y, deal))
	var rot := (1.0 - deal) * (0.5 - i * 0.4) + (i - 1) * 0.025
	var sc := 1.0
	var h: float = lift[i]
	p.y -= 22.0 * h
	sc += 0.04 * h
	if not kb and i == hover:
		rot += clampf((mouse_p.x - c.x) / CW, -0.5, 0.5) * 0.06 * h
	if pick >= 0:
		if i == pick:
			var mv := Ink.ease_in_out(clampf(pick_t / 0.35, 0.0, 1.0))
			p = p.lerp(Vector2(vp.x * 0.5, vp.y * 0.5 + 30.0), mv)
			sc = lerpf(sc, 1.16, mv)
			rot = lerpf(rot, -0.02, mv)
			if pick_t > 1.8:
				var out := Ink.ease_in_out(clampf((pick_t - 1.8) / 0.3, 0.0, 1.0))
				sc *= 1.0 - 0.5 * out
				p.y -= 200.0 * out
		else:
			var fall := clampf(pick_t / 0.6, 0.0, 1.0)
			p.y += vp.y * fall * fall
			rot += (i - pick) * 0.6 * fall
	var r := Rect2(-CW * 0.5, -CH * 0.5, CW, CH)
	if pick < 0 and deal > 0.95:
		rects.append(Rect2(p - Vector2(CW, CH) * 0.5 * sc, Vector2(CW, CH) * sc))
	else:
		rects.append(Rect2())
	draw_set_transform(p, rot, Vector2(sc, sc))
	draw_rect(Rect2(r.position + Vector2(10, 14) + Vector2(4, 12) * h, r.size), Color(0, 0, 0, 0.25 + 0.1 * h))
	draw_rect(r, Pal.c("paper"))
	draw_rect(Rect2(r.position, Vector2(CW, 54)), Pal.c("red").darkened(0.1))
	Ink.text(self, "科研计划书", r.position + Vector2(22, 36), 20, Pal.c("paper"), Pal.bold)
	Ink.text(self, "No.%03d" % (hash(id) % 997), Vector2(r.end.x - 20, r.position.y + 35), 14, Pal.c("paper"), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_rect(r, Pal.c("gold") if (i == hover and pick < 0) else el, false, 3.0 if i == hover else 1.6)
	draw_rect(r.grow(-8), Color(el, 0.25), false, 1.0)
	# 名称
	var nfs := 34
	while nfs > 20 and Ink.size(Pal.bold, d.name, nfs).x > CW - 48:
		nfs -= 1
	Ink.text(self, d.name, Vector2(0, r.position.y + 112), nfs, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(r.position.x + 30, r.position.y + 134), Vector2(r.end.x - 30, r.position.y + 134), Color(el, 0.4), 1.0)
	# 增益
	var y := r.position.y + 176.0
	Ink.text(self, "▲ 增益", Vector2(r.position.x + 28, y), 18, Pal.c("green"), Pal.bold)
	Ink.para(self, Pal.font, Vector2(r.position.x + 28, y + 30), d.good, CW - 56, 20, -1, ink)
	y += 116.0
	Ink.text(self, "▼ 代价", Vector2(r.position.x + 28, y), 18, Pal.c("red"), Pal.bold)
	Ink.para(self, Pal.font, Vector2(r.position.x + 28, y + 30), d.bad, CW - 56, 20, -1, ink)
	# 一句闲话
	Ink.para(self, Pal.hand, Vector2(r.position.x + 28, r.end.y - 118), "“" + d.lore + "”", CW - 56, 17, -1, Pal.c("blue"))
	# 签字栏
	var sy := r.end.y - 46.0
	Ink.text(self, "负责人签字：", Vector2(r.position.x + 28, sy), 16, Pal.c("text2"))
	draw_line(Vector2(r.position.x + 130, sy + 4), Vector2(r.end.x - 30, sy + 4), Color(el, 0.6), 1.2)
	if i == pick:
		# 签名一笔一笔写出来
		var sk := clampf((pick_t - 0.35) / 0.6, 0.0, 1.0)
		var pts := PackedVector2Array()
		var n := int(40 * sk)
		for k in n:
			var u := k / 39.0
			pts.append(Vector2(r.position.x + 140 + u * 170.0, sy - 4 + sin(u * 23.0) * 9.0 * (1.0 - u * 0.4) + cos(u * 7.0) * 4.0))
		if pts.size() > 1:
			draw_polyline(pts, Pal.c("blue"), 2.4, true)
		# 红色“批准”章砸下来
		if pick_t > 1.0:
			var sk2 := clampf((pick_t - 1.0) / 0.14, 0.0, 1.0)
			var ssc := lerpf(2.4, 1.0, Ink.ease_out_back(sk2))
			draw_set_transform(p + Vector2(70, 120).rotated(rot) * sc, rot - 0.3, Vector2(sc * ssc, sc * ssc))
			draw_circle(Vector2.ZERO, 70.0, Color(Pal.c("red"), 0.1))
			draw_arc(Vector2.ZERO, 70.0, 0.4, TAU, 48, Pal.c("red"), 6.0, true)
			draw_arc(Vector2.ZERO, 58.0, 0, TAU, 48, Pal.c("red"), 2.0, true)
			Ink.text(self, "批准", Vector2(0, 14), 40, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
