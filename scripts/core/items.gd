class_name Items
## 物品数据（M2 首批：15 件饰品 + 6 种设备）。名称、描述、物品故事取自用户确认的 GDD，原样保留；
## 数值按游戏当前尺度（RP 数百、经费数十）换算；原 GDD 的维修费已取消（FULL_GAME_PLAN F12）。

enum { COMMON, UNCOMMON, RARE, LEGEND }
const RARITY_NAME := ["普通", "精良", "稀有", "传说"]

## kind: relic 饰品 / device 设备
const ALL := {
	# —— 设备 ——
	"magnet_sc": {"kind": "device", "name": "超导弯转磁铁", "rarity": UNCOMMON, "price": 24,
		"desc": "束流丢失概率 ×0.85。", "big": "丢失率 ×0.85", "lore": "比实验室里任何人都更擅长转弯。"},
	"quad_array": {"kind": "device", "name": "四极聚焦阵列", "rarity": UNCOMMON, "price": 26,
		"desc": "加速成功概率提高 12 个百分点。", "big": "成功率 +12%", "lore": "四块磁铁互相都不服气，结果反而把束流夹得很紧。"},
	"injector_hi": {"kind": "device", "name": "高流强注入器", "rarity": RARE, "price": 34,
		"desc": "基础科研价值 ×1.5，束流丢失概率 +5 个百分点。", "big": "价值 ×1.5 · 丢失 +5%", "lore": "说明书第一页写着：请勿超过额定流强。第二页被撕了。"},
	"collimator": {"kind": "device", "name": "精密准直器", "rarity": COMMON, "price": 16,
		"desc": "束流丢失概率 ×0.88，但基础科研价值 -10%。", "big": "丢失率 ×0.88 · 价值 −10%", "lore": "多余的粒子都被它挡在门外，包括一部分有用的。"},
	"rf_backup": {"kind": "device", "name": "冗余射频控制器", "rarity": COMMON, "price": 18,
		"desc": "完美同步概率提高 6 个百分点。", "big": "完美同步率 +6%", "lore": "主控制器坏掉的那天，大家才发现还有个备用的。"},
	"diagnostic": {"kind": "device", "name": "快速束流诊断仪", "rarity": UNCOMMON, "price": 22,
		"desc": "每次实验首次失谐转化为保持稳定。", "big": "首次失谐变稳定", "lore": "它总能比你早半秒知道哪里不对。"},
	# —— M3 第 5 批：金属设备 ——
	"rf_cavity": {"kind": "device", "name": "高频射频腔", "rarity": RARE, "price": 36,
		"desc": "完美同步额外 +1 能级。", "big": "完美同步：能级 +1", "lore": "共振的时候，整层楼的窗户都在嗡嗡响。"},
	"extractor": {"kind": "device", "name": "高效束流引出器", "rarity": COMMON, "price": 16,
		"desc": "主动引出时最终科研价值 +20%。", "big": "引出价值 +20%", "lore": "送束流出门的时候，比谁都利索。"},
	"cryo_magnet": {"kind": "device", "name": "低温磁体升级", "rarity": RARE, "price": 34,
		"desc": "能级 ≥ 10 时束流丢失概率 ×0.75。", "big": "能级≥10：丢失率 ×0.75", "lore": "零下二百六十九度，比财务处还冷。"},
	"beam_dump": {"kind": "device", "name": "束流收集靶", "rarity": COMMON, "price": 14,
		"desc": "束流丢失时返还 $（能级 × 2）。", "big": "丢失返 $能级×2", "lore": "所有失败的束流，最后都来到这里。"},
	# —— M3 第 6 批：电子设备 ——
	"calorimeter": {"kind": "device", "name": "高分辨率量能器", "rarity": UNCOMMON, "price": 26,
		"desc": "能级 ≥ 8 时科研价值 ×1.6。", "big": "能级≥8：价值 ×1.6", "lore": "能量越高，它越来劲。"},
	"protect_sys": {"kind": "device", "name": "束流保护系统", "rarity": UNCOMMON, "price": 24,
		"desc": "每阶段首次束流丢失保留 30% 科研价值。", "big": "每阶段首次丢失保留30%", "lore": "设计寿命十五年，已经服役二十二年。"},
	"daq": {"kind": "device", "name": "多级数据采集器", "rarity": UNCOMMON, "price": 24,
		"desc": "本次实验每次连续成功，结算 +3%，最多 +60%。", "big": "连胜：结算 +3%", "lore": "每一次成功都被它记下来，连你自己都忘了。"},
	"lock_loop": {"kind": "device", "name": "锁相反馈回路", "rarity": UNCOMMON, "price": 26,
		"desc": "锁相 +1 次安全加速。", "big": "锁相安全加速 +1", "lore": "调得太好，有时候连噪声都被锁住了。"},
	"bpm": {"kind": "device", "name": "束流位置监测器", "rarity": COMMON, "price": 18,
		"desc": "保持稳定概率的一半转给加速成功。", "big": "稳定概率一半转成功", "lore": "束流歪一点点，它就会尖叫。"},
	# —— 饰品 ——
	"dean_paper": {"kind": "relic", "name": "校长几年前用过的实验稿纸", "rarity": RARE, "price": 42,
		"desc": "每局首次发生无法被其他效果阻止的束流丢失时，保留当前科研价值的 80%，随后实验结束。", "big": "每局首次丢失保留80%",
		"lore": "我们找到了校长当年疯狂吹牛说是发了sci论文……的草稿"},
	"eraser": {"kind": "relic", "name": "延毕学长的橡皮", "rarity": UNCOMMON, "price": 24, "uses": 3,
		"desc": "每次出现失谐时，自动重抽一次结果。最多使用 3 次，用完消失。", "big": "失谐重抽 · 最多3次",
		"lore": "这算是圣遗物吗？真的能用吗？"},
	"coin": {"kind": "relic", "name": "祖传幸运硬币", "rarity": UNCOMMON, "price": 28,
		"desc": "发生束流丢失时抛硬币：正面抵挡本次破碎。每次实验触发一次。", "big": "丢失时抛硬币抵挡",
		"lore": "据说是从上一任学长手里传下来的。"},
	"badge": {"kind": "relic", "name": "学姐留下的工牌", "rarity": COMMON, "price": 12,
		"desc": "每阶段第一次发生失谐时，将结果改为保持稳定。", "big": "每阶段首次失谐变稳定",
		"lore": "她已经毕业三年了，圣遗物。"},
	"note100": {"kind": "relic", "name": "写着“求求实验通过吧”的便利贴", "rarity": RARE, "price": 20, "consumable": true,
		"desc": "消耗品：若本次普通成功与完美同步的总概率已达 75%，下次加速必定至少普通成功。触发后销毁。", "big": "成功率≥75%：下次必成",
		"lore": "看起来是哪个绝望的学长写的。"},
	"wrong_answer": {"kind": "relic", "name": "学弟的错误答案", "rarity": UNCOMMON, "price": 22,
		"desc": "每次出现失谐时，有 20% 概率将其转化为完美同步。", "big": "失谐20%转完美同步",
		"lore": "虽然过程非常的严谨，但是实验方向一开始就错了。"},
	"koi": {"kind": "relic", "name": "实验室门口的锦鲤照片", "rarity": COMMON, "price": 14,
		"desc": "每次完美同步获得一层好运，每层使束流丢失概率 ×0.95。本次实验最多 5 层。", "big": "完美同步：丢失率 ×0.95",
		"lore": "浪费墨水"},
	"ultimatum": {"kind": "relic", "name": "导师的最后通牒", "rarity": RARE, "price": 38,
		"desc": "每次实验前 3 次加速必定至少普通成功。从第 4 次开始，本次实验的束流丢失概率提高 10 个百分点。", "big": "前3次必成 · 丢失 +10%",
		"lore": "“我的耐心已经被你们耗完了！这是最后一次机会！”"},
	"lucky_cat": {"kind": "relic", "name": "实验室的招财猫", "rarity": COMMON, "price": 12,
		"desc": "每次成功加速有 8% 概率获得额外 $3。连续两次触发时，第二次收益翻倍。", "big": "成功8%获得 $3",
		"lore": "一直在招手。"},
	"rejected": {"kind": "relic", "name": "被拒稿十七次的论文", "rarity": UNCOMMON, "price": 24,
		"desc": "每次失谐获得一层怨气。达到 3 层后，下一次成功加速额外提升 3 级，并清空怨气。", "big": "失谐3次：下次成功 +3级",
		"lore": "“我其实所有单数次的交稿都是一模一样的，但是不知道为什么这次过了”"},
	"dean_pen": {"kind": "relic", "name": "校长的签名笔", "rarity": RARE, "price": 40,
		"desc": "每阶段第一次成功引出的实验，科研价值 ×3。该阶段后续实验价值 ×0.8。", "big": "阶段首次引出 ×3 · 后续×0.8",
		"lore": "校长亲自批的项目，经费多到用不完。"},
	"chair": {"kind": "relic", "name": "实验室唯一的好椅子", "rarity": COMMON, "price": 16,
		"desc": "连续成功期间，每次成功增加 0.2 倍科研倍率。失谐或保持稳定时，清空该饰品积累的额外倍率。", "big": "连胜：科研倍率 +0.2",
		"lore": "不知道是谁偷偷换了的新的椅子。"},
	"budget": {"kind": "relic", "name": "去年没用完的经费", "rarity": UNCOMMON, "price": 22,
		"desc": "引出实验时，每持有 $10 经费，当前科研得分增加 5%，最高增加 50%。", "big": "每 $10：引出得分 +5%",
		"lore": "再不花完，明年的预算就要被削了。"},
	"coffee": {"kind": "relic", "name": "博士生早上没喝完的咖啡", "rarity": UNCOMMON, "price": 26,
		"desc": "连续成功 3 次后，自动获得一次 3 次安全加速的锁相窗口。每次实验最多触发一次。", "big": "连胜3次：锁相3次",
		"lore": "早上九点还有组会。"},
	"fast_clock": {"kind": "relic", "name": "快五分钟的闹钟", "rarity": RARE, "price": 34,
		"desc": "所有锁相窗口额外 +2 次安全加速，但每次实验的第一次加速额外增加 5 个百分点的束流丢失概率。", "big": "锁相 +2 · 首次丢失 +5%",
		"lore": "屎山代码能用就不要改，不知道为什么一调回来就一下快一下慢。"},
	# —— M3 第 1 批：纸张 ——
	"lost_data": {"kind": "relic", "name": "那次忘记保存的数据", "rarity": RARE, "price": 36,
		"desc": "在本局最高潜在成果时发生束流丢失：下次引出额外获得失去价值的 15%，下一束初始锁相充能最多 +2 格（不会直接触发锁相）。每阶段最多一次。", "big": "最高成果丢失：返15% · 下束充能",
		"lore": "“我记得我明明把资料放在桌子上啊”。"},
	"calib_log": {"kind": "relic", "name": "设备校准记录", "rarity": LEGEND, "price": 58,
		"desc": "锁相所需充能 -2 格（6 格 → 4 格）。", "big": "锁相充能 6→4 格",
		"lore": "维护记录：一切正常 日期：2000年3月5日。"},
	"duty_roster": {"kind": "relic", "name": "周末值班表", "rarity": COMMON, "price": 12,
		"desc": "每次实验第一次加速，加速成功概率 +15 个百分点。", "big": "首次加速：成功率 +15%",
		"lore": "“怎么又是我值班啊？”"},
	"third_draft": {"kind": "relic", "name": "修改稿第三版", "rarity": UNCOMMON, "price": 22,
		"desc": "每次保持稳定，本次实验科研倍率 +0.1，最多 +1.0；每两次稳定额外获得 1 格锁相充能（本束充能锁相触发前）。", "big": "稳定：倍率+0.1 · 两次充能+1",
		"lore": "和第一版一字不差。"},
	"reimburse": {"kind": "relic", "name": "被退回的报销申请单", "rarity": UNCOMMON, "price": 22,
		"desc": "每次束流丢失获得 $8。", "big": "丢失获得 $8",
		"lore": "“你没发票我给你报销个蛋呢”"},
	"applications": {"kind": "relic", "name": "填不完的申报书", "rarity": UNCOMMON, "price": 22,
		"desc": "商店每次进货或刷新后，第一件商品半价。", "big": "进货或刷新首件半价",
		"lore": "我就要10支水笔，怎么要我填10个申请表啊。"},
	"nobel_list": {"kind": "relic", "name": "去年的诺奖预测名单", "rarity": LEGEND, "price": 52,
		"desc": "能级 ≥ 12 时，超级同步概率翻倍，每次成功加速获得 $4。", "big": "能级≥12：超级同步率 ×2",
		"lore": "名单上有你导师。可惜划掉了。"},
	# —— M3 第 2 批：咖啡 / 钟表 ——
	"coffee_cup": {"kind": "relic", "name": "没洗的咖啡杯", "rarity": COMMON, "price": 16,
		"desc": "锁相充能只需 5 格（原 6 格）。", "big": "锁相充能只需5格",
		"lore": "杯底已经形成了独立的生态系统。"},
	"thermos": {"kind": "relic", "name": "前任主任的保温杯", "rarity": RARE, "price": 38,
		"desc": "锁相期间每次加速 25% 概率不消耗锁相次数。", "big": "锁相25%不消耗次数",
		"lore": "里面的茶垢比这台加速器还历史悠久。"},
	"alarm_4am": {"kind": "relic", "name": "凌晨四点的闹钟", "rarity": RARE, "price": 34,
		"desc": "一次实验连续加速 7 次且没有引出时，获得一次 4 次安全加速的锁相。", "big": "连续加速7次：锁相4次",
		"lore": "“哪个傻逼定的？”"},
	# —— M3 第 3 批：文具 ——
	"bandaid": {"kind": "relic", "name": "贴在屏幕上的创可贴", "rarity": COMMON, "price": 14,
		"desc": "保持稳定有 40% 概率转为加速成功。", "big": "稳定 40% 转成功",
		"lore": "原来屏幕坏了吗？"},
	"marker": {"kind": "relic", "name": "会议室的白板笔", "rarity": COMMON, "price": 14,
		"desc": "引出时，若本次实验没出现过失谐，科研价值 +15%。", "big": "无失谐引出：价值 +15%",
		"lore": "全都没墨了，不知道为什么在这里。"},
	"wipes": {"kind": "relic", "name": "半盒消毒湿巾", "rarity": COMMON, "price": 12, "consumable": true,
		"desc": "消耗品：下一次实验全程束流丢失概率 ×0.82，结束后用完。", "big": "下次实验：丢失率 ×0.82",
		"lore": "另外半盒不知道去哪里了。"},
	"tape_roll": {"kind": "relic", "name": "一卷没拆封的胶带", "rarity": COMMON, "price": 12,
		"desc": "每次实验第一次射频失谐不降能级（改为保持稳定）。", "big": "首次失谐变稳定",
		"lore": "从哪撕开啊？"},
	# —— M3 第 4 批：证章 ——
	"rec_letter": {"kind": "relic", "name": "系主任的推荐信", "rarity": UNCOMMON, "price": 24,
		"desc": "主动引出时 25% 概率科研评分 +50%。每阶段第一次触发后失效，下一阶段恢复。", "big": "引出25%：评分 +50%",
		"lore": "他甚至没看过实验数据。"},
	"grad_promise": {"kind": "relic", "name": "导师的毕业承诺", "rarity": LEGEND, "price": 50,
		"desc": "每次失谐，给下一次锁相 +1 次安全加速，最多累计 +4。成功引出后清零。", "big": "失谐：下次锁相 +1",
		"lore": "明年一定能毕业。"},
	"phd_cert": {"kind": "relic", "name": "博士学位证书（未填写姓名）", "rarity": LEGEND, "price": 48,
		"desc": "本阶段最后一次实验时，若累计分仍未达标，所有成功带来的科研倍率额外 ×2。若最终仍未通过，本局不给任何局外解锁进度。", "big": "阶段末未达标：倍率 ×2",
		"lore": "先把名字写上去吧。"},
	"dose_card": {"kind": "relic", "name": "过期的辐射剂量卡", "rarity": UNCOMMON, "price": 24,
		"desc": "能级 ≥ 10 时，完美同步概率 +8 个百分点。", "big": "能级≥10：完美同步率 +8%",
		"lore": "真的过期了吗？"},
	"meal_card": {"kind": "relic", "name": "食堂的饭卡", "rarity": COMMON, "price": 12,
		"desc": "每次实验结束后，第一次打开采购终端获得 $2。", "big": "实验后首次进店 +$2",
		"lore": "绝对的圣遗物！余额永远是 3.5 元。"},
	"red_flag": {"kind": "relic", "name": "安全生产流动红旗", "rarity": RARE, "price": 34,
		"desc": "本阶段还没发生过束流丢失时，引出价值 ×1.4。", "big": "阶段无丢失：引出价值 ×1.4",
		"lore": "今年终于要被收回了。"},
	"crooked_seal": {"kind": "relic", "name": "盖歪了的公章", "rarity": RARE, "price": 36,
		"desc": "过阶段奖金 ×2。", "big": "过阶段奖金 ×2",
		"lore": "盖上去之前谁都不知道它会歪向哪边。"},
	# —— M3 第 5 批：金属 ——
	"screw": {"kind": "relic", "name": "隔壁实验室的螺丝", "rarity": UNCOMMON, "price": 22,
		"desc": "不占饰品槽，整局只能持有一个。每次加速 3% 概率潜在成果翻倍，2% 概率额外触发一次束流丢失判定。", "big": "3%成果翻倍 · 2%判丢失",
		"lore": "装不上去，但扔了又觉得可惜。"},
	"lab8_key": {"kind": "relic", "name": "第八号实验室的钥匙", "rarity": RARE, "price": 36,
		"desc": "每次刷新商店，10% 概率额外出现一件免费饰品。", "big": "刷新10%出现免费饰品",
		"lore": "我们学校没有八号实验室。"},
	"extinguisher": {"kind": "relic", "name": "检查日期写着“待定”的灭火器", "rarity": COMMON, "price": 14,
		"desc": "每阶段首次束流丢失时，若能级 ≤ 6，改为保持稳定。", "big": "阶段首次丢失可变稳定",
		"lore": "领导检查之前填写日期。"},
	"wrench": {"kind": "relic", "name": "隔壁组借走没还的扳手", "rarity": RARE, "price": 38,
		"desc": "设备槽 +1。", "big": "设备槽 +1",
		"lore": "我借扳手是为了用，我都用到扳手了我还什么。"},
	# —— M3 第 6 批：电子 ——
	"emergency_call": {"kind": "relic", "name": "教授的紧急联系电话", "rarity": LEGEND, "price": 56,
		"desc": "每阶段首次束流丢失时，直接抵挡破碎并保留全部当前价值，允许继续实验。", "big": "每阶段首次丢失可抵挡",
		"lore": "非紧急情况不要打。"},
	"red_button": {"kind": "relic", "name": "绝对不能按的红色按钮", "rarity": LEGEND, "price": 50,
		"desc": "控制台多出一个红按钮，每次实验可按一次，概率公开：潜在成果 ×10（10%）／立即进入 4 次锁相（25%）／当前束流直接丢失（35%）／获得一件随机精良以上饰品（30%）。", "big": "红按钮：随机改变实验",
		"lore": "屎山代码的一部分"},
	"printer": {"kind": "relic", "name": "总在交稿前卡纸的打印机", "rarity": COMMON, "price": 14,
		"desc": "商店刷新费用不再翻倍。", "big": "刷新费用不再翻倍",
		"lore": "它只在交稿前一小时卡纸。"},
	"last_slide": {"kind": "relic", "name": "组会 PPT 的最后一页", "rarity": UNCOMMON, "price": 26,
		"desc": "每阶段最后一次实验，科研价值 ×1.5。", "big": "阶段最后实验：价值 ×1.5",
		"lore": "谢谢大家，欢迎批评指正。"},
	"calc7": {"kind": "relic", "name": "按什么都等于 7 的计算器", "rarity": UNCOMMON, "price": 24,
		"desc": "引出时 7% 概率科研价值 ×3。", "big": "引出7%：价值 ×3",
		"lore": "按什么都等于7。"},
	# —— M3 第 7 批：书籍 / 吉祥物 ——
	"impossible": {"kind": "relic", "name": "《这个结果不可能》", "rarity": LEGEND, "price": 52,
		"desc": "完美同步发生时，若抽取前它的概率低于 5%，当前科研价值 ×5。每次实验最多一次。", "big": "低概率完美同步：价值 ×5",
		"lore": "审稿人要求解释实验结果，作者表示自己也想知道。"},
	"schrodinger": {"kind": "relic", "name": "薛定谔的实验报告", "rarity": LEGEND, "price": 54,
		"desc": "束流丢失时进入待定：选“结束”保留 30% 科研价值；选“再加速一次”——成功则撤销丢失继续实验，失败则全部归零。每阶段一次。", "big": "丢失时可选择保留或再试",
		"lore": ""},
	"qm_book2": {"kind": "relic", "name": "量子力学（第二册）", "rarity": RARE, "price": 36,
		"desc": "完美同步时 30% 概率额外 +1 能级。", "big": "完美同步30%：能级 +1",
		"lore": "第一册永远都是找不到的。"},
	"plant": {"kind": "relic", "name": "楼道里没人浇水的盆栽", "rarity": COMMON, "price": 14,
		"desc": "每阶段开始时获得 $6。", "big": "每阶段开始获得 $6",
		"lore": "活的比培养皿的微生物好。"},
	"lab_cat": {"kind": "relic", "name": "不属于任何课题组的猫", "rarity": LEGEND, "price": 56,
		"desc": "每次实验第一次束流丢失时，50% 概率改成完美同步。", "big": "首次丢失50%转完美同步",
		"lore": "哈基米南北路多。"},
}

## 污染标签（只改画面，不进数值；DECISIONS 视觉硬规则）
const TAGS := ["纸张", "咖啡", "文具", "钟表", "证章", "照片", "金属", "电子", "书籍", "吉祥物"]
const TAG := {
	"magnet_sc": "金属", "quad_array": "金属", "injector_hi": "电子", "collimator": "金属", "rf_backup": "电子", "diagnostic": "电子",
	"dean_paper": "纸张", "eraser": "文具", "coin": "金属", "badge": "证章", "note100": "纸张", "wrong_answer": "纸张",
	"koi": "照片", "ultimatum": "纸张", "lucky_cat": "吉祥物", "rejected": "书籍", "dean_pen": "文具", "chair": "金属",
	"budget": "纸张", "coffee": "咖啡", "fast_clock": "钟表",
	"lost_data": "纸张", "calib_log": "纸张", "duty_roster": "纸张", "third_draft": "纸张", "reimburse": "纸张",
	"applications": "纸张", "nobel_list": "纸张",
	"coffee_cup": "咖啡", "thermos": "咖啡", "alarm_4am": "钟表",
	"bandaid": "文具", "marker": "文具", "wipes": "文具", "tape_roll": "文具",
	"rec_letter": "证章", "grad_promise": "证章", "phd_cert": "证章", "dose_card": "证章",
	"meal_card": "证章", "red_flag": "证章", "crooked_seal": "证章",
	"rf_cavity": "金属", "extractor": "金属", "cryo_magnet": "金属", "beam_dump": "金属",
	"screw": "金属", "lab8_key": "金属", "extinguisher": "金属", "wrench": "金属",
	"calorimeter": "电子", "protect_sys": "电子", "daq": "电子", "lock_loop": "电子", "bpm": "电子",
	"emergency_call": "电子", "red_button": "电子", "printer": "电子", "last_slide": "电子", "calc7": "电子",
	"impossible": "书籍", "schrodinger": "书籍", "qm_book2": "书籍", "plant": "吉祥物", "lab_cat": "吉祥物",
}
## 基础池（DECISIONS Q36）：首局就会出现；其余等 M5 局外进度解锁（M5 之前全部进池）
const BASE := ["magnet_sc", "quad_array", "collimator", "rf_backup", "diagnostic", "injector_hi",
	"eraser", "coin", "badge", "note100", "wrong_answer", "koi", "lucky_cat", "chair", "budget", "coffee",
	"duty_roster", "third_draft", "reimburse", "coffee_cup", "bandaid", "marker", "wipes", "tape_roll", "meal_card", "dose_card", "extractor", "beam_dump", "extinguisher", "bpm", "printer", "daq", "plant", "qm_book2"]

static func tag_of(id: String) -> String:
	return TAG.get(id, "")

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

# —— 组合（圣遗物改造第三步，Q75）：商店里能和已持有物品搭配的商品贴“和某某一套”小签 ——
const COMBOS := [
	{"name": "稳定修稿", "ids": ["tape_roll", "badge", "diagnostic", "third_draft", "thermos"]},
	{"name": "拒稿反击", "ids": ["rejected", "grad_promise", "wrong_answer"]},
	{"name": "劫后再战", "ids": ["reimburse", "beam_dump", "lost_data"]},
]
const SHORT := {"tape_roll": "胶带", "badge": "工牌", "diagnostic": "诊断仪", "third_draft": "修改稿", "thermos": "保温杯",
	"rejected": "拒稿论文", "grad_promise": "毕业承诺", "wrong_answer": "错误答案",
	"reimburse": "报销单", "beam_dump": "收集靶", "lost_data": "忘存的数据"}

## 商品 id 和手上已有的哪件是一套：返回 {combo: 组合名, with: 已有那件的短名}；没有返回 {}
static func combo_with(id: String, owned: Array) -> Dictionary:
	for c in COMBOS:
		if not c.ids.has(id):
			continue
		for o in owned:
			if o != id and c.ids.has(o):
				return {"combo": c.name, "with": SHORT.get(o, o)}
	return {}
