class_name Plans
## 科研计划书（DECISIONS F14 / Q35）：从第 2 阶段开始，每阶段开局三选一；每份都是“增益 + 代价”。
## 规则在 Run 里按 plan id 生效；文案用户可改（design/科研计划书.md）。

const LIST := {
	"high_energy": {"name": "高能物理专项", "good": "本阶段能级达到 10 以上时，科研价值 ×1.3", "bad": "束流丢失概率增加 3 个百分点", "lore": "校长说了，既然要做实验，那就把能级开高一点。"},
	"energy_save": {"name": "节能运行令", "good": "束流丢失概率 ×0.92", "bad": "科研价值 ×0.85", "lore": "上个月的电费单寄到了校长办公室，第二天就下了通知。"},
	"collab": {"name": "横向合作课题", "good": "立即获得 $25", "bad": "本阶段考核要求提高 10%", "lore": "甲方说项目很简单，只需要稍微修改一下。"},
	"equip_renew": {"name": "设备更新计划", "good": "本阶段购买设备享受 7 折", "bad": "饰品价格提高 20%", "lore": "旧设备刚卖给隔壁实验室，转头又从他们那里买了一批新的。"},
	"night_shift": {"name": "夜班加点", "good": "本阶段增加 1 束束流", "bad": "每次实验获得的经费减半", "lore": "校长要求今晚加班，反正实验室的灯还没关。"},
	"downsizing": {"name": "精简编制", "good": "本阶段考核要求降低 20%", "bad": "本阶段减少 1 束束流", "lore": "人员裁掉了一半，工作量也跟着减少了一点，剩下的只能自己想办法了。"},
	"safety": {"name": "安全整改", "good": "本阶段第一次束流丢失时保留 50%", "bad": "完美同步概率降低 3 个百分点", "lore": "现在每次操作都要先填写申请表，审核通过以后才能继续实验。"},
	"top_journal": {"name": "冲刺顶刊", "good": "完美同步概率提高 4 个百分点", "bad": "射频失谐概率提高 4 个百分点", "lore": "审稿人二号要求再补几组实验，校长说这次一定要发出去。"},
	"lock_rush": {"name": "锁相攻关", "good": "锁相所需充能减少 2 格", "bad": "锁相安全加速次数减少 1 次", "lore": "调整以后确实快了不少，就是实验的时候得多注意一点。"},
	"audit": {"name": "经费审计", "good": "通过本阶段后，奖金 ×3", "bad": "立即失去一半经费", "lore": "财务要求把所有发票重新检查一遍，连买瓶水都得说明用途。"},
	"open_day": {"name": "实验室开放日", "good": "每次引出额外获得 $5", "bad": "每次实验第一次加速时，束流丢失概率增加 5 个百分点", "lore": "今天有学生过来参观，其中一个趁老师没注意，按了控制台上的按钮。"},
	"steady": {"name": "按部就班", "good": "立即获得 $10", "bad": "无", "lore": "这轮就按照原来的计划进行，大家都不想再临时修改方案了。"},
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
