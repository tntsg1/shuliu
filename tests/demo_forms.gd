extends SceneTree
## 束流形态成长录像：tools/run_test.sh tests/demo_forms.gd --write-movie <out.avi> --fixed-fps 60
## 标准 → 纸张 → 吉祥物，各从 E1 一路按到 E13 以上再引出看成果卡。纸张路线中途失谐一次，演示“受损不退化”。
## 结果用开发者开关固定为加速成功，节奏按真人。

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

func press(k: int) -> void:
	var run: Run = main.run
	run.dev_force = k
	main.cooldown = 0.0
	main.accelerate()
	await until(func(): return main.mode == main.M.CONSOLE)
	run.dev_force = -1
	await sec(0.35)

func route(relics: Array, title: String, detune_at := -1) -> void:
	var run: Run = main.run
	run.relics = relics.duplicate()
	run.experiments_left = 9
	main.gear_bought()
	main.overlay.say(title)
	if run.beam == null:
		main._next_beam()
	await sec(1.6)
	while run.beam.energy < 14:
		if run.beam.energy == detune_at:
			detune_at = -1
			await press(Odds.DETUNE)
			await sec(1.0)
			continue
		await press(Odds.SUCCESS)
	await sec(1.2)
	main.e_guard = 0.0
	main.cooldown = 0.0
	main.extract()
	await until(func(): return main.mode == main.M.CONSOLE and run.beam == null)
	await sec(1.0)

func _go() -> void:
	await frames(3)
	var run: Run = main.run
	run.money = 200
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await route([], "路线一：没有饰品 · 标准束团 → 同步束 → 对撞之花")
	await route(["note100", "third_draft", "duty_roster"], "路线二：纸张饰品 · 纸团束 → 纸鹤束流 → 论文风暴", 7)
	await route(["lucky_cat", "plant"], "路线三：吉祥物饰品 · 毛线球 → 猫形轨迹 → 橘猫束流")
	await sec(1.0)
	quit(0)
