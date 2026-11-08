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
				check(p[Odds.SUPER] > 0.04, "锁相有超级同步 E%d" % e)
			else:
				check(p[Odds.SUPER] == 0.0, "非锁相没有超级同步")
	check(absf(Odds.super_chance(5) - 0.06) < 1e-9 and absf(Odds.super_chance(13) - 0.15) < 1e-9, "超级同步随能级升高")
	# 超级同步：+3 能级，只在锁相时抽到
	var rsu := Run.new(777)
	var got_super := 0
	for i in 4000:
		rsu.beam = Beam.new()
		rsu.beam.energy = 6
		rsu.beam.lock_left = 4 if i % 2 == 0 else 0
		var lk2 := rsu.beam.locked()
		var r0 := rsu.accelerate()
		if r0.outcome == Odds.SUPER:
			got_super += 1
			check(lk2, "超级同步只在锁相出现")
			check(r0.to == 9, "超级同步 +3 能级")
	check(got_super > 60 and got_super < 220, "锁相超级同步频率合理 %d" % got_super)
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
	var rl := Run.new(7)
	rl.start_experiment()
	var locks := 0
	for i in 400:
		if rl.beam == null: break
		var was := rl.beam.locked()
		var r := rl.accelerate()
		if r.lock_started: locks += 1
		if was:
			check(not r.lost, "锁相内不丢失")
	check(locks <= 1, "每束最多一次锁相")

	# —— 概率分配器：任意修正都保持非负、总和 1 ——
	var rr := RandomNumberGenerator.new(); rr.seed = 3
	for i in 500:
		var base := Odds.table(rr.randi_range(1, 20))
		var d := PackedFloat64Array()
		for k in Odds.N: d.append(rr.randf_range(-0.3, 0.3) if rr.randf() < 0.5 else 0.0)
		var q := Odds.apply_mods(base, d)
		var sq := 0.0
		for v in q:
			check(v >= -1e-12, "修正后非负")
			sq += v
		check(absf(sq - 1.0) < 1e-9, "修正后和为 1")
	# 超导磁铁：E9 丢失 16% → 11%
	var rm := Run.new(5)
	rm.devices.append("magnet_sc")
	rm.start_experiment(); rm.beam.energy = 9
	check(absf(rm.odds()[Odds.LOSS] - 0.11) < 1e-9, "超导磁铁 -5pp (%f)" % rm.odds()[Odds.LOSS])
	# 导师的最后通牒：前 3 次必定至少成功；第 4 次起丢失 +10pp
	for sd in 30:
		var ru := Run.new(100 + sd)
		ru.relics.append("ultimatum")
		ru.start_experiment(); ru.beam.energy = 12
		for i in 3:
			var r := ru.accelerate()
			check(r.outcome == Odds.SUCCESS or r.outcome == Odds.PERFECT, "通牒保底")
		if ru.beam != null:
			var before := Odds.table(ru.beam.energy)[Odds.LOSS]
			check(ru.odds()[Odds.LOSS] > before + 0.09, "通牒第 4 次起 +10pp")
	# 橡皮：3 次后消失
	var re := Run.new(11)
	re.relics.append("eraser"); re.uses["eraser"] = 3
	var ne := 0
	while re.has("eraser") and ne < 3000:
		if re.beam == null:
			if re.experiments_left <= 0: re.experiments_left = 3
			re.start_experiment()
		re.beam.energy = 5
		re.accelerate()
		ne += 1
	check(not re.has("eraser"), "橡皮用完消失")
	# 稿纸：丢失时保留 80%，每局一次
	var rp := Run.new(21)
	rp.relics.append("dean_paper")
	rp.start_experiment()
	var got := {}
	for i in 200:
		rp.beam.energy = 18
		var pot := rp.potential()
		var r := rp.accelerate()
		if r.lost:
			got = r
			check(r.salvaged == int(floor(pot * 0.8)) and rp.total == r.salvaged, "稿纸抢救 80%")
			break
	check(not got.is_empty() and rp.paper_used, "稿纸触发")
	# 签名笔：本阶段首次引出 ×3，之后 ×0.8
	var rpn := Run.new(31)
	rpn.relics.append("dean_pen")
	rpn.start_experiment(); rpn.beam.energy = 5
	check(rpn.potential() == int(floor(Odds.value_at(5) * 3.0)), "签名笔 ×3")
	rpn.extract()
	rpn.start_experiment(); rpn.beam.energy = 5
	check(rpn.potential() == int(floor(Odds.value_at(5) * 0.8)), "签名笔之后 ×0.8")
	# 商店：买、槽位上限、卖出半价、经费不够
	var rs := Run.new(41)
	rs.money = 1000
	var bought := 0
	for i in rs.offers.size():
		if rs.buy(i) == "": bought += 1
	check(rs.devices.size() <= Items.device_slots(0) and rs.relics.size() <= Items.relic_slots(0), "槽位上限")
	var any_id: String = (rs.relics + rs.devices)[0]
	var m0 := rs.money
	rs.sell(any_id)
	check(rs.money == m0 + Items.sell_price(any_id) and not rs.has(any_id), "卖出半价")
	var rpoor := Run.new(42); rpoor.money = 0
	check(rpoor.buy(0) == "经费不够", "经费不够")
	# 商店随机不影响实验随机：刷不刷新，结果序列相同
	var x1 := Run.new(77); var x2 := Run.new(77)
	x2.money = 100; x2.refresh(); x2.refresh()
	x1.start_experiment(); x2.start_experiment()
	for i in 8:
		if x1.beam == null or x2.beam == null: break
		check(x1.accelerate().outcome == x2.accelerate().outcome, "商店不扰动实验随机")

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
	for k in Odds.N: se += r3.expected[k]; sa += r3.actual[k]
	check(absf(se - sa) < 1e-6, "期望次数总和=实际次数总和")

	# —— M3 第 1 批：纸张 ——
	var m3_rd := Run.new(41)
	m3_rd.relics.append("duty_roster")
	m3_rd.start_experiment(); m3_rd.beam.energy = 9
	var m3_base9 := Odds.table(9)
	check(m3_rd.odds()[Odds.SUCCESS] > m3_base9[Odds.SUCCESS] + 0.149, "值班表第一次 +15pp")
	m3_rd.beam.presses = 1
	check(absf(m3_rd.odds()[Odds.SUCCESS] - m3_base9[Odds.SUCCESS]) < 1e-9, "值班表只管第一次")
	# 第三版修改稿：保持稳定 +0.1 倍率，最多 1.0
	var m3_rt := Run.new(42)
	m3_rt.relics.append("third_draft")
	m3_rt.start_experiment()
	for i in 400:
		if m3_rt.beam == null:
			m3_rt.beam = Beam.new()
		m3_rt.beam.energy = 3
		m3_rt.accelerate()
		if m3_rt.beam != null:
			check(m3_rt.beam.draft <= 1.0 + 1e-9, "修改稿上限 1.0")
	# 报销单：丢失 +$8
	var m3_rb := Run.new(43)
	m3_rb.relics.append("reimburse")
	var m3_lost_n := 0
	for i in 300:
		m3_rb.beam = Beam.new(); m3_rb.beam.energy = 16
		var mb0 := m3_rb.money
		var m3_r := m3_rb.accelerate()
		if m3_r.lost:
			m3_lost_n += 1
			check(m3_rb.money - mb0 >= 8, "报销单丢失 +$8")
	check(m3_lost_n > 0, "报销单测到了丢失")
	# 申报书：第一件半价
	var m3_ra := Run.new(44)
	m3_ra.relics.append("applications")
	m3_ra.roll_shop()
	var m3_o0: Dictionary = m3_ra.offers[0]
	check(m3_o0.price == int(ceil(Items.ALL[m3_o0.id].price * 0.5)), "申报书第一件半价")
	check(m3_ra.offers[1].price == Items.ALL[m3_ra.offers[1].id].price, "申报书只管第一件")
	# 校准记录：首次锁相升级为完全同步（无稳定/失谐）
	var m3_rc := Run.new(45)
	m3_rc.relics.append("calib_log")
	m3_rc.start_experiment()
	m3_rc.beam.energy = 6; m3_rc.beam.charge = 5
	var m3_guard := 0
	while m3_rc.beam != null and not m3_rc.beam.locked() and m3_guard < 200:
		m3_rc.beam.energy = 6
		m3_rc.accelerate()
		m3_guard += 1
	if m3_rc.beam != null and m3_rc.beam.locked():
		check(m3_rc.beam.full_sync, "校准记录：完全同步")
		var m3_q := m3_rc.odds()
		check(m3_q[Odds.STABLE] == 0.0 and m3_q[Odds.DETUNE] == 0.0 and m3_q[Odds.LOSS] == 0.0, "完全同步只剩成功类")
	# 诺奖名单：E12 锁相时超级同步翻倍
	var m3_rn := Run.new(46)
	m3_rn.start_experiment(); m3_rn.beam.energy = 13; m3_rn.beam.lock_left = 3
	var m3_s1 := m3_rn.odds()[Odds.SUPER]
	m3_rn.relics.append("nobel_list")
	check(absf(m3_rn.odds()[Odds.SUPER] - m3_s1 * 2.0) < 1e-9, "诺奖名单超级同步翻倍")
	# 忘记保存的数据：最高潜在成果时丢失 → 下次引出 +15%
	var m3_rl := Run.new(47)
	m3_rl.relics.append("lost_data")
	var m3_bonus_seen := false
	for i in 400:
		m3_rl.beam = Beam.new(); m3_rl.beam.energy = 15
		m3_rl.best_potential = 0
		var m3_r := m3_rl.accelerate()
		if m3_r.lost and m3_rl.lost_bonus > 0:
			m3_bonus_seen = true
			var m3_lb := m3_rl.lost_bonus
			m3_rl.beam = Beam.new()
			var m3_pot := m3_rl.potential()
			var m3_t0 := m3_rl.total
			m3_rl.extract()
			check(m3_rl.total - m3_t0 == m3_pot + m3_lb, "忘记保存的数据：下次引出加上")
			break
	check(m3_bonus_seen, "忘记保存的数据触发")

	print("core tests: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(1 if fails else 0)
