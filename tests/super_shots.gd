extends SceneTree
## 超级同步截图：锁相纸带（金色段）+ 三连撞与金色射线（不写入真实配置）

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
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.run.inj = "fresh"
	main.enter_console()
	await w(2.4)
	var b: Beam = main.run.beam
	b.energy = 11
	b.lock_left = 3
	b.lock_used = true
	b.charge = 6
	main._sync()
	await w(0.8)
	await snap("super_01_tape")
	b.energy = 14
	main._sync()
	main._impact({"outcome": Odds.SUPER, "to": 14, "from": 11, "lock_started": false, "lock_ended": false})
	main.overlay.stamp(Odds.NAMES[Odds.SUPER], root.get_node("Pal").outcome(Odds.SUPER))
	await w(0.2)
	await snap("super_02_hits")
	await w(0.3)
	await snap("super_03_burst")
	await w(0.35)
	await snap("super_04_after")
	quit(0)
