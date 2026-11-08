extends SceneTree
## 帧率探针：关垂直同步，分场景测 CPU/GPU 每帧耗时；再逐个隐藏节点看谁最贵

var main: Node
var vp: RID

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = true
	root.add_child(main)
	vp = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	_go()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func measure(name: String, n := 120) -> Dictionary:
	await frames(10)
	var cpu := 0.0; var gpu := 0.0; var proc := 0.0; var worst := 0.0
	var t0 := Time.get_ticks_usec()
	var last := t0
	for i in n:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var frame := (Time.get_ticks_usec() - t0) / 1000.0 / n
	var d := {"frame": frame, "proc": proc / n, "cpu": cpu / n, "gpu": gpu / n, "worst": worst,
		"calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"prims": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	print("%-26s frame %6.2f ms  process %5.2f  render-cpu %5.2f  gpu %5.2f  worst %6.1f  calls %5d  prims %7d" % [name, d.frame, d.proc, d.cpu, d.gpu, d.worst, d.calls, d.prims])
	return d

func attribute(tag: String) -> void:
	var base: float = (await measure(tag + " 基线", 90)).frame
	var targets := {}
	for k in ["lab", "ringmap", "detector", "chamber", "pollution", "form", "shot", "gear", "desk", "review", "player", "prompt",
			"clip_l", "clip_r", "panel", "charms", "cel", "overlay", "shop", "plans", "title", "intro", "grain"]:
		var n = main.get(k)
		if n is CanvasItem:
			targets[k] = n
	for k in targets:
		var n: CanvasItem = targets[k]
		if not n.visible:
			continue
		n.visible = false
		var d: float = (await measure("  隐藏 " + k, 60)).frame
		n.visible = true
		print("    → %s 约 %.2f ms" % [k, base - d])

var stamps: Array = []
var draw_acc := {}
var proc_acc := {}
var prof_frames := 0

func _hook(n: Node) -> void:
	if n is CanvasItem and not n.draw.is_connected(_on_draw):
		n.draw.connect(_on_draw.bind(n))
	for c in n.get_children():
		_hook(c)

func _on_draw(n: Node) -> void:
	stamps.append([Time.get_ticks_usec(), n.name if n.get_script() == null else n.get_script().resource_path.get_file()])

## 绘制计时：draw 信号在 _draw 之前发，下一个节点的 draw 信号时间 - 本节点 ≈ 本节点 _draw 耗时
func profile(tag: String, n := 120) -> void:
	_hook(main)
	draw_acc.clear()
	proc_acc.clear()
	for i in n:
		stamps.clear()
		var t0 := Time.get_ticks_usec()
		await process_frame
		var t1 := Time.get_ticks_usec()
		stamps.append([t1, "_end"])
		for j in stamps.size() - 1:
			var k: String = stamps[j][1]
			draw_acc[k] = draw_acc.get(k, 0.0) + (stamps[j + 1][0] - stamps[j][0]) / 1000.0
	var keys := draw_acc.keys()
	keys.sort_custom(func(a, b): return draw_acc[a] > draw_acc[b])
	print("== 绘制耗时 " + tag + "（每帧平均 ms）")
	for k in keys.slice(0, 12):
		print("   %-24s %6.3f" % [k, draw_acc[k] / n])
	# 逻辑耗时：逐个关掉 _process
	print("== _process 耗时 " + tag)
	for k in ["chamber", "form", "detector", "lab", "pollution", "gear", "desk", "review", "player", "prompt", "clip_l", "clip_r", "panel", "charms", "cel", "overlay", "title", "shot", "ringmap"]:
		var nd = main.get(k)
		if nd == null or not nd.is_processing():
			continue
		var tt := 0.0
		for i in 30:
			var a := Time.get_ticks_usec()
			nd._process(1.0 / 60.0)
			tt += (Time.get_ticks_usec() - a) / 1000.0
		print("   %-24s %6.3f" % [k, tt / 30.0])

func freeze_test(tag: String) -> void:
	var base: float = (await measure(tag + " 基线", 240)).frame
	for k in ["overlay", "panel", "charms", "form", "chamber", "pollution", "clip_l", "clip_r", "ringmap", "gear", "detector", "desk", "review", "player", "prompt", "shot", "cel"]:
		var n = main.get(k)
		if n == null:
			continue
		n.process_mode = Node.PROCESS_MODE_DISABLED
		var d: float = (await measure("  冻结 " + k, 240)).frame
		n.process_mode = Node.PROCESS_MODE_INHERIT
		print("    → %s 省 %.2f ms" % [k, base - d])
	var all := []
	for k in ["overlay", "panel", "charms", "form", "chamber", "pollution", "clip_l", "clip_r", "ringmap", "gear", "detector", "desk", "review", "player", "prompt", "cel", "shop", "plans", "title"]:
		var n = main.get(k)
		if n != null:
			n.process_mode = Node.PROCESS_MODE_DISABLED
			all.append(n)
	await measure("  全部冻结", 240)
	for n in all:
		n.process_mode = Node.PROCESS_MODE_INHERIT

func _go() -> void:
	await frames(5)
	await measure("主页（刚进）")
	await frames(240)
	await measure("主页（演示束流长大）")
	main.title._choose(0)
	while main.mode != main.M.WALK:
		await process_frame
	main.intro.call("skip") if main.intro.has_method("skip") else null
	await frames(120)
	await measure("走动")
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	while main.mode != main.M.CONSOLE:
		await process_frame
	await frames(60)
	await measure("控制台 E1")
	main.run.start_experiment() if main.run.can_start() else null
	main.run.beam.energy = 14
	main.run.beam.peak = 14
	main.run.relics = ["coin", "emergency_call", "dean_paper", "lab_cat"]
	main._sync()
	await frames(60)
	await measure("控制台 E14")
	await freeze_test("控制台 E14")
	# 动作场景：连续加速、引出开花
	main.run.beam.energy = 8
	main._sync()
	await frames(30)
	for i in 4:
		main.accelerate()
		await measure("  加速 #%d 揭晓" % (i + 1), 70)
		if main.run.beam == null:
			break
	if main.run.beam != null:
		main.extract()
		await measure("  引出开花前段", 90)
		await freeze_test("开花中")
		await measure("  引出开花后段", 90)
	await frames(200)
	await measure("  开花后控制台", 90)
	await freeze_test("开花后")
	quit(0)
