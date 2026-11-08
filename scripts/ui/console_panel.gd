extends Control
## 控制台面板（从屏幕底部升起的“桌面”）：机械滚轮计数器、概率纸带、锁相灯、蘑菇按钮、引出拉杆

const H := 300.0

var main: Node
var show_t := 0.0
var show_v := 0.0
var show_leave := false     # 实验进行中可以离开去采购（由主逻辑每帧设置）
var leave_v := 0.0
var leave_rect := Rect2()
var hover_leave := false
var leave_label := "← 先去采购"
var show_red := false        # 有“绝对不能按的红色按钮”时，控制台上多一个小红按钮
var red_used := false
var red_rect := Rect2()
var hover_red := false
var red_v := 0.0
var _vs := 0.0
# 计数器（滚轮）
var val_disp := 0.0
var _vval := 0.0
var val_target := 0.0
var e_disp := 1.0
var _ve := 0.0
var e_target := 1.0
# 概率纸带宽度
var seg := PackedFloat32Array([0.0, 0.1, 0.69, 0.15, 0.05, 0.01])
var seg_v := PackedFloat32Array([0, 0, 0, 0, 0, 0])
var seg_t := PackedFloat32Array([0.0, 0.1, 0.69, 0.15, 0.05, 0.01])
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
var dec := {}           # 决策条：{total, pot, line, loss, prot:[], lock_left}；空 = 舱里没束流
var t := 0.0
var jolt := 0.0
var btn_c := Vector2.ZERO      # 按钮中心（屏幕坐标）
var knob := Vector2.ZERO       # 拉杆球（屏幕坐标）
var lever_top := 0.0
var lever_len := 120.0
var dragging := false
var drag_v := 0.0
var hover_btn := false
var hover_knob := false
var tape_rect := Rect2()
var seg_x := PackedFloat32Array()
# 概率指针：沿纸带循环滑动、减速、停在结果段
var spinning := false
var spin_done := false
var spin_t := 0.0
var spin_T := 1.0
var spin_from := 0.0
var spin_total := 0.0
var ptr_abs := 0.08
var ptr_speed := 0.0
var _ptr_seg := -1
var ptr_vis := 0.0
var _vj := 0.0
var flash_val := 0.0
var _tick_n := 0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)
	chrome = Baked.make(self, _paint_chrome, true)

var chrome: Baked     # 桌面板、三块面板、铆钉、固定标签：烤成一层，升降只改位置

## 不变的部分（以 y0 = 0 画，节点放在 y0）
func _paint_chrome(ci: CanvasItem) -> void:
	var w: float = chrome.key[0]
	var el := Pal.equip_line()
	var top := PackedVector2Array([Vector2(0, 18), Vector2(w, 18), Vector2(w, H + 40), Vector2(0, H + 40)])
	ci.draw_colored_polygon(top, Pal.c("equip"))
	ci.draw_rect(Rect2(0, 10, w, 10), Pal.c("equip_dark"))
	ci.draw_line(Vector2(0, 10), Vector2(w, 10), el, 2.0)
	ci.draw_line(Vector2(0, 20), Vector2(w, 20), el, 1.2)
	ci.draw_rect(Rect2(0, 20, w, 8), Color(0, 0, 0, 0.06))
	for x in range(40, int(w), 220):
		Ink.rivet(ci, Vector2(x, 15), 2.0)
	for r in [Rect2(50, 46, 440, 220), Rect2(530, 46, 820, 220), Rect2(1390, 46, 480, 220)]:
		ci.draw_rect(r, Pal.c("equip").lerp(Pal.c("paper"), 0.25))
		Ink.frame(ci, r, el, 1.6)
		Ink.frame(ci, Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), Color(el, 0.25), 1.0)
		for p in [r.position + Vector2(10, 10), Vector2(r.end.x - 10, r.position.y + 10), r.end - Vector2(10, 10), Vector2(r.position.x + 10, r.end.y - 10)]:
			Ink.rivet(ci, p, 2.4)
	Ink.text(ci, "能级", Vector2(76, 82), 17, Pal.c("text2"))
	Ink.text(ci, "潜在成果", Vector2(250, 82), 17, Pal.c("text2"))
	Ink.text(ci, "RP", Vector2(446, 170), 16, Pal.c("text2"), Pal.mono)
	Ink.text(ci, "下一次加速", Vector2(556, 82), 17, Pal.c("text2"))

func set_beam(energy: int, value: int, odds: PackedFloat64Array, ch: int, lk: int) -> void:
	e_target = energy
	val_target = value
	for k in Odds.N:
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
	var p := Odds.table(1)
	for k in Odds.N:
		seg_t[k] = p[k]
	charge = 0
	lock_left = 0
	locked = false

func press() -> void:
	_vb = 14.0
	btn_target = 0.0
	_vj += 260.0
	flash_val = 1.0

## 开始揭晓：target_u 为结果在纸带上的落点（0..1），T 秒，绕 laps 圈
func spin(target_u: float, T: float, laps: int) -> void:
	spin_from = ptr_abs
	spin_total = laps + fposmod(target_u - ptr_abs, 1.0)
	spin_t = 0.0
	spin_T = T
	spinning = true
	spin_done = false
	btn_target = 0.8

## 等不及：剩余路程压缩到 0.14 秒（落点不变）
func skip() -> void:
	if not spinning:
		return
	var end_u := spin_from + spin_total
	spin_from = ptr_abs
	spin_total = end_u - ptr_abs
	spin_t = 0.0
	spin_T = 0.14

func progress() -> float:
	return clampf(spin_t / spin_T, 0.0, 1.0) if spinning else 1.0

func _seg_at(u: float) -> int:
	var tot := 0.0
	for k in Odds.N:
		tot += seg[k]
	var acc := 0.0
	for k in Odds.N:
		acc += seg[k] / maxf(tot, 1e-5)
		if u < acc:
			return k
	return Odds.LOSS

func pull() -> void:
	_vlv = 9.0

func _process(dt: float) -> void:
	t += dt
	var r := Ink.spring(show_v, _vs, show_t, 8.5, dt); show_v = r[0]; _vs = r[1]
	r = Ink.spring(val_disp, _vval, val_target, 11.0, dt); val_disp = r[0]; _vval = r[1]
	r = Ink.spring(e_disp, _ve, e_target, 12.0, dt); e_disp = r[0]; _ve = r[1]
	for k in Odds.N:
		r = Ink.spring(seg[k], seg_v[k], seg_t[k], 10.0, dt); seg[k] = r[0]; seg_v[k] = r[1]
	for i in 6:
		lamp_pop[i] = maxf(0.0, lamp_pop[i] - dt * 3.0)
	r = Ink.spring(btn_depth, _vb, btn_target, 26.0, dt); btn_depth = r[0]; _vb = r[1]
	r = Ink.spring(jolt, _vj, 0.0, 22.0, dt); jolt = r[0]; _vj = r[1]
	ptr_vis = lerpf(ptr_vis, 1.0 if (spinning or show_t > 0.0) else 0.0, 1.0 - exp(-10.0 * dt))
	if spinning:
		spin_t += dt
		var x := clampf(spin_t / spin_T, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - x, 4.2)
		var prev := ptr_abs
		ptr_abs = spin_from + spin_total * e
		ptr_speed = (ptr_abs - prev) / maxf(dt, 1e-4)
		var sg := _seg_at(fposmod(ptr_abs, 1.0))
		if sg != _ptr_seg:
			_ptr_seg = sg
			Sfx.play("tick", -7.0 + minf(4.0, 1.0 / maxf(ptr_speed, 0.3)), 0.8 + sg * 0.12, 0.03, 0.02)
		if x >= 1.0:
			spinning = false
			spin_done = true
			ptr_speed = 0.0
			btn_target = 0.0
	flash_val = maxf(0.0, flash_val - dt * 3.0)
	# 滚轮计数器每滚过一格“咔”一声
	var n := int(val_disp / maxf(1.0, val_target / 16.0))
	if n != _tick_n and show_v > 0.5:
		_tick_n = n
		Sfx.play("tick", -12.0, 1.1, 0.08, 0.025)
	# 拉杆：先被拉下，再弹回（欠阻尼弹簧更有机械感）
	var k2 := 90.0
	if dragging:
		lever = lerpf(lever, drag_v, 1.0 - exp(-30.0 * dt))
		_vlv = 0.0
	else:
		_vlv += (-k2 * lever - 9.0 * _vlv) * dt
		lever += _vlv * dt
	if show_v > 0.002 or show_t > 0.0:
		queue_redraw()

func _draw() -> void:
	chrome.visible = show_v >= 0.002
	if show_v < 0.002:
		return
	var vp := get_viewport_rect().size
	var y0 := vp.y - H * show_v + jolt
	var el := Pal.equip_line()
	var paper := Pal.c("paper")
	var ink := Pal.c("text")
	chrome.position = Vector2(0, y0)
	chrome.set_key([vp.x])
	_drums(Vector2(76, y0 + 96), e_disp, 2, 46.0, 66.0, "E")
	# 潜在成果超过 5 位数：鼓轮换成“万 / 亿 / 万亿”为单位
	var shown := val_disp
	var unit := ""
	if val_disp >= 9.9999e11:
		shown = val_disp / 1e12
		unit = "万亿"
	elif val_disp >= 9.9999e7:
		shown = val_disp / 1e8
		unit = "亿"
	elif val_disp >= 99999.5:
		shown = val_disp / 1e4
		unit = "万"
	if unit != "":
		shown = floor(shown)
	_drums(Vector2(250, y0 + 96), shown, 5, 38.0, 66.0, "")
	if flash_val > 0.0:
		Ink.frame(self, Rect2(244, y0 + 90, 196, 78), Color(Pal.c("gold"), 0.35 * flash_val), 4.0)
	if unit != "":
		Ink.text(self, unit, Vector2(446, y0 + 132), 20, Pal.c("red"), Pal.bold)
	if not dec.is_empty():
		_decision(Rect2(64, y0 + 180, 412, 76))
	elif hint != "":
		draw_set_transform(Vector2(76, y0 + 222), -0.02)
		Ink.text(self, hint, Vector2.ZERO, 22, Pal.c("red"), Pal.hand, HORIZONTAL_ALIGNMENT_LEFT, -1)
		draw_set_transform(Vector2.ZERO)
	# —— 中：概率纸带 + 锁相灯 ——
	_tape(Rect2(556, y0 + 98, 768, 44))
	_lamps(Vector2(556, y0 + 214))
	# —— 右：按钮 + 拉杆 ——
	_button(Vector2(1530, y0 + 150))
	_lever(Vector2(1760, y0 + 210))
	_leave_tab(y0)
	_red_box(y0)

func _plate(r: Rect2) -> void:
	var el := Pal.equip_line()
	draw_rect(r, Pal.c("equip").lerp(Pal.c("paper"), 0.25))
	Ink.frame(self, r, el, 1.6)
	Ink.frame(self, Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), Color(el, 0.25), 1.0)
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
		Ink.frame(self, r, el, 1.6)
		x += w
	# 外框
	Ink.frame(self, Rect2(p.x - 6 + (w * 0.72 if prefix != "" else 0.0), p.y - 6, x - p.x + 8 - (w * 0.72 if prefix != "" else 0.0), h + 12), el, 2.0)

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
		Ink.pl(self, zz, Color(el, 0.4), 1.0)
	tape_rect = r
	seg_x.clear()
	var x := r.position.x
	var centers: Array = []
	var total := 0.0
	for k in Odds.N:
		total += seg[k]
	for k in Odds.N:
		var w := r.size.x * seg[k] / maxf(total, 1e-5)
		var sr := Rect2(x, r.position.y, w, r.size.y)
		var col := Pal.outcome(k)
		if locked and k == Odds.LOSS:
			col = Pal.c("lock")
		draw_rect(sr, col)
		_hatch(sr, k)
		Ink.frame(self, sr, el, 1.2)
		centers.append(sr.get_center().x)
		seg_x.append(sr.end.x)
		x += w
	# 印字：标签按最小间距左右避让，并用细线指回色段（超级同步只在锁相时出现）
	var ks: Array = []
	for k in Odds.N:
		if k != Odds.SUPER or seg[k] > 0.004:
			ks.append(k)
	var n := ks.size()
	var lab: Array = []
	for k in ks:
		lab.append(centers[k])
	# 先从左往右保证间距和左边界，再从右往左压回右边界（不会再被推出纸带）
	lab[0] = maxf(lab[0], r.position.x + 44.0)
	for i in range(1, n):
		lab[i] = maxf(lab[i], lab[i - 1] + 96.0)
	lab[n - 1] = minf(lab[n - 1], r.end.x - 44.0)
	for i in range(n - 2, -1, -1):
		lab[i] = minf(lab[i], lab[i + 1] - 96.0)
	for i in n:
		var k: int = ks[i]
		var pct := seg[k] * 100.0
		var hot := k == Odds.LOSS and pct >= 20.0
		var col := Pal.c("red") if hot else Pal.c("text")
		if k == Odds.SUPER:
			col = Pal.c("gold").darkened(0.25)
		if absf(lab[i] - centers[k]) > 2.0:
			draw_line(Vector2(centers[k], r.end.y + 2), Vector2(lab[i], r.end.y + 8), Color(el, 0.5), 1.0, true)
		Ink.text(self, Odds.NAMES[k], Vector2(lab[i], r.end.y + 24), 15, col, Pal.bold if k == Odds.SUPER else Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, "%.1f%%" % pct, Vector2(lab[i], r.end.y + 44), 17, col, Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	# 指针：墨线三角 + 贯穿纸带的竖线；滑动时拖出残影
	if ptr_vis > 0.01:
		var u := fposmod(ptr_abs, 1.0)
		var px := r.position.x + u * r.size.x
		var ink := Pal.c("text")
		if spinning:
			var sg := _seg_at(u)
			var x0 := r.position.x
			for k in sg:
				x0 += r.size.x * seg[k] / maxf(total, 1e-5)
			var sw := r.size.x * seg[sg] / maxf(total, 1e-5)
			Ink.frame(self, Rect2(x0, r.position.y - 2, sw, r.size.y + 4), ink, 3.0)
			var ghosts := clampf(ptr_speed * 0.8, 0.0, 6.0)
			for g in int(ghosts):
				var gx := px - (g + 1) * 14.0
				if gx > r.position.x:
					draw_line(Vector2(gx, r.position.y - 16), Vector2(gx, r.end.y + 4), Color(ink, 0.18 - g * 0.025), 2.0)
		var a := ptr_vis
		draw_line(Vector2(px, r.position.y - 14), Vector2(px, r.end.y + 6), Color(ink, a), 2.6)
		draw_colored_polygon(PackedVector2Array([Vector2(px - 12, r.position.y - 30), Vector2(px + 12, r.position.y - 30), Vector2(px, r.position.y - 10)]), Color(Pal.c("gold"), a))
		Ink.pl(self, PackedVector2Array([Vector2(px - 12, r.position.y - 30), Vector2(px + 12, r.position.y - 30), Vector2(px, r.position.y - 10), Vector2(px - 12, r.position.y - 30)]), Color(ink, a), 2.0)
	# 丢失段：红色圈注（像拿红笔圈出来）
	var lw := r.size.x * seg[Odds.LOSS] / maxf(total, 1e-5)
	if seg[Odds.LOSS] >= 0.12:
		var c := Vector2(r.end.x - lw * 0.5, r.get_center().y)
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 38.0 - 0.3
			pts.append(c + Vector2(cos(a) * (lw * 0.5 + 16 + sin(a * 3.0) * 2.0), sin(a) * (r.size.y * 0.5 + 10)))
		Ink.pl(self, pts, Pal.c("red"), 2.2)

func _hatch(r: Rect2, k: int) -> void:
	if r.size.x < 3:
		return
	var c := Color(0, 0, 0, 0.13)
	match k:
		Odds.SUPER:
			# 金色段：斜向双线 + 慢慢流动，提示“这一段很特别”
			var x3 := r.position.x - fmod(t * 18.0, 10.0)
			while x3 < r.end.x:
				for o in [0.0, 3.0]:
					var xa: float = x3 + o
					var xb: float = xa + r.size.y * 0.5
					if xb > r.position.x and xa < r.end.x:
						draw_line(Vector2(clampf(xa, r.position.x, r.end.x), r.end.y), Vector2(clampf(xb, r.position.x, r.end.x), r.position.y), Color(1, 1, 1, 0.45), 1.2)
				x3 += 10.0
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
	var need: int = main.run.lock_need() if main != null and main.run != null else 6
	for i in need:
		var c := p + Vector2(118 + i * 46, -8)
		var on := i < charge or locked
		var s := 1.0 + lamp_pop[i] * 0.35
		var pts := PackedVector2Array()
		for k in 7:
			pts.append(c + Vector2.from_angle(PI / 3 * k + PI / 6) * 15.0 * s)
		draw_colored_polygon(pts, (Pal.c("lock") if locked else Pal.c("ramp2")) if on else Pal.c("equip_dark"))
		Ink.pl(self, pts, el, 1.6)
		if on:
			draw_line(c + Vector2(-6, -7) * s, c + Vector2(-1, -9) * s, Color(1, 1, 1, 0.5), 2.0)
	if locked:
		var tx := p + Vector2(420, -2)
		draw_rect(Rect2(tx + Vector2(-6, -24), Vector2(232, 34)), Pal.c("lock"))
		Ink.frame(self, Rect2(tx + Vector2(-6, -24), Vector2(232, 34)), el, 1.6)
		Ink.text(self, "锁相 · 剩余 %d 次安全加速" % lock_left, tx, 17, Pal.c("paper"), Pal.bold)

func _button(c: Vector2) -> void:
	btn_c = c
	var el := Pal.equip_line()
	if hover_btn and enabled:
		draw_arc(c, 86.0, 0, TAU, 64, Pal.c("red"), 3.0, true)
	# 底座（俯视的金属环 + 侧面厚度）
	Ink.disc(self, c + Vector2(0, 10), 78.0, Pal.c("equip_dark").darkened(0.15))
	Ink.disc(self, c, 78.0, Pal.c("equip_dark"))
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
	Ink.disc(self, c + Vector2(0, 6), 54.0, cap.darkened(0.35))
	Ink.disc(self, c - Vector2(0, rise - 6), 54.0, cap.darkened(0.2))
	Ink.disc(self, c - Vector2(0, rise), 54.0, cap)
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
	knob = base + Vector2(0, hy)
	lever_top = base.y - 130.0
	if (hover_knob or dragging) and enabled:
		draw_arc(knob, 28.0, 0, TAU, 32, Pal.c("red"), 3.0, true)
		Ink.text(self, "往下拖到底", base + Vector2(-150, -40), 15, Pal.c("red"), Pal.hand)
	draw_line(base + Vector2(0, -2), knob, el, 8.0, true)
	draw_line(base + Vector2(0, -2), knob, Pal.c("equip"), 5.0, true)
	Ink.disc(self, knob, 21.0, Pal.c("gold") if enabled else Pal.c("equip_dark"))
	draw_arc(knob, 21.0, 0, TAU, 32, el, 2.0, true)
	draw_arc(knob, 13.0, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.5), 4.0, true)
	Ink.text(self, "引出", base + Vector2(56, -86), 26, Pal.c("text"), Pal.bold)
	Ink.text(self, "E", base + Vector2(56, -56), 15, Pal.c("text2"), Pal.mono)

# —— 鼠标命中 ——
func hit_button(p: Vector2) -> bool:
	return show_v > 0.9 and p.distance_to(btn_c) < 70.0

func hit_knob(p: Vector2) -> bool:
	return show_v > 0.9 and p.distance_to(knob) < 32.0

func start_drag() -> void:
	dragging = true
	drag_v = lever

func drag_to(y: float) -> void:
	drag_v = clampf((y - lever_top) / lever_len, 0.0, 1.0)

## 松手：拖到 75% 以上即引出
func end_drag() -> bool:
	dragging = false
	return drag_v >= 0.75

func seg_at(p: Vector2) -> int:
	if show_v < 0.9 or not tape_rect.grow(6).has_point(p):
		return -1
	for k in seg_x.size():
		if p.x <= seg_x[k]:
			return k
	return seg_x.size() - 1

## 面板左上角伸出的纸签：实验进行中随时离开去采购，束流留在舱里等你回来
func _leave_tab(y0: float) -> void:
	leave_v = lerpf(leave_v, 1.0 if show_leave else 0.0, 0.2)
	if leave_v < 0.02:
		leave_rect = Rect2()
		return
	var el := Pal.equip_line()
	var h := 40.0
	var r := Rect2(60, y0 + 14 - h * leave_v - (4.0 if hover_leave else 0.0), 236, h + 8)
	leave_rect = r if leave_v > 0.8 else Rect2()
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.12))
	draw_rect(r, Pal.c("gold") if hover_leave else Pal.c("paper"))
	Ink.frame(self, r, Pal.c("red") if hover_leave else el, 2.0 if hover_leave else 1.4)
	Ink.text(self, leave_label, r.position + Vector2(16, 28), 18, Pal.c("text"), Pal.bold)
	Ink.text(self, "Esc · 右键", r.position + Vector2(r.size.x - 14, 27), 13, Pal.c("text2"), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)

## 绝对不能按的红色按钮：面板上沿伸出一个小盒子，翻开的透明盖子 + 红按钮；按过以后盖子合上
func _red_box(y0: float) -> void:
	red_v = lerpf(red_v, 1.0 if show_red else 0.0, 0.2)
	if red_v < 0.02:
		red_rect = Rect2()
		return
	var el := Pal.equip_line()
	var r := Rect2(320, y0 + 16 - 62 * red_v, 150, 62)
	red_rect = r if red_v > 0.8 and not red_used else Rect2()
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.14))
	draw_rect(r, Color("#e9c64a"))
	# 黄黑警示斜纹
	var x := r.position.x - 20.0
	while x < r.end.x:
		draw_line(Vector2(maxf(x, r.position.x), r.position.y + (maxf(x, r.position.x) - x)), Vector2(minf(x + 14, r.end.x), r.position.y + minf(14.0, r.end.x - x)), Color("#2b2a28"), 4.0)
		x += 16.0
	Ink.frame(self, r, el, 1.6)
	var c := Vector2(r.position.x + 40, r.get_center().y + 4)
	var press := 4.0 if hover_red else 0.0
	Ink.disc(self, c + Vector2(0, 4), 18.0, Pal.c("red").darkened(0.35))
	Ink.disc(self, c + Vector2(0, press * 0.5), 18.0, Pal.c("red") if not red_used else Pal.c("red").lerp(Pal.c("equip_dark"), 0.6))
	draw_arc(c + Vector2(0, press * 0.5), 18.0, 0, TAU, 32, el, 1.6, true)
	# 透明翻盖：没按过时掀开，按过后盖上
	if red_used:
		draw_rect(Rect2(c - Vector2(24, 24), Vector2(48, 48)), Color(1, 1, 1, 0.35))
		Ink.frame(self, Rect2(c - Vector2(24, 24), Vector2(48, 48)), el, 1.4)
	else:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-24, -24), c + Vector2(24, -24), c + Vector2(20, -40), c + Vector2(-20, -40)]), Color(1, 1, 1, 0.35))
	Ink.text(self, "绝对不能按", Vector2(r.position.x + 70, r.position.y + 26), 14, Color("#2b2a28"), Pal.bold)
	Ink.text(self, "已按过" if red_used else "B 键", Vector2(r.position.x + 70, r.position.y + 46), 12, Color("#2b2a28"), Pal.mono)
	if hover_red and not red_used:
		Ink.frame(self, r.grow(3), Pal.c("red"), 2.0)

## 决策条（左面板下半）：现在引出累计多少 / 离考核线还差多少；下一次丢失风险；还剩什么保护或锁相
func _decision(r: Rect2) -> void:
	var ink := Pal.c("text")
	var after: int = dec.total + dec.pot
	var ln: int = dec.line
	var ok := after >= ln
	# 第一行：引出后累计 + 够线进度条
	var y := r.position.y + 18.0
	Ink.text(self, "现在引出", Vector2(r.position.x, y), 15, Pal.c("text2"))
	var s1 := ("累计 %s / %s" % [main.fmt(after), main.fmt(ln)])
	Ink.text(self, s1, Vector2(r.position.x + 70, y), 17, ink, Pal.mono)
	var tag := "够线 ✓" if ok else "还差 %s" % main.fmt(ln - after)
	Ink.text(self, tag, Vector2(r.end.x, y), 17, Pal.c("green") if ok else Pal.c("red"), Pal.bold, HORIZONTAL_ALIGNMENT_RIGHT)
	var bar := Rect2(r.position.x, y + 8, r.size.x, 7)
	draw_rect(bar, Color(Pal.equip_line(), 0.15))
	var f0 := clampf(float(dec.total) / maxf(1.0, ln), 0.0, 1.0)
	var f1 := clampf(float(after) / maxf(1.0, ln), 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * f0, bar.size.y)), Pal.c("ink2"))
	draw_rect(Rect2(bar.position + Vector2(bar.size.x * f0, 0), Vector2(bar.size.x * (f1 - f0), bar.size.y)), Pal.c("green") if ok else Pal.c("gold"))
	Ink.frame(self, bar, Pal.equip_line(), 1.0)
	# 第二行：风险 + 保护 / 锁相
	y += 44.0
	if dec.lock_left > 0:
		Ink.text(self, "锁相中 · 还剩 %d 次 · 这几下不会丢失" % dec.lock_left, Vector2(r.position.x, y), 17, Pal.c("lock"), Pal.bold)
		return
	var lp: float = dec.loss
	var rc := Pal.c("red") if lp >= 0.2 else (Pal.c("orange") if lp >= 0.08 else Pal.c("text2"))
	Ink.text(self, "丢失风险", Vector2(r.position.x, y), 15, Pal.c("text2"))
	Ink.text(self, "%.0f%%" % (lp * 100.0) if lp >= 0.1 else "%.1f%%" % (lp * 100.0), Vector2(r.position.x + 70, y), 20, rc, Pal.bold)
	var prot: Array = dec.prot
	var ps := "保护：" + ("、".join(prot) if not prot.is_empty() else "无")
	var fs := 15
	while fs > 11 and Ink.size(Pal.font, ps, fs).x > r.size.x - 140:
		fs -= 1
	Ink.text(self, ps, Vector2(r.end.x, y), fs, Pal.c("green") if not prot.is_empty() else Pal.c("text2"), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)
