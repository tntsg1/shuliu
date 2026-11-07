extends Node2D
## 研究员：程序化骨骼 + 两骨 IK 走路 + 白大褂下摆弹簧摆动 + 眨眼呼吸

const SPEED := 330.0
const ACCEL := 9.0

var vx := 0.0
var facing := 1.0
var face_s := 1.0
var _vf := 0.0
var phase := 0.0
var stride := 0.0
var hem := 0.0          # 下摆偏移（弹簧）
var _vh := 0.0
var t := 0.0
var blink := 0.0
var next_blink := 2.5
var console_pose := 0.0  # 0..1 伸手操作控制台
var t_console := 0.0
var _vc := 0.0
var input_enabled := true
var auto_target := -1.0  # 自动走到某 x（进入控制台）

func _ready() -> void:
	position = Vector2(700, Geo.FLOOR)

func _process(dt: float) -> void:
	t += dt
	var want := 0.0
	if input_enabled:
		want = Input.get_axis("move_left", "move_right")
	if auto_target >= 0.0:
		var dx := auto_target - position.x
		want = clampf(dx / 40.0, -1.0, 1.0)
		if absf(dx) < 2.0:
			want = 0.0
	vx = lerpf(vx, want * SPEED, 1.0 - exp(-ACCEL * dt))
	if absf(vx) < 1.0 and want == 0.0:
		vx = 0.0
	position.x = clampf(position.x + vx * dt, Geo.WALK_MIN, Geo.WALK_MAX)
	if want != 0.0:
		facing = signf(want)
	if auto_target >= 0.0 and absf(auto_target - position.x) < 2.0:
		facing = 1.0
	var r := Ink.spring(face_s, _vf, facing, 18.0, dt); face_s = r[0]; _vf = r[1]
	var spd := absf(vx) / SPEED
	stride = lerpf(stride, spd, 1.0 - exp(-10.0 * dt))
	phase += absf(vx) * dt / 34.0
	r = Ink.spring(hem, _vh, -vx / SPEED * 9.0, 7.0, dt); hem = r[0]; _vh = r[1]
	r = Ink.spring(console_pose, _vc, t_console, 9.0, dt); console_pose = r[0]; _vc = r[1]
	next_blink -= dt
	if next_blink <= 0.0:
		blink = 0.14
		next_blink = randf_range(2.0, 4.5)
	blink = maxf(0.0, blink - dt)
	queue_redraw()

func _ik(hip: Vector2, foot: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := clampf(hip.distance_to(foot), 0.01, l1 + l2 - 0.01)
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	var dir := (foot - hip).angle()
	return hip + Vector2.from_angle(dir - a * bend) * l1

func _draw() -> void:
	var el := Pal.c("ink") if not Pal.dark else Color("#2a2620")
	var coat := Pal.c("coat")
	var s := Vector2(face_s, 1.0)
	# 投影
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(_ellipse(Vector2(0, 1), 30.0 * (1.0 - stride * 0.15), 5.0), Color(0, 0, 0, 0.14))
	draw_set_transform(Vector2.ZERO, 0.0, s)
	var bob := -absf(sin(phase * PI)) * 3.2 * stride
	var breath := sin(t * 2.2) * 0.8 * (1.0 - stride)
	var hip := Vector2(0, -64 + bob)
	# 腿
	for side in [-1.0, 1.0]:
		var ph: float = phase * PI + (0.0 if side > 0 else PI)
		var foot := Vector2(sin(ph) * 15.0 * stride + side * 3.0, -maxf(0.0, cos(ph)) * 9.0 * stride)
		var h2 := hip + Vector2(side * 4.0, 0)
		var knee := _ik(h2, foot, 33.0, 32.0, -1.0)
		var leg_col := el.lerp(Color("#3a4250"), 0.5) if not Pal.dark else Color("#3a3a36")
		draw_polyline(PackedVector2Array([h2, knee, foot]), leg_col, 7.0, true)
		draw_colored_polygon(PackedVector2Array([foot + Vector2(-5, -4), foot + Vector2(10, -4), foot + Vector2(11, 1), foot + Vector2(-5, 1)]), el)
	# 白大褂（下摆随速度弹簧摆动）
	var sh := Vector2(0, -124 + bob + breath)
	var hem_l := Vector2(-21 + hem * 0.6, -44 + bob)
	var hem_r := Vector2(24 + hem, -44 + bob + absf(hem) * 0.15)
	var body := PackedVector2Array([sh + Vector2(-16, 0), sh + Vector2(16, 0), Vector2(19, -88 + bob), hem_r, hem_r.lerp(hem_l, 0.5) + Vector2(hem * 0.3, 2), hem_l, Vector2(-18, -88 + bob)])
	draw_colored_polygon(body, coat)
	body.append(body[0])
	draw_polyline(body, el, 1.8, true)
	draw_line(sh + Vector2(3, 6), Vector2(4 + hem * 0.4, -46 + bob), Color(el, 0.5), 1.0, true)
	draw_line(sh + Vector2(-4, 2), sh + Vector2(3, 14), Color(el, 0.6), 1.0, true)
	draw_line(sh + Vector2(10, 2), sh + Vector2(3, 14), Color(el, 0.6), 1.0, true)
	# 口袋 + 笔 + 工牌
	draw_rect(Rect2(sh + Vector2(6, 30), Vector2(9, 9)), Color(el, 0.0))
	draw_polyline(PackedVector2Array([sh + Vector2(6, 30), sh + Vector2(6, 39), sh + Vector2(15, 39), sh + Vector2(15, 30)]), Color(el, 0.6), 1.0, true)
	draw_line(sh + Vector2(9, 26), sh + Vector2(9, 33), Pal.c("blue"), 2.0)
	draw_rect(Rect2(sh + Vector2(-13, 24), Vector2(8, 10)), Pal.c("red"))
	# 手臂：走路摆臂 ↔ 操作控制台
	var arm_sw := sin(phase * PI) * 0.5 * stride
	for side in [1.0, -1.0]:
		var sp: Vector2 = sh + Vector2(side * 9.0, 4)
		var hand_walk: Vector2 = sp + Vector2.from_angle(PI / 2 + arm_sw * side) * 52.0
		var hand_work: Vector2 = sh + Vector2(42 + (6.0 if side < 0 else 0.0), 30 + sin(t * 9.0) * 1.2 * console_pose)
		var hand: Vector2 = hand_walk.lerp(hand_work, console_pose)
		var elbow := _ik(sp, hand, 27.0, 27.0, side * 0.0 + 1.0)
		var arm_col := coat if side > 0 else coat.darkened(0.06)
		draw_polyline(PackedVector2Array([sp, elbow, hand]), el, 8.6, true)
		draw_polyline(PackedVector2Array([sp, elbow, hand]), arm_col, 6.0, true)
		draw_circle(hand, 3.4, Pal.c("skin"))
	# 头
	var hp := sh + Vector2(1, -16)
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
	# 眼镜 + 眼
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
