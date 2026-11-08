extends Node2D
## 实体化构筑：设备装在束流线上（带外壳的模块），饰品摆在观测舱下方的“护身符架”上，好椅子真的放在控制台旁

const DEVICE_X := [452.0, 658.0, 788.0, 1425.0, 1555.0, 375.0]
const SHELF := Rect2(1040, 694, 156, 96)

var main: Node
var bounce := {}        # id -> 0..1
var t := 0.0

func ping(id: String) -> void:
	bounce[id] = 1.0

func _process(dt: float) -> void:
	t += dt
	for k in bounce.keys():
		bounce[k] = maxf(0.0, bounce[k] - dt * 1.6)
	queue_redraw()

func _draw() -> void:
	if main == null or main.run == null:
		return
	var run: Run = main.run
	var el := Pal.equip_line()
	# —— 设备模块：夹在束流管上的外壳 + 图标窗 ——
	for i in run.devices.size():
		var id: String = run.devices[i]
		var x: float = DEVICE_X[i % DEVICE_X.size()]
		var b: float = bounce.get(id, 0.0)
		var y := Geo.BEAMY - sin(b * PI) * 6.0
		var r := Rect2(x - 34, y - 46, 68, 92)
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.12))
		Ink.box(self, r, Pal.c("equip"), el, 2.0, i * 31)
		draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(56, 56)), Pal.c("paper"))
		draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(56, 56)), el, false, 1.2)
		Icons.draw(self, id, r.position + Vector2(34, 34), 50.0)
		# 底部状态灯：触发时变亮
		var lamp := Pal.c("ramp2").lerp(Pal.c("gold"), b) if b > 0.0 else Pal.c("equip_dark")
		draw_rect(Rect2(r.position + Vector2(10, 70), Vector2(48, 10)), lamp)
		draw_rect(Rect2(r.position + Vector2(10, 70), Vector2(48, 10)), el, false, 1.0)
		Ink.rivet(self, r.position + Vector2(5, 86), 2.0)
		Ink.rivet(self, r.position + Vector2(63, 86), 2.0)
		if b > 0.0:
			draw_rect(r.grow(4 + b * 6), Color(Pal.c("gold"), b), false, 3.0)
	# —— 护身符架（舱下两层搁板） ——
	var s := SHELF
	Ink.box(self, Rect2(s.position.x, s.position.y + 42, s.size.x, 6), Pal.c("equip_dark"), el, 1.4, 901)
	Ink.box(self, Rect2(s.position.x, s.end.y - 6, s.size.x, 6), Pal.c("equip_dark"), el, 1.4, 902)
	Ink.box(self, Rect2(s.position.x - 4, s.position.y - 4, 6, s.size.y + 4), Pal.c("equip_dark"), el, 1.2, 903)
	Ink.box(self, Rect2(s.end.x - 2, s.position.y - 4, 6, s.size.y + 4), Pal.c("equip_dark"), el, 1.2, 904)
	Ink.sticker(self, "护身符", Vector2(s.position.x + 34, s.position.y - 12), -0.05, 10)
	var shown := 0
	for id in run.relics:
		if id == "chair":
			continue
		var row := shown / 3
		var col := shown % 3
		var b: float = bounce.get(id, 0.0)
		var p := Vector2(s.position.x + 28 + col * 50, s.position.y + 20 + row * 48 - sin(b * PI) * 12.0)
		Icons.draw(self, id, p, 40.0 + b * 10.0, sin(t * 2.0 + shown) * 0.04 + b * 0.3)
		if run.uses.has(id):
			Ink.text(self, "×%d" % run.uses[id], p + Vector2(10, 18), 10, Pal.c("red"), Pal.bold)
		shown += 1
	# 好椅子：真放在控制台左边
	if run.relics.has("chair"):
		var b: float = bounce.get("chair", 0.0)
		Icons.draw(self, "chair", Vector2(848, Geo.FLOOR - 34 - sin(b * PI) * 8.0), 70.0, -b * 0.2)

## 鼠标悬停：返回该世界坐标下的设备或饰品 id
func item_at(p: Vector2) -> String:
	if main == null or main.run == null:
		return ""
	var run: Run = main.run
	for i in run.devices.size():
		var x: float = DEVICE_X[i % DEVICE_X.size()]
		if Rect2(x - 34, Geo.BEAMY - 46, 68, 92).has_point(p):
			return run.devices[i]
	var shown := 0
	for id in run.relics:
		if id == "chair":
			if Rect2(812, Geo.FLOOR - 72, 72, 72).has_point(p):
				return id
			continue
		var c := Vector2(SHELF.position.x + 28 + (shown % 3) * 50, SHELF.position.y + 20 + (shown / 3) * 48)
		if p.distance_to(c) < 24.0:
			return id
		shown += 1
	return ""
