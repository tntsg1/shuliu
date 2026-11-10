extends SceneTree
## 圣遗物改造第二步：挂板每张牌底下的状态签（层数 / 本阶段 / 本束 / 条件），文字变了跳一下

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

func press(k: int) -> void:
	var run: Run = main.run
	run.dev_force = k
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(6)

func _go() -> void:
	await frames(5)
	var run: Run = main.run
	run.devices = ["cryo_magnet", "diagnostic"]
	run.relics = ["rejected", "badge", "tape_roll", "third_draft", "red_flag", "coffee"]
	main.player.position.x = Geo.CONSOLE_STAND - 60
	run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(40)
	await snap("cs_01_start")
	var ok := true
	ok = ok and run.charm_state("rejected").t == "怨气累计 0/3" and run.charm_state("tape_roll").t == "当前束流可以使用"
	# 失谐：诊断仪先拦（本束已用），第二次胶带拦，第三次工牌拦
	await press(Odds.DETUNE)
	await press(Odds.DETUNE)
	await press(Odds.DETUNE)
	ok = ok and run.charm_state("diagnostic").t == "已经使用" and run.charm_state("tape_roll").t == "已经使用" and run.charm_state("badge").t == "已经使用"
	ok = ok and run.charm_state("third_draft").t.begins_with("加成 ×1.3")
	# 第四次失谐没人拦：怨气 1/3
	await press(Odds.DETUNE)
	ok = ok and run.charm_state("rejected").t == "怨气累计 1/3"
	await frames(8)
	await snap("cs_02_used_pulse")
	await press(Odds.SUCCESS)
	await press(Odds.SUCCESS)
	ok = ok and run.charm_state("coffee").t == "连续成功 2/3"
	run.beam.energy = 11
	main._sync()
	await frames(50)
	ok = ok and not run.charm_state("cryo_magnet").dim
	await snap("cs_03_cond_on")
	print("charm states: ", "OK" if ok else "FAIL")
	for id in run.devices + run.relics:
		print("  ", id, " = ", run.charm_state(id))
	quit(0)
