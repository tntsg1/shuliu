extends SceneTree
## 阶段通过庆祝：章砸下 → 横幅 → 礼炮 → 下一阶段目标卡

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

func until(f: Callable, limit := 1500) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func _go() -> void:
	for i in 3:
		await process_frame
	var run: Run = main.run
	run.total = 640
	main.player.position.x = main.review.STAND
	main.open_review()
	await until(func(): return main.overlay.card_v > 0.95)
	await snap("cel_00_review")
	main.submit()
	await until(func(): return main.cel.t > 0.16)
	await snap("cel_01_slam")
	await until(func(): return main.cel.t > 0.5)
	await snap("cel_02_banner")
	await until(func(): return main.cel.t > 1.6)
	print("rockets ", main.cel.rockets.size(), " sparks ", main.cel.sparks.size(), " fired ", main.cel._fired.keys())
	await snap("cel_03_confetti")
	await until(func(): return main.cel.t > 3.3)
	await snap("cel_04_goal")
	quit(0)
