extends SceneTree
## 新游戏与局内重开引导入口，以及成果瓶/空瓶纸条的真实状态条件。
var main: Node
var failures := 0
func _initialize() -> void:
 main = load("res://main.tscn").instantiate()
 main.play_intro = true
 main.play_tutorial = true
 root.add_child(main)
 call_deferred("test_flow")
func check(ok: bool, label: String) -> void:
 print(("PASS " if ok else "FAIL ") + label)
 if not ok: failures += 1
func step(id: String) -> Dictionary:
 for st in main.tutorial.steps:
  if st.id == id: return st
 return {}
func select_only(id: String) -> void:
 main.tutorial.start(false)
 for st in main.tutorial.steps:
  if st.id != id: main.tutorial.shown[st.id] = true
 main.tutorial._process(0.01)
func test_flow() -> void:
 await process_frame
 main.tutorial.persist = false
 main._on_title_start()
 check(main.tutorial.active, "主页新游戏启动引导")
 main.intro.active = false
 main.mode = main.M.END
 main.restart()
 check(not main.tutorial.active and not main.letter.open, "重开一局不启动引导或开场信")
 main._on_title_start()
 check(main.tutorial.active, "回主页再次新游戏仍启动引导")
 main.intro.active = false
 main.letter.open = false
 main.mode = main.M.CONSOLE
 main.run.beam = null
 main.run.experiment_no = 1
 main.run.inj = "empty"
 check(not step("report").show.call(), "失败留空瓶时不提示成果装瓶")
 main.run.inj = "full"
 check(step("report").show.call(), "引出成果瓶后提示送审")
 main.mode = main.M.WALK
 main.run.inj = "empty"
 main.run.held = ""
 select_only("toss")
 check(main.tutorial.idx >= 0 and main.tutorial.steps[main.tutorial.idx].id == "toss", "空瓶在瓶座时出现回收引导")
 main.run.inj = ""
 main.run.held = "empty"
 main.tutorial._process(0.1)
 check(main.tutorial.done_t < 0.0, "拿起空瓶后引导不提前消失")
 select_only("toss")
 check(main.tutorial.idx >= 0 and main.tutorial.steps[main.tutorial.idx].id == "toss", "手持空瓶时仍能出现回收引导")
 main.run.held = ""
 main.tutorial._process(0.1)
 check(main.tutorial.done_t >= 0.0, "放进回收站后完成引导")
 main.run.held = "full"
 main.run.basket = [{"value": 100}]
 check(step("deliver").show.call(), "已有成果时仍可提示送新成果瓶")
 var resume_run := Run.new(123)
 main.resume(resume_run)
 check(not main.tutorial.active, "继续存档不播放引导")
 print("tutorial entry and bottle guidance: ", "OK" if failures == 0 else "%d FAIL" % failures)
 quit(0 if failures == 0 else 1)
