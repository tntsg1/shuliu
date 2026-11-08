extends SceneTree
## 决策信息集中：控制台决策条（引出后累计/差额/风险/保护）+ 右夹板概率核对收起/展开

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
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	run.relics = ["coin", "emergency_call", "dean_paper"]
	run.total = 260
	run.beam.energy = 9
	run.beam.peak = 9
	main._sync()
	await frames(60)
	await snap("hud_01_short")
	run.beam.energy = 12
	run.beam.peak = 12
	run.beam.coin_used = true
	main._sync()
	await frames(60)
	await snap("hud_02_enough")
	run.beam.lock_left = 3
	main._sync()
	await frames(60)
	await snap("hud_03_lock")
	var c: Vector2 = main.clip_r._xf * main.clip_r.freq_rect.get_center()
	main.clip_r.toggle_at(c)
	await frames(30)
	await snap("hud_04_freq_open")
	quit(0)
