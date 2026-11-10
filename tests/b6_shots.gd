extends SceneTree
## M3 第 6 批（电子）：图标、示波器污染、红色按钮与四格转盘

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

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 1500) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func _go() -> void:
	await frames(3)
	var run: Run = main.run
	run.money = 400
	for grp in [["emergency_call", "red_button", "printer", "last_slide", "calc7"], ["calorimeter", "protect_sys", "daq", "lock_loop", "bpm"]]:
		run.offers.clear()
		for id in grp:
			run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
		main.player.position.x = Geo.TERMINAL_X + 35
		if main.mode != main.M.SHOP:
			main.open_shop()
		await frames(70)
		await snap("b6_shop_%s" % grp[0])
	main.shop.hide_shop()
	await frames(30)
	run.relics = ["red_button", "printer", "calc7", "emergency_call"]
	run.devices = ["daq", "bpm"]
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(90)
	await snap("b6_console_red")
	run.dev_roll = 1
	main.press_red()
	await until(func(): return not main.charms.fires.is_empty() and main.charms.fires[0].t > 1.2)
	await snap("b6_red_spin")
	await until(func(): return not main.charms.fires.is_empty() and main.charms.fires[0].t > 1.85)
	await snap("b6_red_result")
	quit(0)
