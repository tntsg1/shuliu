class_name Contracts
## 教授办公室的合同（M5-11 / M5-15 / M5-16）：
## 课题组合同——开局签一个组，决定这局的起始配置；5 个组逐个解锁。
## 挑战合同——开局从 3 份里选 1 份或不签，规则由游戏强制执行，打完这局声望按倍数多给。
## 只能在本局第一束实验开始之前签 / 改签（Run.can_sign）。

const GROUPS := {
	"base": {"name": "本组", "desc": "按照原来的设置开始实验，没有额外的加成或限制。", "unlock": ""},
	"theory": {"name": "理论组", "desc": "开局额外获得一张便利贴，但初始经费只有 $15。", "unlock": "首次通过第 3 阶段"},
	"engineering": {"name": "工程组", "desc": "设备槽位增加 1 个，饰品槽位减少 1 个。", "unlock": "装满所有设备槽位后，通过任意一个阶段"},
	"finance": {"name": "财务组", "desc": "开局获得 $60，但束流丢失概率增加 2 个百分点。", "unlock": "在一局实验中累计花费 $300"},
	"postdoc": {"name": "博士后流动站", "desc": "每个阶段只有 4 瓶氢气，考核要求提高 25%。", "unlock": "首次完成全部阶段"},
}
const GROUP_ORDER := ["base", "theory", "engineering", "finance", "postdoc"]

const CHALLENGES := {
	"devices_only": {"name": "只买设备", "desc": "本局只能购买设备，无法购买饰品。从失物招领处获得的饰品也只能折算成经费。", "bonus": 0.5},
	"zero_money": {"name": "零经费", "desc": "开局没有初始经费，需要在实验过程中自己想办法赚钱。", "bonus": 0.4},
	"one_relic": {"name": "一件护身符", "desc": "护身符架只能放置 1 件饰品。", "bonus": 0.6},
	"no_early": {"name": "不许早交", "desc": "每个阶段都必须用完所有氢气瓶，才能提交评审。", "bonus": 0.3},
	"no_lock": {"name": "不许锁相", "desc": "本局无法通过任何方式进入锁相状态。", "bonus": 0.5},
	"no_refresh": {"name": "不许刷新", "desc": "本局无法花费经费刷新采购终端的商品。", "bonus": 0.25},
	"no_cab": {"name": "储备柜封存", "desc": "本局无法使用储备柜中的任何物品。", "bonus": 0.2},
	"min_e8": {"name": "E8 起步", "desc": "束流能级必须达到 E8 或以上，才能进行引出操作。", "bonus": 0.4},
}

## 这一局摆在办公桌上的 3 份挑战合同（按种子定，读档不变）
static func deal(seed_value: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value ^ 0x2c1b3c6d
	var ids: Array = CHALLENGES.keys()
	for i in ids.size():
		var j := r.randi() % ids.size()
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	return ids.slice(0, 3)
