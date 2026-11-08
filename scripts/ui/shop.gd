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
var refresh_rect := Rect2()
var close_rect := Rect2()
var hover_extra := ""
var t := 0.0
var pr_cache := Rect2()

# —— 库存槽动画状态 ——
const HOLD := 0.55          # 按住多久卖出（防误卖）
var kb := false             # 最近一次操作是键盘
var mouse_p := Vector2(-999, -999)
var hover_id := ""          # 鼠标下的库存物件
var hover_card := -1        # 鼠标下的商品卡
var hov := {}               # id -> [值, 速度]（欠阻尼弹簧，有一点回弹）
var spos := {}              # id -> [位置, 速度]（卖掉后其余物件滑过去补位）
var pop := {}               # id -> 落位挤压 1..0
var in_air := {}            # id -> 飞行中，不在槽里画
var flyers: Array = []      # 买入/卖出的飞行图标
var coins: Array = []       # 卖出时飞向经费的硬币
var puffs: Array = []       # 落位/离开的圆环
var hold_id := ""
var hold_t := 0.0
var wiggle := {}            # id -> 1..0（点一下没按住：摇一摇提示）
var confirm_id := ""        # 键盘卖出需要按两次
var confirm_t := 0.0
var money_pulse := 0.0
var full_flash := {"device": 0.0, "relic": 0.0}
var tip_id := ""
var tip_v := 0.0
var card_h := PackedFloat32Array([0, 0, 0, 0, 0])
var card_hv := PackedFloat32Array([0, 0, 0, 0, 0])

const CARD := Vector2(272, 448)

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func show_shop() -> void:
	open = true
	area = "shop"
	sel = 0
	money_disp = main.run.money
	flyers.clear(); coins.clear(); puffs.clear(); in_air.clear()
	hold_id = ""; confirm_id = ""; tip_id = ""; tip_v = 0.0
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
	kb = true
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
		var o_id: String = main.run.offers[sel].id if sel < main.run.offers.size() else ""
		var err: String = main.run.buy(sel)
		if err == "":
			stamp_t[sel] = 0.0
			Sfx.play("btn", -2.0, 0.8)
			Sfx.play("whoosh", -14.0, 1.3)
			_fly_in(o_id, sel)
			main.gear_bought()
		else:
			shake[sel] = 1.0
			_say(err)
			Sfx.play("hit_low", -10.0, 1.4)
			if err.contains("槽已满") and o_id != "":
				full_flash[Items.ALL[o_id].kind] = 1.0
	else:
		var items := _inv_items()
		if sel < items.size():
			var id: String = items[sel]
			if confirm_id == id and confirm_t > 0.0:
				_sell(id)
			else:
				confirm_id = id
				confirm_t = 2.0
				wiggle[id] = 1.0
				_say("再按一次 E 确认卖出 %s" % Items.ALL[id].name)
				Sfx.play("tick", -8.0, 0.9)

## 卖出：图标弹起旋转飞走，硬币一枚枚飞进经费
func _sell(id: String) -> void:
	var from: Vector2 = spos[id][0] if spos.has(id) else pr_cache.get_center()
	var gain: int = main.run.sell(id)
	hold_id = ""
	confirm_id = ""
	if gain <= 0:
		return
	money_disp = float(main.run.money - gain)   # 经费等硬币到了再涨
	flyers.append({"id": id, "a": from, "b": from + Vector2(randf_range(-30, 30), -150), "t": 0.0, "dur": 0.5, "out": true, "spin": randf_range(-1, 1)})
	puffs.append({"p": from, "t": 0.0, "col": Pal.c("red")})
	var n := clampi(gain / 2, 3, 9)
	for i in n:
		coins.append({"a": from + Vector2(randf_range(-16, 16), randf_range(-10, 10)), "b": _money_pos(),
			"t": -i * 0.05, "dur": 0.5 + randf() * 0.12, "h": randf_range(120, 220), "v": float(gain) / n})
	hov.erase(id)
	spos.erase(id)
	_say("卖掉了 %s，+$%d" % [Items.ALL[id].name, gain])
	Sfx.play("paper", -6.0, 1.2)
	Sfx.play("whoosh", -12.0, 1.6)
	main.gear_bought()
	sel = clampi(sel, 0, maxi(0, _inv_items().size() - 1))
	if _inv_items().is_empty():
		area = "shop"
		sel = 0

## 买入：图标从商品卡沿弧线飞进对应空槽，落下时挤压回弹
func _fly_in(id: String, card_i: int) -> void:
	var def: Dictionary = Items.ALL[id]
	var list: Array = main.run.devices if def.kind == "device" else main.run.relics
	var to := _slot_rect(def.kind, list.size() - 1).get_center()
	var cr: Rect2 = card_rects[card_i] if card_i < card_rects.size() else Rect2(to, Vector2.ZERO)
	var from := cr.get_center() + Vector2(0, -cr.size.y * 0.5 + 110)
	in_air[id] = true
	spos[id] = [to, Vector2.ZERO]
	flyers.append({"id": id, "a": from, "b": to, "t": 0.0, "dur": 0.62, "out": false, "spin": 0.0})

func _money_pos() -> Vector2:
	return Vector2(pr_cache.end.x - 190, pr_cache.position.y + 50)

func _slot_rect(kind: String, j: int) -> Rect2:
	var bx := pr_cache.position.x + (48.0 if kind == "device" else 760.0)
	return Rect2(bx + j * 104, pr_cache.position.y + 600 + 16, 92, 92)

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

func mouse(ev: InputEvent) -> void:
	if not open:
		return
	if ev is InputEventMouseMotion:
		kb = false
		mouse_p = ev.position
		hover_extra = "refresh" if refresh_rect.has_point(ev.position) else ("close" if close_rect.has_point(ev.position) else "")
		hover_card = -1
		for i in card_rects.size():
			if card_rects[i].has_point(ev.position):
				hover_card = i
				if area != "shop" or sel != i:
					area = "shop"
					sel = i
					Sfx.play("tick", -16.0, 1.5)
		var hid := ""
		for i in inv_rects.size():
			if inv_rects[i].rect.has_point(ev.position):
				hid = inv_rects[i].id
				if area != "inv" or sel != i:
					area = "inv"
					sel = i
		if hid != hover_id:
			if hid != "":
				Sfx.play("tick", -14.0, 1.25)
			if hold_id != "" and hid != hold_id:
				hold_id = ""     # 拖出去 = 取消
			hover_id = hid
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover_extra != "" or _over_any(ev.position) else Input.CURSOR_ARROW)
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
		if hold_id != "":
			if hold_t < 0.18:
				wiggle[hold_id] = 1.0
				_say("按住不放才会卖出（防止误卖）")
			hold_id = ""
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		hide_shop()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		kb = false
		mouse_p = ev.position
		if refresh_rect.has_point(ev.position):
			_refresh()
			return
		if close_rect.has_point(ev.position):
			hide_shop()
			return
		for i in card_rects.size():
			if card_rects[i].has_point(ev.position):
				area = "shop"
				sel = i
				_confirm()
				return
		for i in inv_rects.size():
			if inv_rects[i].rect.has_point(ev.position):
				area = "inv"
				sel = i
				hold_id = inv_rects[i].id
				hold_t = 0.0
				Sfx.play("lever", -16.0, 1.6)
				return

func _hot_id() -> String:
	if kb:
		var items := _inv_items()
		return items[sel] if area == "inv" and sel < items.size() else ""
	return hover_id

func _hot_card() -> int:
	if kb:
		return sel if area == "shop" else -1
	return hover_card

func _process(dt: float) -> void:
	t += dt
	var r := Ink.spring(v, _vv, 1.0 if open else 0.0, 9.0, dt); v = r[0]; _vv = r[1]
	if main and main.run:
		if coins.is_empty():
			r = Ink.spring(money_disp, _vm, float(main.run.money), 10.0, dt); money_disp = r[0]; _vm = r[1]
	for i in 5:
		# 翻牌：速度给负冲量，弹簧拉回 1
		flip_v[i] += (-120.0 * (flips[i] - 1.0) - 14.0 * flip_v[i]) * dt
		flips[i] += flip_v[i] * dt
		shake[i] = maxf(0.0, shake[i] - dt * 3.0)
		if stamp_t[i] >= 0.0:
			stamp_t[i] += dt
	msg_t = maxf(0.0, msg_t - dt)
	_anim(dt)
	if v > 0.002:
		queue_redraw()

func _anim(dt: float) -> void:
	var d := minf(dt, 1.0 / 30.0)
	var hot := _hot_id()
	var hc := _hot_card()
	for i in 5:
		var tg := 1.0 if i == hc else 0.0
		card_hv[i] += (260.0 * (tg - card_h[i]) - 20.0 * card_hv[i]) * d
		card_h[i] += card_hv[i] * d
	for id in _inv_items():
		if not hov.has(id):
			hov[id] = [0.0, 0.0]
		var h: Array = hov[id]
		var tg := 1.0 if id == hot else 0.0
		h[1] += (300.0 * (tg - h[0]) - 19.0 * h[1]) * d
		h[0] += h[1] * d
	for k in pop.keys():
		pop[k] = maxf(0.0, pop[k] - dt * 2.4)
	for k in wiggle.keys():
		wiggle[k] = maxf(0.0, wiggle[k] - dt * 2.2)
	for k in full_flash.keys():
		full_flash[k] = maxf(0.0, full_flash[k] - dt * 1.2)
	money_pulse = maxf(0.0, money_pulse - dt * 3.0)
	confirm_t = maxf(0.0, confirm_t - dt)
	if hold_id != "":
		var before := hold_t
		hold_t += dt
		# 越接近卖出，咔哒声越密越高
		if floor(before / 0.11) != floor(hold_t / 0.11):
			Sfx.play("tick", -18.0, 1.0 + hold_t * 1.2)
		if hold_t >= HOLD:
			_sell(hold_id)
	# 提示条：切换物件时重新展开
	if hot != tip_id:
		tip_id = hot
		tip_v = 0.0
	tip_v = minf(1.0, tip_v + dt * 5.0) if tip_id != "" and hold_id == "" else maxf(0.0, tip_v - dt * 8.0)
	for f in flyers:
		f.t += dt
		if not f.out and f.t >= f.dur:
			in_air.erase(f.id)
			pop[f.id] = 1.0
			puffs.append({"p": f.b, "t": 0.0, "col": Icons.rarity_col(Items.ALL[f.id].rarity)})
			Sfx.play("metal", -10.0, 1.3)
			Sfx.play("btn2", -14.0, 1.8)
	flyers = flyers.filter(func(f): return f.t < f.dur)
	for c in coins:
		c.t += dt
		if c.t >= c.dur:
			money_disp += c.v
			money_pulse = 1.0
			Sfx.play("tick", -12.0, 1.8 + randf() * 0.4)
	coins = coins.filter(func(c): return c.t < c.dur)
	for p in puffs:
		p.t += dt
	puffs = puffs.filter(func(p): return p.t < 0.45)

func _draw() -> void:
	if v < 0.002 or main == null:
		return
	var vp := get_viewport_rect().size
	var run: Run = main.run
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.35 * clampf(v, 0, 1)))
	var y0 := lerpf(vp.y + 40, 70.0, v)
	var pr := Rect2(150, y0, vp.x - 300, 900)
	pr_cache = pr
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	draw_rect(Rect2(pr.position + Vector2(10, 12), pr.size), Color(0, 0, 0, 0.2))
	draw_rect(pr, Pal.c("paper"))
	draw_rect(pr, el, false, 2.0)
	draw_rect(pr.grow(-10), Color(el, 0.3), false, 1.0)
	# 页眉
	Ink.text(self, "采购目录", pr.position + Vector2(48, 62), 36, ink, Pal.bold)
	Ink.text(self, "第七实验站 · 物资科 · 第 %03d 期" % (run.experiment_no + 1), pr.position + Vector2(232, 60), 16, Pal.c("text2"))
	draw_set_transform(Vector2(pr.end.x - 260, pr.position.y + 66), 0.0, Vector2.ONE * (1.0 + money_pulse * 0.12))
	Ink.text(self, "$ %d" % int(round(money_disp)), Vector2.ZERO, 44, Pal.c("green").lerp(Pal.c("gold"), money_pulse), Pal.mono)
	draw_set_transform(Vector2.ZERO)
	Ink.text(self, "经费", Vector2(pr.end.x - 320, pr.position.y + 60), 16, Pal.c("text2"))
	var rc := Rect2(pr.end.x - 520, pr.position.y + 32, 170, 40)
	refresh_rect = rc
	draw_rect(rc.grow(2) if hover_extra == "refresh" else rc, Pal.c("gold") if hover_extra == "refresh" else Pal.c("paper2"))
	draw_rect(rc, el, false, 1.4)
	Ink.text(self, "R  刷新  $%d" % run.refresh_cost, rc.position + Vector2(16, 28), 17, ink if run.money >= run.refresh_cost else Pal.c("text2"))
	draw_line(pr.position + Vector2(40, 90), Vector2(pr.end.x - 40, pr.position.y + 90), Color(el, 0.5), 1.4)
	# 关闭（×）
	close_rect = Rect2(pr.end.x - 64, pr.position.y + 14, 48, 48)
	var xc := close_rect.get_center()
	if hover_extra == "close":
		draw_circle(xc, 22.0, Color(Pal.c("red"), 0.15))
	draw_line(xc - Vector2(12, 12), xc + Vector2(12, 12), Pal.c("red") if hover_extra == "close" else ink, 3.0, true)
	draw_line(xc + Vector2(-12, 12), xc + Vector2(12, -12), Pal.c("red") if hover_extra == "close" else ink, 3.0, true)
	# 商品卡
	card_rects.clear()
	var n := run.offers.size()
	var gap := 24.0
	var x0 := pr.get_center().x - (n * CARD.x + (n - 1) * gap) * 0.5
	for i in n:
		var o: Dictionary = run.offers[i]
		var cr := Rect2(x0 + i * (CARD.x + gap), pr.position.y + 116, CARD.x, CARD.y)
		card_rects.append(cr)
		_card(cr, o, i, _hot_card() == i)
	_draw_inventory(pr, el, ink)
	# 页脚
	draw_line(Vector2(pr.position.x + 40, pr.end.y - 70), Vector2(pr.end.x - 40, pr.end.y - 70), Color(el, 0.4), 1.0)
	Ink.text(self, "鼠标：点击商品购买 · 按住已有物品卖出 · 右键离开      键盘：← → 选择  ↑ ↓ 切换  E 购买 / 两次 E 卖出  R 刷新  Esc 离开", Vector2(pr.position.x + 48, pr.end.y - 32), 16, ink)
	if msg_t > 0.0:
		var a := clampf(msg_t / 0.3, 0.0, 1.0)
		Ink.text(self, msg, Vector2(pr.end.x - 48, pr.end.y - 32), 18, Color(Pal.c("red"), a), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)

func _card(cr: Rect2, o: Dictionary, i: int, hot: bool) -> void:
	var d: Dictionary = Items.ALL[o.id]
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	var ch := card_h[i]
	var lift := -16.0 * ch
	var sx := clampf(flips[i], -1.0, 1.2) * (1.0 + 0.025 * ch)
	var jit := sin(t * 60.0) * 6.0 * shake[i]
	var c := cr.get_center() + Vector2(jit, lift)
	var tilt := 0.0
	if not kb and hover_card == i:
		tilt = clampf((mouse_p.x - cr.get_center().x) / cr.size.x, -0.5, 0.5) * 0.05 * ch
	draw_set_transform(c, tilt, Vector2(absf(sx), 1.0 + 0.025 * ch))
	var o2 := -cr.size * 0.5
	draw_rect(Rect2(o2 + Vector2(6, 8) + Vector2(4, 14) * ch, cr.size), Color(0, 0, 0, 0.08 + 0.1 * ch))
	var bg := Pal.c("paper") if d.kind == "relic" else Pal.c("paper2")
	draw_rect(Rect2(o2, cr.size), bg)
	draw_rect(Rect2(o2, cr.size), Pal.c("red") if hot else el, false, 3.0 if hot else 1.6)
	if absf(sx) < 0.15:
		draw_set_transform(Vector2.ZERO)
		return
	# 种类条 + 稀有度
	var rcol := Icons.rarity_col(d.rarity)
	draw_rect(Rect2(o2, Vector2(cr.size.x, 30)), Color(rcol, 0.85))
	Ink.text(self, ("设备" if d.kind == "device" else "饰品") + " · " + Items.RARITY_NAME[d.rarity], o2 + Vector2(14, 21), 15, Pal.c("paper"), Pal.bold)
	# 图标
	if absf(sx) > 0.6:
		Icons.draw(self, o.id, c + Vector2(0, -cr.size.y * 0.5 + 110 - 6.0 * ch), 110.0 * absf(sx) * (1.0 + 0.08 * ch), sin(t * 3.0) * 0.05 * ch)
	draw_set_transform(c, tilt, Vector2(absf(sx), 1.0 + 0.025 * ch))
	# 名称
	# 名字太长就缩小字号，别被截断
	var nfs := 19
	while nfs > 13 and Pal.bold.get_string_size(d.name, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > cr.size.x - 32:
		nfs -= 1
	draw_string(Pal.bold, o2 + Vector2(16, 204), d.name, HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 32, nfs, ink)
	# 效果
	draw_multiline_string(Pal.font, o2 + Vector2(16, 236), d.desc, HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 32, 15, 7, ink)
	# 物品故事
	if d.lore != "":
		draw_multiline_string(Pal.hand, o2 + Vector2(16, cr.size.y - 92), "“" + d.lore + "”", HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 32, 15, 3, Pal.c("blue"))
	# 价签
	var price: int = o.get("price", d.price)
	var can: bool = main.run.money >= price
	var tag := Rect2(o2 + Vector2(cr.size.x - 104, cr.size.y - 46), Vector2(92, 34))
	draw_rect(tag, Pal.c("gold") if can else Pal.c("paper2"))
	draw_rect(tag, el, false, 1.4)
	Ink.text(self, "$%d" % price, tag.get_center() + Vector2(0, 8), 20, ink if can else Pal.c("red"), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	if price < d.price:
		# 打折：原价划掉 + 红色“半价”小章
		var op := tag.position + Vector2(-58, 24)
		Ink.text(self, "$%d" % d.price, op, 15, Pal.c("text2"), Pal.mono)
		draw_line(op + Vector2(-2, -6), op + Vector2(36, -6), Pal.c("red"), 2.0)
		Ink.text(self, "免费" if price == 0 else "半价", tag.position + Vector2(-8, -8), 14, Pal.c("red"), Pal.bold)
	if hot and not o.sold:
		var can2: bool = main.run.money >= price
		Ink.text(self, ("点击购买" if can2 else "经费不够"), o2 + Vector2(16, cr.size.y - 22), 15, Pal.c("red") if not can2 else Pal.c("green"), Pal.bold)
	# 已购印章
	if o.sold:
		var k := clampf(stamp_t[i] / 0.14, 0.0, 1.0) if stamp_t[i] >= 0.0 else 1.0
		var sc := lerpf(1.8, 1.0, Ink.ease_out_back(k))
		draw_set_transform(c + Vector2(0, 30), -0.25, Vector2(sc * absf(sx), sc))
		draw_rect(Rect2(-90, -30, 180, 60), Color(Pal.c("paper"), 0.6))
		draw_rect(Rect2(-90, -30, 180, 60), Pal.c("red"), false, 4.0)
		Ink.text(self, "已购入", Vector2(0, 14), 34, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

func _over_any(p: Vector2) -> bool:
	for r in card_rects:
		if r.has_point(p): return true
	for e in inv_rects:
		if e.rect.has_point(p): return true
	return false

# —— 库存槽 ——
func _draw_inventory(pr: Rect2, el: Color, ink: Color) -> void:
	var run: Run = main.run
	inv_rects.clear()
	var iy := pr.position.y + 600
	var hot := _hot_id()
	var hc := _hot_card()
	var want_kind := ""
	if hc >= 0 and hc < run.offers.size() and not run.offers[hc].sold:
		want_kind = Items.ALL[run.offers[hc].id].kind
	for kind in ["device", "relic"]:
		var list: Array = run.devices if kind == "device" else run.relics
		var slots: int = run.slot_count(kind) + (1 if kind == "relic" and run.has("screw") else 0)
		var hx := pr.position.x + (48.0 if kind == "device" else 760.0)
		var ff: float = full_flash[kind]
		var full: bool = run.slot_used(kind) >= run.slot_count(kind)
		var title := ("已安装设备  %d/%d" if kind == "device" else "护身符架  %d/%d") % [run.slot_used(kind), run.slot_count(kind)]
		Ink.text(self, title, Vector2(hx + sin(t * 50.0) * 4.0 * ff, iy), 17, ink.lerp(Pal.c("red"), ff), Pal.bold)
		for j in slots:
			var r := _slot_rect(kind, j)
			draw_rect(r, Pal.c("paper2"))
			draw_rect(Rect2(r.position + Vector2(8, r.size.y - 14), Vector2(r.size.x - 16, 8)), Color(0, 0, 0, 0.06))
			if j >= list.size():
				var target: bool = want_kind == kind and j == list.size()
				var pulse := 0.5 + 0.5 * sin(t * 5.0)
				var col := Color(Pal.c("green"), 0.5 + 0.5 * pulse) if target else Color(el, 0.35)
				_dashed(r.grow(-3), col, 2.0 if target else 1.2, t * (30.0 if target else 6.0))
				if target:
					Icons.draw(self, run.offers[hc].id, r.get_center() + Vector2(0, -3 * pulse), 64.0, 0.0)
					draw_rect(r.grow(-4), Color(Pal.c("paper2"), 0.72))
					Ink.text(self, "放这里", r.get_center() + Vector2(0, 40), 13, Pal.c("green"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
				else:
					var cc := r.get_center()
					draw_line(cc - Vector2(8, 0), cc + Vector2(8, 0), Color(el, 0.3), 2.0)
					draw_line(cc - Vector2(0, 8), cc + Vector2(0, 8), Color(el, 0.3), 2.0)
			else:
				draw_rect(r, Color(el, 0.5), false, 1.4)
			if (want_kind == kind and full) or ff > 0.0:
				var a := maxf(ff, (0.4 + 0.3 * sin(t * 8.0)) if want_kind == kind and full else 0.0)
				draw_rect(r.grow(3), Color(Pal.c("red"), a), false, 2.4)
		if want_kind == kind and full:
			Ink.text(self, "槽位已满，先按住一件卖掉", Vector2(hx + 190, iy), 15, Pal.c("red"), Pal.bold)
	# 物件（按 id 弹簧定位：卖掉一件，后面的滑过去补位）
	var hot_draw := []
	for kind in ["device", "relic"]:
		var list: Array = run.devices if kind == "device" else run.relics
		for j in list.size():
			var id: String = list[j]
			var r := _slot_rect(kind, j)
			inv_rects.append({"rect": r, "id": id})
			if not spos.has(id):
				spos[id] = [r.get_center(), Vector2.ZERO]
			var sp: Array = spos[id]
			var rr := Ink.spring2(sp[0], sp[1], r.get_center(), 16.0, get_process_delta_time())
			sp[0] = rr[0]
			sp[1] = rr[1]
			if in_air.has(id):
				continue
			if id == hot:
				hot_draw = [id, sp[0]]
			else:
				_tile(id, sp[0], el)
	if not hot_draw.is_empty():
		_tile(hot_draw[0], hot_draw[1], el)     # 悬停的最后画，盖在邻居上面
	# 飞行物
	for f in flyers:
		var k := clampf(f.t / f.dur, 0.0, 1.0)
		if f.out:
			var e := Ink.ease_out_cubic(k)
			var p: Vector2 = f.a.lerp(f.b, e) + Vector2(0, 260.0 * k * k)
			var s := (1.0 + 0.3 * sin(k * PI)) * (1.0 - k * 0.6)
			Icons.draw(self, f.id, p, 70.0 * s, f.spin * k * 4.0)
			draw_rect(Rect2(p - Vector2(40, 40) * s, Vector2(80, 80) * s), Color(Pal.c("paper"), k * 0.9))
		else:
			var e := Ink.ease_in_out(k)
			var mid: Vector2 = (f.a + f.b) * 0.5 + Vector2(0, -180)
			var p: Vector2 = f.a.lerp(mid, e).lerp(mid.lerp(f.b, e), e)
			var s := lerpf(110.0, 70.0, e) * (1.0 + 0.18 * sin(k * PI))
			var rc := Icons.rarity_col(Items.ALL[f.id].rarity)
			for g in 4:
				var k2 := clampf(k - (g + 1) * 0.05, 0.0, 1.0)
				var e2 := Ink.ease_in_out(k2)
				var p2: Vector2 = f.a.lerp(mid, e2).lerp(mid.lerp(f.b, e2), e2)
				draw_circle(p2, 10.0 - g * 2.0, Color(rc, 0.25 - g * 0.05))
			draw_circle(p + Vector2(10, 20 + 40 * (1.0 - e)), s * 0.35, Color(0, 0, 0, 0.1))
			Icons.draw(self, f.id, p, s, sin(k * TAU) * 0.25)
	# 硬币（翻转着飞向经费）
	for c in coins:
		if c.t < 0.0:
			continue
		var k := clampf(c.t / c.dur, 0.0, 1.0)
		var e := Ink.ease_in_out(k)
		var mid: Vector2 = (c.a + c.b) * 0.5 + Vector2(0, -c.h)
		var p: Vector2 = c.a.lerp(mid, e).lerp(mid.lerp(c.b, e), e)
		var sq := absf(cos(c.t * 14.0))
		draw_set_transform(p, 0.0, Vector2(maxf(0.2, sq), 1.0))
		draw_circle(Vector2.ZERO, 9.0, Pal.c("gold"))
		draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, Pal.equip_line(), 1.4, true)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color(Pal.equip_line(), 0.6), 1.4)
		draw_set_transform(Vector2.ZERO)
	for p in puffs:
		var k: float = p.t / 0.45
		draw_arc(p.p, 30.0 + 40.0 * Ink.ease_out_cubic(k), 0, TAU, 40, Color(p.col, 0.6 * (1.0 - k)), 3.0 * (1.0 - k) + 0.5, true)
	# 悬停说明：从物件下面垂下来展开
	if tip_id != "" and tip_v > 0.03 and spos.has(tip_id) and not in_air.has(tip_id):
		_tip(tip_id, spos[tip_id][0], pr, el, ink)

func _tile(id: String, c: Vector2, el: Color) -> void:
	var h: float = hov[id][0] if hov.has(id) else 0.0
	var hp := clampf(hold_t / HOLD, 0.0, 1.0) if hold_id == id else 0.0
	var pp: float = pop.get(id, 0.0)
	var wg: float = wiggle.get(id, 0.0)
	var d: Dictionary = Items.ALL[id]
	var rcol := Icons.rarity_col(d.rarity)
	var tilt := 0.0
	if not kb and hover_id == id:
		tilt = clampf((mouse_p.x - c.x) / 46.0, -1.0, 1.0) * 0.12 * h
	var rot := tilt + sin(t * 46.0) * 0.07 * hp + sin(wg * 18.0) * 0.18 * wg
	var lift := -18.0 * h + 6.0 * hp
	var sc := 1.0 + 0.14 * h - 0.12 * hp
	var sq := 0.25 * pp * sin(pp * 9.0)
	var squash := Vector2(1.0 + sq, 1.0 - sq)
	var p := c + Vector2(sin(t * 60.0) * 2.5 * hp, lift)
	# 底座阴影：物件抬得越高，影子越小越淡
	draw_set_transform(c + Vector2(0, 40), 0.0, Vector2(1.0 - 0.25 * h, 0.22))
	draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.18 - 0.07 * h))
	draw_set_transform(p, rot, squash * sc)
	var tr := Rect2(-41, -41, 82, 82)
	draw_rect(Rect2(tr.position + Vector2(3, 4) + Vector2(3, 10) * h, tr.size), Color(0, 0, 0, 0.1 + 0.12 * h))
	draw_rect(tr, Pal.c("paper"))
	draw_rect(Rect2(tr.position.x, tr.end.y - 7, tr.size.x, 7), rcol)
	draw_rect(tr, rcol.lerp(el, 0.4) if h > 0.3 else el, false, 1.6 + 1.2 * h)
	draw_set_transform(Vector2.ZERO)
	Icons.draw(self, id, p + Vector2(0, -3).rotated(rot), 62.0 * sc * squash.y, rot)
	if main.run.uses.has(id):
		Ink.text(self, "×%d" % main.run.uses[id], p + Vector2(38, 34) * sc, 14, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
	# 按住卖出：红圈一点点合拢
	if hp > 0.0:
		draw_arc(p, 56.0, 0, TAU, 48, Color(Pal.c("red"), 0.18), 4.0, true)
		draw_arc(p, 56.0, -PI / 2, -PI / 2 + TAU * hp, 48, Pal.c("red"), 4.0, true)
		Ink.text(self, "卖出 +$%d" % Items.sell_price(id), p + Vector2(66, 6 - 6 * hp), 18, Pal.c("red"), Pal.bold)

func _tip(id: String, c: Vector2, pr: Rect2, el: Color, ink: Color) -> void:
	var d: Dictionary = Items.ALL[id]
	var k := Ink.ease_out_back(tip_v)
	var w := 470.0
	var desc_h := Pal.font.get_multiline_string_size(d.desc, HORIZONTAL_ALIGNMENT_LEFT, w - 36, 15).y
	var lore_h := 0.0
	if d.lore != "":
		lore_h = Pal.hand.get_multiline_string_size("“" + d.lore + "”", HORIZONTAL_ALIGNMENT_LEFT, w - 36, 14).y + 6
	var h := 44.0 + desc_h + lore_h + 40.0
	# 放在物件旁边（右边放不下就放左边），从物件那侧横向“唰”地展开
	var right_side := c.x + 64.0 + w < pr.end.x - 30.0
	var top := clampf(c.y - h * 0.5, pr.position.y + 560.0, pr.end.y - 84.0 - h)
	var x := c.x + 64.0 if right_side else c.x - 64.0 - w
	var anchor := Vector2(c.x + (50.0 if right_side else -50.0), c.y)
	var edge := Vector2(x if right_side else x + w, clampf(c.y, top + 12, top + h - 12))
	draw_line(anchor, edge, Color(el, 0.6 * tip_v), 1.4, true)
	draw_circle(edge, 3.0, Color(el, tip_v))
	var pivot := Vector2(x if right_side else x + w, top)
	draw_set_transform(pivot, 0.0, Vector2(maxf(0.01, k), 1.0))
	if not right_side:
		draw_set_transform(pivot - Vector2(w, 0) * maxf(0.01, k), 0.0, Vector2(maxf(0.01, k), 1.0))
	var r := Rect2(0, 0, w, h)
	draw_rect(Rect2(r.position + Vector2(5, 7), r.size), Color(0, 0, 0, 0.14))
	draw_rect(r, Pal.c("paper"))
	draw_rect(Rect2(0, 0, 6, h), Icons.rarity_col(d.rarity))
	draw_rect(r, el, false, 1.4)
	if tip_v > 0.35:
		var a := clampf((tip_v - 0.35) / 0.4, 0.0, 1.0)
		Ink.text(self, d.name, Vector2(20, 30), 19, Color(ink, a), Pal.bold)
		Ink.text(self, ("设备" if d.kind == "device" else "饰品") + " · " + Items.RARITY_NAME[d.rarity], Vector2(w - 18, 28), 14, Color(Icons.rarity_col(d.rarity), a), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
		draw_multiline_string(Pal.font, Vector2(20, 56), d.desc, HORIZONTAL_ALIGNMENT_LEFT, w - 36, 15, -1, Color(ink, a))
		if d.lore != "":
			draw_multiline_string(Pal.hand, Vector2(20, 56 + desc_h + 6), "“" + d.lore + "”", HORIZONTAL_ALIGNMENT_LEFT, w - 36, 14, -1, Color(Pal.c("blue"), a))
		var hint := "按住鼠标卖出"
		if kb:
			hint = "再按 E 确认卖出" if confirm_id == id and confirm_t > 0.0 else "E 卖出（按两次）"
		draw_line(Vector2(16, h - 34), Vector2(w - 16, h - 34), Color(el, 0.3 * a), 1.0)
		Ink.text(self, hint, Vector2(20, h - 12), 14, Color(Pal.c("text2"), a))
		Ink.text(self, "+$%d" % Items.sell_price(id), Vector2(w - 18, h - 11), 17, Color(Pal.c("red"), a), Pal.mono, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_set_transform(Vector2.ZERO)

func _dashed(r: Rect2, col: Color, wdt: float, off: float) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	var dash := 9.0
	var gap := 6.0
	var acc := -fmod(off, dash + gap)
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var L := a.distance_to(b)
		var s := acc
		while s < L:
			var s0 := maxf(0.0, s)
			var s1 := minf(L, s + dash)
			if s1 > s0:
				draw_line(a.lerp(b, s0 / L), a.lerp(b, s1 / L), col, wdt)
			s += dash + gap
		acc = s - L - (dash + gap)
