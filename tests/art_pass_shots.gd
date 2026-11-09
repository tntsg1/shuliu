extends SceneTree
## 美术整改前后对比截图（design/任务_去AI味_第一阶段.md 第 5 节）
## 用法：bash tools/run_test.sh tests/art_pass_shots.gd -- before|after|compare
##   before / after：截全景（亮、暗）、局部放大、控制台前姿势
##   compare：把 before / after 拼成 shots/art_compare.png（每行左旧右新）

var main: Node
var tag := "after"

const CROPS := [
	["wall", Rect2(300, 230, 560, 260), 2.0],
	["injector", Rect2(0, 380, 520, 460), 1.6],
	["office", Rect2(0, 0, 1920, 200), 1.0],
	["storage", Rect2(0, 820, 1920, 260), 1.0],
	["detector", Rect2(1380, 200, 540, 620), 1.2],
]
const ORDER := ["lab_light", "lab_dark", "wall", "injector", "office", "storage", "detector", "console"]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if not a.is_empty():
		tag = a[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/art/"))
	if tag == "compare":
		_compare()
		quit(0)
		return
	if tag == "compare_ui":
		_compare_ui()
		quit(0)
		return
	main = load("res://main.tscn").instantiate()
	main.play_tutorial = false
	main.play_intro = false
	root.add_child(main)
	_go()

func _path(n: String) -> String:
	return ProjectSettings.globalize_path("res://shots/art/%s_%s.png" % [tag, n])

func grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_viewport().get_texture().get_image()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _go() -> void:
	await frames(10)
	main.player.position.x = 700
	await frames(40)
	var img: Image = await grab()
	img.save_png(_path("lab_light"))
	for c in CROPS:
		var r: Rect2 = c[1]
		var sub := img.get_region(Rect2i(r))
		sub.resize(int(r.size.x * c[2]), int(r.size.y * c[2]), Image.INTERPOLATE_LANCZOS)
		sub.save_png(_path(c[0]))
	var pal := root.get_node("Pal")
	pal.set_dark(true)
	await frames(10)
	img = await grab()
	img.save_png(_path("lab_dark"))
	pal.set_dark(false)
	# 控制台前：双手落在台面
	main.player.position.x = Geo.CONSOLE_STAND
	main.player.t_console = 1.0
	main.player.console_pose = 1.0
	await frames(30)
	img = await grab()
	var r2 := Rect2i(820, 560, 300, 260)
	var sub2 := img.get_region(r2)
	sub2.resize(r2.size.x * 2, r2.size.y * 2, Image.INTERPOLATE_LANCZOS)
	sub2.save_png(_path("console"))
	print("art shots ", tag, " OK")
	quit(0)

func _compare() -> void:
	var rows := []
	var w := 0
	var h := 0
	for n in ORDER:
		var b := Image.load_from_file(ProjectSettings.globalize_path("res://shots/art/before_%s.png" % n))
		var f := Image.load_from_file(ProjectSettings.globalize_path("res://shots/art/after_%s.png" % n))
		if b == null or f == null:
			continue
		# 每格最宽 1200，等比缩
		var s := minf(1.0, 1200.0 / b.get_width())
		b.resize(int(b.get_width() * s), int(b.get_height() * s), Image.INTERPOLATE_LANCZOS)
		f.resize(b.get_width(), b.get_height(), Image.INTERPOLATE_LANCZOS)
		rows.append([b, f])
		w = maxi(w, b.get_width() * 2 + 30)
		h += b.get_height() + 20
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.15, 0.15, 0.15))
	var y := 0
	for r in rows:
		var b: Image = r[0]
		b.convert(Image.FORMAT_RGBA8)
		r[1].convert(Image.FORMAT_RGBA8)
		out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(0, y))
		out.blit_rect(r[1], Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(b.get_width() + 30, y))
		y += b.get_height() + 20
	out.save_png(ProjectSettings.globalize_path("res://shots/art_compare.png"))
	print("compare saved ", rows.size(), " rows")

## 界面整改：shots/art_ui/before_* 与 after_* 逐张拼成 shots/art_ui_compare.png
func _compare_ui() -> void:
	var names := []
	for f in DirAccess.get_files_at(ProjectSettings.globalize_path("res://shots/art_ui/")):
		if f.begins_with("before_") and f.ends_with(".png"):
			names.append(f.trim_prefix("before_"))
	names.sort()
	var rows := []
	var h := 0
	for n in names:
		var b := Image.load_from_file(ProjectSettings.globalize_path("res://shots/art_ui/before_" + n))
		var f := Image.load_from_file(ProjectSettings.globalize_path("res://shots/art_ui/after_" + n))
		if b == null or f == null:
			continue
		for im in [b, f]:
			im.resize(960, 540, Image.INTERPOLATE_LANCZOS)
			im.convert(Image.FORMAT_RGBA8)
		rows.append([b, f])
		h += 560
	var out := Image.create(960 * 2 + 30, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.15, 0.15, 0.15))
	var y := 0
	for r in rows:
		out.blit_rect(r[0], Rect2i(0, 0, 960, 540), Vector2i(0, y))
		out.blit_rect(r[1], Rect2i(0, 0, 960, 540), Vector2i(990, y))
		y += 560
	out.save_png(ProjectSettings.globalize_path("res://shots/art_ui_compare.png"))
	print("ui compare saved ", rows.size(), " rows")
