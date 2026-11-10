class_name Plans
## 科研计划书（DECISIONS F14 / Q35）：从第 2 阶段开始，每阶段开局三选一；每份都是“增益 + 代价”。
## 规则在 Run 里按 plan id 生效；文案用户可改（design/科研计划书.md）。

const LIST := {
	"high_energy": {"name": "高能物理专项", "good": "本阶段能级 ≥ 10 时，科研价值 ×1.3", "bad": "束流丢失 +3 个百分点", "lore": "上面说了，要搞就搞大的。"},
	"energy_save": {"name": "节能运行令", "good": "束流丢失概率 ×0.92", "bad": "科研价值 ×0.85", "lore": "电费单寄到了校长办公室。"},
	"collab": {"name": "横向合作课题", "good": "立即获得 $25", "bad": "本阶段考核线 +10%", "lore": "甲方说需求很简单。"},
	"equip_renew": {"name": "设备更新计划", "good": "本阶段设备 7 折", "bad": "饰品贵 20%", "lore": "旧设备卖给隔壁，新设备从隔壁买。"},
	"night_shift": {"name": "夜班加点", "good": "本阶段多 1 束", "bad": "每次实验经费收入减半", "lore": "加速器不睡觉，你也别睡。"},
	"downsizing": {"name": "精简编制", "good": "本阶段考核线 -20%", "bad": "少 1 束", "lore": "人少了，指标也就少了。理论上。"},
	"safety": {"name": "安全整改", "good": "本阶段首次束流丢失保留 50%", "bad": "完美同步 -3 个百分点", "lore": "所有操作都要先填表。"},
	"top_journal": {"name": "冲刺顶刊", "good": "完美同步 +4 个百分点", "bad": "射频失谐 +4 个百分点", "lore": "审稿人二号已经在路上了。"},
	"lock_rush": {"name": "锁相攻关", "good": "锁相充能少 2 格", "bad": "锁相少 1 次安全加速", "lore": "快是快了，就是不太稳。"},
	"audit": {"name": "经费审计", "good": "过阶段奖金 ×3", "bad": "立即失去一半经费", "lore": "每一张发票都要解释。"},
	"open_day": {"name": "实验室开放日", "good": "每次引出额外 $5", "bad": "每次实验第一次加速，束流丢失 +5 个百分点", "lore": "参观的小学生按了一下不该按的按钮。"},
	"steady": {"name": "按部就班", "good": "立即获得 $10", "bad": "无", "lore": "什么都不改，就是最大的改变。"},
}

## 抽三份不重复的
static func deal(rng: RandomNumberGenerator) -> Array:
	var keys: Array = LIST.keys()
	var out: Array = []
	while out.size() < 3 and not keys.is_empty():
		var i := rng.randi() % keys.size()
		out.append(keys[i])
		keys.remove_at(i)
	return out
