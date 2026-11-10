class_name Options
## 玩家设置（user://settings.cfg 的 options 段；和新手便条共用一个文件，只动自己这一段）。
## -s 测试既不读也不写——测试窗口不能被全屏、正式设置不能被测试改掉。

const CFG := "user://settings.cfg"
static var volume := 80          # 0..100
static var fullscreen := false
static var dark := false
static var shake := true

static func load_and_apply() -> void:
	if not Memes._testing():
		var c := ConfigFile.new()
		if c.load(CFG) == OK:
			volume = int(c.get_value("options", "volume", volume))
			fullscreen = bool(c.get_value("options", "fullscreen", fullscreen))
			dark = bool(c.get_value("options", "dark", dark))
			shake = bool(c.get_value("options", "shake", shake))
	apply()

static func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume / 100.0)))
	AudioServer.set_bus_mute(0, volume <= 0)
	if Pal.dark != dark:
		Pal.set_dark(dark)
	if not Memes._testing():
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)

static func save() -> void:
	if Memes._testing():
		return
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("options", "volume", volume)
	c.set_value("options", "fullscreen", fullscreen)
	c.set_value("options", "dark", dark)
	c.set_value("options", "shake", shake)
	if c.has_section_key("options", "tutorial"):
		c.erase_section_key("options", "tutorial")   # 旧版“每局都放”开关，作废
	c.save(CFG)
