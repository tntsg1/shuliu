extends SceneTree
## 商店组合小签：手上有胶带时，修改稿/保温杯卡上贴“和胶带一套”（Q75）
var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _go() -> void:
	await frames(3)
	main.run.money = 400
	main.run.relics = ["tape_roll", "rejected"]
	main.run.devices = []
	main.run.offers.clear()
	for id in ["third_draft", "thermos", "grad_promise", "magnet_sc", "beam_dump"]:
		main.run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await frames(100)
	main.shop.kb = false
	main.shop.hover_card = -1
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/combo_shop.png"))
	var ok: bool = Items.combo_with("third_draft", main.run.relics).get("with", "") == "胶带" \
		and Items.combo_with("grad_promise", main.run.relics).get("with", "") == "拒稿论文" \
		and Items.combo_with("magnet_sc", main.run.relics).is_empty() and Items.combo_with("beam_dump", main.run.relics).is_empty()
	print("combo shop: ", "OK" if ok else "FAIL")
	quit(0)
