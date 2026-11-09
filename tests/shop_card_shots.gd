extends SceneTree
## 商店卡亮暗配色、鼠标和键盘说明框的截图与状态检查。
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

func snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + n + ".png"))
	print("截图：", n)

func _go() -> void:
	await frames(3)
	var pal := root.get_node("Pal")
	var longest_name := ""
	var longest_big := ""
	var nw := 0.0
	var bw := 0.0
	for id in Items.ALL:
		var d: Dictionary = Items.ALL[id]
		assert(d.has("big") and d.big != "")
		var n: float = load("res://scripts/util/ink.gd").size(pal.bold, d.name, 19).x
		var b: float = load("res://scripts/util/ink.gd").size(pal.bold, d.big, 18).x
		if n > nw:
			nw = n; longest_name = id
		if b > bw:
			bw = b; longest_big = id
	print("最长名称：", longest_name, "；最长效果：", longest_big)
	var ids := [longest_name, longest_big, "injector_hi", "beam_dump", "red_button"]
	main.run.money = 400
	main.run.offers.clear()
	for id in ids:
		main.run.offers.append({"id": id, "sold": false, "price": Items.ALL[id].price})
	main.player.position.x = Geo.TERMINAL_X + 35
	main.open_shop()
	await frames(100)
	main.shop.kb = false
	main.shop.hover_card = -1
	await frames(10)
	await snap("shop_cards_light")
	pal.set_dark(true)
	await frames(10)
	await snap("shop_cards_dark")
	pal.set_dark(false)
	await frames(10)
	var ev := InputEventMouseMotion.new()
	ev.position = main.shop.card_rects[0].get_center()
	main.shop.mouse(ev)
	await create_timer(0.8).timeout
	assert(main.shop.card_tip_index == 0 and main.shop.card_tip_v > 0.9)
	await snap("shop_card_mouse_tip")
	main.shop.kb = true
	main.shop.area = "shop"
	main.shop.sel = 4
	await create_timer(0.8).timeout
	assert(main.shop.card_tip_index == 4 and main.shop.card_tip_v > 0.9)
	await snap("shop_card_keyboard_tip")
	main.run.offers[4].sold = true
	await frames(3)
	assert(main.shop.card_tip_index == -1)
	main.run.offers[4].sold = false
	main.shop.flips[4] = 0.0
	main.shop._anim(0.01)
	assert(main.shop.card_tip_index == -1)
	main.shop.hide_shop()
	print("商店卡截图与状态检查：通过")
	quit(0)
