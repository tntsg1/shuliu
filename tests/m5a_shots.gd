extends SceneTree
## M5a：局外声望结算、首局 25 件池、货梯下地下储藏室、失物招领箱抽一件（收下 / 折 $10）
var main: Node
var ok := true

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	Meta.reset_for_test()
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

func check(c: bool, what: String) -> void:
	print("  ", "ok   " if c else "FAIL ", what)
	if not c:
		ok = false

func _go() -> void:
	await frames(5)
	check(Meta.pool().size() == 25, "首局池 25 件")
	var run: Run = main.run
	run.pool = Meta.pool()
	# 商店只出池里的
	var bad := 0
	for i in 40:
		run.roll_shop()
		for o in run.offers:
			if not run.pool.has(o.id):
				bad += 1
	check(bad == 0, "商店只出首局池里的物品")
	main.player.position.x = Geo.LIFT_X + 60
	await frames(40)
	await snap("m5a_01_locked")
	main._spot_do("lift")
	await frames(10)
	check(not main.underground(), "没开放时货梯下不去")
	# 一局结束：失败在第 3 阶段 → 声望 45，储藏室开放
	var r2 := Run.new(5)
	r2.stage = 2
	r2.failed = true
	var m := Meta.settle(r2)
	check(m.gain == 45 and m.opened.has("storage") and Meta.storage_open(), "第 3 阶段失败：声望 +45，储藏室开放")
	print("  ", main._meta_lines(m))
	var r3 := Run.new(6)
	r3.stage = 8
	var m3 := Meta.settle(r3)
	check(m3.gain == 8 * 15 + 60 and m3.opened.has("office"), "通关：声望 +180，办公室开放")
	r3.endless = true
	r3.stage = 10
	r3.failed = true
	check(Meta.settle(r3).gain == 3 * 15, "无尽失败在第 11 阶段：只补 3 个阶段")
	# 坐货梯下去
	main.player.position.x = Geo.LIFT_X
	main._spot_do("lift")
	await frames(60)
	await snap("m5a_02_riding")
	await create_timer(1.8).timeout
	check(main.underground() and absf(main.player.position.y - Geo.B_FLOOR) < 1.0, "到了地下储藏室")
	await frames(40)
	await snap("m5a_03_basement")
	# 失物招领箱
	main.player.position.x = Geo.LOST_X - 60
	await frames(5)
	check(main._spot() == "lostbox", "站在失物招领箱前")
	var m0: int = run.money
	main._spot_do("lostbox")
	await frames(30)
	check(main.mode == main.M.LOST and run.lost_pick != "", "抽到一件：" + run.lost_pick)
	await snap("m5a_04_lost_card")
	main._lost_cash()
	await frames(5)
	check(run.money == m0 + 10 and run.lost_drawn and run.lost_pick == "" and main.mode == main.M.WALK, "折成 $10")
	main._spot_do("lostbox")
	check(main.mode == main.M.WALK, "本局不能再抽")
	# 收下的情况：换一局
	var r4 := Run.new(11)
	r4.lost_roll()
	var pick := r4.lost_pick
	check(r4.lost_take() == "" and r4.has(pick) and (r4.trial.has(pick) == not Meta.unlocked(pick)), "收下：%s（试用 %s）" % [pick, r4.trial.has(pick)])
	# 回实验室
	main.player.position.x = Geo.LIFT_X
	main._spot_do("lift_b")
	await create_timer(2.3).timeout
	check(not main.underground() and absf(main.lift.plat_y - Geo.FLOOR) < 1.0, "回到实验室")
	await frames(30)
	await snap("m5a_05_back")
	print("m5a: ", "OK" if ok else "FAIL")
	quit(0)
