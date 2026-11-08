extends SceneTree
## 奇葩事件：20 种梗图逐一画在探测屏上截图（放大镜头）

var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/memes/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _go() -> void:
	await frames(2)
	main.cam_target = Geo.SCREEN.get_center()
	main.zoom_target = 3.6
	main.cam_omega = 40.0
	main.mode = main.M.SHOT          # 别让 WALK 模式把镜头拉回去
	await frames(60)
	for id in Memes.LIST:
		main.detector.bloom(10, "precise", id)
		main.detector.progress = 1.0
		main.detector.playing = false
		main.detector.meme_t = 3.2
		await frames(4)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/memes/%s.png" % id))
	print("memes done")
	quit(0)
