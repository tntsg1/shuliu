extends SceneTree
## 回归：实际鼠标点击标签/桶身，角色走近后丢空瓶；靠近后 E 键也可回收。
var main: Node
var failures := 0

func _initialize() -> void:
 main = load("res://main.tscn").instantiate()
 main.play_tutorial = false
 main.play_intro = false
 root.add_child(main)
 call_deferred("run_test")

func check(ok: bool, label: String) -> void:
 print(("PASS " if ok else "FAIL ") + label)
 if not ok: failures += 1

func click_world(pos: Vector2) -> void:
 var ev := InputEventMouseButton.new()
 ev.button_index = MOUSE_BUTTON_LEFT
 ev.pressed = true
 ev.position = root.get_canvas_transform() * pos
 main._mouse(ev)

func setup_empty(x: float) -> void:
 main.run.held = "empty"
 main.run.inj = ""
 main.player.position.x = x
 main.player.vx = 0.0
 main.player.auto_target = -1.0
 main.player.act_t = 1.0
 main.walk_goal = ""

func run_test() -> void:
 await create_timer(0.5).timeout
 var bin: Rect2 = main.stash.BIN
 var label_pos := Vector2(bin.get_center().x + 6, bin.position.y - 34)
 check(main._spot_at(label_pos) == "bin", "文字属于回收站点击区域")
 setup_empty(282.0)
 click_world(label_pos)
 await create_timer(2.0).timeout
 check(main.run.held == "", "点击文字后走近并回收")
 await create_timer(0.7).timeout
 var initial_bin: int = main.stash.bin_n
 setup_empty(282.0)
 click_world(bin.get_center())
 await create_timer(2.0).timeout
 check(main.run.held == "" and main.stash.bin_n > initial_bin, "点击桶身后回收并播放落桶")
 await create_timer(0.7).timeout
 setup_empty(120.0)
 var ev := InputEventAction.new()
 ev.action = "interact"
 ev.pressed = true
 main._unhandled_input(ev)
 check(main.run.held == "", "站在回收站前按 E 回收")
 await create_timer(0.7).timeout
 setup_empty(120.0)
 main.player.act(Vector2(120, 700), 0.4)
 click_world(label_pos)
 await create_timer(1.5).timeout
 check(main.run.held == "", "动作尚未结束时点击也会在动作结束后执行")
 print("recycle input: ", "OK" if failures == 0 else "%d FAIL" % failures)
 quit(0 if failures == 0 else 1)

