extends SceneTree
## 演示录像驱动：tools/run_test.sh tests/demo.gd --write-movie <out.avi> --fixed-fps 60
## 先找一个能完整展示“稳健引出 → 锁相冲高 → 贪心丢失”的种子，再按真人节奏操作

var main: Node

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_go()

## 用与游戏完全相同的随机消耗模拟三次实验
func _good_seed() -> int:
	for s in range(1, 20000):
		var r := Run.new(s)
		# 实验 1：稳健到 E8
		r.start_experiment()
		var ok := true
		while r.beam != null and r.beam.energy < 8:
			if r.accelerate().lost: ok = false
		if not ok or r.beam == null or r.beam.presses > 10: continue
		r.extract()
		# 实验 2：触发锁相并冲到 E11
		r.start_experiment()
		while r.beam != null and (r.beam.energy < 11 or r.beam.locked()) and r.beam.presses < 18:
			r.accelerate()
		if r.beam == null or not r.beam.lock_used or r.beam.energy < 11: continue
		r.extract()
		if r.won() or r.stage != 1: continue
		# 实验 3：贪心，在 E9 以上丢失
		r.start_experiment()
		var lost_at := 0
		while r.beam != null and r.beam.presses < 20:
			var e := r.beam.energy
			if r.accelerate().lost: lost_at = e
		if lost_at >= 9:
			return s
	return 1

func key(action: String, hold := 0.0) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	if hold > 0.0:
		Input.action_press(action)
		await create_timer(hold).timeout
		Input.action_release(action)
	await create_timer(0.05).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)

func idle() -> void:
	while main.mode == main.M.SPIN:
		await process_frame

func w(s: float) -> void:
	await create_timer(s).timeout

func _go() -> void:
	await process_frame
	await process_frame
	var seed := _good_seed()
	print("demo seed ", seed)
	main.run = Run.new(seed)
	# 开场推近（让它完整播完）
	while main.intro.active:
		await process_frame
	await w(1.4)
	# 走到墙上的主环图前，再走去控制台
	await key("move_left", 0.75)
	await w(0.9)
	await key("move_right", 1.35)
	await w(0.4)
	await key("interact")
	await w(2.2)
	# 实验 1：稳健
	while main.run.beam != null and main.run.beam.energy < 8:
		await key("accelerate")
		await idle()
		await w(randf_range(0.25, 0.45))
	await w(0.7)
	await key("interact")
	await w(4.4)
	await key("accelerate")   # 注入新束流
	await w(1.0)
	# 实验 2：锁相冲高
	while main.run.beam != null and (main.run.beam.energy < 11 or main.run.beam.locked()) and main.run.beam.presses < 18:
		await key("accelerate")
		await idle()
		await w(0.15 if main.run.beam != null and main.run.beam.locked() else randf_range(0.25, 0.45))
	await w(0.9)
	await key("interact")
	await w(4.6)
	await key("accelerate")
	await w(1.0)
	# 实验 3：贪心到丢失
	while main.run.beam != null and main.run.beam.presses < 20:
		await key("accelerate")
		await idle()
		var p: float = 0.0 if main.run.beam == null else main.run.beam.odds()[Odds.LOSS]
		await w(0.3 + p * 1.4)
	await w(3.4)
	# 切换暗色，离开控制台走两步
	await key("theme")
	await w(1.6)
	await key("back")
	await w(1.2)
	await key("move_left", 1.0)
	await w(1.8)
	quit(0)
