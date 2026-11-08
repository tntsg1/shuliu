extends SceneTree
## 新流程：实验结束只弹小纸条、留在控制台；束流用完不能再开；去审核台提交

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

func until(f: Callable, limit := 1500) -> bool:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1
	return f.call()

func key(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	main._unhandled_input(ev)

func _go() -> void:
	await frames(2)
	var run: Run = main.run
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	# 第 1 束：两次成功后引出
	for i in 2:
		run.dev_force = Odds.SUCCESS
		main.cooldown = 0.0
		main.accelerate()
		await until(func(): return main.mode == main.M.CONSOLE)
		await frames(5)
	main.cooldown = 0.0
	main.e_guard = 0.0
	main.extract()
	await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
	await frames(25)
	await snap("rv_01_tally")
	print("after exp1: mode console=", main.mode == main.M.CONSOLE, " beam=", run.beam, " left=", run.experiments_left)
	# 第 2、3 束：直接丢失，用完束流
	for b in 2:
		main.cooldown = 0.0
		key("accelerate")          # 注入下一束
		await until(func(): return run.beam != null)
		await frames(10)
		run.dev_force = Odds.LOSS
		main.cooldown = 0.0
		main.accelerate()
		await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
		await frames(10)
	await frames(150)
	main.cooldown = 0.0
	key("accelerate")              # 用完了：应被拒绝
	await frames(20)
	await snap("rv_02_used_up")
	print("used up: beam=", run.beam, " left=", run.experiments_left, " label=", main.panel.leave_label)
	# 纸签 → 走去审核台
	run.total = run.line()
	main._leave_tab_go()
	await until(func(): return main.mode == main.M.REVIEW)
	await frames(30)
	await snap("rv_03_review")
	key("submit")
	await frames(40)
	await snap("rv_04_passed")
	print("stage now ", run.stage, " left ", run.experiments_left)
	key("interact")
	await frames(30)
	print("back to walk: ", main.mode == main.M.WALK)
	await snap("rv_05_desk_world")
	quit(0)
