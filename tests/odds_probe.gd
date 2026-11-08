extends SceneTree
func _initialize():
	for e in [13, 18, 20, 30, 50, 70, 99]:
		var p := Odds.table(e)
		print("E%d loss %.1f%% success+perfect %.1f%% value %d" % [e, p[Odds.LOSS]*100, (p[Odds.SUCCESS]+p[Odds.PERFECT])*100, Odds.value_at(e)])
	quit()
