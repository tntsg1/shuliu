extends SceneTree
var main: Node
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()
func _go() -> void:
	for i in 60: await process_frame
	main.cam_pos = Vector2(960, 540); main.cam_zoom = 1.0
	main.cam_target = Vector2(960, 540); main.zoom_target = 1.0
	for i in 90: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/z_lab_full.png"))
	quit(0)
