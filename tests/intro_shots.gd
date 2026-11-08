extends SceneTree
## 开场与主环规模感截图

var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	root.add_child(main)
	_go()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))
	print("shot ", name)

func _go() -> void:
	await process_frame
	await process_frame
	for p in [[0.9, "i1"], [2.6, "i2"], [3.7, "i3"], [5.0, "i4"], [7.5, "i5_game"]]:
		var target: float = p[0]
		while main.intro.t < target and main.intro.active:
			await process_frame
		if not main.intro.active:
			await create_timer(1.3).timeout
		await snap(p[1])
	quit(0)
