extends SceneTree
## 书架借阅按钮：用真实鼠标事件（push_input）左键点击能否借到
var main: Node

func _initialize() -> void:
	Meta.reset_for_test()
	Meta.d.prestige = 300
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _go() -> void:
	await frames(5)
	main.mode = main.M.LIBRARY
	main.library.show_lib()
	await frames(30)
	var lib = main.library
	lib.sel = Vector2i(4, 1)
	await frames(5)
	var id: String = lib.selected()
	var c: Vector2 = lib.borrow_rect.get_center()
	print("sel=", id, " rect=", lib.borrow_rect, " block=", Meta.borrow_block(id))
	var mv := InputEventMouseMotion.new()
	mv.position = c
	mv.global_position = c
	root.push_input(mv, true)
	await frames(2)
	for p in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = p
		ev.position = c
		ev.global_position = c
		root.push_input(ev, true)
		await frames(2)
	var ok: bool = Meta.borrow_block(id) != "" and lib.msg.begins_with("已成功借阅")
	# 点左边物品格：只选中，不花声望，按钮弹一下
	var before: int = Meta.d.prestige
	var tr: Rect2 = lib.tiles["thermos"]
	for p in [true, false]:
		var e2 := InputEventMouseButton.new()
		e2.button_index = MOUSE_BUTTON_LEFT
		e2.pressed = p
		e2.position = tr.get_center()
		e2.global_position = e2.position
		root.push_input(e2, true)
		await frames(1)
	await frames(8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/lib_click_nudge.png"))
	ok = ok and lib.selected() == "thermos" and Meta.d.prestige == before and lib.t - lib.nudge_t < 1.0
	print("library click: ", "OK" if ok else "FAIL", " sel=", lib.selected(), " prestige ", before, "->", Meta.d.prestige)
	quit(0)
