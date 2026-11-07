extends Node2D
## 横向胶囊观测舱：着色器束流 + 舱框；所有状态量用临界阻尼弹簧平滑（丝滑）

var beam_rect: ColorRect
var frame: Node2D
var mat: ShaderMaterial

# 目标与平滑值
var t_value := 0.0
var t_danger := 0.0
var t_lock := 0.0
var value := 0.0
var danger := 0.0
var lockf := 0.0
var _vv := 0.0
var _vd := 0.0
var _vl := 0.0
var pulse := 0.0
var dissolve := 0.0
var dissolving := false
var appear := 0.0
var t_appear := 0.0
var _va := 0.0
var shake := 0.0
var lit := 0            # 已点亮的磁体灯数
var flick := 0.0

func _ready() -> void:
	position = Geo.CHAMBER
	beam_rect = ColorRect.new()
	beam_rect.size = Geo.CH_SIZE
	beam_rect.position = -Geo.CH_SIZE * 0.5
	beam_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/beam.gdshader")
	beam_rect.material = mat
	add_child(beam_rect)
	frame = Node2D.new()
	frame.set_script(load("res://scripts/world/chamber_frame.gd"))
	frame.set("chamber", self)
	add_child(frame)
	mat.set_shader_parameter("size", Geo.CH_SIZE)
	mat.set_shader_parameter("seed", randf() * 10.0)
	Pal.changed.connect(_apply_palette)
	_apply_palette()

func _apply_palette() -> void:
	mat.set_shader_parameter("ink", Pal.c("ink") if not Pal.dark else Pal.c("paper"))
	mat.set_shader_parameter("inner0", Pal.c("inner0"))
	mat.set_shader_parameter("inner1", Pal.c("inner1"))
	mat.set_shader_parameter("grid_col", Pal.c("grid"))
	mat.set_shader_parameter("danger_col", Pal.c("red"))
	mat.set_shader_parameter("lock_col", Pal.c("lock"))
	mat.set_shader_parameter("beam_hi", Pal.c("paper"))
	mat.set_shader_parameter("paper_mode", 0.0 if Pal.dark else 1.0)

## 由主逻辑每帧调用：beam 为 null 表示舱空
func set_state(energy: int, loss_p: float, locked: bool) -> void:
	t_value = clampf((energy - 1) / 12.0, 0.0, 1.0)
	t_danger = clampf(loss_p / 0.36, 0.0, 1.0)
	t_lock = 1.0 if locked else 0.0

func inject() -> void:
	dissolving = false
	dissolve = 0.0
	appear = 0.0
	t_appear = 1.0
	value = 0.0
	mat.set_shader_parameter("seed", randf() * 10.0)

func kick(strength := 1.0) -> void:
	pulse = minf(1.0, pulse + 0.85 * strength)
	shake = maxf(shake, 0.6 * strength)

func lose() -> void:
	dissolving = true
	dissolve = 0.0
	shake = 1.6

func empty() -> void:
	t_appear = 0.0

func _process(dt: float) -> void:
	var r := Ink.spring(value, _vv, t_value, 9.0, dt); value = r[0]; _vv = r[1]
	r = Ink.spring(danger, _vd, t_danger, 7.0, dt); danger = r[0]; _vd = r[1]
	r = Ink.spring(lockf, _vl, t_lock, 10.0, dt); lockf = r[0]; _vl = r[1]
	r = Ink.spring(appear, _va, t_appear, 7.5, dt); appear = r[0]; _va = r[1]
	pulse = maxf(0.0, pulse - dt * 3.2)
	shake = maxf(0.0, shake - dt * 4.0)
	if dissolving:
		dissolve = minf(1.0, dissolve + dt * 1.1)
	# 舱体微震（危险越高越抖）
	var jit := shake * 3.0 + danger * danger * 1.2
	beam_rect.position = -Geo.CH_SIZE * 0.5 + Vector2(randf_range(-jit, jit), randf_range(-jit, jit)) * 0.5
	var bc := Pal.ramp(value)
	mat.set_shader_parameter("beam_col", bc)
	mat.set_shader_parameter("value", value)
	mat.set_shader_parameter("danger", danger)
	mat.set_shader_parameter("lockf", lockf)
	mat.set_shader_parameter("pulse", pulse)
	mat.set_shader_parameter("dissolve", dissolve)
	mat.set_shader_parameter("appear", clampf(appear, 0.0, 1.2))
	var want := int(round(value * 6.0 * clampf(appear, 0.0, 1.0)))
	if lockf > 0.5:
		want = 6
	lit = want
	flick += dt
	frame.queue_redraw()
