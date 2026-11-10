extends SceneTree
## 新手开场截图：开场信 → 墙上日程表（旁白）→ 气瓶 → 注入时气瓶飞进注入器 → 报告飞进审核台 → 提前提交气瓶退回
## 教程 persist=false：不写玩家配置

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
	main.tutorial.persist = false
	main.tutorial.start(false)
	main.open_letter()
	await frames(50)
	await snap("tut_01_letter_typing")
	if not main.letter._all_shown():
		main.letter.press()
	await frames(40)
	await snap("tut_02_letter_full")
	main.letter.press()
	await until(func(): return not main.letter.open)
	await frames(70)
	await snap("tut_03_wall")
	await until(func(): return main.tutorial.idx >= 0 and main.tutorial.steps[main.tutorial.idx].id == "bottles")
	await frames(60)
	await snap("tut_04_bottles")
	main.tutorial.stop()
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	if main.run.beam == null:
		main._new_beam()
	await frames(18)
	await snap("tut_05_bottle_take")
	main.run.beam.energy = 9
	main._sync()
	await frames(30)
	main.extract()
	await until(func(): return main.mode == main.M.CONSOLE and main.run.beam == null, 1200)
	await frames(130)
	await snap("tut_06_report_fly")
	main.leave_console()
	await frames(60)
	main.player.position.x = 700
	await frames(30)
	main.run.total = 620
	main.open_review()
	main.submit()
	await frames(25)
	await snap("tut_07_refund")
	main.close_review()
	await frames(15)
	if main.mode == main.M.PLAN:
		main._on_plan_chosen(main.run.plan_offers[0])
		main.plans.visible = false
	main.overlay.hide_card()
	main.cel.visible = false
	await frames(50)
	await snap("tut_08_refill")
	quit(0)
