extends Node
## 主题与字体（自动加载 Pal）。亮色=工程图纸风，暗色=七十年代实验室风（DECISIONS Q24/Q27）

signal changed

var dark := false
var font: SystemFont
var bold: SystemFont
var mono: SystemFont
var hand: SystemFont

const PAPER := {
	"bg": "efe8d8", "office": "e2d7c0", "lamp": "e8b45a", "slab": "cfc3a8", "storage": "ddd2b8",
	"wall0": "ece4d2", "wall1": "efe8d8", "wall2": "e9e0cc", "panel_line": "c9bea6",
	"ink": "2b2a28", "ink2": "7a7264", "line": "b9ae98", "paper": "f7f2e6", "paper2": "ebe2cf",
	"equip": "d8ccb2", "equip_dark": "c4b79a", "pipe": "cfc3a8",
	"dip_a": "3a5fa8", "dip_b": "2f4f8e", "quad_a": "c2563f", "quad_b": "a8442f",
	"det0": "d9cbe8", "det1": "c4b0dc", "det2": "ae96cf", "det3": "987dc2", "det4": "8264b5",
	"term": "e9cf8a", "red": "c2412d", "orange": "d9822b", "gold": "c9971a", "lock": "6a4fb0", "green": "4a7a5a", "blue": "2f5d9e",
	"inner0": "f7f2e6", "inner1": "e3d8c2", "grid": "d6cbb4", "screen": "1d1f26",
	"ramp0": "3a4fa0", "ramp1": "2f7fa8", "ramp2": "2f9a8a", "ramp3": "6a9f45", "ramp4": "c9971a",
	"coat": "f6f3ec", "skin": "e8c9a8", "hair": "3a3430", "shadow": "000000",
	"text": "2b2a28", "text2": "7a7264",
	"grain": 0.10, "line_jitter": 0.7,
}
const LAB70 := {
	"bg": "1f2724", "office": "2a231c", "lamp": "e8b04a", "slab": "4a3b2e", "storage": "1d1f1a",
	"wall0": "2e3a36", "wall1": "2b3632", "wall2": "2e3a36", "panel_line": "3e4a45",
	"ink": "efe6cf", "ink2": "a59f88", "line": "4a5650", "paper": "e9dfc6", "paper2": "d9cdb0",
	"equip": "c9b99a", "equip_dark": "a8987a", "pipe": "9a8e76",
	"dip_a": "4f6fa0", "dip_b": "3e5a88", "quad_a": "c4573a", "quad_b": "a8452c",
	"det0": "6a5a8a", "det1": "7a6a9a", "det2": "8a7aa8", "det3": "9a8ab6", "det4": "aa9ac4",
	"term": "d9a62e", "red": "c4473a", "orange": "d8792e", "gold": "d9a62e", "lock": "9a7cc4", "green": "6f9a5a", "blue": "4f7fa0",
	"inner0": "2a3632", "inner1": "1a221f", "grid": "34423d", "screen": "14181a",
	"ramp0": "4f7fa0", "ramp1": "3f8f8a", "ramp2": "8fb06a", "ramp3": "d9c27a", "ramp4": "f1e6c8",
	"coat": "efe8d6", "skin": "d9b896", "hair": "2a2420", "shadow": "000000",
	"text": "2a2620", "text2": "6e6656",
	"grain": 0.16, "line_jitter": 0.0,
}
## 设备轮廓线在暗色下用深色（米白设备 + 深描边）
const LAB70_EQUIP_LINE := "2a2620"

func _ready() -> void:
	font = _sys(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "SimHei"], 400)
	bold = _sys(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "SimHei"], 700)
	mono = _sys(["Consolas", "Cascadia Mono", "Courier New"], 400)
	hand = _sys(["KaiTi", "STKaiti", "Kaiti SC", "SimKai"], 400)

func _sys(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	f.oversampling = 1.0
	return f

func _tab() -> Dictionary:
	return LAB70 if dark else PAPER

func c(key: String) -> Color:
	return Color("#" + _tab()[key])

func f(key: String) -> float:
	return _tab()[key]

## 设备描边：亮色用墨线，暗色用深棕
func equip_line() -> Color:
	return Color("#" + LAB70_EQUIP_LINE) if dark else c("ink")

## 能级色阶 v∈[0,1]
func ramp(v: float) -> Color:
	v = clampf(v, 0.0, 1.0) * 4.0
	var i := mini(3, int(floor(v)))
	return c("ramp%d" % i).lerp(c("ramp%d" % (i + 1)), v - i)

## 六种结果的颜色
func outcome(k: int) -> Color:
	match k:
		Odds.SUPER: return c("gold")
		Odds.PERFECT: return c("ramp4") if dark else c("blue")
		Odds.SUCCESS: return c("ramp2")
		Odds.STABLE: return c("ink2")
		Odds.DETUNE: return c("orange")
		_: return c("red")

func set_dark(on: bool) -> void:
	if on == dark:
		return
	dark = on
	changed.emit()
