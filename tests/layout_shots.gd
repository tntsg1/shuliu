extends SceneTree
## 氢气瓶流程布局（Q70）：回收站 · 注入器瓶座 · 气瓶架 · 审核台篮子 · 储备柜，摆上样例瓶子截图

var main: Node

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

func _save(img: Image, r: Rect2i, sc: float, name: String) -> void:
	var sub := img.get_region(r)
	sub.resize(int(r.size.x * sc), int(r.size.y * sc), Image.INTERPOLATE_LANCZOS)
	sub.save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))

func _go() -> void:
	await frames(10)
	main.run.inj = "empty"
	main.stash.bin_n = 2
	main.run.cab = [{"value": 1133, "energy": 10}]
	main.run.basket = [{"value": 84, "energy": 3}, {"value": 256, "energy": 6}, {"value": 539, "energy": 8}]
	main.player.position.x = 600
	await frames(30)
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://shots/layout_full.png"))
	_save(img, Rect2i(0, 560, 560, 260), 2.0, "layout_left")
	_save(img, Rect2i(1300, 520, 420, 300), 2.0, "layout_right")
	print("layout OK")
	quit(0)
