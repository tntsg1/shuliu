extends SceneTree
## 主页截图：刚进来、演示束流长大后、悬停“设置”、设置页、点开始后的退场

var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = true
	root.add_child(main)
	_go()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))
	print("shot ", name)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 3000) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func move(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	main._mouse(ev)

func _go() -> void:
	await frames(3)
	await until(func(): return main.title.t > 1.2)
	await snap("title_01")
	await until(func(): return main.run.beam != null and main.run.beam.energy >= 10)
	await frames(40)
	await snap("title_02_grown")
	move(main.title.rects[1].get_center())
	await frames(30)
	await snap("title_03_hover")
	main.title._choose(1)
	await frames(40)
	await snap("title_04_settings")
	main.title._to_page("main")
	await frames(30)
	main.title._choose(0)
	await until(func(): return main.title.out_t > 0.4)
	await snap("title_05_out")
	await until(func(): return main.mode == main.M.WALK)
	await frames(30)
	await snap("title_06_intro")
	quit(0)
