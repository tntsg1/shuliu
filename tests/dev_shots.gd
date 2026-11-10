extends SceneTree
## 开发者面板 + “先揭晓原始结果，再被饰品改写”截图（不写入真实配置）

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

func until(f: Callable, limit := 900) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func _go() -> void:
	await frames(2)
	var run: Run = main.run
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await frames(150)
	# 面板：用按键事件打开，装上工牌和硬币
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_QUOTELEFT
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(40)
	main.dev._do("item", "badge")
	main.dev._do("item", "coin")
	main.dev._do("force", Odds.DETUNE)
	main.dev.hover_item = "badge"
	await frames(10)
	await snap("dev_01_panel")
	main.dev.toggle()
	await frames(30)
	# 强制失谐 → 工牌改成保持稳定
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.overlay.st_text == "射频失谐" and main.overlay.st_t > 0.2)
	await snap("dev_02_raw_detune")
	await until(func(): return not main.charms.fires.is_empty() and main.charms.fires[0].t > 0.6)
	await snap("dev_03_badge_jumps")
	await until(func(): return not main.overlay.prev.is_empty() and main.overlay.prev.t > 0.2)
	await snap("dev_04_rewritten")
	await until(func(): return main.mode == main.M.CONSOLE and main.charms.fires.is_empty())
	# 强制丢失 + 硬币必中 → 先看到“束流丢失”，硬币抽卡挡住
	run.dev_force = Odds.LOSS
	run.dev_roll = 1
	run.beam.energy = 9
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.overlay.st_text == "束流丢失" and main.overlay.st_t > 0.15)
	await snap("dev_05_raw_loss")
	await until(func(): return not main.overlay.prev.is_empty() and main.overlay.prev.t > 0.25)
	await snap("dev_06_coin_saved")
	print("beam alive after coin: ", run.beam != null)
	quit(0)
