extends Node2D
## 观测舱里的束流形态：每按一次长一点（能级连续成长），跨过 E7/E13/传说门槛当场蜕变（弹出 + 小章）。
## 失谐掉回门槛以下不退化，只“受损”：歪斜、抖动，涨回来就修好。只读画面上已揭晓的能级（main.shown_e），不剧透。

var main: Node
var chamber: Node2D
var art := FormArt.new()
var t := 0.0
var g := 1.0            # 平滑后的能级（成长）
var _vg := 0.0
var peak := 1           # 画面上到过的最高能级
var stage_key := ""     # 当前形态（路线 + 档 / 传说），变了就播蜕变
var grow := 1.0
var _vgrow := 0.0
var dmg := 0.0
var _vdmg := 0.0
var morph_t := -1.0     # 蜕变动画（秒）
var morph_label := ""
var traits: Array = []
var alpha := 0.0
var info := {}          # 当前形态（给成果卡和测试看）
var last_st := {}       # 最近一帧画的状态（碎裂时接着用）
var shatter_t := -1.0   # 丢失碎裂（秒）
var shards: Array = []  # 束芯碎片 {p, v, rot, w, pts, c}
var cracks: Array = []  # 裂纹折线

func reset() -> void:
	shatter_t = -1.0
	peak = 1
	g = 1.0
	_vg = 0.0
	stage_key = ""
	traits = []
	morph_t = -1.0
	dmg = 0.0

func _process(dt: float) -> void:
	t += dt
	var b: Beam = main.run.beam if main != null and main.run != null else null
	var tgt_a := 0.0
	if b != null:
		tgt_a = clampf(chamber.appear, 0.0, 1.0)
		var e: int = main.shown_e
		peak = maxi(peak, e)
		var r := Ink.spring(g, _vg, float(e), 6.0, dt); g = r[0]; _vg = r[1]
		# 称号只在揭晓完（回到控制台）后更新，避免剧透
		if main.mode == main.M.CONSOLE:
			traits = Forms.traits_of(b)
		var items: Array = main.run.relics + main.run.devices
		info = Forms.describe(b.route, e, peak, traits, Forms.legend_of(peak, items))
		info["omen"] = Forms.omen(e, peak, items)
		var key: String = info.id
		if key != stage_key:
			var first := stage_key == ""
			stage_key = key
			if not first and (info.tier > 0 or info.legend != ""):
				_morph()
			elif not first:
				grow = 0.6
		var rd := Ink.spring(dmg, _vdmg, 1.0 if info.damaged else 0.0, 5.0, dt); dmg = rd[0]; _vdmg = rd[1]
	var ra := Ink.spring(grow, _vgrow, 1.0, 9.0, dt); grow = ra[0]; _vgrow = ra[1]
	alpha = move_toward(alpha, tgt_a, dt * 4.0)
	if shatter_t >= 0.0:
		shatter_t += dt
		for sh in (shards if shatter_t > 0.25 else []):
			sh.v.y += 260.0 * dt
			sh.v *= 1.0 - 0.8 * dt
			sh.p += sh.v * dt
			sh.rot += sh.w * dt
		if shatter_t > 2.2:
			shatter_t = -1.0
			shards.clear()
	if morph_t >= 0.0:
		morph_t += dt
		if morph_t > 1.6:
			morph_t = -1.0
	queue_redraw()

func _morph() -> void:
	morph_t = 0.0
	grow = 0.25
	_vgrow = 0.0
	morph_label = "传说" if info.legend != "" else Forms.TIER_NAMES[info.tier]
	chamber.kick(1.6, Pal.c("gold") if info.legend != "" else Pal.ramp(clampf((g - 1.0) / 12.0, 0.0, 1.0)))
	Sfx.play("perfect", -6.0, 0.8)
	Sfx.play("paper", -6.0, 0.9)
	if main != null:
		main.hitstop(0.05)

func _draw() -> void:
	if shatter_t >= 0.0:
		_draw_shatter()
		return
	if info.is_empty() or alpha < 0.01 or main.run.beam == null:
		return
	var v: float = chamber.value
	var st := info.duplicate()
	st["g"] = g
	st["t"] = t
	st["dmg"] = dmg
	st["grow"] = grow
	st["col"] = Pal.ramp(v)
	st["core_r"] = (9.0 + v * 22.0) * clampf(chamber.appear, 0.0, 1.2)
	st["pulse"] = chamber.pulse
	modulate.a = alpha
	art.draw(self, Vector2.ZERO, 1.0, st)
	last_st = st
	if morph_t >= 0.0:
		_morph_fx()

## 蜕变：一圈墨线波纹扩散 + 舱顶盖一个小章
func _morph_fx() -> void:
	var k := morph_t
	var e := Ink.ease_out_cubic(clampf(k / 0.6, 0.0, 1.0))
	var a := 1.0 - clampf(k / 0.8, 0.0, 1.0)
	if a > 0.0:
		var pts := PackedVector2Array()
		for i in 49:
			var an := i / 48.0 * TAU
			pts.append(Vector2(cos(an) * 270.0, sin(an) * 145.0) * e)
		draw_polyline(pts, Color(Pal.c("ink"), a), 3.0, true)
	var sa := clampf(k / 0.12, 0.0, 1.0) * clampf((1.6 - k) / 0.3, 0.0, 1.0)
	var sc := lerpf(2.2, 1.0, Ink.ease_out_back(clampf(k / 0.18, 0.0, 1.0)))
	var red := Pal.c("gold").darkened(0.2) if info.legend != "" else Pal.c("red")
	draw_set_transform(Vector2(190, -112), -0.18, Vector2(sc, sc))
	var w := Pal.bold.get_string_size(morph_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 28.0
	draw_rect(Rect2(-w * 0.5, -22, w, 40), Color(Pal.c("paper"), 0.9 * sa))
	draw_rect(Rect2(-w * 0.5, -22, w, 40), Color(red, sa), false, 3.0)
	Ink.text(self, morph_label, Vector2(0, 8), 26, Color(red, sa), Pal.bold, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)

## 丢失：先让玩家看清“它碎了”——形态被裂纹劈开、歪斜抖散、慢慢褪掉；束芯崩成切面碎片往外飞再落下
func shatter() -> void:
	if last_st.is_empty():
		return
	shatter_t = 0.0
	shards.clear()
	cracks.clear()
	var r: float = art.gem_radius(last_st.g, last_st.get("omen", 0.0))
	var col: Color = last_st.col
	var n := 10 + int(r / 4.0)
	for i in n:
		var a0 := i * TAU / n + randf_range(-0.1, 0.1)
		var a1 := a0 + TAU / n
		var pts := PackedVector2Array([Vector2.ZERO, Vector2(cos(a0), sin(a0)) * r, Vector2(cos(a1), sin(a1)) * r * randf_range(0.8, 1.1)])
		var mid := (pts[1] + pts[2]) / 3.0
		for k in 3:
			pts[k] -= mid
		var dir := mid.normalized()
		shards.append({"p": mid, "v": dir * randf_range(160, 420) + Vector2(0, -randf_range(60, 200)), "rot": 0.0,
			"w": randf_range(-9, 9), "pts": pts, "c": col.darkened(randf_range(0.0, 0.35)).lerp(Pal.c("paper"), randf_range(0.0, 0.4))})
	for i in 7:
		var a := i * TAU / 7.0 + randf_range(-0.3, 0.3)
		var pts := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		for k in 6:
			p += Vector2.from_angle(a + randf_range(-0.5, 0.5)) * randf_range(28, 46)
			pts.append(p * Vector2(1.0, 0.6))
		cracks.append(pts)

func _draw_shatter() -> void:
	var k := shatter_t
	# 1) 形态：先定格 0.25 秒让人看清，再被劈开、抖散、褪掉
	var hold := clampf(k / 0.25, 0.0, 1.0)
	var go := clampf((k - 0.25) / 1.3, 0.0, 1.0)
	if go < 1.0:
		var st := last_st.duplicate()
		st["dmg"] = 0.6 + 2.4 * go
		st["t"] = last_st.t + k * 0.2
		st["traits"] = []
		st["no_gem"] = true
		modulate.a = 1.0 - go
		art.draw(self, Vector2(0, 14.0 * go * go), 1.0 + 0.08 * go, st)
		modulate.a = 1.0
		# 2) 裂纹：从中心一笔笔劈出去
		var ck := clampf(k / 0.22, 0.0, 1.0)
		for c in cracks:
			var m := int(c.size() * ck)
			if m >= 2:
				var sub: PackedVector2Array = c.slice(0, m)
				draw_polyline(sub, Color(Pal.c("ink"), 1.0 - go), 3.0, true)
				draw_polyline(sub, Color(Pal.c("paper"), 0.8 * (1.0 - go)), 1.0, true)
	# 3) 束芯碎片：定格后才飞
	var fly := hold >= 1.0
	for sh in shards:
		var p: Vector2 = sh.p
		var a := 1.0 - clampf((k - 1.3) / 0.9, 0.0, 1.0)
		var pts := PackedVector2Array()
		for q in sh.pts:
			pts.append(p + (q as Vector2).rotated(sh.rot if fly else 0.0))
		draw_colored_polygon(pts, Color(sh.c, a))
		pts.append(pts[0])
		draw_polyline(pts, Color(Pal.c("ink"), a), 1.4, true)
