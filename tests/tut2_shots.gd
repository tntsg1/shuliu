extends SceneTree
## 第一局后半段的便条：卖出、挂板、饰品生效、超级同步（不写入真实配置）

var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_intro = false
	root.add_child(main)
	_go()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))
	print("shot ", name)

func w(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _go() -> void:
	await process_frame
	await process_frame
	var tu: Node = main.tutorial
	tu.persist = false
	tu.start(false)
	for id in ["walk", "shop", "shop_ui", "console", "space", "value", "lock", "lever", "clips", "submit", "rebuy"]:
		tu.shown[id] = true
	var run: Run = main.run
	run.experiment_no = 1
	run.experiments_left = 2
	run.devices = ["magnet_sc", "diagnostic"]
	run.relics = ["coin", "eraser", "chair"]
	run.uses["eraser"] = 3
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await w(1.0)
	run.experiment_no = 2
	await w(1.2)
	await snap("tut2_01_sell")
	main.shop.hide_shop()
	await w(0.8)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	run.experiment_no = 1
	main.enter_console()
	await w(2.6)
	await snap("tut2_02_board")
	main._triggers({"triggers": [["coin", "正面！挡住了"]]})
	await w(1.4)
	await snap("tut2_03_fired")
	await w(6.5)
	var b: Beam = run.beam
	if b != null:
		b.energy = 9
		b.lock_left = 3
		b.lock_used = true
		main._sync()
	await w(1.5)
	await snap("tut2_04_super")
	quit(0)
