extends SceneTree
## M3 验收录像（约 1 分钟）：tools/run_test.sh tests/demo_m3.gd -- --write-movie <out.avi> --fixed-fps 60
## 采购（买饰品飞进槽位）→ 加速 → 原始结果被饰品改写 → 抽卡 → 红色按钮 → 引出出奇葩事件 →
## 去审核台提交 → 庆祝 → 挑科研计划书 → 回控制台锁相冲超级同步。结果用开发者开关固定，节奏按真人。

var main: Node

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func sec(s: float) -> void:
	await frames(int(s * 60.0))

func until(f: Callable, limit := 900) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func move(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	main._mouse(ev)

## 一次加速：结果固定为 k（-1 = 照常随机），等揭晓结束
func press(k: int, roll := -1) -> void:
	var run: Run = main.run
	run.dev_force = k
	run.dev_roll = roll
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.mode == main.M.CONSOLE)
	run.dev_force = -1
	await sec(0.55)

func _go() -> void:
	await frames(3)
	var run: Run = main.run
	run.money = 160
	run.relics = []
	run.devices = ["magnet_sc"]
	run.offers.clear()
	for id in ["quad_array", "wrong_answer", "coin", "duty_roster", "third_draft"]:
		run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
	main.player.position.x = 700
	await sec(1.0)
	# —— 走去采购终端 ——
	main._walk_to(Geo.TERMINAL_X + 35, "shop")
	await until(func(): return main.mode == main.M.SHOP)
	await sec(1.0)
	for i in [0, 1, 2]:
		move(main.shop.card_rects[i].get_center())
		await sec(0.55)
		main.shop.area = "shop"
		main.shop.sel = i
		main.shop._confirm()
		await sec(0.9)
	move(main.shop.inv_rects[1].rect.get_center() if main.shop.inv_rects.size() > 1 else Vector2(960, 700))
	await sec(1.0)
	main.shop.hide_shop()
	await sec(0.4)
	run.relics.append("red_button")     # 演示用：红色按钮是之前就买好的
	main.gear_bought()
	# —— 去控制台 ——
	main._walk_to(Geo.CONSOLE_STAND, "console")
	await until(func(): return main.mode == main.M.CONSOLE)
	await sec(0.8)
	await press(Odds.SUCCESS)
	await press(Odds.SUCCESS)
	await press(Odds.PERFECT)
	# 射频失谐 → 学弟的错误答案抽卡命中 → 改写成完美同步
	await press(Odds.DETUNE, 1)
	await sec(0.4)
	await press(Odds.SUCCESS)
	# 束流丢失 → 祖传硬币抽卡正面 → 挡住
	await press(Odds.LOSS, 1)
	await sec(0.4)
	# 绝对不能按的红色按钮：×10
	run.dev_roll = 1
	main.press_red()
	await until(func(): return main.mode == main.M.CONSOLE and main.charms.fires.is_empty())
	run.dev_roll = -1
	await sec(1.0)
	# —— 引出：探测屏上出奇葩事件 ——
	main.dev_meme_force = "woodfish"
	main.e_guard = 0.0
	main.cooldown = 0.0
	main.extract()
	await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
	await sec(2.2)
	# —— 去审核台提交 ——
	main._leave_tab_go()
	await until(func(): return main.mode == main.M.REVIEW)
	await sec(1.6)
	main.submit()
	await until(func(): return main.cel.t > 4.2)
	await sec(1.2)
	main.close_review()
	# —— 挑科研计划书 ——
	await until(func(): return main.plans.t > 1.0)
	for i in [0, 2, 1]:
		move(main.plans._card_center(i))
		await sec(0.6)
	main.plans._choose(1)
	await until(func(): return main.mode == main.M.WALK)
	await sec(0.8)
	# —— 回控制台：锁相里冲一个超级同步 ——
	main._walk_to(Geo.CONSOLE_STAND, "console")
	await until(func(): return main.mode == main.M.CONSOLE)
	await sec(0.6)
	await press(Odds.SUCCESS)
	await press(Odds.PERFECT)
	run.beam.charge = run.lock_need() - 1
	await press(Odds.SUCCESS)
	await sec(0.4)
	await press(Odds.SUPER)
	await sec(2.5)
	quit(0)
