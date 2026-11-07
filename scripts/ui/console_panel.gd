extends Control
## 控制台面板（从屏幕底部升起的“桌面”）：机械滚轮计数器、概率纸带、锁相灯、蘑菇按钮、引出拉杆

const H := 300.0

var main: Node
var show_t := 0.0
var show_v := 0.0
var _vs := 0.0
# 计数器（滚轮）
var val_disp := 0.0
var _vval := 0.0
var val_target := 0.0
var e_disp := 1.0
var _ve := 0.0
var e_target := 1.0
# 概率纸带宽度
var seg := PackedFloat32Array([0.1, 0.69, 0.15, 0.05, 0.01])
var seg_v := PackedFloat32Array([0, 0, 0, 0, 0])
var seg_t := PackedFloat32Array([0.1, 0.69, 0.15, 0.05, 0.01])
# 锁相灯
var charge := 0
var lamp_pop := PackedFloat32Array([0, 0, 0, 0, 0, 0])
var lock_left := 0
var locked := false
# 按钮/拉杆
var btn_depth := 0.0
var _vb := 0.0
var btn_target := 0.0
var lever := 0.0
var _vlv := 0.0
var lever_target := 0.0
var enabled := false
var hint := ""
var t := 0.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func set_beam(energy: int, value: int, odds: PackedFloat64Array, ch: int, lk: int) -> void:
	e_target = energy
	val_target = value
	for k in 5:
		seg_t[k] = odds[k]
	if ch > charge:
		for i in range(charge, mini(ch, 6)):
			lamp_pop[i] = 1.0
	charge = ch
	lock_left = lk
	locked = lk > 0

func reset_beam() -> void:
	e_target = 1
	val_target = Odds.value_at(1)
	charge = 0
	lock_left = 0
	locked = false

func press() -> void:
	_vb = 14.0
	btn_target = 0.0

func pull() -> void:
	_vlv = 9.0

func _process(dt: float) -> void:
	t += dt
	var r := Ink.spring(show_v, _vs, show_t, 8.5, dt); show_v = r[0]; _vs = r[1]
	r = Ink.spring(val_disp, _vval, val_target, 11.0, dt); val_disp = r[0]; _vval = r[1]
	r = Ink.spring(e_disp, _ve, e_target, 12.0, dt); e_disp = r[0]; _ve = r[1]
	for k in 5:
		r = Ink.spring(seg[k], seg_v[k], seg_t[k], 10.0, dt); seg[k] = r[0]; seg_v[k] = r[1]
	for i in 6:
		lamp_pop[i] = maxf(0.0, lamp_pop[i] - dt * 3.0)
	r = Ink.spring(btn_depth, _vb, btn_target, 26.0, dt); btn_depth = r[0]; _vb = r[1]
	# 拉杆：先被拉下，再弹回（欠阻尼弹簧更有机械感）
	var k2 := 90.0
	_vlv += (-k2 * lever - 9.0 * _vlv) * dt
	lever += _vlv * dt
	if show_v > 0.002 or show_t > 0.0:
		queue_redraw()

func _draw() -> void:
	if show_v < 0.002:
		return
	var vp := get_viewport_rect().size
	var y0 := vp.y - H * show_v
	var el := Pal.equip_line()
	var paper := Pal.c("paper")
	var ink := Pal.c("text")
	# 桌面板：上沿斜切 + 金属包边
	var top := PackedVector2Array([Vector2(0, y0 + 18), Vector2(vp.x, y0 + 18), Vector2(vp.x, vp.y + 10), Vector2(0, vp.y + 10)])
	draw_colored_polygon(top, Pal.c("equip"))
	draw_rect(Rect2(0, y0 + 10, vp.x, 10), Pal.c("equip_dark"))
	draw_line(Vector2(0, y0 + 10), Vector2(vp.x, y0 + 10), el, 2.0)
	draw_line(Vector2(0, y0 + 20), Vector2(vp.x, y0 + 20), el, 1.2)
	draw_rect(Rect2(0, y0 + 20, vp.x, 8), Color(0, 0, 0, 0.06))
	for x in range(40, int(vp.x), 220):
		Ink.rivet(self, Vector2(x, y0 + 15), 2.0)
	# 面板分区
	_plate(Rect2(50, y0 + 46, 440, 220))
	_plate(Rect2(530, y0 + 46, 820, 220))
	_plate(Rect2(1390, y0 + 46, 480, 220))
	# —— 左：能级与潜在成果 ——
	Ink.text(self, "能级", Vector2(76, y0 + 82), 17, Pal.c("text2"))
	_drums(Vector2(76, y0 + 96), e_disp, 2, 46.0, 66.0, "E")
	Ink.text(self, "潜在成果", Vector2(250, y0 + 82), 17, Pal.c("text2"))
	_drums(Vector2(250, y0 + 96), val_disp, 5, 38.0, 66.0, "")
	Ink.text(self, "RP", Vector2(446, y0 + 170), 16, Pal.c("text2"), Pal.mono)
	if hint != "":
		draw_set_transform(Vector2(76, y0 + 222), -0.02)
		draw_string(Pal.hand, Vector2.ZERO, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.c("red"))
		draw_set_transform(Vector2.ZERO)
	# —— 中：概率纸带 + 锁相灯 ——
	Ink.text(self, "下一次加速", Vector2(556, y0 + 82), 17, Pal.c("text2"))
	_tape(Rect2(556, y0 + 98, 768, 44))
	_lamps(Vector2(556, y0 + 214))
	# —— 右：按钮 + 拉杆 ——
	_button(Vector2(1530, y0 + 150))
	_lever(Vector2(1760, y0 + 210))

func _plate(r: Rect2) -> void:
	var el := Pal.equip_line()
	draw_rect(r, Pal.c("equip").lerp(Pal.c("paper"), 0.25))
	draw_rect(r, el, false, 1.6)
	draw_rect(Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), Color(el, 0.25), false, 1.0)
	for p in [r.position + Vector2(10, 10), Vector2(r.end.x - 10, r.position.y + 10), r.end - Vector2(10, 10), Vector2(r.position.x + 10, r.end.y - 10)]:
		Ink.rivet(self, p, 2.4)

## 机械滚轮计数器（里程表式进位）
func _drums(p: Vector2, v: float, digits: int, w: float, h: float, prefix: String) -> void:
	var el := Pal.equip_line()
	var x := p.x
	if prefix != "":
		Ink.text(self, prefix, Vector2(x, p.y + h * 0.72), int(h * 0.62), Pal.c("text"), Pal.mono)
		x += w * 0.72
	v = maxf(0.0, v)
	for i in range(digits - 1, -1, -1):
		var r := Rect2(x, p.y, w - 4, h)
		draw_rect(r, Pal.c("screen") if not Pal.dark else Color("#1a1612"))
		var pw := pow(10.0, i)
		var wheel := v / pw
		var dgt := int(floor(wheel)) % 10
		var frac := 0.0
		if i == 0:
			frac = wheel - floor(wheel)
		else:
			var rest := fmod(v, pw)
			frac = clampf(rest - (pw - 1.0), 0.0, 1.0)
		var leading := v < pw and i > 0 and dgt == 0 and frac < 0.01
		var fs := int(h * 0.66)
		var col := Color("#f3ead6") if not leading else Color("#f3ead6", 0.18)
		var cy := p.y + h * 0.5 + fs * 0.36
		# 当前数字上移、下一个数字从下方进入
		draw_set_transform(Vector2.ZERO)
		var clip_top := p.y + 3
		for kk in 2:
			var d := (dgt + kk) % 10
			var yy := cy - frac * h + kk * h
			if yy - fs * 0.8 < p.y + h and yy > clip_top:
				var a := 1.0 - clampf(absf(yy - fs * 0.36 - (p.y + h * 0.5)) / (h * 0.62), 0.0, 1.0)
				Ink.text(self, str(d), Vector2(r.get_center().x, yy), fs, Color(col, col.a * a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
		# 滚轮的圆柱明暗
		draw_rect(Rect2(r.position, Vector2(r.size.x, 10)), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 10), Vector2(r.size.x, 10)), Color(0, 0, 0, 0.35))
		draw_line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Color(1, 1, 1, 0.04), 1.0)
		draw_rect(r, el, false, 1.6)
		x += w
	# 外框
	draw_rect(Rect2(p.x - 6 + (w * 0.72 if prefix != "" else 0.0), p.y - 6, x - p.x + 8 - (w * 0.72 if prefix != "" else 0.0), h + 12), el, false, 2.0)

## 概率纸带：五段色块 + 排线纹理 + 下方印字
func _tape(r: Rect2) -> void:
	var el := Pal.equip_line()
	var paper := Pal.c("paper")
	# 纸带本体 + 两端锯齿撕口
	var pr := Rect2(r.position + Vector2(-12, -6), r.size + Vector2(24, 62))
	draw_rect(pr, paper)
	draw_line(pr.position, Vector2(pr.end.x, pr.position.y), Color(el, 0.4), 1.0)
	draw_line(Vector2(pr.position.x, pr.end.y), pr.end, Color(el, 0.4), 1.0)
	for side in [pr.position.x, pr.end.x]:
		var zz := PackedVector2Array()
		for i in 13:
			zz.append(Vector2(side + (4.0 if i % 2 == 0 else -4.0), pr.position.y + pr.size.y * i / 12.0))
		draw_polyline(zz, Color(el, 0.4), 1.0, true)
	var x := r.position.x
	var centers: Array = []
	var total := 0.0
	for k in 5:
		total += seg[k]
	for k in 5:
		var w := r.size.x * seg[k] / maxf(total, 1e-5)
		var sr := Rect2(x, r.position.y, w, r.size.y)
		var col := Pal.outcome(k)
		if locked and k == Odds.LOSS:
			col = Pal.c("lock")
		draw_rect(sr, col)
		_hatch(sr, k)
		draw_rect(sr, el, false, 1.2)
		centers.append(sr.get_center().x)
		x += w
	# 印字：标签按最小间距左右避让，并用细线指回色段
	var lab: Array = centers.duplicate()
	for i in range(1, 5):
		lab[i] = maxf(lab[i], lab[i - 1] + 96.0)
	var over: float = lab[4] - (r.end.x - 40.0)
	if over > 0.0:
		for i in 5:
			lab[i] -= over
		for i in range(3, -1, -1):
			lab[i] = minf(lab[i], lab[i + 1] - 96.0)
	var under: float = r.position.x + 44.0 - lab[0]
	if under > 0.0:
		for i in 5:
			lab[i] += under
	for k in 5:
		var pct := seg[k] * 100.0
		var hot := k == Odds.LOSS and pct >= 20.0
		var col := Pal.c("red") if hot else Pal.c("text")
		if absf(lab[k] - centers[k]) > 2.0:
			draw_line(Vector2(centers[k], r.end.y + 2), Vector2(lab[k], r.end.y + 8), Color(el, 0.5), 1.0, true)
		Ink.text(self, Odds.NAMES[k], Vector2(lab[k], r.end.y + 24), 15, col, Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, "%.1f%%" % pct, Vector2(lab[k], r.end.y + 44), 17, col, Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	# 丢失段：红色圈注（像拿红笔圈出来）
	var lw := r.size.x * seg[Odds.LOSS] / maxf(total, 1e-5)
	if seg[Odds.LOSS] >= 0.12:
		var c := Vector2(r.end.x - lw * 0.5, r.get_center().y)
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 38.0 - 0.3
			pts.append(c + Vector2(cos(a) * (lw * 0.5 + 16 + sin(a * 3.0) * 2.0), sin(a) * (r.size.y * 0.5 + 10)))
		draw_polyline(pts, Pal.c("red"), 2.2, true)

func _hatch(r: Rect2, k: int) -> void:
	if r.size.x < 3:
		return
	var c := Color(0, 0, 0, 0.13)
	match k:
		Odds.PERFECT:
			var y := r.position.y + 5
			while y < r.end.y:
				draw_line(Vector2(r.position.x + 1, y), Vector2(r.end.x - 1, y), Color(1, 1, 1, 0.35), 1.0)
				y += 5.0
		Odds.DETUNE:
			var x := r.position.x
			while x < r.end.x:
				draw_line(Vector2(x, r.end.y), Vector2(minf(x + r.size.y, r.end.x), r.end.y - minf(r.size.y, r.end.x - x)), c, 1.0)
				x += 6.0
		Odds.LOSS:
			var x2 := r.position.x
			while x2 < r.end.x:
				draw_line(Vector2(x2, r.position.y), Vector2(minf(x2 + r.size.y, r.end.x), r.position.y + minf(r.size.y, r.end.x - x2)), Color(0, 0, 0, 0.2), 1.4)
				x2 += 5.0

func _lamps(p: Vector2) -> void:
	var el := Pal.equip_line()
	Ink.text(self, "锁相充能", p + Vector2(0, -2), 16, Pal.c("text2"))
	for i in 6:
		var c := p + Vector2(118 + i * 46, -8)
		var on := i < charge or locked
		var s := 1.0 + lamp_pop[i] * 0.35
		var pts := PackedVector2Array()
		for k in 7:
			pts.append(c + Vector2.from_angle(PI / 3 * k + PI / 6) * 15.0 * s)
		draw_colored_polygon(pts, (Pal.c("lock") if locked else Pal.c("ramp2")) if on else Pal.c("equip_dark"))
		draw_polyline(pts, el, 1.6, true)
		if on:
			draw_line(c + Vector2(-6, -7) * s, c + Vector2(-1, -9) * s, Color(1, 1, 1, 0.5), 2.0)
	if locked:
		var tx := p + Vector2(420, -2)
		draw_rect(Rect2(tx + Vector2(-6, -24), Vector2(232, 34)), Pal.c("lock"))
		draw_rect(Rect2(tx + Vector2(-6, -24), Vector2(232, 34)), el, false, 1.6)
		Ink.text(self, "锁相 · 剩余 %d 次安全加速" % lock_left, tx, 17, Pal.c("paper"), Pal.bold)

func _button(c: Vector2) -> void:
	var el := Pal.equip_line()
	# 底座（俯视的金属环 + 侧面厚度）
	draw_circle(c + Vector2(0, 10), 78.0, Pal.c("equip_dark").darkened(0.15))
	draw_circle(c, 78.0, Pal.c("equip_dark"))
	draw_arc(c, 78.0, 0, TAU, 64, el, 2.0, true)
	draw_arc(c, 66.0, 0, TAU, 64, Color(el, 0.4), 1.0, true)
	for i in 8:
		Ink.rivet(self, c + Vector2.from_angle(TAU * i / 8.0 + 0.2) * 72.0, 2.2)
	# 蘑菇帽：按下时下沉 + 变扁
	var d := clampf(btn_depth, -0.3, 1.0)
	var cap := Pal.c("red") if enabled else Pal.c("red").lerp(Pal.c("equip_dark"), 0.55)
	if locked and enabled:
		cap = Pal.c("lock")
	var rise := 14.0 * (1.0 - d)
	draw_circle(c + Vector2(0, 6), 54.0, cap.darkened(0.35))
	draw_circle(c - Vector2(0, rise - 6), 54.0, cap.darkened(0.2))
	draw_circle(c - Vector2(0, rise), 54.0, cap)
	draw_arc(c - Vector2(0, rise), 54.0, 0, TAU, 64, el, 2.0, true)
	draw_arc(c - Vector2(0, rise), 40.0, PI * 1.05, PI * 1.6, 24, Color(1, 1, 1, 0.45), 6.0, true)
	Ink.text(self, "加速", c - Vector2(0, rise - 9), 28, Pal.c("paper"), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "空格", c + Vector2(0, 104), 15, Pal.c("text2"), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

func _lever(base: Vector2) -> void:
	var el := Pal.equip_line()
	# 导槽
	Ink.box(self, Rect2(base + Vector2(-16, -150), Vector2(32, 160)), Pal.c("equip_dark"), el, 1.6, 77)
	draw_rect(Rect2(base + Vector2(-4, -140), Vector2(8, 140)), Color(0, 0, 0, 0.35))
	# 刻度
	for i in 5:
		draw_line(base + Vector2(20, -140 + i * 35), base + Vector2(30, -140 + i * 35), el, 1.4)
	# 手柄位置：0=上（待命），1=下（已引出）
	var k := clampf(lever, 0.0, 1.2)
	var hy := lerpf(-130.0, -10.0, k)
	var knob := base + Vector2(0, hy)
	draw_line(base + Vector2(0, -2), knob, el, 8.0, true)
	draw_line(base + Vector2(0, -2), knob, Pal.c("equip"), 5.0, true)
	draw_circle(knob, 21.0, Pal.c("gold") if enabled else Pal.c("equip_dark"))
	draw_arc(knob, 21.0, 0, TAU, 32, el, 2.0, true)
	draw_arc(knob, 13.0, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.5), 4.0, true)
	Ink.text(self, "引出", base + Vector2(56, -86), 26, Pal.c("text"), Pal.bold)
	Ink.text(self, "E", base + Vector2(56, -56), 15, Pal.c("text2"), Pal.mono)
