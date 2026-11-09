extends Control
## 开场信（DECISIONS Q62）：第一次开局在剖面图之后递上来；之后点墙上的“经费处理决定”可以重读。
## 一行一行显出来；按任意键/点击：先把剩下的字一次显完，再按一次收下（纸往下滑走）。
## 文案是草稿，等用户改定（design/开场与教程文案.md）。

signal closed

const TITLE := "关于第七实验站的经费处理决定"
const TO := "第七实验站负责人："
const BODY := [
	"贵站已连续三个财年没有拿出像样的成果。",
	"隔壁的星汇数据公司出价收购主环隧道，打算改建成数据中心。",
	"校董会决定，再给贵站最后 8 次评审：",
	"每次评审前，经费处配给 3 瓶束流气瓶。用它们做实验、攒科研点，",
	"在审核台交够了，就续拨经费；",
	"有一次没交够，第七实验站即日出售。",
]
const SIGN := "校长办公室"

var open := false
var t := 0.0
var out_t := -1.0
var reveal_all := false

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

func show_letter() -> void:
	open = true
	visible = true
	t = 0.0
	out_t = -1.0
	reveal_all = false
	Sfx.play("paper", -4.0, 0.85)

func _line_t(i: int) -> float:
	return 0.55 + i * 0.42

func _all_shown() -> bool:
	return reveal_all or t > _line_t(BODY.size()) + 0.3

## 任意键 / 点击
func press() -> void:
	if not open or out_t >= 0.0 or t < 0.25:
		return
	if not _all_shown():
		reveal_all = true
		return
	out_t = 0.0
	Sfx.play("paper", -6.0, 1.15)

func _process(dt: float) -> void:
	if not open:
		return
	t += dt
	if out_t >= 0.0:
		out_t += dt
		if out_t > 0.5:
			open = false
			visible = false
			closed.emit()
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	var ink := Color("#2b2a28")
	var red := Color("#c2412d")
	var inn := Ink.ease_out_cubic(clampf(t / 0.45, 0.0, 1.0))
	var go := Ink.ease_in_out(clampf(out_t / 0.5, 0.0, 1.0)) if out_t >= 0.0 else 0.0
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.62 * inn * (1.0 - go)))
	var w := 980.0
	var h := 600.0
	var c := Vector2(vp.x * 0.5, lerpf(vp.y + h * 0.6, vp.y * 0.5, inn) + go * (vp.y * 0.5 + h))
	draw_set_transform(c, -0.012 + go * 0.15)
	var o := Vector2(-w * 0.5, -h * 0.5)
	draw_rect(Rect2(o + Vector2(10, 14), Vector2(w, h)), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(o, Vector2(w, h)), Color("#f8f3e7"))
	# 信笺抬头：两道红线
	draw_rect(Rect2(o + Vector2(0, 96), Vector2(w, 3)), red)
	draw_rect(Rect2(o + Vector2(0, 102), Vector2(w, 1)), red)
	Ink.text(self, "第 七 实 验 站 所 属 大 学 · 校 长 办 公 室", o + Vector2(w * 0.5, 44), 16, Color(red, 0.9), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, TITLE, o + Vector2(w * 0.5, 82), 26, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, TO, o + Vector2(70, 148), 20, ink, Pal.font)
	var y := 192.0
	for i in BODY.size():
		var a := 1.0 if reveal_all else clampf((t - _line_t(i)) / 0.3, 0.0, 1.0)
		var important := i == 2 or i == 5
		Ink.text(self, BODY[i], o + Vector2(108 - (1.0 - a) * 8.0, y), 20, Color(red if important else ink, a), Pal.bold if important else Pal.font)
		y += 44.0
	# 落款 + 红章（最后盖下来）
	var sa := 1.0 if reveal_all else clampf((t - _line_t(BODY.size())) / 0.25, 0.0, 1.0)
	Ink.text(self, SIGN, o + Vector2(w - 90, h - 92), 20, Color(ink, sa), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)
	Ink.text(self, "一九七四年十月", o + Vector2(w - 90, h - 60), 16, Color(ink, 0.7 * sa), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)
	if sa > 0.0:
		var sc := o + Vector2(w - 290, h - 80)
		var ss := lerpf(1.6, 1.0, Ink.ease_out_cubic(sa))
		draw_set_transform(c + (sc).rotated(-0.012), -0.2, Vector2(ss, ss))
		draw_arc(Vector2.ZERO, 46.0, 0, TAU, 40, Color(red, 0.75 * sa), 3.0, true)
		draw_arc(Vector2.ZERO, 40.0, 0, TAU, 40, Color(red, 0.5 * sa), 1.2, true)
		Ink.text(self, "★", Vector2(0, -8), 18, Color(red, 0.8 * sa), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.text(self, "校长办公室", Vector2(0, 20), 13, Color(red, 0.8 * sa), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform(c, -0.012 + go * 0.15)
	# 底部提示
	var ha := (0.6 + 0.4 * sin(t * 3.0)) * (1.0 - go)
	Ink.text(self, ("点击 / 任意键  收下这封信" if _all_shown() else "点击 / 任意键  显示全文"), o + Vector2(w * 0.5, h + 44), 16, Color("#f8f3e7", ha), Pal.font, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
