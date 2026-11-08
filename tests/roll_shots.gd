extends SceneTree
## 饰品“抽卡”截图：中了（创可贴 40%）与没中（祖传硬币 50%），并跑一次真实加速确认揭晓会等抽卡结束

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

func w(s: float) -> void:
	await create_timer(s, true, false, true).timeout

## 按演出自己的时间等（截图窗口在后台时帧率低，墙钟不可靠）
func at(tt: float) -> void:
	while not main.charms.fires.is_empty() and main.charms.fires[0].t < tt:
		await process_frame

func _go() -> void:
	await process_frame
	await process_frame
	var run: Run = main.run
	run.relics = ["bandaid", "coin", "wrong_answer"]
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	await w(2.6)
	main.charms.fire("bandaid", "稳定 → 加速成功", {"p": 0.4, "hit": true})
	await at(0.35)
	await snap("roll_01_fly")
	await at(1.0)
	await snap("roll_02_spin")
	await at(1.62)
	await snap("roll_03_stop")
	await at(1.95)
	await snap("roll_04_hit")
	while not main.charms.fires.is_empty():
		await process_frame
	main.charms.fire("coin", "反面……", {"p": 0.5, "hit": false})
	await at(1.95)
	await snap("roll_05_miss")
	while not main.charms.fires.is_empty():
		await process_frame
	# 真实流程：失谐 + 错误答案 → 揭晓要等抽卡
	var waited := false
	for i in 25:
		if run.beam == null: break
		run.beam.energy = 9
		main.cooldown = 0.0
		main.accelerate()
		while main.mode == main.M.SPIN:
			if main.charms.roll_wait() > 0.0:
				waited = true
			await process_frame
		await w(0.1)
		if waited: break
	print("reveal waited for roll: ", waited)
	quit(0)
