extends SceneTree
## M4 截图：主页继续实验、读档回控制台（第 4 阶段大考）、够线后的扣分警告、扣分结果、提前提交目标卡、通关继续挑战

var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = true
	root.add_child(main)
	_go()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))
	print("shot ", name)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 2000) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func _go() -> void:
	await frames(3)
	main.title.cont_info = "第 4 / 8 阶段 · 累计 6,240 RP"
	await until(func(): return main.title.t > 1.4)
	await snap("m4_01_title_continue")
	# 读档：第 4 阶段（大考），舱里一束 E9 正在跑，累计已够线
	main.title.open = false
	main.title.visible = false
	var r := Run.new(777)
	r.stage = 3
	r.total = 7400
	r.money = 64
	r.relics = ["coin", "dean_paper", "lab_cat"]
	r.devices = ["magnet_sc"]
	r.experiment_no = 10
	r.experiments_left = 2
	r.start_experiment()
	r.beam.energy = 9
	r.beam.peak = 9
	main.resume(r)
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(80)
	await snap("m4_02_resume_tax_warn")
	# 丢了：扣 30%（先拿掉会挡丢失的硬币和猫）
	r.relics = ["dean_paper"]
	main._sync()
	await frames(30)
	r.dev_force = Odds.LOSS
	main.accelerate()
	await until(func(): return main.mode == main.M.CONSOLE and main.run.beam == null, 900)
	await frames(50)
	await snap("m4_03_tax_result")
	# 再做一束、够线后提前提交：剩余束流折经费
	r.dev_force = -1
	r.total = 8000
	main.open_review()
	main.submit()
	await frames(200)
	await snap("m4_04_goal_leftover")
	# 通关第 8 阶段：继续挑战
	main.close_review()
	await frames(20)
	if main.mode == main.M.PLAN:
		main._on_plan_chosen(main.run.plan_offers[0])
		main.plans.visible = false
	await frames(60)
	r.stage = 7
	r.total = 32000
	r.experiments_left = 0
	main.submit()
	await frames(90)
	await snap("m4_05_win_endless")
	main.go_endless()
	await frames(60)
	if main.mode == main.M.PLAN:
		main._on_plan_chosen(main.run.plan_offers[0])
	await frames(30)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(60)
	await snap("m4_06_endless_board")
	quit(0)
