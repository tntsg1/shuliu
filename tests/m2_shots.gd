extends SceneTree
## M2 截图：商店、护身符架与束流线设备、饰品触发纸签

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
	await create_timer(s).timeout

func _go() -> void:
	await process_frame
	await process_frame
	var run: Run = main.run
	run.money = 260
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await w(1.2)
	await snap("m2_01_shop")
	main.shop.sel = 1
	main.shop._confirm()
	main.shop.sel = 2
	main.shop._confirm()
	await w(0.6)
	await snap("m2_02_bought")
	# 直接装满一套有代表性的构筑
	run.devices = ["magnet_sc", "quad_array", "diagnostic"]
	run.relics = ["coin", "eraser", "chair"]
	run.uses["eraser"] = 3
	main.shop.area = "inv"
	main.shop.sel = 1
	await w(0.5)
	await snap("m2_03_inventory")
	main.shop.hide_shop()
	await w(1.0)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	await w(0.8)
	await snap("m2_04_lab_gear")
	main.enter_console()
	await w(2.4)
	for i in 4:
		if run.beam == null: break
		main.cooldown = 0.0
		main.accelerate()
		while main.mode == main.M.SPIN:
			await process_frame
		await w(0.15)
	if run.beam != null:
		await snap("m2_05a_board")
		main._triggers({"triggers": [["coin", "正面！挡住了"], ["eraser", "橡皮重抽"]]})
		await w(0.3)
		await snap("m2_05b_fly")
		await w(0.32)
		await snap("m2_05c_burst")
		await w(0.35)
		await snap("m2_05d_banner")
		await w(1.2)
		await snap("m2_05e_back")
	quit(0)
