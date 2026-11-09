extends Control
## 主页：左边一张实验室封面纸（标题 + 菜单 / 设置），右边一块放大镜扣在真实的观测舱上——
## 里面一束演示束流自己一路加速、蜕变、偶尔碎掉再重来。鼠标点选，或 ↑↓ + 回车 / E / 空格。哑光平涂，不发光。

signal start_game
signal continue_game
signal quit_game

var main: Node
var open := false
var t := 0.0
var out_t := -1.0          # 点“开始”后的退场动画
var page := "main"         # main / settings
var page_t := 0.0
var hover := -1
var kb := false
var rects: Array = []
var slide := PackedFloat32Array()
var slide_v := PackedFloat32Array()
var lens_c := Vector2(1300, 470)
var lens_r := 330.0
var demo_text := ""
var drag_vol := false
var vol_rect := Rect2()

const MAIN_ITEMS := [["01", "开始实验", "START", "start"], ["02", "设置", "SETTINGS", "settings"], ["03", "退出", "QUIT", "quit"]]
var cont_info := ""       # 有存档时：“第 3 阶段 · 累计 4,210 RP”，菜单最上面多一项“继续实验”
var _go_continue := false

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	slide.resize(8)
	slide_v.resize(8)

func show_title() -> void:
	open = true
	visible = true
	t = 0.0
	out_t = -1.0
	page = "main"
	hover = 0
	kb = true

func _items() -> Array:
	if page == "main":
		if cont_info == "":
			return MAIN_ITEMS
		return [["01", "继续实验", cont_info, "continue"], ["02", "开始新实验", "NEW RUN", "start"], ["03", "设置", "SETTINGS", "settings"], ["04", "退出", "QUIT", "quit"]]
	return [["", "主音量", "%d%%" % Options.volume], ["", "全屏", "开" if Options.fullscreen else "关"],
		["", "配色", "七十年代实验室（暗）" if Options.dark else "工程图纸（亮）"], ["", "画面震动", "开" if Options.shake else "关"],
		["", "新手教程", "每局开头 · " + ("开" if Options.tutorial else "关")], ["", "返回", "Esc"]]

func handle(ev: InputEvent) -> void:
	if not open or out_t >= 0.0 or t < 0.5:
		return
	var n := _items().size()
	if ev.is_action("ui_up") or (ev is InputEventKey and ev.physical_keycode == KEY_W):
		kb = true
		hover = (maxi(hover, 0) - 1 + n) % n
		Sfx.play("tick", -10.0, 1.2)
	elif ev.is_action("ui_down") or (ev is InputEventKey and ev.physical_keycode == KEY_S):
		kb = true
		hover = (hover + 1) % n
		Sfx.play("tick", -10.0, 1.2)
	elif page == "settings" and (ev.is_action("ui_left") or ev.is_action("ui_right")) and hover >= 0:
		_adjust(hover, -1 if ev.is_action("ui_left") else 1)
	elif ev.is_action("back") or ev.is_action("ui_cancel"):
		if page == "settings":
			_to_page("main")
	elif (ev.is_action("ui_accept") or ev.is_action("interact") or ev.is_action("accelerate")) and hover >= 0:
		_choose(hover)

func mouse(ev: InputEventMouse) -> void:
	if not open or out_t >= 0.0:
		return
	if ev is InputEventMouseMotion:
		if drag_vol:
			_set_vol_from(ev.position.x)
			return
		kb = false
		var h := -1
		for i in rects.size():
			if rects[i].has_point(ev.position):
				h = i
		if h != hover and h >= 0:
			Sfx.play("tick", -12.0, 1.3)
		hover = h
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover >= 0 else Input.CURSOR_ARROW)
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if not ev.pressed:
			if drag_vol:
				drag_vol = false
				Options.save()
			return
		if t < 0.5:
			return
		if page == "settings" and vol_rect.grow(8).has_point(ev.position):
			drag_vol = true
			_set_vol_from(ev.position.x)
			return
		for i in rects.size():
			if rects[i].has_point(ev.position):
				_choose(i)
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed and page == "settings":
		_to_page("main")

func _set_vol_from(x: float) -> void:
	Options.volume = int(round(clampf((x - vol_rect.position.x) / vol_rect.size.x, 0.0, 1.0) * 20.0)) * 5
	Options.apply()
	Sfx.play("tick", -8.0, 0.8 + Options.volume / 100.0)

func _to_page(p: String) -> void:
	page = p
	page_t = 0.0
	hover = 0 if kb else -1
	Sfx.play("paper", -6.0, 1.1)

func _choose(i: int) -> void:
	if page == "main":
		var its := _items()
		if i < 0 or i >= its.size():
			return
		match its[i][3]:
			"continue", "start":
				_go_continue = its[i][3] == "continue"
				out_t = 0.0
				Sfx.play("btn", -2.0, 0.8)
				Sfx.play("whoosh", -6.0, 0.9)
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			"settings":
				Sfx.play("btn2", -6.0)
				_to_page("settings")
			"quit":
				Sfx.play("btn2", -6.0, 0.8)
				quit_game.emit()
		return
	match i:
		0: _adjust(0, 1)
		1, 2, 3, 4: _adjust(i, 1)
		5: _to_page("main")

func _adjust(i: int, d: int) -> void:
	match i:
		0: Options.volume = clampi(Options.volume + d * 10, 0, 100)
		1: Options.fullscreen = not Options.fullscreen
		2: Options.dark = not Options.dark
		3: Options.shake = not Options.shake
		4: Options.tutorial = not Options.tutorial
		_: return
	Options.apply()
	Options.save()
	Sfx.play("btn2", -6.0, 1.2)

func _process(dt: float) -> void:
	if not open:
		return
	t += dt
	page_t += dt
	if out_t >= 0.0:
		out_t += dt
		if out_t > 0.9:
			open = false
			visible = false
			if _go_continue:
				continue_game.emit()
			else:
				start_game.emit()
	for i in slide.size():
		var tg := 1.0 if i == hover else 0.0
		slide_v[i] += (260.0 * (tg - slide[i]) - 22.0 * slide_v[i]) * minf(dt, 1.0 / 30.0)
		slide[i] += slide_v[i] * minf(dt, 1.0 / 30.0)
	queue_redraw()

func _draw() -> void:
	rects.clear()
	if not open:
		return
	var vp := get_viewport_rect().size
	var ink := Pal.c("text")        # 纸上的字：两种配色下纸都是浅色，字一律深色
	var lens_ink := Pal.c("ink")
	var paper := Pal.c("paper")
	var el := Pal.equip_line()
	var ok := Ink.ease_out_cubic(clampf(out_t / 0.8, 0.0, 1.0)) if out_t >= 0.0 else 0.0
	var inn := Ink.ease_out_cubic(clampf(t / 0.7, 0.0, 1.0))
	# —— 放大镜：镜外压暗，镜圈 + 手柄 ——
	var lr := lens_r * (1.0 + ok * 1.6)
	var dim := 0.5 * (1.0 - ok)
	var ring := PackedVector2Array()
	var n := 72
	for i in n + 1:
		var a := i * TAU / n
		ring.append(lens_c + Vector2(cos(a), sin(a)) * lr)
	# 压暗：用一圈多边形把镜外盖住（外框四角 + 镜圈）
	var shade := Color(Pal.c("screen") if Pal.dark else Color("#2b2a28"), dim)
	for i in n:
		var a0 := ring[i]
		var a1 := ring[i + 1]
		var d0 := lens_c + (a0 - lens_c).normalized() * 3000.0
		var d1 := lens_c + (a1 - lens_c).normalized() * 3000.0
		draw_colored_polygon(PackedVector2Array([a0, d0, d1, a1]), shade)
	if ok < 0.95:
		var ra := 1.0 - ok
		var hd := Vector2(-0.62, 0.78).normalized()
		var h0 := lens_c + hd * (lr + 18.0)
		var h1 := lens_c + hd * (lr + 210.0)
		var nrm := Vector2(-hd.y, hd.x)
		var handle := PackedVector2Array([h0 + nrm * 22, h1 + nrm * 26, h1 - nrm * 26, h0 - nrm * 22])
		draw_colored_polygon(handle, Color(Pal.c("equip_dark"), ra))
		var hc := handle.duplicate()
		hc.append(handle[0])
		Ink.pl(self, hc, Color(el, ra), 2.4)
		draw_line(h0.lerp(h1, 0.55) + nrm * 24, h0.lerp(h1, 0.55) - nrm * 24, Color(el, 0.6 * ra), 1.6)
		draw_arc(lens_c, lr + 12.0, 0, TAU, 96, Color(Pal.c("equip"), ra), 26.0, true)
		draw_arc(lens_c, lr + 25.0, 0, TAU, 96, Color(el, ra), 2.4, true)
		draw_arc(lens_c, lr - 1.0, 0, TAU, 96, Color(el, ra), 2.4, true)
		for i in 24:
			var a := i * TAU / 24.0 + t * 0.02
			draw_line(lens_c + Vector2(cos(a), sin(a)) * (lr + 4), lens_c + Vector2(cos(a), sin(a)) * (lr + (14 if i % 6 == 0 else 9)), Color(el, 0.7 * ra), 1.4)
		# 镜内读数：十字刻线 + 当前演示束流
		draw_line(lens_c + Vector2(-lr * 0.92, 0), lens_c + Vector2(-lr * 0.78, 0), Color(lens_ink, 0.5 * ra), 1.2)
		draw_line(lens_c + Vector2(lr * 0.78, 0), lens_c + Vector2(lr * 0.92, 0), Color(lens_ink, 0.5 * ra), 1.2)
		if demo_text != "":
			# 读数纸签：挂在镜圈右下
			var tp := lens_c + Vector2(lr * 0.42, lr * 0.86)
			var tw := Ink.size(Pal.mono, demo_text, 17).x + 28.0
			var tr := Rect2(tp, Vector2(tw, 34))
			draw_rect(Rect2(tr.position + Vector2(4, 5), tr.size), Color(0, 0, 0, 0.2 * ra))
			draw_rect(tr, Color(paper, ra))
			Ink.frame(self, tr, Color(el, ra), 1.6)
			draw_rect(Rect2(tr.position, Vector2(6, tr.size.y)), Color(Pal.c("red"), ra))
			Ink.text(self, demo_text, tr.position + Vector2(16, 23), 17, Color(ink, ra), Pal.mono)
	# —— 左：封面纸 ——
	var px := lerpf(-760.0, 0.0, inn) - ok * 820.0
	var sheet := PackedVector2Array([Vector2(px, 0), Vector2(px + 690, 0), Vector2(px + 640, vp.y * 0.35), Vector2(px + 700, vp.y * 0.7), Vector2(px + 660, vp.y), Vector2(px, vp.y)])
	draw_colored_polygon(PackedVector2Array([sheet[0] + Vector2(10, 0), sheet[1] + Vector2(12, 0), sheet[2] + Vector2(12, 0), sheet[3] + Vector2(12, 0), sheet[4] + Vector2(12, 0), sheet[5]]), Color(0, 0, 0, 0.18))
	draw_colored_polygon(sheet, paper)
	# 坐标纸格
	for gx in range(int(px) + 40, int(px) + 640, 40):
		draw_line(Vector2(gx, 0), Vector2(gx, vp.y), Color("#d6cbb4", 0.5), 1.0)
	for gy in range(40, int(vp.y), 40):
		draw_line(Vector2(px, gy), Vector2(px + 640, gy), Color("#d6cbb4", 0.5), 1.0)
	var sc := sheet.duplicate()
	sc.append(sheet[0])
	Ink.pl(self, sc, el, 2.0)
	var x0 := px + 96.0
	# 抬头
	Ink.text(self, "第七实验站 · 主环 26.7 km", Vector2(x0, 120), 15, Pal.c("text2"), Pal.font)
	# 标题
	Ink.text(self, "束流", Vector2(x0 + 6, 288 + 6), 150, Color(0, 0, 0, 0.12), Pal.bold)
	Ink.text(self, "束流", Vector2(x0, 288), 150, ink, Pal.bold)
	draw_line(Vector2(x0, 322), Vector2(x0 + 70, 322), Pal.c("red"), 3.0)
	Ink.text(self, "B  E  A  M  L  I  N  E", Vector2(x0 + 86, 330), 18, Pal.c("red"), Pal.mono)
	draw_line(Vector2(x0 + 330, 322), Vector2(x0 + 470, 322), Color(Pal.c("red"), 0.5), 1.4)
	Ink.text(self, "把一束粒子养到舍不得，再决定要不要收手。", Vector2(x0, 384), 24, Pal.c("blue"), Pal.hand)
	# 菜单
	var items := _items()
	var y := 470.0
	var pk := Ink.ease_out_back(clampf(page_t / 0.35, 0.0, 1.0))
	if page == "settings":
		Ink.text(self, "设置", Vector2(x0, y - 18), 30, ink, Pal.bold)
		Ink.text(self, "SETTINGS", Vector2(x0 + 76, y - 20), 14, Pal.c("text2"), Pal.mono)
		y += 22.0
	for i in items.size():
		var it: Array = items[i]
		var appear := clampf((t - 0.25 - i * 0.07) / 0.35, 0.0, 1.0) * pk
		var ix := x0 - 40.0 * (1.0 - Ink.ease_out_cubic(appear)) + 14.0 * slide[i] - ok * 300.0
		var hh := 62.0 if page == "main" else 50.0
		var r := Rect2(x0 - 30, y - hh * 0.62, 470, hh)
		rects.append(r)
		var a := appear
		if slide[i] > 0.01:
			draw_rect(Rect2(r.position, Vector2(r.size.x * slide[i], r.size.y)), Color(Pal.c("paper2"), a))
			draw_rect(Rect2(r.position, Vector2(5, r.size.y)), Color(Pal.c("red"), a * slide[i]))
		if page == "main":
			Ink.text(self, it[0], Vector2(ix, y), 16, Color(Pal.c("text2"), a), Pal.mono)
			Ink.text(self, it[1], Vector2(ix + 44, y + 6), 36, Color(ink, a), Pal.bold)
			var w := Ink.size(Pal.bold, it[1], 36).x
			Ink.text(self, it[2], Vector2(ix + 58 + w, y + 2), 14, Color(Pal.c("text2"), a), Pal.mono)
		else:
			Ink.text(self, it[1], Vector2(ix, y + 4), 24, Color(ink, a), Pal.bold)
			if i == 0:
				vol_rect = Rect2(ix + 150, y - 6, 200, 8)
				draw_rect(vol_rect, Color(el, 0.2 * a))
				draw_rect(Rect2(vol_rect.position, Vector2(vol_rect.size.x * Options.volume / 100.0, vol_rect.size.y)), Color(Pal.c("green"), a))
				Ink.frame(self, vol_rect, Color(el, a), 1.2)
				Ink.disc(self, Vector2(vol_rect.position.x + vol_rect.size.x * Options.volume / 100.0, vol_rect.get_center().y), 9.0, Color(Pal.c("gold"), a))
				draw_arc(Vector2(vol_rect.position.x + vol_rect.size.x * Options.volume / 100.0, vol_rect.get_center().y), 9.0, 0, TAU, 16, Color(el, a), 1.4, true)
				Ink.text(self, it[2], Vector2(ix + 372, y + 4), 18, Color(Pal.c("text2"), a), Pal.mono)
			else:
				var vcol := Pal.c("blue") if i < 5 else Pal.c("text2")
				Ink.text(self, ("◂ " + it[2] + " ▸") if i in [1, 2, 3, 4] else it[2], Vector2(ix + 150, y + 4), 18, Color(vcol, a), Pal.font)
		y += hh + (10.0 if page == "main" else 4.0)
	# 底部
	var hint := "鼠标点选 · ↑↓ 选择 · 回车 / E 确认" if page == "main" else "← → 调整 · Esc / 右键 返回"
	Ink.text(self, hint, Vector2(x0, vp.y - 70), 15, Pal.c("text2"), Pal.font)
	Ink.text(self, "v0.3 · 试验版", Vector2(x0, vp.y - 42), 13, Pal.c("text2"), Pal.mono)
