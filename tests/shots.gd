extends SceneTree
## 截图自审：tools/run_test.sh tests/shots.gd  → shots/*.png（不抢焦点、不碰鼠标）

var main: Node
var out := "res://shots/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_go()

func wait(s: float) -> void:
	await create_timer(s).timeout

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(out + name + ".png"))
	print("shot ", name)

func _go() -> void:
	var dark := OS.get_cmdline_user_args().has("--dark")
	if dark:
		root.get_node("Pal").set_dark(true)
	var pre := "d_" if dark else ""
	await wait(0.6)
	main.player.position.x = Geo.CONSOLE_STAND - 40
	await wait(1.2)
	await snap(pre + "01_walk")
	main.enter_console()
	await wait(2.4)
	await snap(pre + "02_console_e1")
	var run: Run = main.run
	for i in 6:
		main.cooldown = 0.0
		if run.beam == null:
			break
		run.beam.lock_used = true   # 先关掉锁相，保证截到常态
		main.accelerate()
		await wait(0.2)
	if run.beam != null:
		run.beam.energy = 9
		run.beam.charge = 0
		main._sync()
		await wait(1.4)
		await snap(pre + "03_console_e9")
		run.beam.lock_used = true
		run.beam.lock_left = 3
		run.beam.charge = 6
		run.beam.energy = 11
		main._sync()
		await wait(1.4)
		await snap(pre + "04_lock")
		run.beam.lock_left = 0
		run.beam.energy = 10
		main._sync()
		main.cooldown = 0.0
		main.extract()
		await wait(1.5)
		await snap(pre + "05_bloom")
		await wait(2.6)
		await snap(pre + "06_result")
	if main.mode == main.M.RESULT and run.can_start():
		main._new_beam()
		await wait(0.8)
		run.beam.energy = 12
		main._sync()
		await wait(1.2)
		var r := {"from": 12, "to": 12, "odds": Odds.table(12), "outcome": Odds.LOSS, "lost": true}
		r.merge(run._finish(0))
		main._lose(r)
		await wait(0.55)
		await snap(pre + "07_loss")
	quit(0)
