extends SceneTree
## 搬瓶动作的中间帧：拿瓶 / 装瓶 / 拆空瓶 / 扔空瓶，每个动作截 4 帧拼成一张 shots/handling.png
## 用法：bash tools/run_test.sh tests/handling_shots.gd [-- style=a2]

var main: Node
var tiles: Array = []

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func grab_tile(cx: float) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var sub := img.get_region(Rect2i(int(cx) - 150, 560, 300, 260))
	sub.convert(Image.FORMAT_RGBA8)
	tiles.append(sub)

func at(x: float) -> void:
	while main.player.busy():
		await process_frame
	await frames(10)
	main.player.position.x = x
	await frames(10)

## 做一个动作，在 0.06 / 0.16 / 0.28 / 0.6 秒各截一帧
func seq(cx: float, f: Callable) -> void:
	f.call()
	var t0 := Time.get_ticks_msec()
	for ms in [60, 160, 280, 600]:
		while Time.get_ticks_msec() - t0 < ms:
			await process_frame
		await grab_tile(cx)

func _go() -> void:
	await frames(10)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("style="):
			main.player.style = a.substr(6)
	var run: Run = main.run
	await at(354)
	await seq(300, func(): main._spot_do("rack"))
	await at(282)
	await seq(230, func(): main._spot_do("cradle"))
	# 假装做过一次实验、丢了：瓶座上是空瓶
	run.inj = "empty"
	await at(282)
	await seq(230, func(): main._spot_do("cradle"))
	await at(130)
	await seq(180, func(): main._spot_do("bin"))
	var out := Image.create(300 * 4 + 30, 260 * 4 + 30, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.15, 0.15, 0.15))
	for i in tiles.size():
		out.blit_rect(tiles[i], Rect2i(0, 0, 300, 260), Vector2i((i % 4) * 310, (i / 4) * 270))
	out.save_png(ProjectSettings.globalize_path("res://shots/handling.png"))
	print("handling OK ", tiles.size())
	quit(0)
