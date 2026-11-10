extends SceneTree
## M5a + M5b 验收录像（约 1 分钟）：tools/run_test.sh tests/demo_m5.gd -- --write-movie <out.avi> --fixed-fps 60
## 坐货梯下储藏室 → 失物招领箱抽到没借阅的保温杯（本局试用）→ 回实验室 → 爬梯子上教授办公室 →
## 书架用声望借书 → 办公桌签课题组 + 挑战合同 → 下楼 → 一局结束的结算卡（声望 × 挑战倍数、解锁）。
## 局外进度用测试里的内存进度（不碰玩家的 meta.cfg），节奏按真人。

var main: Node

func _initialize() -> void:
	Meta.reset_for_test()
	Meta.d.storage_open = true
	Meta.d.office_open = true
	Meta.d.prestige = 300
	Meta.d.best_stage = 5
	(Meta.d.groups as Array).append("finance")
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

func until(f: Callable, limit := 1200) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func walk(x: float, goal := "") -> void:
	main._walk_to(x, goal)
	await until(func(): return main.walk_goal == "" and main.player.auto_target < 0.0 and main.ride.is_empty() and not main.player.busy())

func key(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	main._unhandled_input(ev)

func _go() -> void:
	await frames(3)
	var run := Run.new(20261110)
	run.pool = Meta.pool()
	run.lost_pick = "thermos"         # 让箱子里翻出一件还没借阅的稀有饰品
	run.challenge_offers = ["one_relic", "no_refresh", "min_e8"]
	main.run = run
	main.player.position = Vector2(980, Geo.FLOOR)
	await sec(1.2)
	# —— 地下储藏室 ——
	await walk(Geo.LIFT_X, "spot:lift")
	await sec(0.6)
	await walk(Geo.LOST_X - 60, "spot:lostbox")
	await sec(2.6)
	main._lost_take()
	await sec(1.6)
	await walk(Geo.LIFT_X, "spot:lift_b")
	await sec(0.4)
	# —— 楼上办公室 ——
	await walk(Geo.LADDER_X + 8, "spot:ladder")
	await sec(0.8)
	await walk(700, "spot:shelf")
	await sec(1.0)
	var lib = main.library
	for p in [Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(4, 2)]:
		lib.sel = p
		lib._tick()
		await sec(0.55)
	await sec(0.8)
	lib._borrow()
	await sec(1.6)
	lib.sel = Vector2i(6, 0)
	lib._tick()
	await sec(0.6)
	lib._borrow()
	await sec(1.4)
	lib.close()
	await sec(0.5)
	await walk(1390, "spot:desk")
	await sec(1.0)
	var cu = main.contract_ui
	for r in [1, 2, 3]:
		cu.side = 0
		cu.row = r
		cu._tick()
		await sec(0.5)
	cu._sign(0, 3)
	await sec(1.3)
	cu.side = 1
	for r in [0, 1, 2, 0]:
		cu.row = r
		cu._tick()
		await sec(0.45)
	cu._sign(1, 0)
	await sec(1.8)
	cu.close()
	await sec(0.5)
	await walk(Geo.LADDER_X + 10, "spot:ladder_o")
	await sec(0.6)
	# —— 一局结束：结算卡上的声望（挑战合同倍数）——
	run.stage = 4
	run.experiments_left = 0
	run.total = 2600
	await walk(1480)
	main.open_review()
	await sec(1.2)
	main.submit()
	await sec(5.5)
	quit(0)
