extends SceneTree
## M3 第 1 批（纸张）截图：新图标商店、污染三档浓度（舱空 / 有束流）

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

func _go() -> void:
	await process_frame
	await process_frame
	var run: Run = main.run
	run.money = 300
	run.relics = ["applications"]
	run.offers.clear()
	var first := true
	for id in ["lost_data", "calib_log", "duty_roster", "third_draft", "reimburse"]:
		var pr: int = Items.ALL[id].price
		if first:
			pr = int(ceil(pr * 0.5))
			first = false
		run.offers.append({"id": id, "sold": false, "price": pr})
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await w(1.2)
	await snap("b1_01_shop")
	run.offers.clear()
	for id in ["nobel_list", "applications"]:
		run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
	await w(0.3)
	await snap("b1_02_shop2")
	main.shop.hide_shop()
	await w(0.6)
	main.player.position.x = Geo.CONSOLE_STAND - 60
	# 三档浓度：1 件 / 2 件 / 4 件纸张
	var sets := [["duty_roster"], ["duty_roster", "third_draft"], ["duty_roster", "third_draft", "reimburse", "nobel_list"]]
	for i in sets.size():
		run.relics = sets[i]
		await w(1.6)
		await snap("b1_1%d_empty" % i)
	main.run.inj = "fresh"
	main.enter_console()
	await w(2.6)
	await snap("b1_20_beam_full")
	run.relics = ["duty_roster"]
	await w(1.6)
	await snap("b1_21_beam_low")
	quit(0)
