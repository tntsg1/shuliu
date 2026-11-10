extends SceneTree
## M3 第 7 批（书籍 / 吉祥物）：图标、公式与猫的污染、薛定谔二选一

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
	run.offers.clear()
	for id in ["impossible", "schrodinger", "qm_book2", "plant", "lab_cat"]:
		run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await frames(70)
	await snap("b7_shop")
	main.shop.hide_shop()
	await frames(20)
	run.relics = ["schrodinger", "impossible", "qm_book2", "plant", "lab_cat"]
	main.player.position.x = Geo.CONSOLE_STAND - 60
	await frames(200)
	await snap("b7_poll_empty")
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	run.beam.energy = 9
	main._sync()
	await frames(60)
	run.dev_force = Odds.LOSS
	run.dev_roll = 0            # 猫不救，好让薛定谔接手
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.mode == main.M.CHOICE)
	await until(func(): return main.overlay.card_v > 0.95)
	await snap("b7_sch_choice")
	run.dev_force = Odds.SUCCESS
	main._sch_go()
	await until(func(): return main.mode == main.M.CONSOLE and main.charms.fires.is_empty(), 2500)
	await frames(30)
	await snap("b7_sch_alive")
	print("alive after gamble: ", run.beam != null, " E", run.beam.energy if run.beam else -1)
	quit(0)
