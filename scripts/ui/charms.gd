extends Control
## 实验中的“护身符挂板”：控制台升起时，右下角挂出本局全部设备和饰品（钉子 + 挂绳 + 纸牌，会晃）。
## 某件生效时：它从钉子上弹下来 → 旋转飞到观测舱前放大 → 色块射线 + 墨圈 + 纸屑爆开，
## 旁边展开一条写着效果的纸条 → 再飞回钉子上晃两下。哑光平涂，不发光。

var main: Node
var t := 0.0
var swing := {}          # id -> [角度, 角速度]
var hov := {}            # id -> [值, 速度]
var hover_id := ""
var fires: Array = []    # 正在表演的触发
var pos := {}            # id -> 挂板上的屏幕位置（每帧更新）
var vis := 0.0
var fired := 0            # 本局触发过几次（新手便条用）

const TOK := 48.0
const GAP := 62.0
const BOARD_W := 400.0
const FLY_END := 0.5
const ROLL_T := 1.15

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func _items() -> Array:
	if main == null or main.run == null:
		return []
	return main.run.devices + main.run.relics

## 触发：同一次加速里多件同时生效时依次错开出场。
## roll = {p, hit}：带概率的饰品，先飞到屏幕中央放大，转盘“抽卡”揭晓中没中
func fire(id: String, text: String, roll := {}) -> void:
	fired += 1
	var busy := 0
	for f in fires:
		if f.t < f.S + 0.9:
			busy += 1
	var R := ROLL_T if not roll.is_empty() else 0.0
	var f := {"id": id, "text": text, "t": -busy * 0.28, "slot": busy % 3, "parts": [], "burst": false, "landed": false,
		"R": R, "S": FLY_END + R, "roll": roll, "hit": roll.get("hit", true), "tick": -1}
	if not roll.is_empty():
		# 指针最终停的位置：中了落在绿色段里，没中落在灰色段里（避开边缘，看得清）
		var u := 0.0
		if roll.has("segs"):
			# 多段转盘（红色按钮）：落在选中那一段里
			var acc := 0.0
			for i in roll.segs.size():
				if i == roll.pick:
					u = acc + randf_range(0.15, 0.85) * roll.segs[i][0]
					break
				acc += roll.segs[i][0]
		else:
			var p: float = roll.p
			u = randf_range(0.12, 0.88) * p if f.hit else p + randf_range(0.1, 0.9) * (1.0 - p)
		f["spin"] = 3.0 + u        # 转 3 圈再停
	fires.append(f)

## 从现在起还要等多久，抽卡类饰品才揭晓完（主流程据此推迟这次加速的揭晓）
func roll_wait() -> float:
	var w := 0.0
	for f in fires:
		if f.R > 0.0:
			w = maxf(w, f.S + 0.6 - f.t)
	return w

func item_at(p: Vector2) -> String:
	if vis < 0.5:
		return ""
	for id in pos:
		if p.distance_to(pos[id] + Vector2(0, 26)) < TOK * 0.6:
			return id
	return ""

func board_rect() -> Rect2:
	return _board_rect()

func _board_rect() -> Rect2:
	var vp := get_viewport_rect().size
	var panel_top: float = vp.y - 300.0 * main.panel.show_v + main.panel.jolt
	var rows := 0
	if not main.run.devices.is_empty(): rows += 1
	if not main.run.relics.is_empty(): rows += 1
	var h := 14.0 + rows * 64.0
	return Rect2(vp.x - BOARD_W - 34.0, panel_top - h - 6.0, BOARD_W, h)

func _process(dt: float) -> void:
	t += dt
	if main == null or main.run == null:
		return
	vis = clampf(main.panel.show_v, 0.0, 1.0)
	var d := minf(dt, 1.0 / 30.0)
	for id in _items():
		if not swing.has(id):
			swing[id] = [0.0, 0.0]
		var s: Array = swing[id]
		# 单摆：带阻尼，偶尔被空调风吹一下
		s[1] += (-38.0 * s[0] - 2.2 * s[1]) * d
		s[1] += sin(t * 0.7 + id.length()) * 0.06 * d * 60.0 * 0.02
		s[0] += s[1] * d
		if not hov.has(id):
			hov[id] = [0.0, 0.0]
		var h: Array = hov[id]
		var tg := 1.0 if id == hover_id else 0.0
		h[1] += (320.0 * (tg - h[0]) - 20.0 * h[1]) * d
		h[0] += h[1] * d
	for f in fires:
		var before: float = f.t
		f.t += dt
		if before < 0.0 and f.t >= 0.0:
			Sfx.play("lever", -12.0, 1.7)
			Sfx.play("whoosh", -12.0, 1.4)
		# 抽卡转盘：指针每扫过一格咔哒一声，越转越慢
		if f.R > 0.0 and f.t >= FLY_END and f.t < f.S:
			var n := int(floor(_spin_at(f, (f.t - FLY_END) / f.R) * 16.0))
			if n != f.tick:
				f.tick = n
				Sfx.play("tick", -9.0, 1.2 + 0.4 * ((f.t - FLY_END) / f.R))
		if not f.burst and f.t >= f.S:
			f.burst = true
			if f.hit:
				_burst(f)
				Sfx.play("ring", -6.0, 1.25)
				Sfx.play("metal", -10.0, 1.1)
				Sfx.play("paper", -10.0, 1.3)
				if f.R > 0.0:
					Sfx.play("perfect", -8.0, 1.4)
			else:
				Sfx.play("hit_low", -6.0, 0.8)
				Sfx.play("paper", -12.0, 0.8)
		if not f.landed and f.t >= f.S + 1.22:
			f.landed = true
			if swing.has(f.id):
				swing[f.id][1] += 7.0
			Sfx.play("tick", -8.0, 1.4)
		for p in f.parts:
			p.v.y += 900.0 * dt
			p.v *= 1.0 - 1.6 * dt
			p.p += p.v * dt
			p.r += p.w * dt
	fires = fires.filter(func(f): return f.t < f.S + 1.45)
	queue_redraw()

func _burst(f: Dictionary) -> void:
	var cols := [Icons.rarity_col(Items.ALL[f.id].rarity), Pal.c("gold"), Pal.c("red"), Pal.c("paper"), Pal.c("blue")]
	for i in 22:
		var a := randf() * TAU
		var sp := randf_range(260.0, 620.0)
		f.parts.append({"p": Vector2.ZERO, "v": Vector2.from_angle(a) * sp + Vector2(0, -180), "r": randf() * TAU,
			"w": randf_range(-14, 14), "s": Vector2(randf_range(5, 11), randf_range(3, 6)), "c": cols[i % cols.size()]})

func _show_point(f: Dictionary) -> Vector2:
	if f.R > 0.0:
		return Vector2(960.0 + f.slot * 340.0, 400.0)      # 抽卡：屏幕中央
	return Vector2(1215.0, 560.0 - f.slot * 175.0)

## 指针转过的圈数（0..spin），强减速：最后几格一点一点挪，要出不出
func _spin_at(f: Dictionary, k: float) -> float:
	var e := 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.6)
	return f.spin * e

func _draw() -> void:
	if main == null or main.run == null or vis < 0.01:
		pos.clear()
		return
	var items := _items()
	if items.is_empty():
		pos.clear()
		return
	var el := Pal.equip_line()
	var br := _board_rect()
	var a := clampf(vis * 1.4 - 0.2, 0.0, 1.0)
	# 挂板：穿孔板 + 两颗螺丝
	draw_rect(Rect2(br.position + Vector2(5, 7), br.size), Color(0, 0, 0, 0.12 * a))
	draw_rect(br, Color(Pal.c("equip_dark").lerp(Pal.c("paper2"), 0.55), a))
	for yy in range(int(br.position.y) + 12, int(br.end.y) - 6, 14):
		for xx in range(int(br.position.x) + 12, int(br.end.x) - 6, 14):
			draw_circle(Vector2(xx, yy), 1.4, Color(0, 0, 0, 0.12 * a))
	draw_rect(br, Color(el, a), false, 1.6)
	Ink.rivet(self, br.position + Vector2(8, 8), 2.4)
	Ink.rivet(self, Vector2(br.end.x - 8, br.position.y + 8), 2.4)
	pos.clear()
	var row := 0
	var hot_tok := []
	for kind in ["device", "relic"]:
		var list: Array = main.run.devices if kind == "device" else main.run.relics
		if list.is_empty():
			continue
		var ry := br.position.y + 10.0 + row * 64.0
		Ink.sticker(self, "设备" if kind == "device" else "护身符", Vector2(br.position.x + 30, ry + 26), -0.08, 11)
		for j in list.size():
			var id: String = list[j]
			var hook := Vector2(br.position.x + 84.0 + j * GAP, ry + 4.0)
			pos[id] = hook
			if _flying(id):
				draw_circle(hook, 3.0, Color(el, a))
				continue
			if id == hover_id:
				hot_tok = [id, hook]
			else:
				_token(id, hook, a, el)
		row += 1
	if not hot_tok.is_empty():
		_token(hot_tok[0], hot_tok[1], a, el)
	for f in fires:
		if f.t >= 0.0:
			_fire(f, el)

func _flying(id: String) -> bool:
	for f in fires:
		if f.id == id and f.t >= 0.12 and f.t < f.S + 1.22:
			return true
	return false

func _pre(id: String) -> float:
	for f in fires:
		if f.id == id and f.t >= 0.0 and f.t < 0.12:
			return f.t / 0.12
	return 0.0

## 挂在钉子上的纸牌
func _token(id: String, hook: Vector2, a: float, el: Color) -> void:
	var sw: float = swing[id][0] if swing.has(id) else 0.0
	var h: float = hov[id][0] if hov.has(id) else 0.0
	var pre := _pre(id)
	var rot := sw + sin(pre * 40.0) * 0.12 * pre
	var sc := 1.0 + 0.16 * h + 0.3 * pre
	var d: Dictionary = Items.ALL[id]
	var rc := Icons.rarity_col(d.rarity)
	var ctr := hook + Vector2(0, 30).rotated(rot)
	draw_line(hook, hook + Vector2(0, 8).rotated(rot), Color(el, a), 1.4, true)
	draw_circle(hook, 3.0, Color(el, a))
	draw_set_transform(ctr + Vector2(0, -4 * h), rot, Vector2(sc, sc))
	var r := Rect2(-TOK * 0.5, -TOK * 0.5 + 4, TOK, TOK)
	draw_rect(Rect2(r.position + Vector2(2, 3) + Vector2(2, 6) * h, r.size), Color(0, 0, 0, (0.12 + 0.1 * h) * a))
	draw_rect(r, Color(Pal.c("paper"), a))
	draw_rect(Rect2(r.position.x, r.end.y - 5, r.size.x, 5), Color(rc, a))
	draw_rect(r, Color(rc.lerp(el, 0.4) if h > 0.3 else el, a), false, 1.3 + h)
	draw_circle(Vector2(0, r.position.y + 5), 2.4, Color(el, a))
	if pre > 0.0:
		draw_rect(r, Color(1, 1, 1, 0.7 * (1.0 - absf(pre * 2.0 - 1.0))))
	draw_set_transform(Vector2.ZERO)
	Icons.draw(self, id, ctr + Vector2(0, 3 - 4 * h).rotated(rot), 40.0 * sc, rot)
	if main.run.uses.has(id):
		Ink.text(self, "×%d" % main.run.uses[id], ctr + Vector2(TOK * 0.5 + 2, TOK * 0.5 + 4) * sc, 12, Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)

## 一次触发的完整表演
func _fire(f: Dictionary, el: Color) -> void:
	var id: String = f.id
	var tt: float = f.t
	var hook: Vector2 = pos.get(id, Vector2(1700, 700))
	var home := hook + Vector2(0, 30)
	var sp := _show_point(f)
	var d: Dictionary = Items.ALL[id]
	var rc := Icons.rarity_col(d.rarity)
	if tt < 0.12:
		return
	var p := sp
	var big := 150.0 if f.R > 0.0 else 128.0
	var size := big
	var rot := 0.0
	var S: float = f.S
	var gray := 0.0
	if tt < FLY_END:
		# 飞出：弧线 + 转一圈 + 变大，带残影
		var k := Ink.ease_in_out((tt - 0.12) / (FLY_END - 0.12))
		var mid := (home + sp) * 0.5 + Vector2(0, -220)
		p = home.lerp(mid, k).lerp(mid.lerp(sp, k), k)
		size = lerpf(TOK, big, k)
		rot = TAU * k
		for g in 5:
			var k2 := clampf(k - (g + 1) * 0.06, 0.0, 1.0)
			var p2 := home.lerp(mid, k2).lerp(mid.lerp(sp, k2), k2)
			draw_circle(p2, 12.0 - g * 2.0, Color(rc, 0.35 - g * 0.06))
	elif tt < S:
		# 抽卡：牌在屏幕中央轻轻呼吸，外圈转盘在转
		var k: float = (tt - FLY_END) / f.R
		size = big * (1.0 + 0.03 * sin(tt * 14.0))
		_dial(f, sp, k, el, 1.0)
	elif tt < S + 0.88:
		var k := tt - S
		if f.R > 0.0:
			_dial(f, sp, 1.0, el, clampf((0.7 - k) / 0.3, 0.0, 1.0))
		if f.hit:
			var pop := 1.0 + 0.35 * exp(-k * 9.0) * cos(k * 30.0)
			size = big * pop
			p = sp + Vector2(0, sin(k * 6.0) * 4.0)
			rot = sin(k * 5.0) * 0.06
			# 射线：从中心转着张开，色块平涂
			var ra := clampf(k / 0.12, 0.0, 1.0) * clampf((0.88 - k) / 0.3, 0.0, 1.0)
			if ra > 0.0:
				var L := 70.0 + 120.0 * Ink.ease_out_cubic(minf(1.0, k / 0.25)) + (40.0 if f.R > 0.0 else 0.0)
				for i in 12:
					var ang := i * TAU / 12.0 + k * 0.9
					var col: Color = rc if i % 2 == 0 else Pal.c("gold")
					var pts := PackedVector2Array([p + Vector2.from_angle(ang - 0.07) * 58.0, p + Vector2.from_angle(ang) * (L + (i % 2) * 30.0), p + Vector2.from_angle(ang + 0.07) * 58.0])
					draw_colored_polygon(pts, Color(col, 0.75 * ra))
			# 墨圈（两道，前后错开）
			for ri in 2:
				var kk := clampf((k - ri * 0.1) / 0.45, 0.0, 1.0)
				if kk > 0.0 and kk < 1.0:
					draw_arc(p, 64.0 + 150.0 * Ink.ease_out_cubic(kk), 0, TAU, 64, Color(el if ri == 0 else rc, 0.8 * (1.0 - kk)), 5.0 * (1.0 - kk) + 1.0, true)
		else:
			# 没中：牌被弹得一抖，褪成灰色，往下一沉
			p = sp + Vector2(sin(k * 60.0) * 10.0 * exp(-k * 6.0), 18.0 * Ink.ease_out_cubic(minf(1.0, k / 0.3)))
			rot = sin(k * 40.0) * 0.12 * exp(-k * 5.0)
			gray = clampf(k / 0.15, 0.0, 1.0)
		# 纸条：从牌左边“唰”地展开
		_banner(f, p, k, rc if f.hit else Pal.c("text2"), el)
		if f.R > 0.0:
			_verdict(f, sp, k)
	else:
		# 飞回钉子
		var k := Ink.ease_in_out((tt - S - 0.88) / 0.34)
		var mid := (home + sp) * 0.5 + Vector2(0, -120)
		p = sp.lerp(mid, k).lerp(mid.lerp(home, k), k)
		size = lerpf(big, TOK, k)
		rot = -0.4 * sin(k * PI)
		gray = 0.0 if f.hit else 1.0 - k
	# 纸屑
	for q in f.parts:
		var qa := clampf((S + 1.1 - tt) / 0.4, 0.0, 1.0)
		draw_set_transform(sp + q.p, q.r, Vector2(1.0, absf(cos(q.r * 1.3)) * 0.8 + 0.2))
		draw_rect(Rect2(-q.s * 0.5, q.s), Color(q.c, qa))
		draw_set_transform(Vector2.ZERO)
	# 纸牌本体
	var s := size / TOK
	draw_set_transform(p, rot, Vector2(s, s))
	var r := Rect2(-TOK * 0.5, -TOK * 0.5, TOK, TOK)
	draw_rect(Rect2(r.position + Vector2(3, 5), r.size), Color(0, 0, 0, 0.18))
	draw_rect(r, Pal.c("paper"))
	draw_rect(Rect2(r.position.x, r.end.y - 5, r.size.x, 5), rc)
	draw_rect(r, el, false, 1.6 / s * 1.8)
	draw_set_transform(Vector2.ZERO)
	Icons.draw(self, id, p + Vector2(0, -2).rotated(rot) * s, size * 0.78, rot)
	if gray > 0.0:
		draw_set_transform(p, rot, Vector2(s, s))
		draw_rect(r, Color(Pal.c("paper2"), 0.55 * gray))
		draw_set_transform(Vector2.ZERO)

## 抽卡转盘：绿色段 = 生效概率；指针从顶上出发转 3 圈多，强减速停下
func _dial(f: Dictionary, c: Vector2, k: float, el: Color, a: float) -> void:
	if a <= 0.0:
		return
	var vp := get_viewport_rect().size
	# 背景压暗一点，把视线收到中间
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.18 * a * clampf((f.t - FLY_END) / 0.15, 0.0, 1.0)))
	var R := 112.0
	var W := 18.0
	var top := -PI / 2
	if f.roll.has("segs"):
		_dial_segs(f, c, a, R, W, top)
	else:
		_dial_two(f, c, a, R, W, top)
	draw_arc(c, R + W * 0.5, 0, TAU, 96, Color(el, a), 1.6, true)
	draw_arc(c, R - W * 0.5, 0, TAU, 96, Color(el, a), 1.6, true)
	for i in 16:
		var ang := top + TAU * i / 16.0
		draw_line(c + Vector2.from_angle(ang) * (R - W * 0.5), c + Vector2.from_angle(ang) * (R - W * 0.5 + 5.0), Color(el, 0.5 * a), 1.0)
	# 指针：转盘外的金色三角，指向圆心
	var ang2 := top + TAU * _spin_at(f, k)
	var dir := Vector2.from_angle(ang2)
	var tip := c + dir * (R + W * 0.5 + 2.0)
	var nrm := dir.orthogonal()
	var base := tip + dir * 26.0
	draw_colored_polygon(PackedVector2Array([tip, base + nrm * 11.0, base - nrm * 11.0]), Color(Pal.c("gold"), a))
	draw_polyline(PackedVector2Array([tip, base + nrm * 11.0, base - nrm * 11.0, tip]), Color(el, a), 2.0, true)
	# 拖影
	if k < 1.0:
		for g in 4:
			var a3 := top + TAU * _spin_at(f, maxf(0.0, k - (g + 1) * 0.025))
			draw_line(c + Vector2.from_angle(a3) * (R + W * 0.5 + 4.0), c + Vector2.from_angle(a3) * (R + W * 0.5 + 22.0), Color(el, (0.3 - g * 0.06) * a), 3.0)

## 揭晓：大字“生效！”/“没中”从牌上方盖下来
func _verdict(f: Dictionary, c: Vector2, k: float) -> void:
	var a := clampf((0.85 - k) / 0.25, 0.0, 1.0)
	var sc := lerpf(1.8, 1.0, Ink.ease_out_back(clampf(k / 0.16, 0.0, 1.0)))
	var txt := "生效！" if f.hit else "没中"
	if f.roll.has("segs"):
		txt = f.roll.segs[f.roll.pick][1] + "！"
	var col := Pal.c("gold").darkened(0.15) if f.hit else Pal.c("text2")
	draw_set_transform(c + Vector2(0, -150), -0.06, Vector2(sc, sc))
	var w := Pal.bold.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x + 36.0
	draw_rect(Rect2(-w * 0.5, -32, w, 58), Color(Pal.c("paper"), 0.85 * a))
	draw_rect(Rect2(-w * 0.5, -32, w, 58), Color(col, a), false, 4.0)
	Ink.text(self, txt, Vector2(0, 12), 40, Color(col, a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

func _banner(f: Dictionary, p: Vector2, k: float, rc: Color, el: Color) -> void:
	if f.R > 0.0:
		p = p + Vector2(-60, 0)
	var d: Dictionary = Items.ALL[f.id]
	var title: String = d.name
	var sub: String = f.text
	var w := maxf(Pal.bold.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x, Pal.bold.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x) + 56.0
	var open := Ink.ease_out_back(clampf((k - 0.05) / 0.22, 0.0, 1.0))
	var close := clampf((k - 0.7) / 0.18, 0.0, 1.0)
	var ww := w * open * (1.0 - Ink.ease_in_out(close))
	if ww < 4.0:
		return
	var right := p.x - 70.0
	var r := Rect2(right - ww, p.y - 40, ww, 80)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(r.position + Vector2(5, 7), r.size), Color(0, 0, 0, 0.16))
	draw_rect(r, Pal.c("paper"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 8)), rc)
	draw_rect(r, el, false, 1.6)
	# 文字只在纸条展开够宽时出现，从右往左“写”出来
	if ww > w * 0.6:
		var ta := clampf((ww - w * 0.6) / (w * 0.3), 0.0, 1.0)
		Ink.text(self, title, Vector2(right - 22, p.y - 10), 20, Color(Pal.c("text2"), ta), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
		Ink.text(self, sub, Vector2(right - 22, p.y + 26), 26, Color(Pal.c("text"), ta), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)

func _dial_two(f: Dictionary, c: Vector2, a: float, R: float, W: float, top: float) -> void:
	var p: float = f.roll.p
	draw_arc(c, R, 0, TAU, 96, Color(Pal.c("paper2"), a), W, true)
	draw_arc(c, R, top, top + TAU * p, 64, Color(Pal.c("green"), a), W, true)
	var mid := top + TAU * p * 0.5
	Ink.text(self, "%d%%" % int(round(p * 100.0)), c + Vector2.from_angle(mid) * (R + 34.0) + Vector2(0, 7), 20, Color(Pal.c("green").darkened(0.2), a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)

## 多段转盘：每段一种颜色，旁边写名字和概率
func _dial_segs(f: Dictionary, c: Vector2, a: float, R: float, W: float, top: float) -> void:
	var acc := 0.0
	for i in f.roll.segs.size():
		var sg: Array = f.roll.segs[i]
		var a0 := top + TAU * acc
		var a1: float = top + TAU * (acc + float(sg[0]))
		draw_arc(c, R, a0, a1, 40, Color(sg[2], a), W, true)
		draw_line(c + Vector2.from_angle(a0) * (R - W * 0.5), c + Vector2.from_angle(a0) * (R + W * 0.5), Color(Pal.equip_line(), a), 2.0)
		var mid: float = (a0 + a1) * 0.5
		var lp := c + Vector2.from_angle(mid) * (R + 60.0)
		Ink.text(self, sg[1], lp + Vector2(0, -2), 15, Color(Color(sg[2]).darkened(0.25), a), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, "%d%%" % int(round(sg[0] * 100.0)), lp + Vector2(0, 17), 14, Color(Pal.c("text2"), a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
		acc += sg[0]
