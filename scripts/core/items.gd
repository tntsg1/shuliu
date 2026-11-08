class_name Items
## 物品数据（M2 首批：15 件饰品 + 6 种设备）。名称、描述、物品故事取自用户确认的 GDD，原样保留；
## 数值按游戏当前尺度（RP 数百、经费数十）换算；原 GDD 的维修费已取消（FULL_GAME_PLAN F12）。

enum { COMMON, UNCOMMON, RARE, LEGEND }
const RARITY_NAME := ["普通", "精良", "稀有", "传说"]

## kind: relic 饰品 / device 设备
const ALL := {
	# —— 设备 ——
	"magnet_sc": {"kind": "device", "name": "超导弯转磁铁", "rarity": UNCOMMON, "price": 24,
		"desc": "束流丢失概率降低 5 个百分点。", "lore": ""},
	"quad_array": {"kind": "device", "name": "四极聚焦阵列", "rarity": UNCOMMON, "price": 26,
		"desc": "加速成功概率提高 8 个百分点。", "lore": ""},
	"injector_hi": {"kind": "device", "name": "高流强注入器", "rarity": RARE, "price": 34,
		"desc": "基础科研价值 ×1.5，束流丢失概率 +5 个百分点。", "lore": ""},
	"collimator": {"kind": "device", "name": "精密准直器", "rarity": COMMON, "price": 16,
		"desc": "束流丢失概率降低 4 个百分点，但基础科研价值 -10%。", "lore": ""},
	"rf_backup": {"kind": "device", "name": "冗余射频控制器", "rarity": COMMON, "price": 18,
		"desc": "完美同步概率提高 4 个百分点。", "lore": ""},
	"diagnostic": {"kind": "device", "name": "快速束流诊断仪", "rarity": UNCOMMON, "price": 22,
		"desc": "每次实验首次失谐转化为保持稳定。", "lore": ""},
	# —— 饰品 ——
	"dean_paper": {"kind": "relic", "name": "校长当年的实验稿纸", "rarity": RARE, "price": 42,
		"desc": "每局首次发生无法被其他效果阻止的束流丢失时，保留当前科研价值的 80%，随后实验结束。",
		"lore": "校长说，这是他唯一一次没算错的实验。"},
	"eraser": {"kind": "relic", "name": "延毕学长的橡皮", "rarity": UNCOMMON, "price": 24, "uses": 3,
		"desc": "每次出现失谐时，自动重抽一次结果。最多使用 3 次，用完消失。",
		"lore": "已经擦了六年，还有一半没用完。"},
	"coin": {"kind": "relic", "name": "祖传幸运硬币", "rarity": UNCOMMON, "price": 28,
		"desc": "发生束流丢失时抛硬币：正面抵挡本次破碎。每次实验触发一次。",
		"lore": "据说是从上一任主任手里传下来的。上一任主任去哪了，没人提过。"},
	"badge": {"kind": "relic", "name": "学姐留下的工牌", "rarity": COMMON, "price": 12,
		"desc": "每阶段第一次发生失谐时，将结果改为保持稳定。",
		"lore": "她已经毕业三年了，门禁却一直没注销。"},
	"note100": {"kind": "relic", "name": "写着“100%”的便利贴", "rarity": RARE, "price": 20, "consumable": true,
		"desc": "消耗品：若本次普通成功与完美同步的总概率已达 75%，下次加速必定至少普通成功。触发后销毁。",
		"lore": "写得很用力。"},
	"wrong_answer": {"kind": "relic", "name": "学弟的错误答案", "rarity": UNCOMMON, "price": 22,
		"desc": "每次出现失谐时，有 20% 概率将其转化为完美同步。",
		"lore": "最后答案错了，但是过程很有说服力。"},
	"koi": {"kind": "relic", "name": "实验室门口的锦鲤照片", "rarity": COMMON, "price": 14,
		"desc": "每次完美同步获得一层好运，每层使束流丢失概率降低 2 个百分点。本次实验最多 5 层。",
		"lore": "打印机没墨了，所以这条鱼只有半截。"},
	"ultimatum": {"kind": "relic", "name": "导师的最后通牒", "rarity": RARE, "price": 38,
		"desc": "每次实验前 3 次加速必定至少普通成功。从第 4 次开始，本次实验的束流丢失概率提高 10 个百分点。",
		"lore": "最后一次机会。这句话已经说过很多次了。"},
	"lucky_cat": {"kind": "relic", "name": "实验室的招财猫", "rarity": COMMON, "price": 12,
		"desc": "每次成功加速有 8% 概率获得额外 $3。连续两次触发时，第二次收益翻倍。",
		"lore": "财务处要求把它列为固定资产。"},
	"rejected": {"kind": "relic", "name": "被拒稿十七次的论文", "rarity": UNCOMMON, "price": 24,
		"desc": "每次失谐获得一层怨气。达到 5 层后，下一次成功加速额外提升 3 级，并清空怨气。",
		"lore": "第十八次投稿，作者换了个标题。"},
	"dean_pen": {"kind": "relic", "name": "校长的签名笔", "rarity": RARE, "price": 40,
		"desc": "每阶段第一次成功引出的实验，科研价值 ×3。该阶段后续实验价值 ×0.8。",
		"lore": "校长亲自批的项目，从来不缺经费。"},
	"chair": {"kind": "relic", "name": "实验室唯一的好椅子", "rarity": COMMON, "price": 16,
		"desc": "连续成功期间，每次成功增加 0.2 倍科研倍率。失谐或保持稳定时，清空该饰品积累的额外倍率。",
		"lore": "有人偷偷换了椅子，第二天整个实验室都知道了。"},
	"budget": {"kind": "relic", "name": "去年没用完的经费", "rarity": UNCOMMON, "price": 22,
		"desc": "引出实验时，每持有 $10 经费，当前科研得分增加 5%，最高增加 50%。",
		"lore": "再不花完，明年的预算就要被削了。"},
	"coffee": {"kind": "relic", "name": "博士生的第七杯咖啡", "rarity": UNCOMMON, "price": 26,
		"desc": "连续成功 3 次后，自动获得一次 3 次安全加速的锁相窗口。每次实验最多触发一次。",
		"lore": "早上九点还有组会。"},
	"fast_clock": {"kind": "relic", "name": "永远快五分钟的钟", "rarity": RARE, "price": 34,
		"desc": "所有锁相窗口额外 +2 次安全加速，但每次实验的第一次加速额外增加 5 个百分点的束流丢失概率。",
		"lore": "没人敢把时间调回来。"},
}

## 槽位（GDD 9.4）：按阶段扩张
static func device_slots(stage: int) -> int:
	return [3, 3, 4, 4, 5, 5, 6, 6][clampi(stage, 0, 7)]

static func relic_slots(stage: int) -> int:
	return [2, 2, 3, 3, 4, 4, 5, 5][clampi(stage, 0, 7)]

static func get_def(id: String) -> Dictionary:
	return ALL.get(id, {})

static func ids(kind: String) -> Array:
	var out: Array = []
	for k in ALL:
		if ALL[k].kind == kind:
			out.append(k)
	return out

static func sell_price(id: String) -> int:
	return int(floor(ALL[id].price * 0.5))
