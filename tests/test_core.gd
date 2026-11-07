extends SceneTree
## 核心逻辑无界面测试：godot --headless --path . -s tests/test_core.gd

var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: ", msg)

func _initialize() -> void:
	# 概率和为 1、非负；锁相丢失为 0
	for e in range(1, Odds.EMAX + 1):
		for lk in [false, true]:
			var p := Odds.table(e, lk)
			var s := 0.0
			for v in p:
				check(v >= 0.0, "E%d 概率非负" % e)
				s += v
			check(absf(s - 1.0) < 1e-9, "E%d 概率和为1" % e)
			if lk:
				check(p[Odds.LOSS] == 0.0, "锁相丢失为0")
	check(absf(Odds.table(1)[Odds.LOSS] - 0.01) < 1e-9, "E1 丢失 1%")
	check(absf(Odds.table(9)[Odds.LOSS] - 0.16) < 1e-9, "E9 丢失 16%")
	check(Odds.value_at(1) == 40 and Odds.value_at(8) == 279 and Odds.value_at(10) == 487, "价值曲线")

	# 同种子可复现
	var a := Run.new(12345)
	var b := Run.new(12345)
	for i in 3:
		a.start_experiment(); b.start_experiment()
		for j in 6:
			if a.beam == null: break
			var ra := a.accelerate(); var rb := b.accelerate()
			check(ra.outcome == rb.outcome, "同种子结果一致")
		if a.beam != null: a.extract(); b.extract()
	check(a.total == b.total, "同种子总分一致")

	# 锁相：充能 6 → 4 次安全加速，每束一次
	var bm := Beam.new()
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var locks := 0
	var safe_presses := 0
	for i in 400:
		if not bm.alive: break
		var was := bm.locked()
		var r := bm.accelerate(rng)
		if r.lock_started: locks += 1
		if was:
			safe_presses += 1
			check(not r.lost, "锁相内不丢失")
	check(locks <= 1, "每束最多一次锁相")

	# 累计总分：一次大爆分可连过多关
	var run := Run.new(1)
	run.start_experiment()
	run.beam.energy = 16
	var fin := run.extract()
	check(fin.passed.size() == 3 and run.won(), "大爆分连过三关 (%d)" % Odds.value_at(16))
	# 用尽实验次数失败
	var r2 := Run.new(2)
	for i in 3:
		r2.start_experiment(); r2.extract()   # E1 只有 40
	check(r2.lost() and not r2.won(), "三次低分后失败")

	# 统计：期望次数与实际次数同步增长
	var r3 := Run.new(99)
	var n := 0
	while not r3.won() and not r3.lost() and n < 2000:
		if r3.beam == null: r3.start_experiment()
		if r3.beam.energy >= 9: r3.extract()
		else: r3.accelerate()
		n += 1
	var se := 0.0; var sa := 0
	for k in 5: se += r3.expected[k]; sa += r3.actual[k]
	check(absf(se - sa) < 1e-6, "期望次数总和=实际次数总和")

	print("core tests: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(1 if fails else 0)
