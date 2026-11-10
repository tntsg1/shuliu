extends SceneTree
## 圣遗物改造第三步：三套组合样板（Q75）——同一次加速的多件触发按结算顺序逐条播放 + 右上角结算单
## 1 稳定修稿：胶带 失谐→稳定 → 修改稿 → 稳定两次锁相充能 +1
## 2 拒稿反击：失谐三次 怨气 1/3 2/3 3/3 + 毕业承诺 → 下次成功能级 +3；错误答案没中
## 3 劫后再战：硬币反面 → 丢失 → 报销 / 收集靶 / 忘存的数据；下一束开局继承充能

var main: Node
var ok := true

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

func frames(n: int) -> void:
	for i in n:
		await process_frame

func until(f: Callable, limit := 1500) -> void:
	var n := 0
	while not f.call() and n < limit:
		await process_frame
		n += 1

func check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("  FAIL ", what)

## 强制一个结果按一下加速，等揭晓完（不等结算单播完）
func press(k: int) -> Dictionary:
	var run: Run = main.run
	run.dev_force = k
	main.cooldown = 0.0
	main.accelerate()
	var r: Dictionary = main.pending
	await until(func(): return main.mode != main.M.SPIN)
	return r

func chain_lines() -> Array:
	var out: Array = []
	if main.charms.chain.is_empty():
		return out
	for ln in main.charms.chain.lines:
		out.append(String(ln[0]) + "|" + String(ln[2]))
	return out

func console(relics: Array, devices := []) -> void:
	var run: Run = main.run
	run.relics = relics
	run.devices = devices
	run.inj = "fresh"
	main.player.position.x = Geo.CONSOLE_STAND - 60
	main.enter_console()
	await until(func(): return main.mode == main.M.CONSOLE)
	await frames(40)

func _go() -> void:
	await frames(5)
	var run: Run = main.run
	run.dev_roll = 0     # 带概率的都不中：错误答案不改写、硬币反面、保温杯不触发
	# —— 1 稳定修稿 ——
	await console(["tape_roll", "third_draft", "thermos"])
	await press(Odds.DETUNE)
	print("1a ", chain_lines())
	check(chain_lines() == ["抽取结果|射频失谐", "结果修改|胶带生效了，失谐结果改为稳定", "生效效果|第 1 次修改完成，本次倍率 ×1.1", "最终结果|保持稳定"], "稳定修稿 第一下")
	await frames(30)
	await snap("combo_1a")
	await frames(60)
	var c0: int = run.beam.charge
	await press(Odds.STABLE)
	print("1b ", chain_lines(), " charge ", c0, "→", run.beam.charge)
	check(run.beam.charge == c0 + Odds.CHARGE[Odds.STABLE] + 1, "稳定两次补 1 格充能")
	await frames(40)
	await snap("combo_1b")
	# 进入锁相，保温杯开始判
	run.beam.charge = run.lock_need() - 1
	await press(Odds.SUCCESS)
	check(run.beam.locked(), "进入锁相")
	await frames(80)
	await press(Odds.SUCCESS)
	print("1c ", chain_lines())
	await frames(60)
	# —— 2 拒稿反击 ——
	main.cooldown = 0.0
	main.e_guard = 0.0
	run.beam = null
	run.experiments_left = 3
	run.relics = ["rejected", "grad_promise", "wrong_answer"]
	run.inj = "fresh"
	main._new_beam()
	await frames(30)
	for i in 3:
		await press(Odds.DETUNE)
		print("2", i, " ", chain_lines())
		await frames(70)
	check(run.rejected_stacks == 3 and run.promise == 3, "怨气 3/3、承诺 3")
	await press(Odds.DETUNE)   # 第四次：怨气保持 3/3，承诺到 4
	await frames(20)
	await snap("combo_2a")
	await frames(60)
	var e0: int = run.beam.energy
	await press(Odds.SUCCESS)
	print("2s ", chain_lines(), " E ", e0, "→", run.beam.energy)
	check(run.beam.energy == e0 + Odds.DELTA[Odds.SUCCESS] + 3 and run.rejected_stacks == 0, "怨气爆发 +3")
	await frames(40)
	await snap("combo_2b")
	await frames(60)
	# —— 3 劫后再战 ——
	run.beam = null
	run.experiments_left = 3
	run.devices = ["beam_dump"]
	run.relics = ["coin", "reimburse", "lost_data"]
	run.best_potential = 0
	run.inj = "fresh"
	main._new_beam()
	await frames(30)
	run.beam.energy = 6
	main._sync()
	await frames(10)
	var r3: Dictionary = await press(Odds.LOSS)
	print("3 ", chain_lines(), " money ", r3.money)
	check(int(r3.money) == 12 + 8 and run.lost_charge_pending, "丢失：收集靶 $12 + 报销 $8、忘存的数据挂起")
	await frames(10)
	await snap("combo_3a")
	await frames(200)
	main.overlay.hide_card()
	run.inj = "fresh"
	main.mode = main.M.CONSOLE
	main._new_beam()
	check(run.inherited.size() == 1 and run.inherited[0][0] == "lost_data", "下一束继承充能来自忘存的数据")
	await frames(70)
	await snap("combo_3b")
	print("combo: ", "OK" if ok else "FAIL")
	quit(0)
