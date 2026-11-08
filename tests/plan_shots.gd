extends SceneTree
## 科研计划书：过阶段 → 好的 → 三份发上来 → 悬停 → 选中签字盖章 → 夹板上的计划书签

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
	run.total = 700
	main.player.position.x = main.review.STAND
	main.open_review()
	await until(func(): return main.overlay.card_v > 0.95)
	main.submit()
	await until(func(): return main.cel.t > 3.0)
	main.close_review()
	await until(func(): return main.plans.t > 0.25)
	await snap("plan_01_deal")
	await until(func(): return main.plans.t > 1.0)
	var ev := InputEventMouseMotion.new()
	ev.position = main.plans._card_center(1)
	main.plans.mouse(ev)
	await frames(30)
	await snap("plan_02_hover")
	main.plans._choose(1)
	await until(func(): return main.plans.pick_t > 0.8)
	await snap("plan_03_sign")
	await until(func(): return main.plans.pick_t > 1.35)
	await snap("plan_04_stamp")
	await until(func(): return main.mode == main.M.WALK)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(60)
	await snap("plan_05_clip")
	print("plan = ", run.plan)
	quit(0)
