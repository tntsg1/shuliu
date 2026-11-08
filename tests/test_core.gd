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
	check(rs.slot_used("device") <= rs.slot_count("device") and rs.slot_used("relic") <= rs.slot_count("relic"), "槽位上限")
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
	run.total = Run.LINES[-1]
	var n_pass := 0
	while run.can_submit():
		var res := run.submit()
		if res.passed: n_pass += 1
	check(n_pass == Run.LINES.size() and run.won(), "攒够分连续提交全部 %d 关 (%d)" % [Run.LINES.size(), n_pass])
	# 无尽：通关后继续，线按 ENDLESS_G 增长，每 4 阶段一次大考
	run.go_endless()
	check(not run.won() and run.endless and run.plan_offers.size() == 3, "继续挑战进入无尽")
	check(run.line() == Run.line_at(8) and Run.line_at(8) > Run.LINES[-1] and Run.is_big(11) and not Run.is_big(8), "无尽考核线与大考")
	check(Run.is_big(3) and Run.is_big(7) and not Run.is_big(4), "第 4、8 阶段大考")
	# 次数用完强制提交：不够线失败
	var r2 := Run.new(2)
	for i in 3:
		r2.start_experiment(); r2.extract()   # E1 只有 40
	check(r2.must_submit() and not r2.can_start(), "次数用完必须提交")
	var res2 := r2.submit()
	check(not res2.passed and r2.lost() and not r2.won(), "不够线提交失败")
	# 够线但不提交：继续做实验，分数带到下一阶段
	var r4 := Run.new(4)
	r4.start_experiment(); r4.beam.energy = 12; r4.extract()     # 848 ×1.1
	r4.start_experiment(); r4.beam.energy = 12; r4.extract()     # ≥ 580
	r4.start_experiment(); r4.beam.energy = 12; r4.extract()     # ≥ 1800（第 2 阶段线）
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

	# —— M3 第 2 批：咖啡 / 钟表 ——
	var b2c := Run.new(51)
	b2c.relics.append("coffee_cup")
	check(b2c.lock_need() == 5, "咖啡杯：5 格锁相")
	var b2_locked := false
	for i in 300:
		b2c.beam = Beam.new(); b2c.beam.energy = 3; b2c.beam.charge = 4
		var r := b2c.accelerate()
		if r.outcome == Odds.SUCCESS:
			b2_locked = r.lock_started
			break
	check(b2_locked, "咖啡杯：4+1=5 格就锁相")
	# 保温杯：锁相次数有时不减
	var b2t := Run.new(52)
	b2t.relics.append("thermos")
	var kept := 0
	for i in 400:
		b2t.beam = Beam.new(); b2t.beam.energy = 4; b2t.beam.lock_left = 3; b2t.beam.lock_used = true
		b2t.accelerate()
		if b2t.beam != null and b2t.beam.lock_left == 3:
			kept += 1
	check(kept > 60 and kept < 160, "保温杯 25%% 不消耗（%d/400）" % kept)
	# 闹钟：第 7 次加速后进入 4 次锁相
	var b2a := Run.new(53)
	b2a.relics.append("alarm_4am")
	var fired_alarm := false
	for tries in 200:
		b2a.beam = Beam.new(); b2a.beam.energy = 2; b2a.beam.lock_used = true
		for i in 7:
			if b2a.beam == null: break
			b2a.beam.energy = 2
			var r := b2a.accelerate()
			if i < 6 and b2a.beam != null:
				check(not b2a.beam.alarm_used, "闹钟不早响")
			elif b2a.beam != null:
				fired_alarm = b2a.beam.alarm_used and b2a.beam.lock_left == 4
		if fired_alarm: break
	check(fired_alarm, "闹钟：第 7 次后 4 次锁相")

	# —— M3 第 3 批：文具 ——
	var b3 := Run.new(61)
	b3.relics.append("tape_roll")
	var tape_ok := false
	for i in 500:
		b3.beam = Beam.new(); b3.beam.energy = 9
		var r := b3.accelerate()
		if b3.beam != null and b3.beam.tape_used:
			tape_ok = r.outcome == Odds.STABLE
			break
	check(tape_ok, "胶带：第一次失谐改成保持稳定")
	var b3w := Run.new(62)
	b3w.relics.append("wipes")
	b3w.start_experiment(); b3w.beam.energy = 9
	check(absf(b3w.odds()[Odds.LOSS] - (Odds.table(9)[Odds.LOSS] - 0.06)) < 1e-9, "湿巾 -6pp")
	b3w.extract()
	check(not b3w.has("wipes"), "湿巾用完消失")
	var b3m := Run.new(63)
	b3m.relics.append("marker")
	b3m.start_experiment(); b3m.beam.energy = 5
	check(absf(b3m.multiplier() - 1.15) < 1e-9, "白板笔 +15%")
	b3m.beam.had_detune = true
	check(absf(b3m.multiplier() - 1.0) < 1e-9, "白板笔遇失谐失效")
	var b3b := Run.new(64)
	b3b.relics.append("bandaid")
	var conv := 0
	for i in 600:
		b3b.beam = Beam.new(); b3b.beam.energy = 4; b3b.beam.lock_left = 3; b3b.beam.lock_used = true
		var r := b3b.accelerate()
		for tg in r.triggers:
			if tg[0] == "bandaid" and tg[2].hit: conv += 1
	check(conv > 10, "创可贴锁相时转化稳定（%d）" % conv)

	# —— M3 第 4 批：证章 ——
	var b4 := Run.new(71)
	b4.relics.append("crooked_seal")
	b4.total = b4.line()
	b4.experiments_left = 0     # 束流用完再交（不算提前提交折的经费）
	var mm := b4.money
	var sr := b4.submit()
	check(sr.bonus == 30 and b4.money - mm == 30, "公章奖金 ×2")
	var b4f := Run.new(72)
	b4f.relics.append("red_flag")
	b4f.start_experiment()
	check(absf(b4f.multiplier() - 1.4) < 1e-9, "红旗 ×1.4")
	b4f.stage_had_loss = true
	check(absf(b4f.multiplier() - 1.0) < 1e-9, "红旗：丢过就没了")
	var b4d := Run.new(73)
	b4d.relics.append("dose_card")
	b4d.start_experiment(); b4d.beam.energy = 11
	check(b4d.odds()[Odds.PERFECT] > Odds.table(11)[Odds.PERFECT] + 0.059, "剂量卡 +6pp")
	var b4m := Run.new(74)
	b4m.relics.append("meal_card")
	var m0b := b4m.money
	check(b4m.on_shop_open() == 2 and b4m.money == m0b + 2, "饭卡 +$2")
	check(b4m.on_shop_open() == 0 and b4m.money == m0b + 2, "饭卡：反复开关商店不再给钱")
	b4m.start_experiment(); b4m.extract()
	check(b4m.on_shop_open() == 2, "饭卡：实验结束后再给一次")
	var rlk := Run.new(76)
	rlk.start_experiment()
	rlk.relics.append("lucky_cat")
	check(rlk.beam.route == "std" and Forms.of(rlk).route == "std", "路线注入时定，中途买饰品不换")
	var b4p := Run.new(75)
	b4p.relics.append("phd_cert")
	b4p.start_experiment(); b4p.experiments_left = 1
	check(absf(b4p.multiplier() - 2.0) < 1e-9, "博士证书：最后一次没够线 ×2")
	var b4g := Run.new(76)
	b4g.relics.append("grad_promise")
	b4g.dev_force = Odds.DETUNE
	b4g.start_experiment(); b4g.beam.energy = 4
	b4g.accelerate()
	check(b4g.promise == 1, "毕业承诺：失谐攒 1 次")
	b4g.beam.charge = 5
	b4g.dev_force = Odds.SUCCESS
	var rg := b4g.accelerate()
	check(rg.lock_started and b4g.beam.lock_left == Odds.LOCK_PRESSES + 1 and b4g.promise == 0, "毕业承诺：锁相 +1 后清零")
	var b4l := Run.new(77)
	b4l.relics.append("rec_letter")
	b4l.dev_roll = 1
	b4l.start_experiment(); b4l.beam.energy = 6
	var pot4 := b4l.potential()
	var t4 := b4l.total
	var fin4 := b4l.extract()
	check(b4l.total - t4 == int(floor(pot4 * 1.5)) and not fin4.triggers.is_empty(), "推荐信必中 +50%")
	b4l.start_experiment(); b4l.beam.energy = 6
	check(b4l.extract().triggers.is_empty(), "推荐信本阶段只一次")

	# —— M3 第 5 批：金属 ——
	var b5 := Run.new(81)
	b5.relics.append("wrench")
	check(b5.slot_count("device") == Items.device_slots(0) + 1, "扳手：设备槽 +1")
	b5.relics = ["coin", "eraser", "screw"]
	check(b5.slot_used("relic") == 2 and b5.slots_free("relic", "screw"), "螺丝不占槽")
	var b5e := Run.new(82)
	b5e.relics.append("extinguisher")
	b5e.dev_force = Odds.LOSS
	b5e.start_experiment(); b5e.beam.energy = 5
	var re5 := b5e.accelerate()
	check(re5.outcome == Odds.STABLE and re5.raw == Odds.LOSS, "灭火器：能级 ≤6 丢失 → 稳定")
	b5e.dev_force = Odds.LOSS
	check(b5e.accelerate().lost, "灭火器：本阶段只一次")
	var b5d := Run.new(83)
	b5d.devices.append("beam_dump")
	b5d.dev_force = Odds.LOSS
	b5d.start_experiment(); b5d.beam.energy = 7
	var m5 := b5d.money
	var rd5 := b5d.accelerate()
	check(rd5.money >= 14, "收集靶返还 能级×2")
	var b5r := Run.new(84)
	b5r.devices.append("rf_cavity")
	b5r.dev_force = Odds.PERFECT
	b5r.start_experiment(); b5r.beam.energy = 3
	b5r.accelerate()
	check(b5r.beam.energy == 6, "射频腔：完美 +3")
	var b5c := Run.new(85)
	b5c.devices.append("cryo_magnet")
	b5c.start_experiment(); b5c.beam.energy = 11
	check(absf(b5c.odds()[Odds.LOSS] - (Odds.table(11)[Odds.LOSS] - 0.08)) < 1e-9, "低温磁体 -8pp")
	var b5k := Run.new(86)
	b5k.relics.append("lab8_key")
	var free_n := 0
	for i in 300:
		b5k.roll_shop()
		for o in b5k.offers:
			if o.get("free", false): free_n += 1
	check(free_n > 10 and free_n < 60, "钥匙 10%% 免费（%d/300）" % free_n)

	# —— M3 第 6 批：电子 ——
	var b6 := Run.new(91)
	b6.relics.append("emergency_call")
	b6.dev_force = Odds.LOSS
	b6.start_experiment(); b6.beam.energy = 12
	var r6 := b6.accelerate()
	check(r6.outcome == Odds.STABLE and b6.beam != null, "紧急电话：挡住丢失")
	check(b6.accelerate().lost, "紧急电话：本阶段只一次")
	var b6p := Run.new(92)
	b6p.devices.append("protect_sys")
	b6p.dev_force = Odds.LOSS
	b6p.start_experiment(); b6p.beam.energy = 8
	var pot6 := b6p.potential()
	check(b6p.accelerate().salvaged == int(floor(pot6 * 0.3)), "保护系统保住 30%")
	var b6r := Run.new(93)
	b6r.relics.append("printer")
	b6r.money = 100
	b6r.refresh(); b6r.refresh()
	check(b6r.refresh_cost == Run.REFRESH_BASE, "打印机：刷新不翻倍")
	var b6c := Run.new(94)
	b6c.devices.append("calorimeter")
	b6c.start_experiment(); b6c.beam.energy = 8
	check(absf(b6c.multiplier() - 1.6 * 1.1) < 1e-9, "量能器 ×1.6（E8 成形 +10%）")
	# —— 束流形态 ——
	check(Forms.tier_of(6) == 0 and Forms.tier_of(7) == 1 and Forms.tier_of(13) == 2, "形态档：E7 成形、E13 成熟")
	check(Forms.route_of([]) == "std" and Forms.route_of(["coin", "magnet_sc"]) == "std", "没有纸张/吉祥物走标准")
	check(Forms.route_of(["note100", "lucky_cat", "plant"]) == "mascot", "持有最多的标签决定路线")
	check(Forms.route_of(["note100", "lucky_cat"]) == "mascot" and Forms.route_of(["lucky_cat", "note100"]) == "paper", "并列取最近买的")
	check(Forms.legend_of(15, []).is_empty() and Forms.legend_of(16, []).id == "blackhole", "黑洞 E16")
	check(Forms.legend_of(20, []).id == "bigbang" and Forms.legend_of(20, ["lab8_key"]).id == "door" and Forms.legend_of(25, ["lab8_key"]).id == "foil", "传说优先级")
	check(Forms.omen(13, 13, []) > 0.0 and Forms.omen(11, 11, []) == 0.0, "接近 E16 有预兆")
	var fd := Forms.describe("paper", 6, 13, ["saved"], {})
	check(fd.name == "劫后余生的论文风暴" and fd.damaged and fd.bonus == 0.0, "掉档不退化、受损、加成按当前档")
	var ld := Forms.describe("mascot", 16, 16, [], Forms.legend_of(16, []))
	check(ld.name == "黑洞（别担心）" and ld.from == "由橘猫束流演化而来" and ld.rank == "传说", "传说保留来路")
	var fr := Run.new(3)
	fr.start_experiment()
	fr.dev_force = Odds.PERFECT
	for i in 5: fr.accelerate()
	fr.dev_force = Odds.DETUNE
	fr.accelerate()
	check(fr.beam.peak == 11 and fr.beam.energy == 10, "峰值记录")
	fr.dev_force = Odds.LOSS
	fr.relics.append("coin"); fr.dev_roll = 1
	fr.accelerate()
	check(fr.beam != null and fr.beam.saved and Forms.of(fr).name.begins_with("劫后余生的"), "硬币救回 → 劫后余生")
	var b6d := Run.new(95)
	b6d.devices.append("daq")
	b6d.start_experiment(); b6d.beam.streak = 30
	check(absf(b6d.multiplier() - 1.6) < 1e-9, "数据采集器上限 +60%")
	var b6l := Run.new(96)
	b6l.devices.append("lock_loop")
	b6l.dev_force = Odds.SUCCESS
	b6l.start_experiment(); b6l.beam.charge = 5
	b6l.accelerate()
	check(b6l.beam.lock_left == Odds.LOCK_PRESSES + 1, "反馈回路 锁相 +1")
	var b6b := Run.new(97)
	b6b.devices.append("bpm")
	b6b.start_experiment(); b6b.beam.energy = 5
	var base5 := Odds.table(5)
	check(absf(b6b.odds()[Odds.STABLE] - base5[Odds.STABLE] * 0.5) < 1e-9, "位置监测器：稳定减半")
	var b6x := Run.new(98)
	b6x.relics.append("red_button")
	b6x.start_experiment(); b6x.beam.energy = 5
	var seen := {}
	for i in 400:
		b6x.beam = Beam.new(); b6x.beam.energy = 5
		var rr6 := b6x.press_red()
		seen[rr6.pick] = seen.get(rr6.pick, 0) + 1
		check(not b6x.can_press_red() or b6x.beam == null, "红按钮每束一次")
		b6x.relics = ["red_button"]
		b6x.experiments_left = 3
	check(seen.size() == 4 and seen[2] > 100 and seen[2] < 180, "红按钮四种结果（丢失 %d/400）" % seen.get(2, 0))

	# —— M3 第 7 批：书籍 / 吉祥物 ——
	var b7 := Run.new(101)
	b7.relics.append("schrodinger")
	b7.dev_force = Odds.LOSS
	b7.start_experiment(); b7.beam.energy = 9
	var r7 := b7.accelerate()
	check(r7.get("sch", false) and b7.beam != null and b7.beam.sch_pending, "薛定谔：丢失进入待定")
	var pot7 := b7.potential()
	var t7 := b7.total
	b7.sch_end()
	check(b7.total - t7 == int(floor(pot7 * 0.3)) and b7.beam == null, "薛定谔：结束保留 30%")
	var b7g := Run.new(102)
	b7g.relics.append("schrodinger")
	b7g.dev_force = Odds.LOSS
	b7g.start_experiment(); b7g.beam.energy = 9
	b7g.accelerate()
	b7g.beam.sch_gamble = true
	b7g.dev_force = Odds.SUCCESS
	var rg7 := b7g.accelerate()
	check(not rg7.lost and b7g.beam.energy == 10, "薛定谔：赌赢继续")
	var b7f := Run.new(103)
	b7f.relics.append("schrodinger")
	b7f.relics.append("dean_paper")
	b7f.dev_force = Odds.LOSS
	b7f.start_experiment(); b7f.beam.energy = 9
	b7f.accelerate()
	b7f.beam.sch_gamble = true
	b7f.dev_force = Odds.STABLE
	var rf7 := b7f.accelerate()
	check(rf7.lost and rf7.salvaged == 0, "薛定谔：赌输全部归零（稿纸也救不了）")
	var b7c := Run.new(104)
	b7c.relics.append("lab_cat")
	b7c.dev_force = Odds.LOSS
	b7c.dev_roll = 1
	b7c.start_experiment(); b7c.beam.energy = 6
	check(b7c.accelerate().outcome == Odds.PERFECT, "猫：丢失 → 完美同步")
	var b7i := Run.new(105)
	b7i.relics.append("impossible")
	b7i.dev_force = Odds.PERFECT
	b7i.start_experiment(); b7i.beam.energy = 14
	b7i.accelerate()
	check(b7i.beam.imp_mult == 5.0, "结果不可能 ×5")
	var b7p := Run.new(106)
	b7p.relics.append("plant")
	b7p.total = b7p.line()
	check(b7p.submit().bonus == 21, "盆栽 +$6")

	# —— 科研计划书 ——
	var pl := Run.new(111)
	pl.total = pl.line()
	pl.submit()
	check(pl.plan_offers.size() == 3 and pl.plan == "", "过阶段发三份计划书")
	var l0 := pl.line()
	pl.choose_plan("collab")
	check(pl.plan == "collab" and pl.line() == int(ceil(l0 * 1.1)) and pl.plan_offers.is_empty(), "横向合作：线 +10%")
	var pl2 := Run.new(112)
	pl2.money = 80
	pl2.choose_plan("audit")
	check(pl2.money == 40, "经费审计：失去一半")
	pl2.total = pl2.line()
	check(pl2.submit().bonus == 45, "经费审计：奖金 ×3")
	var pl3 := Run.new(113)
	pl3.choose_plan("lock_rush")
	check(pl3.lock_need() == 4, "锁相攻关：4 格")
	var pl4 := Run.new(114)
	pl4.choose_plan("night_shift")
	check(pl4.experiments_left == 4, "夜班：多 1 束")
	var pl5 := Run.new(115)
	pl5.choose_plan("equip_renew")
	pl5.roll_shop()
	for o in pl5.offers:
		var base: int = Items.ALL[o.id].price
		var want := int(ceil(base * (0.7 if Items.ALL[o.id].kind == "device" else 1.2)))
		check(o.price == want or o.get("free", false) or o == pl5.offers[0], "设备更新计划：价格")
	var pl6 := Run.new(116)
	pl6.choose_plan("safety")
	pl6.dev_force = Odds.LOSS
	pl6.start_experiment(); pl6.beam.energy = 8
	var pot_s := pl6.potential()
	check(pl6.accelerate().salvaged == int(floor(pot_s * 0.5)), "安全整改：保留 50%")

	print("core tests: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(1 if fails else 0)
