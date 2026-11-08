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

func _draw() -> void:
	var el := Pal.c("ink") if not Pal.dark else Color("#2a2620")
	var coat := Pal.c("coat")
	draw_colored_polygon(_ellipse(Vector2(0, 1), 26.0 + stride * 6.0, 4.5), Color(0, 0, 0, 0.14))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(face_s, 1.0))
	# 身体起伏：双腿竖直时最高，跨步时最低
	var bob := -(absf(cos(phase)) - 0.6) * 3.4 * stride
	var breath := sin(t * 2.2) * 0.8 * (1.0 - stride)
	var lean := 3.0 * stride
	var hip := Vector2(0, -64 + bob)
	var leg_col := el.lerp(Color("#3a4250"), 0.5) if not Pal.dark else Color("#3a3a36")
	# 远侧腿先画（被身体挡住一部分）
	for side in [1, 0]:
		var ph: float = phase + side * PI
		var fx := sin(ph) * STRIDE * stride
		var fy := -maxf(0.0, cos(ph)) * LIFT * stride
		var foot := Vector2(fx + (1.0 if side == 0 else -2.0), fy)
		var h2 := hip + Vector2(1.0 if side == 0 else -2.0, 0)
		var knee := _ik(h2, foot, 33.0, 32.0, 1.0)
		var c := leg_col if side == 0 else leg_col.darkened(0.25)
		draw_polyline(PackedVector2Array([h2, knee, foot]), c, 7.0, true)
		# 鞋：脚尖朝前，抬脚时略翘
		var toe := -0.25 * maxf(0.0, cos(ph)) * stride
		draw_set_transform(Vector2(foot.x * face_s, foot.y), toe * face_s, Vector2(face_s, 1.0))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -4), Vector2(9, -4), Vector2(11, 1), Vector2(-6, 1)]), el)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face_s, 1.0))
	# 白大褂
	var sh := Vector2(lean, -124 + bob + breath)
	var hem_l := Vector2(-21 + hem * 0.6, -44 + bob)
	var hem_r := Vector2(23 + hem, -44 + bob + absf(hem) * 0.15)
	var body := PackedVector2Array([sh + Vector2(-16, 0), sh + Vector2(16, 0), Vector2(19 + lean * 0.5, -88 + bob), hem_r, hem_r.lerp(hem_l, 0.5) + Vector2(hem * 0.3, 2), hem_l, Vector2(-18 + lean * 0.5, -88 + bob)])
	draw_colored_polygon(body, coat)
	body.append(body[0])
	draw_polyline(body, el, 1.8, true)
	draw_line(sh + Vector2(3, 6), Vector2(4 + hem * 0.4, -46 + bob), Color(el, 0.5), 1.0, true)
	draw_line(sh + Vector2(-4, 2), sh + Vector2(3, 14), Color(el, 0.6), 1.0, true)
	draw_line(sh + Vector2(10, 2), sh + Vector2(3, 14), Color(el, 0.6), 1.0, true)
	draw_polyline(PackedVector2Array([sh + Vector2(6, 30), sh + Vector2(6, 39), sh + Vector2(15, 39), sh + Vector2(15, 30)]), Color(el, 0.6), 1.0, true)
	draw_line(sh + Vector2(9, 26), sh + Vector2(9, 33), Pal.c("blue"), 2.0)
	draw_rect(Rect2(sh + Vector2(-13, 24), Vector2(8, 10)), Pal.c("red"))
	# 手臂：与同侧腿反向摆；肘部朝后；操作控制台时双手落在台面
	for side in [1, 0]:
		var sp: Vector2 = sh + Vector2(-3.0 if side == 1 else 6.0, 5)
		var swing := -sin(phase + side * PI) * 0.42 * stride
		var hand_walk: Vector2 = sp + Vector2.from_angle(PI / 2 - swing) * 50.0
		var desk := Vector2(46.0 if side == 0 else 34.0, -96.0 + tap * 7.0 * (1.0 if side == 0 else 0.3))
		desk.y += sin(t * 7.0 + side) * 0.8
		var hand: Vector2 = hand_walk.lerp(desk, console_pose)
		var elbow := _ik(sp, hand, 27.0, 26.0, -1.0)
		var ac := coat if side == 0 else coat.darkened(0.08)
		draw_polyline(PackedVector2Array([sp, elbow, hand]), el, 8.6, true)
		draw_polyline(PackedVector2Array([sp, elbow, hand]), ac, 6.0, true)
		draw_circle(hand, 3.4, Pal.c("skin"))
	# 头（随步伐轻微点头）
	var hp := sh + Vector2(1 + lean * 0.4, -16)
	draw_line(sh + Vector2(0, 1), hp + Vector2(0, 6), Pal.c("skin"), 6.0)
	draw_circle(hp, 13.0, Pal.c("skin"))
	draw_arc(hp, 13.0, 0, TAU, 32, el, 1.6, true)
	var hair := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0 + 0.25
		hair.append(hp + Vector2.from_angle(a) * 14.0)
	hair.append(hp + Vector2(-10, 2))
	hair.append(hp + Vector2(-14, -2))
	draw_colored_polygon(hair, Pal.c("hair"))
	draw_arc(hp + Vector2(6, -1), 4.2, 0, TAU, 16, el, 1.2, true)
	draw_line(hp + Vector2(1, -1), hp + Vector2(-6, -3), el, 1.0)
	if blink <= 0.0:
		draw_circle(hp + Vector2(7, -1), 1.3, el)
	else:
		draw_line(hp + Vector2(5, -1), hp + Vector2(9, -1), el, 1.2)
	draw_line(hp + Vector2(5, 6), hp + Vector2(9, 5.5), Color(el, 0.6), 1.0)
	draw_set_transform(Vector2.ZERO)

func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
