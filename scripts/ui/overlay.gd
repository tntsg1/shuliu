extends Control
## 屏幕层：顶部纸胶带状态条、结果印章、实验结果卡、开花计数、结局卡、提示

var main: Node
var t := 0.0
# 印章
var st_text := ""
var st_col := Color.RED
var st_t := -1.0
var st_big := false
var st_rot := 0.0
# 结果卡
var card := {}          # {title, value, sub, lines:[], keys}
var card_v := 0.0
var _vc := 0.0
var card_t := 0.0
# 开花计数
var bloom_v := -1.0
var bloom_target := 0
var bloom_disp := 0.0
var _vb := 0.0
var strip_v := 1.0
var _vst := 0.0
var strip_t := 1.0
var toast := ""
var toast_t := 0.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	Pal.changed.connect(queue_redraw)

func stamp(s: String, col: Color, big := false) -> void:
	st_text = s
	st_col = col
	st_t = 0.0
	st_big = big
	st_rot = randf_range(-0.14, 0.08)

func show_card(c: Dictionary) -> void:
	card = c
	card_t = 1.0

func hide_card() -> void:
	card_t = 0.0

func show_bloom(v: int) -> void:
	bloom_target = v
	bloom_disp = 0.0
	_vb = 0.0
	bloom_v = 0.0

func hide_bloom() -> void:
	bloom_v = -1.0

func say(s: String) -> void:
	toast = s
	toast_t = 2.2

func _process(dt: float) -> void:
	t += dt
	if st_t >= 0.0:
		st_t += dt
		if not st_big and st_t > 0.9:
			st_t = -1.0
	var r := Ink.spring(card_v, _vc, card_t, 9.0, dt); card_v = r[0]; _vc = r[1]
	r = Ink.spring(strip_v, _vst, strip_t, 8.0, dt); strip_v = r[0]; _vst = r[1]
	if bloom_v >= 0.0:
		bloom_v += dt
		r = Ink.spring(bloom_disp, _vb, float(bloom_target), 4.2, dt); bloom_disp = r[0]; _vb = r[1]
	toast_t = maxf(0.0, toast_t - dt)
	queue_redraw()

func _draw() -> void:
	if main == null or main.run == null:
		return
	var vp := get_viewport_rect().size
	_strip(vp)
	if bloom_v >= 0.0:
		_bloom(vp)
	if st_t >= 0.0:
		_stamp(vp)
	if card_v > 0.01:
		_card(vp)
	if toast_t > 0.0:
		var a := clampf(toast_t / 0.3, 0.0, 1.0)
		var w := Pal.font.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 40
		var rr := Rect2(vp.x * 0.5 - w * 0.5, 76, w, 40)
		draw_rect(rr, Color(Pal.c("paper"), a))
		draw_rect(rr, Color(Pal.equip_line(), a), false, 1.4)
		Ink.text(self, toast, Vector2(vp.x * 0.5, 102), 18, Color(Pal.c("text"), a), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

## 顶部：一条贴在镜头上的纸胶带
func _strip(vp: Vector2) -> void:
	var run: Run = main.run
	var y := lerpf(vp.y + 60.0, vp.y - 58.0, strip_v)
	var el := Pal.equip_line()
	draw_set_transform(Vector2(30, y), -0.008)
	var w := 860.0
	draw_rect(Rect2(4, 5, w, 42), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(0, 0, w, 42), Pal.c("paper"))
	draw_rect(Rect2(0, 0, w, 42), Color(el, 0.5), false, 1.0)
	draw_rect(Rect2(-8, 8, 34, 26), Color(Pal.c("gold"), 0.45))
	draw_rect(Rect2(w - 26, 8, 34, 26), Color(Pal.c("gold"), 0.45))
	Ink.text(self, "BEAMLINE  束流", Vector2(40, 29), 18, Pal.c("text"), Pal.bold)
	var stg := "全部通过" if run.won() else "考核 %d/%d" % [run.stage + 1, Run.LINES.size()]
	Ink.text(self, stg, Vector2(230, 29), 17, Pal.c("text"))
	Ink.text(self, "累计 %s / %s" % [main.fmt(run.total), main.fmt(run.line())], Vector2(350, 29), 17, Pal.c("text"), Pal.mono)
	Ink.text(self, "剩余实验 %d" % run.experiments_left, Vector2(610, 29), 17, Pal.c("text"))
	Ink.text(self, "F2 切换配色", Vector2(740, 29), 13, Pal.c("text2"))
	draw_set_transform(Vector2.ZERO)

func _stamp(vp: Vector2) -> void:
	var k := minf(1.0, st_t / 0.14)
	var sc := lerpf(1.9, 1.0, Ink.ease_out_back(k))
	var a := 1.0 if st_big else clampf((0.9 - st_t) / 0.3, 0.0, 1.0)
	var c := Vector2(vp.x * 0.5, 210 if not st_big else 330)
	var fs := 34 if not st_big else 72
	draw_set_transform(c, st_rot, Vector2(sc, sc))
	var w := Pal.bold.get_string_size(st_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 48
	var h := fs + 34.0
	var col := Color(st_col, a * 0.92)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(Pal.c("paper"), a * 0.55))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), col, false, 4.0)
	draw_rect(Rect2(-w * 0.5 + 7, -h * 0.5 + 7, w - 14, h - 14), col, false, 1.6)
	Ink.text(self, st_text, Vector2(0, fs * 0.36), fs, col, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	# 印泥不均：随机白点
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(st_text)
	for i in 26:
		var p := Vector2(rng.randf_range(-w * 0.5, w * 0.5), rng.randf_range(-h * 0.5, h * 0.5))
		draw_circle(p, rng.randf_range(0.8, 2.4), Color(Pal.c("paper"), a * 0.7))
	draw_set_transform(Vector2.ZERO)

func _bloom(vp: Vector2) -> void:
	var a := clampf(bloom_v / 0.3, 0.0, 1.0)
	var y := vp.y - 150
	var bw := 520.0
	draw_rect(Rect2(vp.x * 0.5 - bw * 0.5 + 6, y - 74, bw, 132), Color(0, 0, 0, 0.15 * a))
	draw_rect(Rect2(vp.x * 0.5 - bw * 0.5, y - 80, bw, 132), Color(Pal.c("paper"), a))
	draw_rect(Rect2(vp.x * 0.5 - bw * 0.5, y - 80, bw, 132), Color(Pal.equip_line(), a), false, 1.6)
	var s: String = main.fmt(int(round(bloom_disp)))
	Ink.text(self, "+" + s + " RP", Vector2(vp.x * 0.5 + 3, y + 3), 64, Color(0, 0, 0, 0.25 * a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "+" + s + " RP", Vector2(vp.x * 0.5, y), 64, Color(Pal.c("text"), a), Pal.mono, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, "探测屏 · 事件图谱", Vector2(vp.x * 0.5, y + 40), 18, Color(Pal.c("text2"), a), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)

func _card(vp: Vector2) -> void:
	var el := Pal.equip_line()
	var w := 640.0
	var h: float = 300.0 + 30.0 * card.get("lines", []).size()
	var x := vp.x * 0.5 - w * 0.5
	var y := lerpf(vp.y + 40, vp.y * 0.5 - h * 0.5 - 60, card_v)
	draw_set_transform(Vector2(x + w * 0.5, y + h * 0.5), 0.01 * (1.0 - card_v) + 0.006)
	var o := Vector2(-w * 0.5, -h * 0.5)
	draw_rect(Rect2(o + Vector2(8, 10), Vector2(w, h)), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(o, Vector2(w, h)), Pal.c("paper"))
	draw_rect(Rect2(o, Vector2(w, h)), el, false, 2.0)
	draw_rect(Rect2(o + Vector2(10, 10), Vector2(w - 20, h - 20)), Color(el, 0.3), false, 1.0)
	# 打孔
	for i in 3:
		draw_circle(o + Vector2(28, 60 + i * 70), 7.0, Pal.c("paper2"))
		draw_arc(o + Vector2(28, 60 + i * 70), 7.0, 0, TAU, 16, Color(el, 0.5), 1.0, true)
	Ink.text(self, card.get("title", ""), o + Vector2(64, 62), 30, card.get("title_col", Pal.c("text")), Pal.bold)
	Ink.text(self, card.get("value", ""), o + Vector2(64, 138), 56, Pal.c("text"), Pal.mono)
	Ink.text(self, card.get("sub", ""), o + Vector2(64, 176), 18, Pal.c("text2"))
	var ly := 220.0
	for l in card.get("lines", []):
		Ink.text(self, l, o + Vector2(64, ly), 18, Pal.c("blue"), Pal.hand)
		ly += 30.0
	draw_line(o + Vector2(40, h - 62), o + Vector2(w - 40, h - 62), Color(el, 0.4), 1.0)
	Ink.text(self, card.get("keys", ""), o + Vector2(64, h - 30), 18, Pal.c("text"))
	draw_set_transform(Vector2.ZERO)
