class_name Memes
## 奇葩事件：引出时约 1/8 概率，探测器上的粒子径迹拼成一张梗图（纯好看，记进事件图鉴）。
## 文案在 design/奇葩事件.md，用户可改；改完同步到这里。
## rarity：0 常见 / 1 少见 / 2 稀有；min_e：至少要这个能级才可能出现

const CHANCE := 0.125

const LIST := {
	# —— 网络梗 ——
	"woodfish": {"name": "功德 +1", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "径迹拼成了一条电子木鱼。每敲一下……"},
	"six": {"name": "666", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "三束粒子同时拐成了 6。"},
	"yyds": {"name": "YYDS", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "永远的神。量能器也这么觉得。"},
	"thankq": {"name": "栓 Q", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "一个巨大的 Q。谢谢，有被谢到。"},
	"clam": {"name": "蚌埠住了", "cat": "网络梗", "rarity": 1, "min_e": 3, "desc": "径迹画出一只张开的蚌，里面还有颗珠子。"},
	"zundu": {"name": "尊嘟假嘟", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "O.o"},
	"rocket": {"name": "芜湖，起飞！", "cat": "网络梗", "rarity": 1, "min_e": 4, "desc": "所有径迹都往上窜。"},
	"cpu": {"name": "CPU 烧了", "cat": "网络梗", "rarity": 1, "min_e": 5, "desc": "数据采集卡冒烟了，屏幕上留下一块芯片的形状。"},
	"retreat": {"name": "退！退！退！", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "粒子从四面八方往回跑。"},
	"sad": {"name": "我太难了", "cat": "网络梗", "rarity": 0, "min_e": 1, "desc": "一张哭脸，还挂着一滴眼泪。"},
	"champagne": {"name": "开香槟咯", "cat": "网络梗", "rarity": 2, "min_e": 8, "desc": "瓶塞飞了出去，气泡冒个不停。"},
	"broken": {"name": "破防了", "cat": "网络梗", "rarity": 1, "min_e": 3, "desc": "一面盾牌，中间裂了。"},
	# —— 科研人梗 ——
	"p005": {"name": "p < 0.05，可以发了", "cat": "科研梗", "rarity": 1, "min_e": 4, "desc": "显著了。导师在隔壁笑出了声。"},
	"reviewer2": {"name": "审稿人 2 号：请补实验", "cat": "科研梗", "rarity": 1, "min_e": 2, "desc": "一个巨大的 2，后面跟着红叉。"},
	"bug": {"name": "这不是 bug，是已知特性", "cat": "科研梗", "rarity": 0, "min_e": 1, "desc": "径迹爬成了一只虫子。"},
	# —— 物理梗 ——
	"cat": {"name": "猫在不在箱子里？", "cat": "物理梗", "rarity": 1, "min_e": 3, "desc": "打开之前，它既在又不在。"},
	"higgs": {"name": "上帝粒子（大概）", "cat": "物理梗", "rarity": 2, "min_e": 10, "desc": "一个 H 和一圈光环。需要五个西格玛才能确认。"},
	"chicken": {"name": "假设鸡是球形的", "cat": "物理梗", "rarity": 1, "min_e": 2, "desc": "理论物理学家的养鸡场。"},
	"ftl": {"name": "超光速！（线没插好）", "cat": "物理梗", "rarity": 2, "min_e": 11, "desc": "有一条径迹冲出了探测器，冲出了屏幕。"},
	"heart": {"name": "对撞出了爱情", "cat": "物理梗", "rarity": 2, "min_e": 9, "desc": "两束粒子撞出了一颗心。"},
}

const CODEX := "user://codex.cfg"

## 引出时抽一次：返回梗 id，没抽中返回 ""（纯画面，用独立随机，不影响实验结果）
static func roll(energy: int, rng: RandomNumberGenerator, force := "") -> String:
	if force == "" and rng.randf() >= CHANCE:
		return ""
	var pool: Array = []
	var w := [6, 3, 1]
	for id in LIST:
		var m: Dictionary = LIST[id]
		if energy >= m.min_e:
			for i in w[m.rarity]:
				pool.append(id)
	if pool.is_empty():
		return ""
	return pool[rng.randi() % pool.size()]

## 图鉴：记录见过的奇葩事件（测试脚本运行时不写盘）
static func _testing() -> bool:
	for a in OS.get_cmdline_args():
		if a == "-s" or a == "--script" or a.ends_with(".gd"):
			return true
	return false

static func seen_count(id: String) -> int:
	var c := ConfigFile.new()
	if c.load(CODEX) != OK:
		return 0
	return int(c.get_value("memes", id, 0))

## 记一次；返回这是不是第一次见
static func record(id: String) -> bool:
	var first := seen_count(id) == 0
	if _testing():
		return first
	var c := ConfigFile.new()
	c.load(CODEX)
	c.set_value("memes", id, int(c.get_value("memes", id, 0)) + 1)
	c.save(CODEX)
	return first
