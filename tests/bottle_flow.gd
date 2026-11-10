extends SceneTree
## 氢气瓶全手动流程（Q70）：拿瓶 → 装瓶 → 实验 → 引出满瓶进篮子 → 丢失后取下空瓶扔掉 → 篮子 ↔ 储备柜
## 断言打印 PASS/FAIL，顺带截图 shots/flow_*.png

var main: Node
var fails := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 1500) -> bool:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1
	return f.call()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))

func at(x: float) -> void:
	main.player.position.x = x
	main.player.auto_target = -1.0
	await frames(3)

func _go() -> void:
	await frames(5)
	var run: Run = main.run
	check(run.inj == "" and run.held == "", "开局瓶座空、手空")
	# 没装瓶不能开实验
	await at(Geo.CONSOLE_STAND)
	main.enter_console()
	await frames(5)
	check(main.mode == main.M.WALK, "瓶座没装新瓶：进不了控制台")
	# 拿瓶
	await at(351)
	check(main._spot() == "rack" and main._spot_label("rack") == "拿一瓶氢气", "气瓶架提示：拿一瓶氢气")
	main._spot_do("rack")
	check(run.held == "fresh" and run.rack_left() == 2, "手里一瓶新瓶，架子剩 2")
	await at(300)
	await frames(20)
	await snap("flow_01_carry_fresh")
	# 装瓶
	await at(246)
	check(main._spot_label("cradle") == "装上氢气瓶", "瓶座提示：装上氢气瓶")
	main._spot_do("cradle")
	check(run.inj == "fresh" and run.held == "", "新瓶装上瓶座")
	# 实验 → 引出
	await at(Geo.CONSOLE_STAND - 60)
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	check(run.beam != null and run.inj == "empty", "开始实验：瓶里氢气注进环，瓶座剩空瓶")
	run.beam.energy = 6
	main._sync()
	await frames(10)
	main.cooldown = 0.0
	main.e_guard = 0.0
	main.extract()
	await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
	await frames(60)
	await snap("flow_02_bottle_pops")
	await frames(70)
	await snap("flow_03_bottle_flies")
	check(run.basket.size() == 1 and run.inj == "" and run.basket[0].value == run.total, "引出：满瓶进篮子，瓶座空出来，篮子合计 = 累计")
	main.leave_console()
	await until(func(): return main.mode == main.M.WALK)
	# 第二束：丢失 → 空瓶留在瓶座
	await at(351); main._spot_do("rack")
	await at(246); main._spot_do("cradle")
	await at(Geo.CONSOLE_STAND - 60)
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	run.dev_force = Odds.LOSS
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
	check(run.inj == "empty", "丢失：空瓶留在瓶座上")
	main.leave_console()
	await until(func(): return main.mode == main.M.WALK)
	await at(246)
	check(main._spot_label("cradle") == "取下空瓶", "瓶座提示：取下空瓶")
	main._spot_do("cradle")
	check(run.held == "empty" and run.inj == "", "空瓶拿在手里")
	await at(351)
	main._spot_do("rack")
	check(run.held == "empty", "拿着空瓶不能再拿新瓶")
	await at(130)
	await frames(15)
	await snap("flow_04_carry_empty")
	check(main._spot() == "bin" and main._spot_label("bin") == "扔掉空瓶", "回收站提示：扔掉空瓶")
	main._spot_do("bin")
	check(run.held == "" and main.stash.bin_n == 1, "空瓶扔进回收站")
	# 篮子 → 储备柜 → 篮子
	var t0 := run.total
	await at(main.review.STAND)
	main._review_q()
	check(run.held == "full" and run.basket.is_empty() and run.total == 0, "从篮子拿出满瓶，累计跟着减")
	await at(1560)
	await frames(15)
	await snap("flow_05_carry_full")
	check(main._spot_label("cab") == "存进储备柜", "储备柜提示：存进储备柜")
	main._spot_do("cab")
	check(run.cab.size() == 1 and run.held == "", "满瓶存进储备柜")
	await frames(10)
	await snap("flow_06_cab")
	main._spot_do("cab")
	check(run.held == "full" and run.cab.is_empty(), "从储备柜取出")
	await at(main.review.STAND)
	main._review_e()
	check(run.basket.size() == 1 and run.total == t0 and run.held == "", "放回篮子，累计恢复")
	print("bottle flow: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(0)
