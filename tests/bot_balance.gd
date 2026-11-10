extends SceneTree
## 平衡机器人：直接跑真实 Run 规则（饰品、计划书、形态加成、提前提交、达标后丢失扣分），统计各阶段通过率。
## 用法：godot --headless --path . -s tests/bot_balance.gd [-- n=2000 lines=580,1410,...]
## 策略：
##   T      目标能级：到了就引出（锁相中不停）
##   push   最后一束还不够线时，多按到够线为止（最多 T+3）
##   early  够线就立刻提交（剩余束流折经费）；否则用完全部束流
##   shop   每次能买就买（随机顺序，槽满就不买）

var N := 2000
var only: PackedStringArray = []
var skip_plans := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv[0] == "n":
			N = int(kv[1])
		elif kv[0] == "pay":
			Run.LEFTOVER_PAY = int(kv[1])
		elif kv[0] == "step":
			Run.LEFTOVER_STEP = int(kv[1])
		elif kv[0] == "tax":
			Run.OVERLINE_TAX = float(kv[1])
		elif kv[0] == "lines":
			Run.LINES = Array(kv[1].split(",")).map(func(x): return int(x))
		elif kv[0] == "g":
			Odds.GROWTH = float(kv[1])
		elif kv[0] == "pols":
			only = kv[1].split(",")
		elif kv[0] == "plans":
			skip_plans = kv[1] == "skip"
	var pols := [
		{"name": "智能 E10 + 柜子", "T": 10, "early": false, "smart": true, "shop": true, "cab": true},
		{"name": "标准 E10 用满 + 柜子", "T": 10, "early": false, "shop": true, "cab": true},
		{"name": "稳健 E4 早交", "T": 4, "early": true, "shop": true},
		{"name": "标准 E5 用满", "T": 5, "early": false, "shop": true},
		{"name": "智能 E6", "T": 6, "early": false, "smart": true, "shop": true},
		{"name": "不买东西 E5", "T": 5, "early": false, "shop": false},
		{"name": "稳健 E8 早交", "T": 8, "early": true, "shop": true},
		{"name": "标准 E10 早交", "T": 10, "early": true, "shop": true},
		{"name": "标准 E10 用满", "T": 10, "early": false, "shop": true},
		{"name": "贪 E12 早交", "T": 12, "early": true, "shop": true},
		{"name": "不买东西 E10", "T": 10, "early": false, "shop": false},
		{"name": "智能 E10", "T": 10, "early": false, "smart": true, "shop": true},
		{"name": "智能 E12", "T": 12, "early": false, "smart": true, "shop": true},
		{"name": "组合 稳定修稿 E10", "T": 10, "early": false, "smart": true, "shop": true, "cab": true, "combo": 0},
		{"name": "组合 拒稿反击 E10", "T": 10, "early": false, "smart": true, "shop": true, "cab": true, "combo": 1},
		{"name": "组合 劫后再战 E10", "T": 10, "early": false, "smart": true, "shop": true, "cab": true, "combo": 2},
	]
	print("考核线: ", Run.LINES, "  成长 ×", Odds.GROWTH)
	print("科研计划：", "全部跳过" if skip_plans else "随机选择")
	print("剩余束流折 $%d + 阶段×%d，达标后丢失扣 %d%%" % [Run.LEFTOVER_PAY, Run.LEFTOVER_STEP, int(Run.OVERLINE_TAX * 100)])
	for i in pols.size():
		if only.is_empty() or str(i) in only:
			_report(pols[i], _sim(pols[i]))
	quit(0)

func _report(pol: Dictionary, r: Dictionary) -> void:
	var line := "%-14s" % pol.name
	for s in Run.LINES.size():
		line += " %4.0f%%" % (100.0 * r.reach[s + 1] / N)
	line += "  | 通关 %4.1f%%  均分到第 %.2f 阶段  每束均值 %s  丢失率 %.0f%%  扣分次数/局 %.2f  早交/局 %.2f" % [
		100.0 * r.reach[Run.LINES.size()] / N, r.stages / N, _fmt(r.val / maxf(1.0, r.beams)), 100.0 * r.losses / maxf(1.0, r.beams), r.taxes / float(N), r.early / float(N)]
	print(line)
	var st := "    各阶段末平均累计 / 线："
	for s in Run.LINES.size():
		if r.cnt[s] > 0:
			st += " %s/%s" % [_fmt(r.tot[s] / r.cnt[s]), _fmt(Run.LINES[s])]
	print(st)

func _fmt(v: float) -> String:
	return str(int(v))

func _sim(pol: Dictionary) -> Dictionary:
	var reach := []
	reach.resize(Run.LINES.size() + 1)
	reach.fill(0)
	var tot := []
	tot.resize(Run.LINES.size())
	tot.fill(0.0)
	var cnt := []
	cnt.resize(Run.LINES.size())
	cnt.fill(0)
	var r := {"reach": reach, "stages": 0.0, "val": 0.0, "beams": 0, "losses": 0, "taxes": 0, "early": 0, "tot": tot, "cnt": cnt}
	var pick := RandomNumberGenerator.new()
	pick.seed = 99
	for i in N:
		var run := Run.new(1000 + i * 7919)
		var rv := {"sum": 0, "n": 0, "lost": 0}
		while not run.won() and not run.failed:
			if not run.plan_offers.is_empty():
				run.choose_plan("" if skip_plans else run.plan_offers[pick.randi() % run.plan_offers.size()])
			if pol.shop:
				_shop(run, pick, pol)
			var go_now: bool = pol.early or run.experiments_left <= 0
			if pol.get("smart", false) and run.can_submit() and run.experiments_left > 0:
				# 算账：再做一束的期望收益 vs 丢了被扣的分（按本局已做束流的平均收益和丢失率估）
				var mean: float = float(rv.sum) / maxf(1.0, rv.n) if rv.n >= 2 else 1e9
				var pl: float = float(rv.lost) / maxf(1.0, rv.n) if rv.n >= 4 else 0.2
				go_now = mean < pl * run.overline_tax()
			if run.can_submit() and go_now:
				if run.experiments_left > 0:
					r.early += 1
				_submit(run, r)
				continue
			if run.must_submit():
				_submit(run, r)
				continue
			if pol.get("cab", false) and run.total >= run.line():
				# 储备柜（Q70）：够线后把篮子里最大的瓶子存进柜子，压到线下，再丢也不扣分；提交前再放回去
				while run.cab.size() < Run.CAB_SLOTS and not run.basket.is_empty() and run.total >= run.line():
					var bi := 0
					for k in run.basket.size():
						if int(run.basket[k].value) > int(run.basket[bi].value):
							bi = k
					run.take_from_basket(bi)
					run.store_in_cab()
			run.start_experiment()
			run.on_shop_open()
			var last: bool = run.experiments_left == 1
			while run.beam != null:
				var b := run.beam
				if b.sch_pending:
					run.sch_end()
					break
				var need: int = run.line() - run.total
				var stop: bool = b.energy >= int(pol.T) and not b.locked()
				if last and run.potential() < need and b.energy < pol.T + 3:
					stop = false
				if pol.get("push", true) and last and run.potential() >= need and need > 0 and not b.locked() and b.energy >= 6:
					stop = true
				if stop:
					var f := run.extract()
					rv.sum += f.gained
					rv.n += 1
					r.val += f.gained
					r.beams += 1
					break
				var res := run.accelerate()
				if res.get("tax", 0) > 0:
					r.taxes += 1
				if res.lost and not res.get("sch", false):
					rv.n += 1
					rv.lost += 1
					rv.sum += res.get("salvaged", 0)
					r.losses += 1
					r.beams += 1
		r.stages += run.stage
		reach[mini(run.stage, Run.LINES.size())] += 0
		for s in run.stage + 1:
			if s <= Run.LINES.size():
				pass
		for s in mini(run.stage, Run.LINES.size()) + 1:
			reach[s] += 1 if s > 0 else 0
	return r

func _submit(run: Run, r: Dictionary) -> void:
	while not run.cab.is_empty():
		run.take_from_cab()
		run.put_in_basket()
	var s := run.stage
	r.tot[s] += run.total
	r.cnt[s] += 1
	run.submit()

func _shop(run: Run, pick: RandomNumberGenerator, pol := {}) -> void:
	var order := range(run.offers.size())
	for i in order.size():
		var j := pick.randi() % order.size()
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	# 追组合（Q75）：只买某套组合 c 里的饰品（设备照买），先买组合件
	if pol.has("combo"):
		var ids: Array = Items.COMBOS[pol.combo].ids
		order = order.filter(func(i): return ids.has(run.offers[i].id) or Items.ALL[run.offers[i].id].kind == "device")
		order.sort_custom(func(a, b): return ids.has(run.offers[a].id) and not ids.has(run.offers[b].id))
	for i in order:
		var o: Dictionary = run.offers[i]
		if o.sold:
			continue
		run.buy(i)
