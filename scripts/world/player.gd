extends Node2D
## 研究员：程序化骨骼走路（支撑脚贴地不打滑、膝盖朝前、肘部朝后、身体起伏）+ 白大褂弹簧下摆 + 脚步声

const SPEED := 250.0
const ACCEL := 9.0
const STRIDE := 21.0        # 单脚前后摆幅（像素）：支撑期脚相对身体后移速度 = 身体速度
const LIFT := 10.0

var vx := 0.0
var facing := 1.0
var face_s := 1.0
var _vf := 0.0
var phase := 0.0
var stride := 0.0
var hem := 0.0
var _vh := 0.0
var t := 0.0
var blink := 0.0
var next_blink := 2.5
var console_pose := 0.0
var t_console := 0.0
var _vc := 0.0
var tap := 0.0              # 按键时手往下一拍
var input_enabled := true
var carry := ""            # 手里抱着的瓶子（Q70）："" / "fresh" / "empty" / "full"，main 每帧同步
var carry_bt := {}
var carry_t := 0.0         # 0..1 抱瓶姿势过渡
const STASH := preload("res://scripts/world/stash.gd")
var auto_target := -1.0
var _prev_cos := [1.0, 1.0]

func _ready() -> void:
	position = Vector2(700, Geo.FLOOR)

func press() -> void:
	tap = 1.0

func _process(dt: float) -> void:
	t += dt
	var want := 0.0
	if input_enabled:
		want = Input.get_axis("move_left", "move_right")
		if want != 0.0:
			auto_target = -1.0
	if auto_target >= 0.0:
		var dx := auto_target - position.x
		want = clampf(dx / 30.0, -1.0, 1.0)
		if absf(dx) < 2.0:
			want = 0.0
	vx = lerpf(vx, want * SPEED, 1.0 - exp(-ACCEL * dt))
	if absf(vx) < 2.0 and want == 0.0:
		vx = 0.0
	position.x = clampf(position.x + vx * dt, Geo.WALK_MIN, Geo.WALK_MAX)
	if absf(want) > 0.05:
		facing = signf(want)
	if auto_target >= 0.0 and absf(auto_target - position.x) < 2.0:
		facing = 1.0
	var r := Ink.spring(face_s, _vf, facing, 26.0, dt); face_s = r[0]; _vf = r[1]
	var spd := absf(vx) / SPEED
	stride = lerpf(stride, clampf(spd * 1.15, 0.0, 1.0), 1.0 - exp(-12.0 * dt))
	# 角速度 = 速度 / 摆幅 → 支撑脚相对地面静止
	phase = fmod(phase + absf(vx) / STRIDE * dt, TAU * 100.0)
	if stride < 0.05:
		phase = lerpf(phase, round(phase / PI) * PI, 1.0 - exp(-8.0 * dt))
	r = Ink.spring(hem, _vh, -vx / SPEED * 9.0, 7.0, dt); hem = r[0]; _vh = r[1]
	r = Ink.spring(console_pose, _vc, t_console, 9.0, dt); console_pose = r[0]; _vc = r[1]
	carry_t = move_toward(carry_t, 1.0 if carry != "" else 0.0, dt * 6.0)
	tap = maxf(0.0, tap - dt * 7.0)
	next_blink -= dt
	if next_blink <= 0.0:
		blink = 0.14
		next_blink = randf_range(2.0, 4.5)
	blink = maxf(0.0, blink - dt)
	# 脚落地（进入支撑期）时出脚步声
	for side in 2:
		var c := cos(phase + side * PI)
		if _prev_cos[side] >= 0.0 and c < 0.0 and stride > 0.3:
			Sfx.play("step", -14.0, 1.0, 0.12)
		_prev_cos[side] = c
	queue_redraw()

func _ik(root: Vector2, end: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := clampf(root.distance_to(end), 0.01, l1 + l2 - 0.01)
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	var dir := (end - root).angle()
	return root + Vector2.from_angle(dir - a * bend) * l1

## 造型参数（主角草案：cur 现版 / a 瘦长学者 / b 老派工程师 / c 年轻助理）
const STYLES := {
	"cur": {"hip": 64.0, "l1": 33.0, "l2": 32.0, "leg_w": 7.0, "sh": 124.0, "lean": 0.0, "coat_top": 16.0, "coat_mid": 19.0,
		"hem": 44.0, "hem_w": 22.0, "arm1": 27.0, "arm2": 26.0, "arm_w": 6.0, "head_r": 13.0, "hair": "side", "hair_col": "hair",
		"glasses": "mono", "clip": false, "tie": false, "pens": 1, "mous": false, "shoe": 1.0, "sleeve": 0.0},
	"a": {"hip": 72.0, "l1": 37.0, "l2": 37.0, "leg_w": 5.0, "sh": 138.0, "lean": 4.0, "coat_top": 14.0, "coat_mid": 15.0,
		"hem": 30.0, "hem_w": 20.0, "arm1": 29.0, "arm2": 29.0, "arm_w": 5.0, "head_r": 12.0, "hair": "part", "hair_col": "hair",
		"glasses": "round", "clip": true, "tie": false, "pens": 2, "mous": false, "shoe": 1.15, "sleeve": 0.0},
	"b": {"hip": 64.0, "l1": 33.0, "l2": 32.0, "leg_w": 7.5, "sh": 124.0, "lean": 1.5, "coat_top": 18.0, "coat_mid": 22.0,
		"hem": 46.0, "hem_w": 24.0, "arm1": 27.0, "arm2": 26.0, "arm_w": 6.5, "head_r": 13.5, "hair": "gray", "hair_col": "ink2",
		"glasses": "thick", "clip": false, "tie": true, "pens": 3, "mous": true, "shoe": 1.0, "sleeve": 0.0},
	"c": {"hip": 56.0, "l1": 29.0, "l2": 28.0, "leg_w": 6.5, "sh": 108.0, "lean": 0.0, "coat_top": 16.0, "coat_mid": 20.0,
		"hem": 26.0, "hem_w": 25.0, "arm1": 25.0, "arm2": 25.0, "arm_w": 7.0, "head_r": 15.0, "hair": "messy", "hair_col": "hair",
		"glasses": "none", "clip": true, "tie": false, "pens": 1, "mous": false, "shoe": 0.95, "sleeve": 5.0},
}
var style := "a"           # 用户 2026-11-09 选 A 瘦长学者

func _draw() -> void:
	var S: Dictionary = STYLES[style]
	var el := Pal.c("ink") if not Pal.dark else Color("#2a2620")
	var coat := Pal.c("coat")
	draw_colored_polygon(_ellipse(Vector2(0, 1), 26.0 + stride * 6.0, 4.5), Color(0, 0, 0, 0.14))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(face_s, 1.0))
	# 身体起伏：双腿竖直时最高，跨步时最低
	var bob := -(absf(cos(phase)) - 0.6) * 3.4 * stride
	var breath := sin(t * 2.2) * 0.8 * (1.0 - stride)
	var lean := 3.0 * stride + float(S.lean) * (1.0 - console_pose * 0.5)
	var hip := Vector2(lean * 0.2, -float(S.hip) + bob)
	var leg_col := el.lerp(Color("#3a4250"), 0.5) if not Pal.dark else Color("#3a3a36")
	var sw: float = S.shoe
	# 远侧腿先画（被身体挡住一部分）
	for side in [1, 0]:
		var ph: float = phase + side * PI
		var fx := sin(ph) * STRIDE * stride
		var fy := -maxf(0.0, cos(ph)) * LIFT * stride
		var foot := Vector2(fx + (1.0 if side == 0 else -2.0), fy)
		var h2 := hip + Vector2(1.0 if side == 0 else -2.0, 0)
		var knee := _ik(h2, foot, S.l1, S.l2, 1.0)
		var c := leg_col if side == 0 else leg_col.darkened(0.25)
		Ink.pl(self, PackedVector2Array([h2, knee, foot]), c, S.leg_w)
		# 鞋：脚尖朝前，抬脚时略翘
		var toe := -0.25 * maxf(0.0, cos(ph)) * stride
		draw_set_transform(Vector2(foot.x * face_s, foot.y), toe * face_s, Vector2(face_s, 1.0))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -4), Vector2(9 * sw, -4), Vector2(11 * sw, 1), Vector2(-6, 1)]), el)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face_s, 1.0))
	# 白大褂
	var sh := Vector2(lean, -float(S.sh) + bob + breath)
	var ct: float = S.coat_top
	var cm: float = S.coat_mid
	var hw: float = S.hem_w
	var waist := -float(S.hip) - 24.0 + bob
	var hem_l := Vector2(-hw + 1 + hem * 0.6 + lean * 0.3, -float(S.hem) + bob)
	var hem_r := Vector2(hw + 1 + hem + lean * 0.3, -float(S.hem) + bob + absf(hem) * 0.15)
	var body := PackedVector2Array([sh + Vector2(-ct, 0), sh + Vector2(ct, 0), Vector2(cm + lean * 0.5, waist), hem_r, hem_r.lerp(hem_l, 0.5) + Vector2(hem * 0.3, 2), hem_l, Vector2(-cm + 1 + lean * 0.5, waist)])
	draw_colored_polygon(body, coat)
	body.append(body[0])
	Ink.pl(self, body, el, 1.8)
	# 前襟线、领口
	draw_line(sh + Vector2(3, 6), Vector2(4 + hem * 0.4 + lean * 0.3, -float(S.hem) - 2 + bob), Color(el, 0.5), 1.0, true)
	if S.tie:
		# 领带（深红褐，夹在领口 V 里）
		draw_colored_polygon(PackedVector2Array([sh + Vector2(1.5, 3), sh + Vector2(5.5, 3), sh + Vector2(6, 22), sh + Vector2(3.5, 26), sh + Vector2(1, 22)]), Pal.c("quad_b"))
	draw_line(sh + Vector2(-4, 2), sh + Vector2(3, 14), Color(el, 0.6), 1.0, true)
	draw_line(sh + Vector2(10, 2), sh + Vector2(3, 14), Color(el, 0.6), 1.0, true)
	# 胸袋 + 笔
	Ink.pl(self, PackedVector2Array([sh + Vector2(6, 30), sh + Vector2(6, 39), sh + Vector2(15, 39), sh + Vector2(15, 30)]), Color(el, 0.6), 1.0)
	var pen_cols := [Pal.c("blue"), Pal.c("red"), el]
	for i in int(S.pens):
		draw_line(sh + Vector2(9 + i * 2.5, 25 - (i % 2)), sh + Vector2(9 + i * 2.5, 33), pen_cols[i], 2.0)
	draw_rect(Rect2(sh + Vector2(-13, 24), Vector2(8, 10)), Pal.c("red"))
	# 抱着的瓶子：立在胸前，两只手托住（画在手臂前面，手再压在瓶身上）
	var bp := sh + Vector2(19, 78)
	if carry != "":
		draw_set_transform(Vector2.ZERO)
		var at := Vector2(bp.x * face_s, bp.y)
		if carry == "full":
			STASH.full_bottle(self, at, 0.62, carry_bt)
		else:
			_carry_bottle(at, carry == "empty")
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face_s, 1.0))
	# 手臂：与同侧腿反向摆；肘部朝后；操作控制台时双手落在台面；拿夹板时远侧手把夹板抱在胸前
	var clip_hand := Vector2.ZERO
	for side in [1, 0]:
		var sp: Vector2 = sh + Vector2(-3.0 if side == 1 else 6.0, 5)
		var swing := -sin(phase + side * PI) * 0.42 * stride
		var al: float = S.arm1 + S.arm2 - 3.0
		var hand_walk: Vector2 = sp + Vector2.from_angle(PI / 2 - swing) * al
		if S.clip and side == 1:
			hand_walk = sh + Vector2(13, 44)
		var desk := Vector2(46.0 if side == 0 else 34.0, -96.0 + tap * 7.0 * (1.0 if side == 0 else 0.3))
		desk.y += sin(t * 7.0 + side) * 0.8
		var hand: Vector2 = hand_walk.lerp(desk, console_pose)
		# 抱瓶：近手托瓶底、远手扶瓶身
		hand = hand.lerp(bp + (Vector2(-2, -6) if side == 0 else Vector2(-6, -38)), carry_t)
		var elbow := _ik(sp, hand, S.arm1, S.arm2, -1.0)
		var ac := coat if side == 0 else coat.darkened(0.08)
		var aw: float = S.arm_w
		Ink.pl(self, PackedVector2Array([sp, elbow, hand]), el, aw + 2.6)
		Ink.pl(self, PackedVector2Array([sp, elbow, hand]), ac, aw)
		# 袖子长：手只露出一点
		var sl: float = S.sleeve
		if sl > 0.0:
			var d := (hand - elbow).normalized()
			Ink.disc(self, hand + d * (2.0 - sl * 0.2), 2.6, Pal.c("skin"))
		else:
			Ink.disc(self, hand, 3.4, Pal.c("skin"))
		if side == 1:
			clip_hand = hand
	# 夹板：抱在胸前（操作控制台时夹在腋下）
	if S.clip:
		var tuck := maxf(console_pose, carry_t)
		var cp := clip_hand.lerp(sh + Vector2(-8, 30), tuck) + Vector2(-4, -4)
		draw_set_transform(Vector2(cp.x * face_s, cp.y), (-0.25 + tuck * 0.2) * face_s, Vector2(face_s, 1.0))
		draw_rect(Rect2(-7, -18, 15, 22), Color("#8a6a48"))
		draw_rect(Rect2(-5, -15, 11, 16), Pal.c("paper"))
		Ink.frame(self, Rect2(-7, -18, 15, 22), el, Ink.W3)
		draw_rect(Rect2(-3, -20, 7, 3), Pal.c("equip_dark"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face_s, 1.0))
	# 头（随步伐轻微点头）
	var hr: float = S.head_r
	var hp := sh + Vector2(1 + lean * 0.4, -hr - 3.0)
	draw_line(sh + Vector2(0, 1), hp + Vector2(0, hr * 0.45), Pal.c("skin"), 6.0)
	Ink.disc(self, hp, hr, Pal.c("skin"))
	draw_arc(hp, hr, 0, TAU, 32, el, 1.6, true)
	_hair(hp, hr, S.hair, Pal.c(S.hair_col))
	# 眼、眼镜
	var eye := hp + Vector2(hr * 0.54, -1)
	match S.glasses:
		"mono":
			draw_arc(eye + Vector2(-1, 0), 4.2, 0, TAU, 16, el, 1.2, true)
			draw_line(hp + Vector2(1, -1), hp + Vector2(-6, -3), el, 1.0)
		"round":
			draw_arc(eye + Vector2(-1, 0), 4.6, 0, TAU, 16, el, 1.3, true)
			draw_line(eye + Vector2(-5.6, -0.5), hp + Vector2(-hr * 0.5, -2), el, 1.0)
			draw_line(eye + Vector2(3.4, 0), eye + Vector2(5.5, -0.5), el, 1.0)
		"thick":
			draw_rect(Rect2(eye + Vector2(-6, -4), Vector2(10, 7)), Color(el, 0.15))
			Ink.frame(self, Rect2(eye + Vector2(-6, -4), Vector2(10, 7)), el, 2.0)
			draw_line(eye + Vector2(-6, -2), hp + Vector2(-hr * 0.5, -3), el, 1.6)
	if blink <= 0.0:
		Ink.disc(self, eye, 1.3, el)
	else:
		draw_line(eye + Vector2(-2, 0), eye + Vector2(2, 0), el, 1.2)
	if S.mous:
		draw_colored_polygon(PackedVector2Array([hp + Vector2(hr * 0.35, hr * 0.38), hp + Vector2(hr * 0.85, hr * 0.32), hp + Vector2(hr * 0.75, hr * 0.5), hp + Vector2(hr * 0.4, hr * 0.52)]), Pal.c(S.hair_col))
	else:
		draw_line(hp + Vector2(hr * 0.38, hr * 0.46), hp + Vector2(hr * 0.7, hr * 0.42), Color(el, 0.6), 1.0)
	draw_set_transform(Vector2.ZERO)

## 抱在手里的新瓶 / 空瓶（p 是瓶底中心，已经按朝向翻好的本地坐标）
func _carry_bottle(p: Vector2, empty: bool) -> void:
	var el := Pal.equip_line()
	var w := 15.0
	var h := 58.0
	var body := Color("#9fc9a3")
	if empty:
		body = body.lerp(Pal.c("equip_dark"), 0.6)
	draw_rect(Rect2(p.x - w * 0.5, p.y - h, w, h), body)
	Ink.disc(self, Vector2(p.x, p.y - h), w * 0.5, body)
	draw_rect(Rect2(p.x - w * 0.5 + 2, p.y - h, 3, h), Color(1, 1, 1, 0.22))
	Ink.frame(self, Rect2(p.x - w * 0.5, p.y - h, w, h), el, Ink.W2)
	draw_arc(Vector2(p.x, p.y - h), w * 0.5, PI, TAU, 12, el, Ink.W2, true)
	if not empty:
		draw_rect(Rect2(p.x - w * 0.5, p.y - h + 4, w, 4), Color(Pal.c("red"), 0.8))
	draw_rect(Rect2(p.x - 3, p.y - h - w * 0.5 - 7, 6, 7), el)

## 发型：side 侧分 / gray 灰白后退的发际线 / messy 乱蓬蓬
func _hair(hp: Vector2, hr: float, kind: String, col: Color) -> void:
	var hair := PackedVector2Array()
	match kind:
		"side":
			for i in 17:
				var a := PI + PI * i / 16.0 + 0.25
				hair.append(hp + Vector2.from_angle(a) * (hr + 1.0))
			hair.append(hp + Vector2(-hr * 0.77, 2))
			hair.append(hp + Vector2(-hr * 1.08, -2))
		"part":
			# 整齐的侧分短发：只盖头顶和后脑，露出整张脸
			for i in 15:
				var a := PI + 0.35 + (PI - 0.25) * i / 14.0
				hair.append(hp + Vector2.from_angle(a) * (hr + 1.5))
			hair.append(hp + Vector2(hr * 0.2, -hr * 0.55))
			hair.append(hp + Vector2(-hr * 0.55, -hr * 0.2))
			hair.append(hp + Vector2(-hr * 0.95, hr * 0.2))
		"gray":
			# 头顶稀、两侧和后脑一圈
			for i in 13:
				var a := PI * 0.9 + PI * 0.75 * i / 12.0
				hair.append(hp + Vector2.from_angle(a) * (hr + 1.5))
			for i in range(12, -1, -1):
				var a := PI * 0.9 + PI * 0.75 * i / 12.0
				hair.append(hp + Vector2.from_angle(a) * (hr - 3.0))
		"messy":
			for i in 21:
				var a := PI * 0.85 + PI * 1.25 * i / 20.0
				var r := hr + (5.0 if i % 2 == 0 else 1.0)
				hair.append(hp + Vector2.from_angle(a) * r)
			hair.append(hp + Vector2(hr * 0.2, -hr * 0.4))
			hair.append(hp + Vector2(-hr * 0.6, 1))
	draw_colored_polygon(hair, col)

func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
