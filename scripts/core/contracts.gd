class_name Contracts
## 教授办公室的合同（M5-11 / M5-15 / M5-16）：
## 课题组合同——开局签一个组，决定这局的起始配置；5 个组逐个解锁。
## 挑战合同——开局从 3 份里选 1 份或不签，规则由游戏强制执行，打完这局声望按倍数多给。
## 只能在本局第一束实验开始之前签 / 改签（Run.can_sign）。

const GROUPS := {
	"base": {"name": "本组", "desc": "没有变化。", "unlock": ""},
	"theory": {"name": "理论组", "desc": "开局带一张便利贴，经费只有 $15。", "unlock": "第一次通过第 3 阶段"},
	"engineering": {"name": "工程组", "desc": "设备槽 +1，饰品槽 −1。", "unlock": "装满设备通过一个阶段"},
	"finance": {"name": "财务组", "desc": "开局 $60，束流丢失率 +2 个百分点。", "unlock": "一局里累计花掉 $300"},
	"postdoc": {"name": "博士后流动站", "desc": "每阶段 4 瓶氢气，考核线 ×1.25。", "unlock": "第一次通关"},
}
const GROUP_ORDER := ["base", "theory", "engineering", "finance", "postdoc"]

const CHALLENGES := {
	"devices_only": {"name": "只买设备", "desc": "本局不能买饰品（失物招领抽到饰品也只能折钱）。", "bonus": 0.5},
	"zero_money": {"name": "零经费", "desc": "开局经费 $0。", "bonus": 0.4},
	"one_relic": {"name": "一件护身符", "desc": "护身符架只有 1 个位置。", "bonus": 0.6},
	"no_early": {"name": "不许早交", "desc": "每阶段的氢气瓶必须用完才能提交。", "bonus": 0.3},
	"no_lock": {"name": "不许锁相", "desc": "本局任何方式都进不了锁相。", "bonus": 0.5},
	"no_refresh": {"name": "不许刷新", "desc": "采购终端不能付费刷新。", "bonus": 0.25},
	"no_cab": {"name": "储备柜封存", "desc": "储备柜本局不能用。", "bonus": 0.2},
	"min_e8": {"name": "E8 起步", "desc": "能级低于 E8 不能引出。", "bonus": 0.4},
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
