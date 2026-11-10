extends SceneTree
## M3 第 2 批（咖啡 / 钟表）截图：新图标、污染浓度、指针随加速走

var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))
	print("shot ", name)

func w(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _go() -> void:
	await process_frame
	await process_frame
	var run: Run = main.run
	run.money = 300
	run.offers.clear()
	for id in ["screw", "lab8_key", "extinguisher", "wrench", "rf_cavity"]:
		run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await w(1.2)
	await snap("b5_01_shop")
	main.shop.hide_shop()
	await w(0.6)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	run.relics = ["koi"]
	run.devices = []
	await w(1.6)
	await snap("b5_10_low")
	run.relics = ["koi", "screw", "lab8_key", "extinguisher", "wrench"]; run.devices = ["rf_cavity", "extractor", "beam_dump"]
	await w(1.8)
	await snap("b5_11_full_empty")
	main.run.inj = "fresh"
	main.enter_console()
	await w(2.4)
	for i in 5:
		if run.beam == null: break
		run.beam.energy = 2
		main.cooldown = 0.0
		main.accelerate()
		while main.mode == main.M.SPIN:
			await process_frame
		await w(0.2)
	await w(0.8)
	await snap("b5_12_full_beam")
	quit(0)
