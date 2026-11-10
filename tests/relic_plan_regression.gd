extends SceneTree
var failed := 0
func check(ok: bool, label: String) -> void:
 print(("PASS " if ok else "FAIL ") + label)
 if not ok: failed += 1
func _initialize() -> void:
 call_deferred("run_checks")
func run_checks() -> void:
 var a := Run.new(101)
 a.relics = ["rejected"]
 a.start_experiment()
 for i in 3:
  a.dev_force = Odds.DETUNE
  a.accelerate()
 check(a.rejected_stacks == 3, "失谐三次积累怨气")
 var e := a.beam.energy
 a.dev_force = Odds.SUCCESS
 a.accelerate()
 check(a.beam.energy == e + 4 and a.rejected_stacks == 0, "成功消耗怨气并额外加三级")
 var b := Run.new(102)
 b.relics = ["third_draft"]
 b.start_experiment()
 b.dev_force = Odds.STABLE
 b.accelerate()
 b.accelerate()
 check(b.beam.charge == 1 and is_equal_approx(b.beam.draft, 0.2), "两次稳定增加收益与锁相充能")
 var loaded := Save.unpack(Save.pack(b))
 check(loaded.beam.draft_stable == 2 and loaded.beam.charge == 1, "稳定次数和充能可存档")
 var c := Run.new(103)
 c.relics = ["lost_data"]
 c.start_experiment()
 c.dev_force = Odds.SUCCESS
 c.accelerate()
 c.dev_force = Odds.LOSS
 c.accelerate()
 check(c.lost_charge_pending and c.lost_bonus > 0, "最高潜在成果丢失可继承奖励")
 c = Save.unpack(Save.pack(c))
 c.start_experiment()
 check(c.beam.charge == 2 and not c.lost_charge_pending, "下一束获得充能且仅消耗一次")
 var d := Run.new(104)
 d.relics = ["coffee", "fast_clock"]
 d.start_experiment()
 d.dev_force = Odds.SUCCESS
 for i in 3: d.accelerate()
 print("coffee lock actual: ", d.beam.lock_left, " streak ", d.beam.streak, " charge ", d.beam.charge)
 check(d.beam.lock_left == 5, "咖啡锁相与闹钟正确相加一次")
 var game = load("res://main.tscn").instantiate()
 game.play_intro = false
 game.play_tutorial = false
 root.add_child(game)
 await process_frame
 game.run.plan_offers = ["collab", "steady", "audit"]
 game.mode = game.M.PLAN
 game.player.input_enabled = false
 game.plans.show_plans(game.run.plan_offers, 2)
 game.plans.t = 1.0
 var event := InputEventAction.new()
 event.action = "back"
 event.pressed = true
 game.plans.handle(event)
 check(game.run.plan == "" and game.run.plan_offers.is_empty(), "Esc 跳过计划且不附加效果")
 check(game.mode == game.M.WALK and game.player.input_enabled and not game.plans.open, "跳过后可继续游戏")
 var packed := Save.unpack(Save.pack(game.run))
 check(packed.plan_offers.is_empty() and packed.plan == "", "跳过后存档恢复不会重新弹出")
 print("relic and optional plans: ", "OK" if failed == 0 else "%d FAIL" % failed)
 quit(0 if failed == 0 else 1)

