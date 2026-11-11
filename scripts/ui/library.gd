extends Control
## 教授书架借阅（M5-9）：40 本按稀有度分四格摊开，每格两列；右边是选中那本的借书卡。
## 借阅花科研声望，借走的永久进入之后每局的商店池。传说格第一次通关后才打开。
## 键盘：方向键选、E / 空格借阅、Esc 离开；鼠标：悬停选中、点“借阅”章。

signal closed

var main: Node
var open := false
var t := 0.0
var sel := Vector2i(0, 0)       # (格内列 0..7, 行)
var kb := false
var tiles := {}                 # id -> Rect2（屏幕坐标，绘制时更新）
var borrow_rect := Rect2()
var stamp := {}                 # id -> 借阅瞬间的时刻（盖章动画）
var msg := ""
var msg_t := 0.0
var nudge_t := -9.0             # 点了物品格：借阅按钮跳一下，提示去点按钮

const TILE := 66.0
const PAD := 8.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

func show_lib() -> void:
	open = true
	visible = true
	t = 0.0
	msg = ""
	kb = false
	sel = Vector2i(0, 0)
	Sfx.play("paper", -4.0, 0.8)
	Sfx.play("whoosh", -10.0, 0.9)

func close() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	open = false
	visible = false
	Sfx.play("paper", -8.0, 1.1)
	closed.emit()

## 8 列网格：每个稀有度占两列
func _grid() -> Array:
	var cols: Array = preload("res://scripts/world/office.gd").shelf_items()
	var g: Array = []
	for c in 4:
		var list: Array = cols[c]
		for k in 2:
			var col: Array = []
			for i in list.size():
				if i % 2 == k:
					col.append(list[i])
			g.append(col)
	return g

func selected() -> String:
	var g := _grid()
	var col: Array = g[clampi(sel.x, 0, g.size() - 1)]
	if col.is_empty():
		return ""
	return col[clampi(sel.y, 0, col.size() - 1)]

func handle(ev: InputEvent) -> void:
	if not open or t < 0.25:
		return
	kb = true
	var g := _grid()
	if ev.is_action("back"):
		close()
	elif ev.is_action("move_left") or ev.is_action("ui_left"):
		sel.x = maxi(0, sel.x - 1)
		_tick()
	elif ev.is_action("move_right") or ev.is_action("ui_right"):
		sel.x = mini(g.size() - 1, sel.x + 1)
		_tick()
	elif ev.is_action("ui_up"):
		sel.y = maxi(0, sel.y - 1)
		_tick()
	elif ev.is_action("ui_down"):
		sel.y = sel.y + 1
		_tick()
	elif ev.is_action("interact") or ev.is_action("accelerate"):
		_borrow()
	var col: Array = g[sel.x]
	sel.y = clampi(sel.y, 0, maxi(0, col.size() - 1))

func _tick() -> void:
	Sfx.play("tick", -12.0, 1.3)

func mouse(ev: InputEventMouse) -> void:
	if not open:
		return
	if ev is InputEventMouseMotion:
		kb = false
		var g := _grid()
		for x in g.size():
			for y in (g[x] as Array).size():
				var id: String = g[x][y]
				if tiles.has(id) and (tiles[id] as Rect2).has_point(ev.position) and sel != Vector2i(x, y):
					sel = Vector2i(x, y)
					_tick()
		var hot := borrow_rect.has_point(ev.position)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hot or _tile_at(ev.position) != Vector2i(-1, -1) else Input.CURSOR_ARROW)
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_RIGHT:
			close()
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			if borrow_rect.has_point(ev.position):
				_borrow()
			else:
				var p := _tile_at(ev.position)
				if p != Vector2i(-1, -1):
					kb = false
					if sel != p:
						sel = p
					nudge_t = t
					Sfx.play("tick", -8.0, 1.0)

## 鼠标下面是哪一格；没有返回 (-1, -1)
func _tile_at(pos: Vector2) -> Vector2i:
	var g := _grid()
	for x in g.size():
		for y in (g[x] as Array).size():
			var id: String = g[x][y]
			if tiles.has(id) and (tiles[id] as Rect2).has_point(pos):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _borrow() -> void:
	var id := selected()
	if id == "":
		return
	var err := Meta.borrow(id)
	if err != "":
		msg = err
		msg_t = t
		Sfx.play("hit_low", -10.0, 1.3)
		return
	stamp[id] = t
	msg = "已成功借阅：%s。以后每局都有机会在商店和失物招领箱中获得这件物品。" % Items.ALL[id].name
	msg_t = t
	Sfx.play("btn", -2.0, 0.7)
	Sfx.play("metal", -8.0, 1.2)
	Sfx.play("paper", -6.0, 1.3)

func _process(dt: float) -> void:
	if open:
		t += dt
		queue_redraw()

func _draw() -> void:
	if not open:
		return
	var vp := get_viewport_rect().size
	var a := clampf(t / 0.2, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.45 * a))
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	var pr := Rect2(150, 110 + (1.0 - Ink.ease_out_cubic(a)) * 60.0, vp.x - 300, vp.y - 220)
	draw_rect(Rect2(pr.position + Vector2(6, 9), pr.size), Color(0, 0, 0, 0.18))
	draw_rect(pr, Pal.c("paper"))
	Ink.frame(self, pr, el, Ink.W1)
	Ink.text(self, "教授书架", pr.position + Vector2(40, 58), 34, ink, Pal.bold)
	Ink.text(self, "借阅过的物品，以后每局都有机会在商店和失物招领箱中出现。", pr.position + Vector2(210, 56), 15, Pal.c("text2"), Pal.font)
	Ink.text(self, "科研声望 %d" % Meta.prestige(), Vector2(pr.end.x - 40, pr.position.y + 58), 26, Pal.c("gold").darkened(0.25), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(pr.position + Vector2(30, 80), Vector2(pr.end.x - 30, pr.position.y + 80), Color(el, 0.4), Ink.W2)
	# 书格
	var g := _grid()
	var names := ["普通 · 20", "精良 · 40", "稀有 · 70", "传说 · 120"]
	var legend_open: bool = int(Meta.get_v("clears", 0)) >= 1
	var gx := pr.position.x + 40
	var gy := pr.position.y + 130
	tiles.clear()
	for c in 4:
		var x0 := gx + c * (TILE * 2 + PAD + 34)
		var rc := Icons.rarity_col(c)
		draw_rect(Rect2(x0 - 6, gy - 34, TILE * 2 + PAD + 12, 24), Color(rc, 0.85))
		Ink.text(self, names[c], Vector2(x0 + 4, gy - 16), 14, Pal.c("paper"), Pal.bold)
		for k in 2:
			var col: Array = g[c * 2 + k]
			for y in col.size():
				var id: String = col[y]
				var r := Rect2(x0 + k * (TILE + PAD), gy + y * (TILE + PAD), TILE, TILE)
				tiles[id] = r
				var is_sel := sel == Vector2i(c * 2 + k, y)
				var got := Meta.unlocked(id)
				var locked := c == 3 and not legend_open
				draw_rect(r, Pal.c("paper2") if not got else Pal.c("paper"))
				Ink.frame(self, r, Pal.c("red") if is_sel else Color(el, 0.6), 3.0 if is_sel else Ink.W3)
				var ia := 0.35 if locked else (1.0 if not got else 0.55)
				Icons.draw(self, id, r.get_center(), 44.0, 0.0)
				if ia < 1.0:
					draw_rect(r.grow(-2), Color(Pal.c("paper2"), 1.0 - ia))
				if got:
					var sk := clampf((t - float(stamp.get(id, -9.0))) / 0.18, 0.0, 1.0)
					var sc := lerpf(1.8, 1.0, Ink.ease_out_back(sk)) if stamp.has(id) else 1.0
					draw_set_transform(r.get_center(), -0.3, Vector2(sc, sc))
					Ink.frame(self, Rect2(-28, -11, 56, 22), Pal.c("red"), 2.4)
					Ink.text(self, "已借阅", Vector2(0, 6), 13, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
					draw_set_transform(Vector2.ZERO)
				elif locked:
					draw_arc(r.get_center() + Vector2(0, -4), 7.0, PI, TAU, 10, el, 2.4, true)
					draw_rect(Rect2(r.get_center() + Vector2(-9, -4), Vector2(18, 14)), Pal.c("gold"))
		if c == 3 and not legend_open:
			Ink.text(self, "首次通关后开放", Vector2(x0 + TILE + PAD * 0.5, gy + 4 * (TILE + PAD) + 30), 13, Pal.c("text2"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 借书卡（选中那本）
	var id := selected()
	var cr := Rect2(pr.end.x - 520, pr.position.y + 110, 480, pr.size.y - 150)
	draw_rect(Rect2(cr.position + Vector2(4, 6), cr.size), Color(0, 0, 0, 0.1))
	draw_rect(cr, Pal.c("paper2").lerp(Pal.c("paper"), 0.5))
	Ink.frame(self, cr, el, Ink.W2)
	borrow_rect = Rect2()
	if id != "":
		var d: Dictionary = Items.ALL[id]
		var rc2 := Icons.rarity_col(d.rarity)
		draw_rect(Rect2(cr.position, Vector2(cr.size.x, 30)), Color(rc2, 0.85))
		Ink.text(self, ("设备" if d.kind == "device" else "饰品") + " · " + Items.RARITY_NAME[d.rarity], cr.position + Vector2(16, 21), 15, Pal.c("paper"), Pal.bold)
		Icons.draw(self, id, cr.position + Vector2(cr.size.x * 0.5, 120), 120.0, 0.0)
		var nfs := 24
		while nfs > 15 and Ink.size(Pal.bold, d.name, nfs).x > cr.size.x - 40:
			nfs -= 1
		Ink.text(self, d.name, cr.position + Vector2(20, 228), nfs, ink, Pal.bold)
		# 大字 → 完整描述 → 故事 依次往下排；总高放不下就整体缩小字号
		var tw := cr.size.x - 40
		var bottom := cr.end.y - 84.0
		var big: String = d.get("big", "")
		var lore: String = ("“" + d.lore + "”") if d.get("lore", "") != "" else ""
		var k := 1.0
		while k > 0.7:
			var hh := Ink.para_size(Pal.bold, big, tw, int(20 * k)).y + 10.0 + Ink.para_size(Pal.font, d.desc, tw, int(15 * k)).y
			if lore != "":
				hh += 12.0 + Ink.para_size(Pal.hand, lore, tw, int(14 * k)).y
			if cr.position.y + 248.0 + hh <= bottom:
				break
			k -= 0.05
		var y := cr.position.y + 248.0
		Ink.para(self, Pal.bold, Vector2(cr.position.x + 20, y + int(20 * k)), big, tw, int(20 * k), -1, ink)
		y += Ink.para_size(Pal.bold, big, tw, int(20 * k)).y + 10.0
		Ink.para(self, Pal.font, Vector2(cr.position.x + 20, y + int(15 * k)), d.desc, tw, int(15 * k), -1, Pal.c("text2"))
		y += Ink.para_size(Pal.font, d.desc, tw, int(15 * k)).y + 12.0
		if lore != "":
			Ink.para(self, Pal.hand, Vector2(cr.position.x + 20, y + int(14 * k)), lore, tw, int(14 * k), -1, Pal.c("blue"))
		var why := Meta.borrow_block(id)
		var br := Rect2(cr.position.x + 20, cr.end.y - 74, cr.size.x - 40, 54)
		borrow_rect = br
		var can := why == ""
		# 点了物品格：按钮弹一下（先鼓起再回落），提示“借阅点这里”
		var nk := clampf((t - nudge_t) / 0.45, 0.0, 1.0)
		if nk < 1.0:
			var bump := sin(nk * PI) * (1.0 - nk * 0.5)
			br = br.grow_individual(10 * bump, 6 * bump, 10 * bump, 6 * bump)
			draw_rect(br.grow(6), Color(el, 0.35 * (1.0 - nk)), false, 3.0)
		draw_rect(br, Pal.c("gold") if can else Pal.c("paper2"))
		Ink.frame(self, br, el, Ink.W2)
		var label := ("花费 %d 声望借阅 · 按 E 或点击" % Meta.borrow_price(id)) if can else why
		Ink.text(self, label, br.get_center() + Vector2(0, 7), 18 if can else 15, ink if can else Pal.c("text2"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	if msg != "" and t - msg_t < 3.0:
		Ink.text(self, msg, Vector2(pr.position.x + 40, pr.end.y - 30), 16, Pal.c("green").darkened(0.2) if msg.begins_with("已成功借阅") else Pal.c("red"), Pal.bold)
	else:
		Ink.text(self, "方向键 / 鼠标 选书    E / 空格 / 点右边按钮 借阅    Esc / 右键 离开", Vector2(pr.position.x + 40, pr.end.y - 30), 14, Pal.c("text2"), Pal.font)
