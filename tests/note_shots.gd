extends SceneTree
## 18 张教程便条逐张截图（便条按段落自动折行后的大小、位置）。不写玩家配置。
var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/notes/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func _go() -> void:
	for i in 5:
		await process_frame
	var tut = main.tutorial
	tut.persist = false
	tut.start(false)
	tut.process_mode = Node.PROCESS_MODE_DISABLED
	for i in tut.steps.size():
		tut.active = true
		tut.idx = i
		tut.step_t = 1.0
		tut.done_t = -1.0
		tut.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/notes/%02d_%s.png" % [i + 1, tut.steps[i].id]))
	print("note shots: ", tut.steps.size())
	quit(0)
