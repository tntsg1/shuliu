extends SceneTree
## M5b：楼上教授办公室（爬梯子）、书架借阅、课题组合同、挑战合同的规则与界面
var main: Node
var ok := true

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/"))
	Meta.reset_for_test()
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

func check(c: bool, what: String) -> void:
	print("  ", "ok   " if c else "FAIL ", what)
	if not c:
		ok = false

func _rules() -> void:
	# 课题组
	var r := Run.new(3)
	check(r.sign_group("theory") == "" and r.money == 15 and r.has("note100"), "理论组：$15 + 便利贴")
	check(r.sign_group("finance") == "" and r.money == 60 and not r.has("note100"), "改签财务组：退回理论组配置，$60")
	r.beam = null
	r.start_experiment()
	check(r.odds()[Odds.LOSS] > 0.0 and r.sign_group("base") != "", "财务组：实验开始后不能改签")
	var p := Run.new(4)
	p.sign_group("postdoc")
	check(p.experiments_left == 4 and p.per_stage() == 4 and p.line() == int(ceil(150 * 1.25)), "博士后：4 瓶、考核线 ×1.25")
	var e := Run.new(5)
	var d0 := e.slot_count("device")
	var r0 := e.slot_count("relic")
	e.sign_group("engineering")
	check(e.slot_count("device") == d0 + 1 and e.slot_count("relic") == r0 - 1, "工程组：设备槽 +1、饰品槽 −1")
	# 挑战合同
	var c := Run.new(6)
	c.challenge_offers = Contracts.CHALLENGES.keys()
	c.money = 999
	c.sign_challenge("devices_only")
	c.offers = [{"id": "koi", "sold": false, "price": 10}, {"id": "magnet_sc", "sold": false, "price": 10}]
	check(c.buy(0) != "" and c.buy(1) == "", "只买设备：饰品买不了，设备能买")
	c.sign_challenge("no_refresh")
	check(not c.refresh(), "不许刷新")
	c.sign_challenge("no_cab")
	c.held = "full"
	c.held_bt = {"value": 5, "energy": 3}
	check(c.store_in_cab() != "", "储备柜封存")
	c.held = ""
	c.sign_challenge("zero_money")
	check(c.money == 0, "零经费：经费清零")
	c.sign_challenge("")
	check(c.money > 900, "改成不签：零经费收走的钱退回")
	c.sign_challenge("one_relic")
	check(c.slot_count("relic") == 1, "一件护身符：槽位 1")
	var n := Run.new(7)
	n.challenge_offers = Contracts.CHALLENGES.keys()
	n.sign_challenge("no_early")
	n.total = 9999
	check(not n.can_submit(), "不许早交：瓶子没用完不能交")
	n.experiments_left = 0
	check(n.can_submit(), "不许早交：用完就能交")
	var l := Run.new(8)
	l.challenge_offers = Contracts.CHALLENGES.keys()
	l.sign_challenge("no_lock")
	l.start_experiment()
	for i in 10:
		l.dev_force = Odds.PERFECT
		l.accelerate()
	check(not l.beam.locked() and l.beam.charge == 0, "不许锁相：完美同步十次也不进锁相")
	var m := Run.new(9)
	m.challenge_offers = Contracts.CHALLENGES.keys()
	m.sign_challenge("min_e8")
	m.start_experiment()
	check(not m.can_extract(), "E8 起步：E1 不能引出")
	m.beam.energy = 8
	check(m.can_extract(), "E8 起步：E8 能引出")
	# 声望倍数 + 课题组解锁
	var s := Run.new(10)
	s.challenge_offers = Contracts.CHALLENGES.keys()
	s.sign_challenge("one_relic")
	s.stage = 2
	s.failed = true
	s.spent = 320
	var st := Meta.settle(s)
	check(st.gain == int(round(45 * 1.6)) and st.opened.has("group:finance"), "一件护身符 ×1.6 声望；花满 $300 解锁财务组")

func _go() -> void:
	await frames(5)
	_rules()
	var run: Run = main.run
	main.player.position.x = Geo.LADDER_X + 8
	await frames(40)
	await snap("m5b_01_ladder_locked")
	main._spot_do("ladder")
	await frames(5)
	check(not main.upstairs(), "办公室没开放爬不上去")
	# 通过第 5 阶段：办公室开放
	var r5 := Run.new(12)
	r5.stage = 5
	r5.failed = true
	Meta.settle(r5)
	check(Meta.get_v("office_open", false), "通过第 5 阶段：办公室开放")
	Meta.d.prestige = 260
	main.player.position.x = Geo.LADDER_X + 8
	main._spot_do("ladder")
	await frames(50)
	await snap("m5b_02_climbing")
	await create_timer(1.6).timeout
	check(main.upstairs() and absf(main.player.position.y - Geo.O_FLOOR) < 1.0, "爬到办公室")
	await frames(60)
	await snap("m5b_03_office")
	# 书架
	main.player.position.x = 700
	await frames(3)
	check(main._spot() == "shelf", "站在书架前")
	main._spot_do("shelf")
	await frames(20)
	var id: String = main.library.selected()
	var before := Meta.prestige()
	main.library._borrow()
	check(Meta.unlocked(id) and Meta.prestige() == before - Meta.borrow_price(id), "借到 %s，花 %d 声望" % [id, Meta.borrow_price(id)])
	check(Meta.pool().has(id), "借到的进了之后的商店池")
	main.library.sel = Vector2i(6, 0)
	main.library._borrow()
	check(not Meta.unlocked(main.library.selected()), "传说格没通关借不了")
	main.library.sel = Vector2i(2, 1)
	await frames(30)
	await snap("m5b_04_library")
	main.library.close()
	await frames(5)
	check(main.mode == main.M.WALK, "关掉书架回到行走")
	# 合同
	main.player.position.x = 1390
	await frames(3)
	main._spot_do("desk")
	await frames(10)
	Meta.d.groups.append("theory")
	main.contract_ui._sign(0, 1)
	main.contract_ui._sign(1, 0)
	check(run.group == "theory" and run.challenge == run.challenge_offers[0], "签了理论组 + 挑战合同「%s」" % Contracts.CHALLENGES[run.challenge].name)
	main.contract_ui.side = 1
	main.contract_ui.row = 0
	await frames(30)
	await snap("m5b_05_contracts")
	main.contract_ui.close()
	await frames(5)
	# 下楼
	main.player.position.x = Geo.LADDER_X + 10
	await frames(3)
	check(main._spot() == "ladder_o", "站在舱口")
	main._spot_do("ladder_o")
	await create_timer(2.0).timeout
	check(main.on_lab_floor(), "回到实验室")
	await frames(40)
	await snap("m5b_06_back")
	print("m5b: ", "OK" if ok else "FAIL")
	quit(0)
