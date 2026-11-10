extends SceneTree
## 束芯成长 + 橘猫轨迹 + 丢失碎裂 截图对照表

var main: Node
var tiles: Array = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 1500) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func grab(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	# 观测舱在屏幕上的位置：按相机把世界坐标换成屏幕坐标
	var xf: Transform2D = root.get_viewport().get_canvas_transform()
	var c: Vector2 = xf * Geo.CHAMBER
	var half: Vector2 = Geo.CH_SIZE * 0.5 * xf.get_scale() + Vector2(30, 30)
	var reg := Rect2i(Vector2i(c - half), Vector2i(half * 2.0))
	reg = reg.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var sub := img.get_region(reg)
	sub.resize(480, int(480.0 * sub.get_height() / sub.get_width()))
	tiles.append({"img": sub, "label": label})
	print("tile ", label)

## 把束流摆到某个状态：路线饰品、峰值、当前能级、称号
func setup(relics: Array, peak: int, e: int, traits := {}) -> void:
	var run: Run = main.run
	run.relics = relics.duplicate()
	if run.beam == null:
		main._new_beam()
	main.form.reset()
	var b: Beam = run.beam
	b.route = Forms.route_of(relics)
	b.energy = peak
	b.peak = peak
	b.saved = traits.get("saved", false)
	b.synced = traits.get("synced", false)
	b.crowned = traits.get("crowned", false)
	b.lock_left = 0
	main._sync()
	await frames(40)
	if e != peak:
		b.energy = e
		main._sync()
		await frames(40)
	await frames(30)

func _go() -> void:
	await frames(3)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	for e in [1, 3, 5, 7, 10, 13, 15]:
		await setup([], e, e)
		await grab("标准 E%d" % e)
	await setup(["lucky_cat", "plant"], 15, 15)
	await grab("橘猫束流 E15")
	await setup(["note100", "third_draft"], 9, 9)
	await grab("纸鹤 E9")
	await setup(["note100", "third_draft"], 14, 14)
	await grab("论文风暴 E14")
	# 丢失碎裂
	main.run.dev_force = Odds.LOSS
	main.cooldown = 0.0
	main.accelerate()
	main.run.dev_force = -1
	for x in [0.15, 0.45, 0.8, 1.3]:
		await until(func(): return main.form.shatter_t > x)
		await grab("碎裂 %.2fs" % x)
	_sheet("core_sheet", 4)
	quit(0)

func _sheet(name: String, cols: int) -> void:
	var tw: int = tiles[0].img.get_width()
	var th: int = tiles[0].img.get_height() + 34
	var rows := int(ceil(tiles.size() / float(cols)))
	var sheet := Image.create(tw * cols, th * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#2b2a28"))
	for i in tiles.size():
		var im: Image = tiles[i].img
		im.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((i % cols) * tw, (i / cols) * th + 34))
	sheet.save_png(ProjectSettings.globalize_path("res://shots/%s.png" % name))
	# 标签另存一份文本（Image 不能写字）
	var f := FileAccess.open(ProjectSettings.globalize_path("res://shots/%s.txt" % name), FileAccess.WRITE)
	for i in tiles.size():
		f.store_line("%d: %s" % [i + 1, tiles[i].label])
	print("sheet ", name)
