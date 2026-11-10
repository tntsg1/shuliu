extends SceneTree
## 高能级：潜在成果鼓轮换成万/亿单位
var main: Node
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()
func _go() -> void:
	for i in 3: await process_frame
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	while main.mode != main.M.CONSOLE: await process_frame
	var i := 0
	for e in [24, 52, 99]:
		main.run.beam.energy = e
		main._sync()
		for k in 120: await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/emax_%d.png" % e))
	quit(0)
