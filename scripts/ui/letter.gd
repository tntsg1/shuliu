extends Control
## 开场信（DECISIONS Q62）：第一次开局在剖面图之后递上来；之后点墙上的“经费处理决定”可以重读。
## 一行一行显出来；按任意键/点击：先把剩下的字一次显完，再按一次收下（纸往下滑走）。
## 文案是用户定稿（design/开场与教程文案.md），不改写。

signal closed

const TITLE := "关于第七实验站后续经费的通知"
const TO := "第七实验站负责人："
## 正文（用户定稿，design/开场与教程文案.md）；[文字, 缩进, 是否红字加粗, 段前空]
const BODY := [
	["贵站已经连续三个财年没有提交合格的研究成果。经费处替你们解释了三年，校董会今年不打算再听一次了。", 0, false, 0],
	["另外，隔壁的星汇数据公司已经开价收购主环隧道，打算改建成数据中心。对方给出的价格还不错。", 0, false, 10],
	["经过讨论，学校决定再给贵站八次评审机会。", 0, true, 10],
	["具体安排如下：", 0, false, 10],
	["1. 每次评审前，经费处会发放三瓶束流气瓶。怎么安排实验，由贵站自行决定。", 24, false, 4],
	["2. 实验获得的科研点，需要在评审前交到审核台。交够当轮要求的数量，下轮经费照常发放。", 24, false, 4],
	["3. 只要有一次没交够，学校当天就会接受星汇数据公司的报价。", 24, true, 4],
	["希望贵站珍惜这最后几次机会。", 0, false, 10],
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
	return 0.55 + i * 0.5

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
	var w := 1080.0
	var h := 740.0
	var c := Vector2(vp.x * 0.5, lerpf(vp.y + h * 0.6, vp.y * 0.5, inn) + go * (vp.y * 0.5 + h))
	draw_set_transform(c, -0.012 + go * 0.15)
	var o := Vector2(-w * 0.5, -h * 0.5)
	draw_rect(Rect2(o + Vector2(8, 10), Vector2(w, h)), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(o, Vector2(w, h)), Color("#f8f3e7"))
	# 信纸折过三折：两道很淡的折痕（上半亮、下半暗）
	for k in [1.0, 2.0]:
		var fy: float = h * k / 3.0
		draw_rect(Rect2(o + Vector2(0, fy - 1), Vector2(w, 1)), Color(1, 1, 1, 0.5))
		draw_rect(Rect2(o + Vector2(0, fy), Vector2(w, 1)), Color(0, 0, 0, 0.05))
	Ink.frame(self, Rect2(o, Vector2(w, h)), Color(ink, 0.25), Ink.W3)
	# 左上角回形针
	var cp := o + Vector2(64, -14)
	var clip := PackedVector2Array([cp + Vector2(0, 56), cp + Vector2(0, 6), cp + Vector2(7, 0), cp + Vector2(14, 6), cp + Vector2(14, 46), cp + Vector2(9, 50), cp + Vector2(5, 46), cp + Vector2(5, 14)])
	Ink.pl(self, clip, Color(0, 0, 0, 0.15), 3.2)
	Ink.pl(self, clip, Color("#8a8a86"), 2.0)
	# 信笺抬头：两道红线
	draw_rect(Rect2(o + Vector2(0, 96), Vector2(w, 3)), red)
	draw_rect(Rect2(o + Vector2(0, 102), Vector2(w, 1)), red)
	Ink.text(self, "第 七 实 验 站 所 属 大 学 · 校 长 办 公 室", o + Vector2(w * 0.5, 44), 16, Color(red, 0.9), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, TITLE, o + Vector2(w * 0.5, 82), 26, ink, Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	Ink.text(self, TO, o + Vector2(70, 150), 20, ink, Pal.font)
	var y := 196.0
	var tw := w - 200.0
	for i in BODY.size():
		var pr: Array = BODY[i]
		y += float(pr[3])
		var a := 1.0 if reveal_all else clampf((t - _line_t(i)) / 0.3, 0.0, 1.0)
		var important: bool = pr[2]
		var fnt: Font = Pal.bold if important else Pal.font
		var ind := 108.0 + float(pr[1])
		Ink.para(self, fnt, o + Vector2(ind - (1.0 - a) * 8.0, y), pr[0], tw - float(pr[1]), 20, -1, Color(red if important else ink, a))
		y += Ink.para_size(fnt, pr[0], tw - float(pr[1]), 20).y + 8.0
	# 落款 + 红章（最后盖下来）
	var sa := 1.0 if reveal_all else clampf((t - _line_t(BODY.size())) / 0.25, 0.0, 1.0)
	Ink.text(self, SIGN, o + Vector2(w - 90, h - 96), 20, Color(ink, sa), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)
	Ink.text(self, "一九七四年十月", o + Vector2(w - 90, h - 62), 16, Color(ink, 0.7 * sa), Pal.font, HORIZONTAL_ALIGNMENT_RIGHT)
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
