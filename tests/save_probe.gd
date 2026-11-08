extends SceneTree
## 存档文件真写真读：换成单独的文件 user://run_probe.save（不碰玩家的 run.save），写两次（覆盖）、读回、比较、删除

func _initialize() -> void:
	Save.probe = true
	Save.PATH = "user://run_probe.save"
	var ok := true
	var a := Run.new(9001)
	a.relics = ["coin", "lab_cat"]
	a.start_experiment()
	for i in 3:
		if a.beam != null: a.accelerate()
	if a.beam == null: a.start_experiment()
	Save.write(a)
	a.accelerate() if a.beam != null else null
	Save.write(a)        # 第二次：覆盖旧档
	var b := Save.read()
	ok = ok and b != null and b.total == a.total and b.experiment_no == a.experiment_no and (b.beam == null) == (a.beam == null)
	if a.beam != null and b != null and b.beam != null:
		ok = ok and b.beam.energy == a.beam.energy and b.beam.route == a.beam.route
		ok = ok and a.accelerate().outcome == b.accelerate().outcome
	print("summary: ", Save.summary())
	a.failed = true
	Save.write(a)        # 一局结束：删档
	ok = ok and not Save.exists()
	print("save probe: ", "OK" if ok else "FAIL")
	quit(0)
