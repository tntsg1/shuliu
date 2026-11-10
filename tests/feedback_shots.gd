extends SceneTree
## 饰品可见反馈：加速时改概率的物品在挂板上晃 + 小纸签、纸带“原值→现值”；引出时倍率明细逐行播放

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
	await frames(5)
	var run: Run = main.run
	run.devices = ["magnet_sc", "quad_array"]
	run.relics = ["marker", "red_flag", "chair", "duty_roster"]
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	run.beam.energy = 5
	main._sync()
	await frames(40)
	for i in 2:
		run.dev_force = Odds.SUCCESS
		main.cooldown = 0.0
		main.accelerate()
		await until(func(): return main.mode == main.M.CONSOLE)
		await frames(4)
	run.beam.energy = 7
	main._sync()
	main.cooldown = 0.0
	run.dev_force = Odds.SUCCESS
	main.accelerate()
	await frames(14)
	await snap("fb_01_nudges")
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(30)
	await snap("fb_02_tape")
	main.cooldown = 0.0
	main.e_guard = 0.0
	main.extract()
	await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
	await frames(30)
	await snap("fb_03_parts_mid")
	await frames(60)
	await snap("fb_04_parts_full")
	quit(0)
