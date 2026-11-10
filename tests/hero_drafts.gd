extends SceneTree
## 主角造型草案：现版 + A/B/C 三个，各截站立、走路、控制台前三个姿势，拼成一张对比图

var main: Node
const ORDER := ["a", "a2", "a3"]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/hero/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_viewport().get_texture().get_image()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _crop(img: Image, cx: float) -> Image:
	var r := Rect2i(int(cx) - 110, 560, 220, 250)
	var sub := img.get_region(r)
	sub.resize(440, 500, Image.INTERPOLATE_LANCZOS)
	sub.convert(Image.FORMAT_RGBA8)
	return sub

func _go() -> void:
	await frames(10)
	var p = main.player
	var tiles := []
	for st in ORDER:
		p.style = st
		var row := []
		# 站立（在墙前空处）
		p.input_enabled = false
		p.t_console = 0.0
		p.console_pose = 0.0
		p.position.x = 1300
		p.vx = 0.0
		p.stride = 0.0
		await frames(20)
		row.append(_crop(await grab(), 1300))
		# 走路：手动给速度和步幅
		p.position.x = 1250
		p.auto_target = 1500
		await frames(22)
		row.append(_crop(await grab(), p.position.x))
		p.auto_target = -1.0
		p.vx = 0.0
		# 控制台前
		p.position.x = Geo.CONSOLE_STAND
		p.t_console = 1.0
		p.console_pose = 1.0
		p.facing = 1.0
		p.face_s = 1.0
		await frames(25)
		row.append(_crop(await grab(), Geo.CONSOLE_STAND + 20))
		tiles.append(row)
	var out := Image.create(440 * 3 + 40, 520 * ORDER.size(), false, Image.FORMAT_RGBA8)
	out.fill(Color(0.15, 0.15, 0.15))
	for i in tiles.size():
		for k in 3:
			out.blit_rect(tiles[i][k], Rect2i(0, 0, 440, 500), Vector2i(k * 460, i * 520))
	out.save_png(ProjectSettings.globalize_path("res://shots/hero_drafts.png"))
	print("hero drafts OK")
	quit(0)
