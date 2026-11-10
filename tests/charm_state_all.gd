extends SceneTree
## 每件物品在“没在实验 / 实验中”两种情况下都能取状态签，不报错
func _initialize() -> void:
	var run := Run.new(7)
	var n := 0
	for id in Items.ALL:
		run.relics = [id]
		run.charm_state(id)
		n += 1
	run.inj = "fresh"
	run.start_experiment()
	for id in Items.ALL:
		run.relics = [id]
		var s: Dictionary = run.charm_state(id)
		if not s.is_empty():
			print(id, " ", s.t)
	print("charm_state all: OK ", n)
	quit(0)
