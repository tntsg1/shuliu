extends Control
## 采购终端：纸质采购目录（5 张商品卡）+ 已有设备/饰品槽（可卖出）。键盘与鼠标都可操作

signal closed

var main: Node
var open := false
var v := 0.0
var _vv := 0.0
var area := "shop"        # shop / inv
var sel := 0
var flips := PackedFloat32Array([1, 1, 1, 1, 1])
var flip_v := PackedFloat32Array([0, 0, 0, 0, 0])
var shake := PackedFloat32Array([0, 0, 0, 0, 0])
var stamp_t := PackedFloat32Array([-1, -1, -1, -1, -1])
var msg := ""
var msg_t := 0.0
var money_disp := 0.0
var _vm := 0.0
var card_rects: Array = []
var inv_rects: Array = []   # [{rect, id}]
var t := 0.0

const CARD := Vector2(272, 448)

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func show_shop() -> void:
	open = true
	area = "shop"
	sel = 0
	mouse_filter = MOUSE_FILTER_STOP
	money_disp = main.run.money
	for i in 5:
		stamp_t[i] = 0.5 if i < main.run.offers.size() and main.run.offers[i].sold else -1.0
	Sfx.play("paper", -4.0)

func hide_shop() -> void:
	open = false
	mouse_filter = MOUSE_FILTER_IGNORE
	Sfx.play("paper", -8.0, 0.9)
	closed.emit()

func _inv_items() -> Array:
	return main.run.devices + main.run.relics

func handle(ev: InputEvent) -> void:
	if ev.is_action("back"):
		hide_shop()
	elif ev.is_action("ui_left") or ev.is_action("move_left"):
		_move(-1)
	elif ev.is_action("ui_right") or ev.is_action("move_right"):
		_move(1)
	elif ev.is_action("ui_up") or ev.is_action("ui_down"):
		var to := "inv" if ev.is_action("ui_down") else "shop"
		if to != area and (to == "shop" or not _inv_items().is_empty()):
			area = to
			sel = 0
			Sfx.play("tick", -10.0)
	elif ev.is_action("restart"):
		_refresh()
	elif ev.is_action("accelerate") or ev.is_action("interact"):
		_confirm()

func _move(d: int) -> void:
	var n: int = main.run.offers.size() if area == "shop" else _inv_items().size()
	if n == 0:
		return
	sel = (sel + d + n) % n
	Sfx.play("tick", -10.0, 1.2)

func _confirm() -> void:
	if area == "shop":
		var err: String = main.run.buy(sel)
		if err == "":
			stamp_t[sel] = 0.0
			Sfx.play("btn", -2.0, 0.8)
			Sfx.play("metal", -12.0, 1.4)
			main.gear_bought()
		else:
			shake[sel] = 1.0
			_say(err)
			Sfx.play("hit_low", -10.0, 1.4)
	else:
		var items := _inv_items()
		if sel < items.size():
			var id: String = items[sel]
			var gain: int = main.run.sell(id)
			if gain > 0:
				_say("卖掉了 %s，+$%d" % [Items.ALL[id].name, gain])
				Sfx.play("paper", -6.0, 1.2)
				main.gear_bought()
				sel = clampi(sel, 0, maxi(0, _inv_items().size() - 1))
				if _inv_items().is_empty():
					area = "shop"
					sel = 0

func _refresh() -> void:
	if main.run.refresh():
		for i in 5:
			flip_v[i] = -18.0 - i * 3.0
			stamp_t[i] = -1.0
		Sfx.play("paper", -4.0, 1.1)
	else:
		_say("经费不够刷新")

func _say(s: String) -> void:
	msg = s
	msg_t = 2.0

func _gui_input(ev: InputEvent) -> void:
	if not open:
		return
	if ev is InputEventMouseMotion:
		for i in card_rects.size():
			if card_rects[i].has_point(ev.position) and (area != "shop" or sel != i):
				area = "shop"; sel = i
		for i in inv_rects.size():
			if inv_rects[i].rect.has_point(ev.position) and (area != "inv" or sel != i):
				area = "inv"; sel = i
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for i in card_rects.size():
			if card_rects[i].has_point(ev.position):
				area = "shop"; sel = i; _confirm(); return
		for i in inv_rects.size():
			if inv_rects[i].rect.has_point(ev.position):
				area = "inv"; sel = i; _confirm(); return

func _process(dt: float) -> void:
	t += dt
	var r := Ink.spring(v, _vv, 1.0 if open else 0.0, 9.0, dt); v = r[0]; _vv = r[1]
	if main and main.run:
		r = Ink.spring(money_disp, _vm, float(main.run.money), 10.0, dt); money_disp = r[0]; _vm = r[1]
	for i in 5:
		# 翻牌：速度给负冲量，弹簧拉回 1
		flip_v[i] += (-120.0 * (flips[i] - 1.0) - 14.0 * flip_v[i]) * dt
		flips[i] += flip_v[i] * dt
		shake[i] = maxf(0.0, shake[i] - dt * 3.0)
		if stamp_t[i] >= 0.0:
			stamp_t[i] += dt
	msg_t = maxf(0.0, msg_t - dt)
	if v > 0.002:
		queue_redraw()

func _draw() -> void:
	if v < 0.002 or main == null:
		return
	var vp := get_viewport_rect().size
	var run: Run = main.run
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.35 * clampf(v, 0, 1)))
	var y0 := lerpf(vp.y + 40, 70.0, v)
	var pr := Rect2(150, y0, vp.x - 300, 900)
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	draw_rect(Rect2(pr.position + Vector2(10, 12), pr.size), Color(0, 0, 0, 0.2))
	draw_rect(pr, Pal.c("paper"))
	draw_rect(pr, el, false, 2.0)
	draw_rect(pr.grow(-10), Color(el, 0.3), false, 1.0)
	# 页眉
	Ink.text(self, "采购目录", pr.position + Vector2(48, 62), 36, ink, Pal.bold)
	Ink.text(self, "第七实验站 · 物资科 · 第 %03d 期" % (run.experiment_no + 1), pr.position + Vector2(232, 60), 16, Pal.c("text2"))
	Ink.text(self, "$ %d" % int(round(money_disp)), Vector2(pr.end.x - 260, pr.position.y + 66), 44, Pal.c("green"), Pal.mono)
	Ink.text(self, "经费", Vector2(pr.end.x - 320, pr.position.y + 60), 16, Pal.c("text2"))
	var rc := Rect2(pr.end.x - 520, pr.position.y + 32, 170, 40)
	draw_rect(rc, Pal.c("paper2"))
	draw_rect(rc, el, false, 1.4)
	Ink.text(self, "R  刷新  $%d" % run.refresh_cost, rc.position + Vector2(16, 28), 17, ink if run.money >= run.refresh_cost else Pal.c("text2"))
	draw_line(pr.position + Vector2(40, 90), Vector2(pr.end.x - 40, pr.position.y + 90), Color(el, 0.5), 1.4)
	# 商品卡
	card_rects.clear()
	var n := run.offers.size()
	var gap := 24.0
	var x0 := pr.get_center().x - (n * CARD.x + (n - 1) * gap) * 0.5
	for i in n:
		var o: Dictionary = run.offers[i]
		var cr := Rect2(x0 + i * (CARD.x + gap), pr.position.y + 116, CARD.x, CARD.y)
		card_rects.append(cr)
		_card(cr, o, i, area == "shop" and sel == i)
	# 已有：设备槽 + 饰品槽
	inv_rects.clear()
	var iy := pr.position.y + 600
	Ink.text(self, "已安装设备  %d/%d" % [run.devices.size(), Items.device_slots(run.stage)], Vector2(pr.position.x + 48, iy), 17, ink, Pal.bold)
	Ink.text(self, "护身符架  %d/%d" % [run.relics.size(), Items.relic_slots(run.stage)], Vector2(pr.position.x + 760, iy), 17, ink, Pal.bold)
	var idx := 0
	for kind in ["device", "relic"]:
		var list: Array = run.devices if kind == "device" else run.relics
		var slots := Items.device_slots(run.stage) if kind == "device" else Items.relic_slots(run.stage)
		var bx := pr.position.x + (48.0 if kind == "device" else 760.0)
		for j in slots:
			var r := Rect2(bx + j * 104, iy + 16, 92, 92)
			draw_rect(r, Pal.c("paper2"))
			draw_rect(r, Color(el, 0.5), false, 1.4)
			if j < list.size():
				var id: String = list[j]
				var hot := area == "inv" and sel == idx
				if hot:
					draw_rect(r.grow(4), Pal.c("red"), false, 3.0)
				Icons.draw(self, id, r.get_center(), 70.0)
				if run.uses.has(id):
					Ink.text(self, "×%d" % run.uses[id], r.end - Vector2(6, 6), 14, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
				inv_rects.append({"rect": r, "id": id})
				idx += 1
	# 选中库存时的说明条
	if area == "inv" and sel < _inv_items().size():
		var id: String = _inv_items()[sel]
		var d: Dictionary = Items.ALL[id]
		Ink.text(self, d.name + "：" + d.desc, Vector2(pr.position.x + 48, iy + 150), 16, ink)
		Ink.text(self, "E / 空格 卖出 +$%d" % Items.sell_price(id), Vector2(pr.end.x - 48, iy + 150), 16, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
	# 页脚
	draw_line(Vector2(pr.position.x + 40, pr.end.y - 70), Vector2(pr.end.x - 40, pr.end.y - 70), Color(el, 0.4), 1.0)
	Ink.text(self, "← →  选择      ↑ ↓  商品 / 已有      E / 空格  购买或卖出      R  刷新      Esc  离开", Vector2(pr.position.x + 48, pr.end.y - 32), 17, ink)
	if msg_t > 0.0:
		var a := clampf(msg_t / 0.3, 0.0, 1.0)
		Ink.text(self, msg, Vector2(pr.end.x - 48, pr.end.y - 32), 18, Color(Pal.c("red"), a), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)

func _card(cr: Rect2, o: Dictionary, i: int, hot: bool) -> void:
	var d: Dictionary = Items.ALL[o.id]
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	var lift := -10.0 if hot else 0.0
	var sx := clampf(flips[i], -1.0, 1.2)
	var jit := sin(t * 60.0) * 6.0 * shake[i]
	var c := cr.get_center() + Vector2(jit, lift)
	draw_set_transform(c, 0.0, Vector2(absf(sx), 1.0))
	var o2 := -cr.size * 0.5
	draw_rect(Rect2(o2 + Vector2(6, 8), cr.size), Color(0, 0, 0, 0.16 if hot else 0.08))
	var bg := Pal.c("paper") if d.kind == "relic" else Pal.c("paper2")
	draw_rect(Rect2(o2, cr.size), bg)
	draw_rect(Rect2(o2, cr.size), Pal.c("red") if hot else el, false, 3.0 if hot else 1.6)
	if sx < 0.15:
		draw_set_transform(Vector2.ZERO)
		return
	# 种类条 + 稀有度
	var rcol := Icons.rarity_col(d.rarity)
	draw_rect(Rect2(o2, Vector2(cr.size.x, 30)), Color(rcol, 0.85))
	Ink.text(self, ("设备" if d.kind == "device" else "饰品") + " · " + Items.RARITY_NAME[d.rarity], o2 + Vector2(14, 21), 15, Pal.c("paper"), Pal.bold)
	# 图标
	if absf(sx) > 0.6:
		Icons.draw(self, o.id, c + Vector2(0, -cr.size.y * 0.5 + 110), 110.0 * absf(sx), 0.0)
	draw_set_transform(c, 0.0, Vector2(absf(sx), 1.0))
	# 名称
	draw_string(Pal.bold, o2 + Vector2(16, 204), d.name, HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 32, 19, ink)
	# 效果
	draw_multiline_string(Pal.font, o2 + Vector2(16, 236), d.desc, HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 32, 15, 7, ink)
	# 物品故事
	if d.lore != "":
		draw_multiline_string(Pal.hand, o2 + Vector2(16, cr.size.y - 92), "“" + d.lore + "”", HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 32, 15, 3, Pal.c("blue"))
	# 价签
	var can: bool = main.run.money >= d.price
	var tag := Rect2(o2 + Vector2(cr.size.x - 104, cr.size.y - 46), Vector2(92, 34))
	draw_rect(tag, Pal.c("gold") if can else Pal.c("paper2"))
	draw_rect(tag, el, false, 1.4)
	Ink.text(self, "$%d" % d.price, tag.get_center() + Vector2(0, 8), 20, ink if can else Pal.c("red"), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	# 已购印章
	if o.sold:
		var k := clampf(stamp_t[i] / 0.14, 0.0, 1.0) if stamp_t[i] >= 0.0 else 1.0
		var sc := lerpf(1.8, 1.0, Ink.ease_out_back(k))
		draw_set_transform(c + Vector2(0, 30), -0.25, Vector2(sc * absf(sx), sc))
		draw_rect(Rect2(-90, -30, 180, 60), Color(Pal.c("paper"), 0.6))
		draw_rect(Rect2(-90, -30, 180, 60), Pal.c("red"), false, 4.0)
		Ink.text(self, "已购入", Vector2(0, 14), 34, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
