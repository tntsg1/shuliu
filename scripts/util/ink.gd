class_name Ink
## 绘制辅助：手绘墨线（亮色图纸风轻微抖动）、弹簧阻尼、文字

## 临界阻尼弹簧：返回 [新值, 新速度]。omega 越大越快，丝滑无过冲
static func spring(x: float, v: float, target: float, omega: float, dt: float) -> Array:
	var f := 1.0 + 2.0 * dt * omega
	var oo := omega * omega
	var hoo := dt * oo
	var hhoo := dt * hoo
	var det := 1.0 / (f + hhoo)
	var nx := (f * x + dt * v + hhoo * target) * det
	var nv := (v + hoo * (target - x)) * det
	return [nx, nv]

static func spring2(x: Vector2, v: Vector2, target: Vector2, omega: float, dt: float) -> Array:
	var a := spring(x.x, v.x, target.x, omega, dt)
	var b := spring(x.y, v.y, target.y, omega, dt)
	return [Vector2(a[0], b[0]), Vector2(a[1], b[1])]

static func ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)

static func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)

static func ease_in_out(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _h(i: int, s: int) -> float:
	var x := sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453
	return x - floor(x) - 0.5

## 沿折线细分并加入稳定的手绘抖动（种子固定 → 不闪烁）
static func wobble(pts: PackedVector2Array, seed: int, closed := true, step := 26.0) -> PackedVector2Array:
	var j := Pal.f("line_jitter")
	var out := PackedVector2Array()
	var n := pts.size()
	var segs := n if closed else n - 1
	var idx := 0
	for i in segs:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var cnt := maxi(1, int(a.distance_to(b) / step))
		for k in cnt:
			var p := a.lerp(b, float(k) / cnt)
			out.append(p + Vector2(_h(idx, seed), _h(idx + 777, seed)) * j * 2.0)
			idx += 1
	if closed:
		out.append(out[0])
	else:
		out.append(pts[n - 1])
	return out

static func rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])

## 墨线矩形：填充 + 抖动描边
static func box(ci: CanvasItem, r: Rect2, fill: Color, line: Color, width := 1.6, seed := 0) -> void:
	ci.draw_rect(r, fill)
	if line.a > 0.0:
		ci.draw_polyline(wobble(rect_pts(r), seed + int(r.position.x * 7 + r.position.y * 13)), line, width, true)

static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, line: Color, width := 1.6, seed := 0) -> void:
	ci.draw_colored_polygon(pts, fill)
	if line.a > 0.0:
		ci.draw_polyline(wobble(pts, seed), line, width, true)

static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width := 1.4, seed := 0) -> void:
	ci.draw_polyline(wobble(PackedVector2Array([a, b]), seed, false), col, width, true)

## 铆钉
static func rivet(ci: CanvasItem, p: Vector2, r := 2.6) -> void:
	ci.draw_circle(p, r, Pal.equip_line().lerp(Pal.c("equip"), 0.45))
	ci.draw_circle(p + Vector2(-0.7, -0.7), r * 0.45, Pal.c("paper").lerp(Pal.c("equip"), 0.3))

# —— 文字排版缓存 ——
# Godot 每个字体只缓存很少几条排好版的字；我们一帧画的不同文字远超这个数，
# 缓存来回挤掉 → 每帧把所有字重排一遍（新字 0.13 ms/条，排好的 0.002 ms/条）。这里自己缓存。
static var _lines := {}
static var _paras := {}

static func _line(fnt: Font, s: String, size: int) -> TextLine:
	var key := [fnt.get_instance_id(), size, s]
	var tl: TextLine = _lines.get(key)
	if tl == null:
		if _lines.size() > 4000:
			_lines.clear()
		tl = TextLine.new()
		tl.add_string(s, fnt, size)
		_lines[key] = tl
	return tl

static func _para(fnt: Font, s: String, size: int, width: float, max_lines: int) -> TextParagraph:
	var key := [fnt.get_instance_id(), size, s, width, max_lines]
	var tp: TextParagraph = _paras.get(key)
	if tp == null:
		if _paras.size() > 600:
			_paras.clear()
		tp = TextParagraph.new()
		tp.add_string(s, fnt, size)
		tp.width = width
		tp.max_lines_visible = max_lines
		_paras[key] = tp
	return tp

## 量字：等同 font.get_string_size(s, LEFT, -1, size)
static func size(fnt: Font, s: String, sz: int) -> Vector2:
	return _line(fnt, s, sz).get_size()

static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, font: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	if s == "" or col.a <= 0.0:
		return
	var fnt: Font = font if font != null else Pal.font
	var tl := _line(fnt, s, size)
	var w := tl.get_size().x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		pos.x += (width - w) * 0.5 if width >= 0.0 else -w * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		pos.x += (width - w) if width >= 0.0 else -w
	tl.draw(ci.get_canvas_item(), Vector2(pos.x, pos.y - tl.get_line_ascent()), col)

## 多行：等同 draw_multiline_string(font, pos, s, LEFT, width, size, max_lines, col)（pos 是首行基线）
static func para(ci: CanvasItem, fnt: Font, pos: Vector2, s: String, width: float, sz: int, max_lines: int, col: Color) -> void:
	if s == "" or col.a <= 0.0:
		return
	var tp := _para(fnt, s, sz, width, max_lines)
	tp.draw(ci.get_canvas_item(), Vector2(pos.x, pos.y - tp.get_line_ascent(0)), col)

static func para_size(fnt: Font, s: String, width: float, sz: int, max_lines := -1) -> Vector2:
	return _para(fnt, s, sz, width, max_lines).get_size()

## 贴纸标签（白底、墨线框、编号）
static func sticker(ci: CanvasItem, s: String, center: Vector2, rot := 0.0, size := 13, bg := Color.TRANSPARENT) -> void:
	var fnt: Font = Pal.mono
	var w := Ink.size(fnt, s, size).x + 12.0
	var h := size + 8.0
	ci.draw_set_transform(center, rot)
	var b := bg if bg.a > 0.0 else Pal.c("paper")
	ci.draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), b)
	ci.draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Pal.equip_line(), false, 1.0)
	Ink.text(ci, s, Vector2(-w * 0.5 + 6, h * 0.5 - 6), size, Pal.equip_line(), fnt)
	ci.draw_set_transform(Vector2.ZERO)
