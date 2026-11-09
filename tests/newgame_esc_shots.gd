extends SceneTree
## 每次开新游戏默认放教程（开场信）；走动时 Esc → 确认卡 → 再 Esc 回主页（主页出现“继续实验”要真存档，测试不写，所以只看回到主页）
var main: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = true
	main.play_intro = true
	root.add_child(main)

	_go()

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + name + ".png"))
	print("shot ", name)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 2000) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	main._unhandled_input(ev)

func _go() -> void:
	await frames(2)
	main.tutorial.persist = false
	await until(func(): return main.title.t > 1.0)
	main.title._choose(0)
	await until(func(): return main.letter.open)
	print("letter on new game: ", main.letter.open, "  tutorial active: ", main.tutorial.active)
	await frames(60)
	await snap("ng_01_letter")
	key(KEY_SPACE); await frames(5); key(KEY_SPACE)
	await until(func(): return not main.letter.open)
	await frames(60)
	key(KEY_ESCAPE)
	await frames(40)
	await snap("ng_02_pause")
	print("mode pause: ", main.mode == main.M.PAUSE)
	key(KEY_ESCAPE)
	await frames(60)
	print("back to title: ", main.mode == main.M.TITLE, "  tutorial stopped: ", not main.tutorial.active)
	await snap("ng_03_title")
	# 再开一局：教程又出现
	main.title._choose(0)
	await until(func(): return main.letter.open, 1500)
	print("letter again on 2nd new game: ", main.letter.open)
	quit(0)
