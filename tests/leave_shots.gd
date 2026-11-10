extends SceneTree
## 实验中途离开去采购再回来：束流保留、实验次数不变

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

func until(f: Callable, limit := 1200) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func _go() -> void:
	await frames(2)
	var run: Run = main.run
	run.money = 200
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	for i in 3:
		run.dev_force = Odds.SUCCESS
		main.cooldown = 0.0
		main.accelerate()
		await until(func(): return main.mode == main.M.CONSOLE)
		await frames(10)
	var e0: int = run.beam.energy
	var n0: int = run.experiment_no
	var left0: int = run.experiments_left
	await frames(20)
	await snap("leave_01_tab")
	# 点纸签离开 → 自动走到终端打开商店
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = main.panel.leave_rect.get_center()
	main._mouse(ev)
	await until(func(): return main.mode == main.M.SHOP)
	await frames(60)
	await snap("leave_02_shop_midbeam")
	var bought := ""
	for i in run.offers.size():
		if run.buy(i) == "":
			bought = run.offers[i].id
			break
	main.shop.hide_shop()
	await frames(30)
	await snap("leave_03_walk_back")
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(30)
	await snap("leave_04_back")
	print("same beam: ", run.beam != null and run.beam.energy == e0, " exp_no ", n0, "->", run.experiment_no, " left ", left0, "->", run.experiments_left, " bought ", bought, " has ", run.has(bought))
	quit(0)
