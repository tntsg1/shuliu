extends Control
## 开发者模式（~ 键开关）：右侧滑出的面板。
## 发任意物品（无视槽位）、改数值、指定下一次结果、强制抽卡中/不中、动画加速、无敌。

var main: Node
var open := false
var v := 0.0
var _vv := 0.0
var tab := "relic"
var btns: Array = []          # [{rect, act, arg}]
var hover := -1
var hover_item := ""
var msg := ""
var msg_t := 0.0
var t := 0.0

const W := 560.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func toggle() -> void:
	open = not open
	Sfx.play("paper", -8.0, 1.4 if open else 1.1)

func _process(dt: float) -> void:
	t += dt
	var r := Ink.spring(v, _vv, 1.0 if open else 0.0, 14.0, dt)
	v = r[0]
	_vv = r[1]
	msg_t = maxf(0.0, msg_t - dt)
	if v > 0.002:
		queue_redraw()
	elif not btns.is_empty():
		btns.clear()
		queue_redraw()

func _panel_rect() -> Rect2:
	var vp := get_viewport_rect().size
	return Rect2(vp.x - W * v, 0, W, vp.y)

## 鼠标：在面板上就吃掉事件（返回 true），不让它漏到游戏里
func mouse(ev: InputEventMouse) -> bool:
	if v < 0.5 or not _panel_rect().has_point(ev.position):
		if hover >= 0 or hover_item != "":
			hover = -1
			hover_item = ""
		return false
	if ev is InputEventMouseMotion:
		hover = -1
		hover_item = ""
		for i in btns.size():
			if btns[i].rect.has_point(ev.position):
				hover = i
				if btns[i].act == "item":
					hover_item = btns[i].arg
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover >= 0 else Input.CURSOR_ARROW)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for b in btns:
			if b.rect.has_point(ev.position):
				_do(b.act, b.arg)
				Sfx.play("tick", -8.0, 1.3)
				break
	return true

func _say(s: String) -> void:
	msg = s
	msg_t = 2.2

func _do(act: String, arg) -> void:
	var run: Run = main.run
	var b: Beam = run.beam
	match act:
		"tab":
			tab = arg
		"item":
			var id: String = arg
			if run.has(id):
				run.relics.erase(id)
				run.devices.erase(id)
				run.uses.erase(id)
				_say("移除：" + Items.ALL[id].name)
			else:
				var def: Dictionary = Items.ALL[id]
				if def.kind == "device":
					run.devices.append(id)
				else:
					run.relics.append(id)
				if def.has("uses"):
					run.uses[id] = def.uses
				_say("装上：" + def.name)
			main.gear_bought()
			main._sync()
		"money":
			run.money += 100
			_say("经费 +100")
		"e_up", "e_down":
			if b == null:
				_say("先开始一次实验")
				return
			b.energy = clampi(b.energy + (1 if act == "e_up" else -1), 1, Odds.EMAX)
			main._sync()
		"lock":
			if b == null:
				_say("先开始一次实验")
				return
			b.charge = run.lock_need()
			b.lock_used = true
			b.lock_left = Odds.LOCK_PRESSES + (2 if run.has("fast_clock") else 0)
			main._sync()
			_say("进入锁相")
		"line":
			run.total = maxi(run.total, run.line())
			_say("累计分已够线")
		"exp_plus":
			run.experiments_left += 1
			_say("本阶段实验 +1")
		"next_stage":
			if b != null:
				_say("先引出这一束")
				return
			run.total = maxi(run.total, run.line())
			main.submit()
		"shop":
			run.roll_shop()
			_say("商店重新进货")
		"force":
			run.dev_force = arg
			_say("每次加速：" + ("自动" if arg < 0 else Odds.NAMES[arg]))
		"roll":
			run.dev_roll = arg
		"speed":
			main.dev_speed = arg
		"god":
			run.dev_god = not run.dev_god
		"plans":
			main.dev_plans()
			open = false
		"meme_all":
			main.dev_meme_always = not main.dev_meme_always
		"meme_next":
			var keys: Array = Memes.LIST.keys()
			var i := keys.find(main.dev_meme_force)
			main.dev_meme_force = keys[(i + 1) % keys.size()]
			_say("下次引出：" + Memes.LIST[main.dev_meme_force].name)

func _btn(r: Rect2, label: String, act: String, arg = null, on := false, col := Color.TRANSPARENT) -> void:
	var i := btns.size()
	btns.append({"rect": r, "act": act, "arg": arg})
	var el := Pal.equip_line()
	var hot := i == hover
	var bg := Pal.c("paper2")
	if on:
		bg = col if col.a > 0.0 else Pal.c("gold")
	draw_rect(r.grow(1.0 if hot else 0.0), bg)
	if col.a > 0.0 and not on:
		draw_rect(Rect2(r.position, Vector2(5, r.size.y)), col)
	draw_rect(r, Pal.c("red") if hot else el, false, 2.0 if hot else 1.2)
	Ink.text(self, label, r.get_center() + Vector2(0, 6), 15, Pal.c("paper") if on and col.a > 0.0 else Pal.c("text"), Pal.bold if on else Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

func _draw() -> void:
	btns.clear()
	if v < 0.002 or main == null or main.run == null:
		return
	var run: Run = main.run
	var pr := _panel_rect()
	var el := Pal.equip_line()
	var ink := Pal.c("text")
	draw_rect(Rect2(pr.position - Vector2(10, 0), Vector2(10, pr.size.y)), Color(0, 0, 0, 0.12))
	draw_rect(pr, Pal.c("paper"))
	draw_line(pr.position, Vector2(pr.position.x, pr.end.y), el, 2.0)
	var x := pr.position.x + 24.0
	var y := 46.0
	Ink.text(self, "开发者模式", Vector2(x, y), 26, ink, Pal.bold)
	Ink.text(self, "~ 关闭", Vector2(pr.end.x - 24, y), 14, Pal.c("text2"), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)
	# 印章式的“DEV”角标
	draw_set_transform(Vector2(x + 190, y - 9), -0.12)
	draw_rect(Rect2(-30, -14, 60, 28), Pal.c("red"), false, 2.5)
	Ink.text(self, "DEV", Vector2(0, 7), 16, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	y += 30.0
	# —— 物品 ——
	Ink.text(self, "物品（点一下装上 / 再点移除，无视槽位）", Vector2(x, y), 15, Pal.c("text2"))
	y += 12.0
	_btn(Rect2(x, y, 120, 32), "饰品 %d" % Items.ids("relic").size(), "tab", "relic", tab == "relic")
	_btn(Rect2(x + 128, y, 120, 32), "设备 %d" % Items.ids("device").size(), "tab", "device", tab == "device")
	y += 44.0
	var ids := Items.ids(tab)
	var cell := 56.0
	var per := int((W - 48.0) / cell)
	for i in ids.size():
		var id: String = ids[i]
		var r := Rect2(x + (i % per) * cell, y + (i / per) * cell, cell - 6, cell - 6)
		var own: bool = run.has(id)
		var bi := btns.size()
		btns.append({"rect": r, "act": "item", "arg": id})
		draw_rect(r, Pal.c("green").lerp(Pal.c("paper"), 0.55) if own else Pal.c("paper2"))
		draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), Icons.rarity_col(Items.ALL[id].rarity))
		draw_rect(r, Pal.c("red") if bi == hover else (Pal.c("green") if own else el), false, 2.0 if (bi == hover or own) else 1.0)
		Icons.draw(self, id, r.get_center() + Vector2(0, -1), 38.0)
	y += ceil(ids.size() / float(per)) * cell + 6.0
	var name := ""
	if hover_item != "":
		var d: Dictionary = Items.ALL[hover_item]
		name = d.name + "：" + d.desc
	Ink.para(self, Pal.font, Vector2(x, y + 14), name if name != "" else "（鼠标停在图标上看名字）", W - 48, 14, 2, Pal.c("text2"))
	y += 48.0
	# —— 数值 ——
	draw_line(Vector2(x, y), Vector2(pr.end.x - 24, y), Color(el, 0.4), 1.0)
	y += 22.0
	var b: Beam = run.beam
	Ink.text(self, "数值　经费 $%d　能级 %s　阶段 %d　剩余实验 %d" % [run.money, str(b.energy) if b else "—", run.stage + 1, run.experiments_left], Vector2(x, y), 15, Pal.c("text2"))
	y += 12.0
	var bw := (W - 48.0 - 3 * 8.0) / 4.0
	var row1 := [["经费 +100", "money"], ["能级 +1", "e_up"], ["能级 −1", "e_down"], ["直接锁相", "lock"]]
	var row2 := [["累计分够线", "line"], ["实验次数 +1", "exp_plus"], ["过本阶段", "next_stage"], ["商店重新进货", "shop"]]
	for i in 4:
		_btn(Rect2(x + i * (bw + 8), y, bw, 34), row1[i][0], row1[i][1])
		_btn(Rect2(x + i * (bw + 8), y + 42, bw, 34), row2[i][0], row2[i][1])
	y += 96.0
	# —— 下一次结果 ——
	draw_line(Vector2(x, y), Vector2(pr.end.x - 24, y), Color(el, 0.4), 1.0)
	y += 22.0
	Ink.text(self, "每次加速强制出（一直生效，点“自动”恢复）", Vector2(x, y), 15, Pal.c("text2"))
	y += 12.0
	var fw := (W - 48.0 - 3 * 8.0) / 4.0
	_btn(Rect2(x, y, fw, 34), "自动", "force", -1, run.dev_force < 0)
	for k in Odds.N:
		var col := Pal.outcome(k)
		var i2 := k + 1
		_btn(Rect2(x + (i2 % 4) * (fw + 8), y + (i2 / 4) * 42, fw, 34), Odds.NAMES[k], "force", k, run.dev_force == k, col)
	y += 92.0
	Ink.text(self, "饰品抽卡", Vector2(x, y), 15, Pal.c("text2"))
	var rw := (W - 48.0 - 100.0 - 2 * 8.0) / 3.0
	var rolls := [["正常", -1], ["必中", 1], ["必不中", 0]]
	for i in 3:
		_btn(Rect2(x + 100 + i * (rw + 8), y - 22, rw, 32), rolls[i][0], "roll", rolls[i][1], run.dev_roll == rolls[i][1])
	y += 24.0
	# —— 速度与无敌 ——
	draw_line(Vector2(x, y), Vector2(pr.end.x - 24, y), Color(el, 0.4), 1.0)
	y += 30.0
	Ink.text(self, "动画速度", Vector2(x, y + 4), 15, Pal.c("text2"))
	var sp := [1.0, 2.0, 4.0]
	for i in 3:
		_btn(Rect2(x + 100 + i * 78, y - 18, 70, 32), "×%d" % int(sp[i]), "speed", sp[i], is_equal_approx(main.dev_speed, sp[i]))
	_btn(Rect2(pr.end.x - 24 - 130, y - 18, 130, 32), "无敌：开" if run.dev_god else "无敌：关", "god", null, run.dev_god, Pal.c("red") if run.dev_god else Color.TRANSPARENT)
	y += 30.0
	Ink.text(self, "奇葩事件", Vector2(x, y + 4), 15, Pal.c("text2"))
	_btn(Rect2(x + 100, y - 18, 150, 32), "每次都出：开" if main.dev_meme_always else "每次都出：关", "meme_all", null, main.dev_meme_always)
	var nm: String = Memes.LIST[main.dev_meme_force].name if main.dev_meme_force != "" else "（自动）"
	_btn(Rect2(x + 258, y - 18, W - 48 - 258, 32), "下次指定：" + nm, "meme_next")
	y += 40.0
	Ink.text(self, "计划书", Vector2(x, y + 4), 15, Pal.c("text2"))
	_btn(Rect2(x + 100, y - 18, 200, 32), "马上发三份来挑", "plans")
	Ink.text(self, "当前：" + (Plans.LIST[run.plan].name if run.plan != "" else "无"), Vector2(x + 316, y + 4), 14, Pal.c("text2"))
	# 提示
	if msg_t > 0.0:
		Ink.text(self, msg, Vector2(x, pr.end.y - 28), 16, Color(Pal.c("red"), clampf(msg_t / 0.3, 0.0, 1.0)), Pal.bold)
