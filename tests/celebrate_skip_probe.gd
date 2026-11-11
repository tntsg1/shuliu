extends SceneTree
## 通关庆祝刚开始就跳过：之后不能再冒出礼花、砸字、欢呼等声音，正在响的要淡出停掉
var main: Node

func _initialize() -> void:
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
	var cel = main.cel
	var Sfx = root.get_node("Sfx")
	cel.start(2, "")
	await frames(30)      # 0.5 秒：礼炮和欢呼已经响了，礼花和砸字还没到点
	cel.finish()
	var t0 := Time.get_ticks_msec() / 1000.0
	await frames(90)
	var late: Array = []
	for n in ["firework", "crackle_fw", "confetti", "boom", "cheer", "applause", "hit"]:
		if float(Sfx.last.get(n, -10.0)) > t0:
			late.append(n)
	var still := 0
	for v in cel._voices:
		if is_instance_valid(v) and v.playing:
			still += 1
	var playing := 0
	for q in Sfx.pool:
		if q.playing and q.stream in [Sfx.streams.get("cheer"), Sfx.streams.get("applause")]:
			playing += 1
	var ok := late.is_empty() and playing == 0
	print("celebrate skip: ", "OK" if ok else "FAIL", " late=", late, " cheer/applause still playing=", playing)
	quit(0)
