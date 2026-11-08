class_name Prof
static var acc := {}
static var last := 0
static var lab := ""
static func mark(l: String) -> void:
	var now := Time.get_ticks_usec()
	if lab != "":
		acc[lab] = acc.get(lab, 0.0) + (now - last) / 1000.0
	lab = l
	last = now
static func stop() -> void:
	mark("")
	lab = ""
