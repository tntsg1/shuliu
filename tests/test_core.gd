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

	# 提交规则：达标不自动过关；可主动提交；大爆分可连续提交多关
	var run := Run.new(1)
	run.start_experiment()
	run.beam.energy = 16
	run.extract()
	check(run.stage == 0 and run.experiments_left == 2, "达标不自动过关")
	check(run.can_submit() and not run.must_submit(), "够线可主动提交")
	var n_pass := 0
	while run.can_submit():
		var res := run.submit()
		if res.passed: n_pass += 1
	check(n_pass == 3 and run.won(), "大爆分连续提交三关 (%d)" % Odds.value_at(16))
	# 次数用完强制提交：不够线失败
	var r2 := Run.new(2)
	for i in 3:
		r2.start_experiment(); r2.extract()   # E1 只有 40
	check(r2.must_submit() and not r2.can_start(), "次数用完必须提交")
	var res2 := r2.submit()
	check(not res2.passed and r2.lost() and not r2.won(), "不够线提交失败")
	# 够线但不提交：继续做实验，分数带到下一阶段
	var r4 := Run.new(4)
	r4.start_experiment(); r4.beam.energy = 10; r4.extract()     # 487
	r4.start_experiment(); r4.beam.energy = 10; r4.extract()     # 974 ≥ 580
	r4.start_experiment(); r4.beam.energy = 10; r4.extract()     # 1461
	check(r4.must_submit(), "第三次后必须提交")
	r4.submit()
	check(r4.stage == 1 and r4.experiments_left == 3 and r4.can_submit(), "攒下的分可直接再交下一阶段")

	# 统计：期望次数与实际次数同步增长
	var r3 := Run.new(99)
	var n := 0
	while not r3.won() and not r3.lost() and n < 2000:
		if r3.beam == null and (r3.must_submit() or r3.can_submit()):
			r3.submit()
			continue
		if r3.beam == null: r3.start_experiment()
		if r3.beam.energy >= 9: r3.extract()
		else: r3.accelerate()
		n += 1
	var se := 0.0; var sa := 0
	for k in 5: se += r3.expected[k]; sa += r3.actual[k]
	check(absf(se - sa) < 1e-6, "期望次数总和=实际次数总和")

	print("core tests: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(1 if fails else 0)
