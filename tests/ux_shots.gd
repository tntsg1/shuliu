extends SceneTree
## 鼠标交互 + 新手引导截图（引导不写入真实配置）

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
	await create_timer(s).timeout

func scr(world: Vector2) -> Vector2:
	return root.get_viewport().get_canvas_transform() * world

func move(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	Input.parse_input_event(ev)

func click(p: Vector2, down := true, up := true) -> void:
	move(p)
	await w(0.05)
	if down:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = true
		e.position = p
		e.global_position = p
		Input.parse_input_event(e)
	await w(0.05)
	if up:
		var u := InputEventMouseButton.new()
		u.button_index = MOUSE_BUTTON_LEFT
		u.pressed = false
		u.position = p
		u.global_position = p
		Input.parse_input_event(u)

func _go() -> void:
	await process_frame
	await process_frame
	main.tutorial.persist = false
	main.tutorial.start(false)
	main.run.money = 120
	await w(1.2)
	await snap("ux_01_walk_note")
	# 点地面走一步，然后悬停采购终端
	await click(scr(Vector2(600, 700)))
	await w(1.2)
	move(scr(Vector2(Geo.TERMINAL_X + 35, Geo.FLOOR - 100)))
	await w(0.5)
	await snap("ux_02_hover_terminal")
	await click(scr(Vector2(Geo.TERMINAL_X + 35, Geo.FLOOR - 100)))
	await w(2.4)
	var cr: Rect2 = main.shop.card_rects[2] if main.shop.card_rects.size() > 2 else Rect2()
	move(cr.get_center())
	await w(0.5)
	await snap("ux_03_shop_hover")
	await click(cr.get_center())
	await w(0.6)
	await click(main.shop.close_rect.get_center())
	await w(1.0)
	# 点控制台
	await click(scr(Vector2(Geo.CONSOLE_X + 70, Geo.FLOOR - 80)))
	await w(4.0)
	await snap("ux_04_console_note")
	for i in 3:
		await click(main.panel.btn_c)
		while main.mode == main.M.SPIN:
			await process_frame
		await w(0.3)
	# 悬停纸带的加速成功段
	var tr: Rect2 = main.panel.tape_rect
	move(Vector2(tr.position.x + tr.size.x * 0.4, tr.get_center().y))
	await w(0.5)
	await snap("ux_05_tape_tip")
	# 悬停护身符架（如果买到了饰品）
	if not main.run.relics.is_empty():
		move(scr(Vector2(1068, 714)))
		await w(0.5)
		await snap("ux_06_relic_tip")
	# 拖拉杆引出
	if main.run.beam != null:
		var k: Vector2 = main.panel.knob
		move(k)
		await w(0.3)
		await click(k, true, false)
		for j in 12:
			move(k + Vector2(0, j * 12))
			await w(0.03)
		await snap("ux_07_drag_lever")
		var u := InputEventMouseButton.new()
		u.button_index = MOUSE_BUTTON_LEFT
		u.pressed = false
		u.position = k + Vector2(0, 140)
		Input.parse_input_event(u)
		await w(6.0)
		if not main.overlay.btn_rects.is_empty():
			move(main.overlay.btn_rects[0].rect.get_center())
			await w(0.5)
		await snap("ux_08_result_buttons")
	quit(0)
