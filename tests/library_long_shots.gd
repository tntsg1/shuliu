extends SceneTree
## 书架借书卡：用户改的长文案排版检查（螺丝 / 红按钮 / 忘记保存的数据）
var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	Meta.reset_for_test()
	Meta.d.prestige = 300
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _go() -> void:
	await frames(5)
	main.library.show_lib()
	await frames(20)
	for want in ["red_button", "lost_data", "screw"]:
		for y in 8:
			for x in 8:
				main.library.sel = Vector2i(x, y)
				if main.library.selected() == want:
					break
			if main.library.selected() == want:
				break
		await frames(10)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/lib_long_%s.png" % want))
		print("shot ", want, " ", main.library.selected())
	quit(0)
