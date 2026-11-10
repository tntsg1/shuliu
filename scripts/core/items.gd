class_name Items
## 物品数据（M2 首批：15 件饰品 + 6 种设备）。名称、描述、物品故事取自用户确认的 GDD，原样保留；
## 数值按游戏当前尺度（RP 数百、经费数十）换算；原 GDD 的维修费已取消（FULL_GAME_PLAN F12）。

enum { COMMON, UNCOMMON, RARE, LEGEND }
const RARITY_NAME := ["普通", "精良", "稀有", "传说"]

## kind: relic 饰品 / device 设备
const ALL := {
	# —— 设备 ——
	"magnet_sc": {"kind": "device", "name": "超导弯转磁铁", "rarity": UNCOMMON, "price": 24,
		"desc": "束流丢失概率降低至原来的 85%。", "big": "丢失率 ×0.85", "lore": "以前每次调整束流方向，总会损失一部分粒子。换上这套磁铁以后，情况总算好了不少。"},
	"quad_array": {"kind": "device", "name": "四极聚焦阵列", "rarity": UNCOMMON, "price": 26,
		"desc": "加速成功概率提高 12 个百分点。", "big": "成功率 +12%", "lore": "当初为了调好这四块磁铁，实验室的人折腾了整整一个下午，好在最后的效果确实不错。"},
	"injector_hi": {"kind": "device", "name": "高流强注入器", "rarity": RARE, "price": 34,
		"desc": "基础科研价值提高至原来的 1.5 倍，束流丢失概率增加 5 个百分点。", "big": "价值 ×1.5 · 丢失 +5%", "lore": "说明书第一页写着“请勿超过额定流强”，第二页已经被人撕掉了。"},
	"collimator": {"kind": "device", "name": "精密准直器", "rarity": COMMON, "price": 16,
		"desc": "束流丢失概率降低至原来的 88%，但基础科研价值减少 10%。", "big": "丢失率 ×0.88 · 价值 −10%", "lore": "安装以后，束流确实稳定了不少，不过有些原本能用的粒子也被一起过滤掉了。"},
	"rf_backup": {"kind": "device", "name": "冗余射频控制器", "rarity": COMMON, "price": 18,
		"desc": "完美同步概率提高 6 个百分点。", "big": "完美同步率 +6%", "lore": "主控制器坏掉了好几年后维修人员才发现旁边还装着一套备用控制器，而且它已经正常运行了好几年。"},
	"diagnostic": {"kind": "device", "name": "快速束流诊断仪", "rarity": UNCOMMON, "price": 22,
		"desc": "每次实验中，第一次出现失谐时会自动恢复稳定状态。", "big": "首次失谐转为稳定", "lore": "以前发现束流失谐以后，研究人员还得花半天时间检查原因。自从换了这台设备，第一次失谐基本不用他们操心了。"},
	# —— M3 第 5 批：金属设备 ——
	"rf_cavity": {"kind": "device", "name": "高频射频腔", "rarity": RARE, "price": 36,
		"desc": "完美同步额外 +1 能级。", "big": "完美同步：能级 +1", "lore": "共振的时候，整层楼的窗户都在嗡嗡响。"},
	"extractor": {"kind": "device", "name": "高效束流引出器", "rarity": COMMON, "price": 16,
		"desc": "主动引出束流时，最终获得的科研价值提高 20%。", "big": "引出价值 +20%", "lore": "以前引出束流总会损失一部分能量，后来换了这台设备，终于能多保留一些实验成果了。"},
	"cryo_magnet": {"kind": "device", "name": "低温磁体升级", "rarity": RARE, "price": 34,
		"desc": "当束流能级达到 10 级或更高时，束流丢失概率降低至原来的 75%。", "big": "能级 ≥10：丢失率 ×0.75", "lore": "这套磁体需要保持在零下二百六十九度，负责采购的研究员看完电费账单以后，觉得自己也快到这个温度了。"},
	"beam_dump": {"kind": "device", "name": "束流收集靶", "rarity": COMMON, "price": 14,
		"desc": "束流丢失时，按照当前能级 × 2 的金额返还经费。", "big": "丢失返还 $能级×2", "lore": "研究人员本来只是想回收一点实验材料，后来财务处发现，连失败的实验都能收回一些成本。"},
	# —— M3 第 6 批：电子设备 ——
	"calorimeter": {"kind": "device", "name": "高分辨率量能器", "rarity": UNCOMMON, "price": 26,
		"desc": "能级 ≥ 8 时科研价值 ×1.6。", "big": "能级≥8：价值 ×1.6", "lore": "能量越高，它越来劲。"},
	"protect_sys": {"kind": "device", "name": "束流保护系统", "rarity": UNCOMMON, "price": 24,
		"desc": "每个阶段第一次发生束流丢失时，仍可保留 30% 的科研价值。", "big": "每阶段首次丢失保留 30%", "lore": "设计使用寿命只有十五年，到现在已经用了二十二年。"},
	"daq": {"kind": "device", "name": "多级数据采集器", "rarity": UNCOMMON, "price": 24,
		"desc": "本次实验中，每次连续成功都会使结算收益提高 3%，最多提高 60%。", "big": "连胜：结算 +3%", "lore": "实验室以前经常有人忘记记录实验结果，后来装了这套设备，每次实验的数据都有保存，连十年前的记录都能查到。"},
	"lock_loop": {"kind": "device", "name": "锁相反馈回路", "rarity": UNCOMMON, "price": 26,
		"desc": "进入锁相状态后，可以额外进行 1 次安全加速。", "big": "锁相安全加速 +1", "lore": "技术员花了一个星期才把参数调整好，后来发现连一部分背景噪声都被算进了锁相范围，只好重新调整。"},
	"bpm": {"kind": "device", "name": "束流位置监测器", "rarity": COMMON, "price": 18,
		"desc": "保持稳定概率的一半转给加速成功。", "big": "稳定概率一半转成功", "lore": "束流歪一点点，它就会尖叫。"},
	# —— 饰品 ——
	"dean_paper": {"kind": "relic", "name": "校长几年前用过的实验稿纸", "rarity": RARE, "price": 42,
		"desc": "每局第一次发生无法被其他效果阻止的束流丢失时，可以保留当前科研价值的 80%，但本次实验会直接结束。", "big": "每局首次束流丢失：保留 80% 科研价值",
		"lore": "我们找到了校长当年疯狂吹牛说是发了sci论文……的草稿"},
	"eraser": {"kind": "relic", "name": "延毕学长的橡皮", "rarity": UNCOMMON, "price": 24, "uses": 3,
		"desc": "每次出现失谐时，都会自动重新抽取一次结果。最多可以使用 3 次，次数用完后，这件物品就会消失。", "big": "出现失谐时重新抽取结果，最多 3 次",
		"lore": "这算是圣遗物吗？真的能用吗？"},
	"coin": {"kind": "relic", "name": "祖传幸运硬币", "rarity": UNCOMMON, "price": 28,
		"desc": "每次实验首次发生束流丢失时，会抛一次硬币。如果结果是正面，就能避免这次束流破碎，每次实验最多触发一次。", "big": "束流丢失时抛硬币，正面可以抵挡破碎",
		"lore": "据说是从上一任学长手里传下来的。"},
	"badge": {"kind": "relic", "name": "学姐留下的工牌", "rarity": COMMON, "price": 12,
		"desc": "每个阶段第一次出现失谐时，会自动将这次结果改为「保持稳定」。", "big": "每阶段首次失谐自动恢复稳定",
		"lore": "她已经毕业三年了，圣遗物。"},
	"note100": {"kind": "relic", "name": "写着“求求实验通过吧”的便利贴", "rarity": RARE, "price": 20, "consumable": true,
		"desc": "消耗品：当普通成功和完美同步的总概率达到 75% 时，可以保证下一次加速至少获得普通成功，效果触发后物品就会被消耗。", "big": "成功率达到 75% 后，下次加速必定成功",
		"lore": "看起来是哪个绝望的学长写的。"},
	"wrong_answer": {"kind": "relic", "name": "学弟的错误答案", "rarity": UNCOMMON, "price": 22,
		"desc": "每次出现失谐时，都有 20% 的概率将这次结果改为「完美同步」。", "big": "每次失谐有 20% 概率变成完美同步",
		"lore": "虽然过程非常的严谨，但是实验方向一开始就错了。"},
	"koi": {"kind": "relic", "name": "实验室门口的锦鲤照片", "rarity": COMMON, "price": 14,
		"desc": "每次达到完美同步，就能积累 1 层好运，每层好运都会让束流丢失概率变为原来的 95%，每次实验最多可以积累 5 层。", "big": "每次完美同步，束流丢失概率 ×0.95",
		"lore": "浪费墨水"},
	"ultimatum": {"kind": "relic", "name": "导师的最后通牒", "rarity": RARE, "price": 38,
		"desc": "每次实验的前 3 次加速都能保证至少普通成功，不过从第 4 次加速开始，束流丢失概率就会提高 10 个百分点，直到本次实验结束。", "big": "前 3 次加速必定成功，之后丢失概率 +10%",
		"lore": "“我的耐心已经被你们耗完了！这是最后一次机会！”"},
	"lucky_cat": {"kind": "relic", "name": "实验室的招财猫", "rarity": COMMON, "price": 12,
		"desc": "每次成功加速时，都有 8% 的概率额外获得 $3。如果连续两次触发这项奖励，第二次获得的金额就会翻倍。", "big": "每次成功加速有 8% 概率获得 $3",
		"lore": "一直在招手。"},
	"rejected": {"kind": "relic", "name": "被拒稿十七次的论文", "rarity": UNCOMMON, "price": 24,
		"desc": "每次出现失谐都会积累 1 层怨气，积累到 3 层以后，下一次成功加速就能额外提升 3 级能级，同时清空之前积累的怨气。", "big": "累计失谐 3 次，下次成功额外提升 3 级",
		"lore": "“我其实所有单数次的交稿都是一模一样的，但是不知道为什么这次过了”"},
	"dean_pen": {"kind": "relic", "name": "校长的签名笔", "rarity": RARE, "price": 40,
		"desc": "每个阶段第一次成功引出的实验，可以获得 3 倍科研价值，不过该阶段之后进行的实验，科研价值都会降低至原来的 80%。", "big": "阶段首次引出价值 ×3，后续实验价值 ×0.8",
		"lore": "校长亲自批的项目，经费多到用不完。"},
	"chair": {"kind": "relic", "name": "实验室唯一的好椅子", "rarity": COMMON, "price": 16,
		"desc": "连续成功加速时，每成功一次，科研倍率就会额外增加 0.2。一旦出现失谐或保持稳定，这件饰品之前积累的额外倍率就会全部清零。", "big": "连续成功：科研倍率 +0.2",
		"lore": "不知道是谁偷偷换了的新的椅子。"},
	"budget": {"kind": "relic", "name": "去年没用完的经费", "rarity": UNCOMMON, "price": 22,
		"desc": "引出实验时，每持有 $10 经费，就能让本次科研得分提高 5%，最多可以提高 50%。", "big": "每持有 $10，经引出获得的科研分数 +5%",
		"lore": "再不花完，明年的预算就要被削了。"},
	"coffee": {"kind": "relic", "name": "博士生早上没喝完的咖啡", "rarity": UNCOMMON, "price": 26,
		"desc": "连续成功加速 3 次后，可以自动获得一次锁相窗口，在接下来的 3 次加速中不会发生束流丢失。每次实验最多触发一次。", "big": "连续成功 3 次，获得 3 次锁相机会",
		"lore": "早上九点还有组会。"},
	"fast_clock": {"kind": "relic", "name": "快五分钟的闹钟", "rarity": RARE, "price": 34,
		"desc": "所有锁相窗口都会额外增加 2 次安全加速机会，不过每次实验的第一次加速，束流丢失概率会额外提高 5 个百分点。", "big": "锁相次数 +2，首次加速丢失概率 +5%",
		"lore": "屎山代码能用就不要改，不知道为什么一调回来就一下快一下慢。"},
	# —— M3 第 1 批：纸张 ——
	"lost_data": {"kind": "relic", "name": "那次忘记保存的数据", "rarity": RARE, "price": 36,
		"desc": "如果束流在本局潜在科研成果达到最高值时发生丢失，下次引出实验时，可以额外获得本次损失科研价值的 15%，下一束流的初始锁相充能最多还能增加 2 格，但这些充能不会直接触发锁相。每个阶段最多触发一次。", "big": "最高科研成果丢失时，返还 15% 价值，并为下一束流充能",
		"lore": "“我记得我明明把资料放在桌子上啊”。"},
	"calib_log": {"kind": "relic", "name": "设备校准记录", "rarity": LEGEND, "price": 58,
		"desc": "触发锁相需要的充能从原来的 6 格降低到 4 格。", "big": "锁相充能从 6 格减少到 4 格",
		"lore": "维护记录：一切正常 日期：2000年3月5日。"},
	"duty_roster": {"kind": "relic", "name": "周末值班表", "rarity": COMMON, "price": 12,
		"desc": "每次实验进行第一次加速时，加速成功概率都会提高 15 个百分点。", "big": "每次实验首次加速，成功概率 +15%",
		"lore": "“怎么又是我值班啊？”"},
	"third_draft": {"kind": "relic", "name": "修改稿第三版", "rarity": UNCOMMON, "price": 22,
		"desc": "每次出现保持稳定，本次实验的科研倍率就会增加 0.1，最多可以累计增加 1.0。在当前束流触发锁相之前，每累计 2 次保持稳定，还可以额外获得 1 格锁相充能。", "big": "每次保持稳定，科研倍率 +0.1；累计 2 次稳定，额外充能 1 格",
		"lore": "和第一版一字不差。"},
	"reimburse": {"kind": "relic", "name": "被退回的报销申请单", "rarity": UNCOMMON, "price": 22,
		"desc": "每次发生束流丢失时，都可以获得 $8 的额外经费。", "big": "每次束流丢失，获得 $8 经费",
		"lore": "“你没发票我给你报销个蛋呢”"},
	"applications": {"kind": "relic", "name": "填不完的申报书", "rarity": UNCOMMON, "price": 22,
		"desc": "每次商店进货或刷新商品后，购买第一件商品时都可以享受半价优惠。", "big": "每次进货或刷新商店后，首件商品半价",
		"lore": "我就要10支水笔，怎么要我填10个申请表啊。"},
	"nobel_list": {"kind": "relic", "name": "去年的诺奖预测名单", "rarity": LEGEND, "price": 52,
		"desc": "当束流能级达到 12 级或更高时，超级同步的概率会提高至原来的 2 倍，而且每次成功加速都能额外获得 $4。", "big": "能级达到 12 级后，超级同步概率翻倍",
		"lore": "名单上有你导师。可惜划掉了。"},
	# —— M3 第 2 批：咖啡 / 钟表 ——
	"coffee_cup": {"kind": "relic", "name": "没洗的咖啡杯", "rarity": COMMON, "price": 16,
		"desc": "锁相充能需要的格数从原来的 6 格减少到 5 格。", "big": "锁相充能只需要 5 格",
		"lore": "杯底已经形成了独立的生态系统。"},
	"thermos": {"kind": "relic", "name": "前任主任的保温杯", "rarity": RARE, "price": 38,
		"desc": "在锁相状态下，每次加速都有 25% 的概率不消耗锁相次数。", "big": "使用锁相时，有 25% 概率不消耗次数",
		"lore": "里面的茶垢比这台加速器还历史悠久。"},
	"alarm_4am": {"kind": "relic", "name": "凌晨四点的闹钟", "rarity": RARE, "price": 34,
		"desc": "如果一次实验连续加速 7 次都没有引出，就能获得一次锁相效果，接下来的 4 次加速都不会发生束流丢失。", "big": "连续加速 7 次，获得 4 次锁相机会",
		"lore": "“哪个傻逼定的？”"},
	# —— M3 第 3 批：文具 ——
	"bandaid": {"kind": "relic", "name": "贴在屏幕上的创可贴", "rarity": COMMON, "price": 14,
		"desc": "每次出现「保持稳定」时，都有 40% 的概率将这次结果转变为「加速成功」。", "big": "保持稳定时，有 40% 概率转为普通成功",
		"lore": "原来屏幕坏了吗？"},
	"marker": {"kind": "relic", "name": "会议室的白板笔", "rarity": COMMON, "price": 14,
		"desc": "主动引出束流时，如果本次实验从未出现过失谐，最终获得的科研价值提高 15%。", "big": "没有发生失谐就成功引出，科研价值 +15%",
		"lore": "全都没墨了，不知道为什么在这里。"},
	"wipes": {"kind": "relic", "name": "半盒消毒湿巾", "rarity": COMMON, "price": 12, "consumable": true,
		"desc": "消耗品：下一次实验中，束流丢失概率降低至原来的 82%，效果会持续到本次实验结束，随后消耗这件物品。", "big": "下一次实验中，束流丢失概率 ×0.82",
		"lore": "另外半盒不知道去哪里了。"},
	"tape_roll": {"kind": "relic", "name": "一卷没拆封的胶带", "rarity": COMMON, "price": 12,
		"desc": "每次实验第一次出现射频失谐时，不会降低当前能级，而是将这次结果改为「保持稳定」。", "big": "每次实验首次失谐，自动改为保持稳定",
		"lore": "从哪撕开啊？"},
	# —— M3 第 4 批：证章 ——
	"rec_letter": {"kind": "relic", "name": "系主任的推荐信", "rarity": UNCOMMON, "price": 24,
		"desc": "主动引出束流时，有 25% 的概率让本次科研评分提高 50%。每个阶段成功触发一次后就会暂时失效，进入下一阶段后可以重新触发。", "big": "主动引出时，有 25% 概率让科研评分 +50%",
		"lore": "他甚至没看过实验数据。"},
	"grad_promise": {"kind": "relic", "name": "导师的毕业承诺", "rarity": LEGEND, "price": 50,
		"desc": "每次出现失谐，都会为下一次锁相增加 1 次安全加速机会，最多可以累计 4 次。成功引出束流后，之前积累的次数会全部清零。", "big": "每次出现失谐，下次锁相增加 1 次安全加速",
		"lore": "明年一定能毕业。"},
	"phd_cert": {"kind": "relic", "name": "博士学位证书（未填写姓名）", "rarity": LEGEND, "price": 48,
		"desc": "如果到了本阶段最后一次实验，累计科研分数仍然没有达到要求，那么所有成功结果带来的科研倍率都会额外提高至原来的 2 倍。不过，如果最终还是没能通过评审，本局就无法获得任何局外解锁进度。", "big": "阶段最后一次实验仍未达标时，成功获得的科研倍率 ×2",
		"lore": "先把名字写上去吧。"},
	"dose_card": {"kind": "relic", "name": "过期的辐射剂量卡", "rarity": UNCOMMON, "price": 24,
		"desc": "当束流能级达到 10 级或更高时，完美同步概率提高 8 个百分点。", "big": "能级达到 10 级后，完美同步率提高 8%",
		"lore": "真的过期了吗？"},
	"meal_card": {"kind": "relic", "name": "食堂的饭卡", "rarity": COMMON, "price": 12,
		"desc": "每次实验结束以后，第一次打开采购终端时，可以额外获得 $2 经费。", "big": "每次实验结束后，首次进入商店获得 $2 经费",
		"lore": "绝对的圣遗物！余额永远是 3.5 元。"},
	"red_flag": {"kind": "relic", "name": "安全生产流动红旗", "rarity": RARE, "price": 34,
		"desc": "如果本阶段还没有发生过束流丢失，那么成功引出束流时，科研价值提高至原来的 1.4 倍。", "big": "当前阶段没有发生束流丢失时，引出价值提高至原来的 1.4 倍",
		"lore": "今年终于要被收回了。"},
	"crooked_seal": {"kind": "relic", "name": "盖歪了的公章", "rarity": RARE, "price": 36,
		"desc": "每次通过阶段评审时，获得的阶段奖金提高至原来的 2 倍。", "big": "完成阶段评审后，获得的奖金提高至原来的 2 倍",
		"lore": "盖上去之前谁都不知道它会歪向哪边。"},
	# —— M3 第 5 批：金属 ——
	"screw": {"kind": "relic", "name": "隔壁实验室的螺丝", "rarity": UNCOMMON, "price": 22,
		"desc": "这件物品不占用饰品槽位，每局只能持有一个。每次加速都有 3% 的概率让潜在科研成果翻倍，同时有 2% 的概率额外进行一次束流丢失判定。", "big": "每次加速有 3% 的概率获得双倍科研成果，同时有 2% 的概率额外进行一次束流丢失判定",
		"lore": "装不上去，但扔了又觉得可惜。"},
	"lab8_key": {"kind": "relic", "name": "第八号实验室的钥匙", "rarity": RARE, "price": 36,
		"desc": "每次刷新商店时，都有 10% 的概率额外出现一件可以免费领取的饰品。", "big": "每次刷新商店时，有 10% 的概率出现免费饰品",
		"lore": "我们学校没有八号实验室。"},
	"extinguisher": {"kind": "relic", "name": "检查日期写着“待定”的灭火器", "rarity": COMMON, "price": 14,
		"desc": "每个阶段第一次发生束流丢失时，如果当前能级不超过 6 级，就会将这次结果改为「保持稳定」，避免束流破碎。", "big": "每个阶段第一次发生束流丢失时，若能级不超过 6 级，可以将实验结果改为保持稳定",
		"lore": "领导检查之前填写日期。"},
	"wrench": {"kind": "relic", "name": "隔壁组借走没还的扳手", "rarity": RARE, "price": 38,
		"desc": "设备槽位增加 1 个，可以额外安装一件设备。", "big": "额外增加 1 个设备槽位",
		"lore": "我借扳手是为了用，我都用到扳手了我还什么。"},
	# —— M3 第 6 批：电子 ——
	"emergency_call": {"kind": "relic", "name": "教授的紧急联系电话", "rarity": LEGEND, "price": 56,
		"desc": "每个阶段第一次发生束流丢失时，可以直接避免这次束流破碎，同时保留当前已经积累的全部科研价值，并且允许继续进行实验。", "big": "每个阶段可以抵挡第一次束流丢失",
		"lore": "非紧急情况不要打。"},
	"red_button": {"kind": "relic", "name": "绝对不能按的红色按钮", "rarity": LEGEND, "price": 50,
		"desc": "控制台会增加一个红色按钮，每次实验可以使用一次。按下以后有 10% 的概率让潜在科研成果变为原来的 10 倍，25% 的概率立即进入 4 次锁相，35% 的概率直接丢失当前束流，还有 30% 的概率获得一件随机的精良或更高稀有度饰品。所有效果的触发概率都会提前显示。", "big": "按下红色按钮后，当前实验会发生随机变化",
		"lore": "屎山代码的一部分"},
	"printer": {"kind": "relic", "name": "总在交稿前卡纸的打印机", "rarity": COMMON, "price": 14,
		"desc": "商店刷新费用不再随着刷新次数增加而翻倍。", "big": "刷新商店的费用不再随着刷新次数翻倍",
		"lore": "它只在交稿前一小时卡纸。"},
	"last_slide": {"kind": "relic", "name": "组会 PPT 的最后一页", "rarity": UNCOMMON, "price": 26,
		"desc": "每个阶段最后一次实验的科研价值提高至原来的 1.5 倍。", "big": "每个阶段的最后一次实验，科研价值提高至原来的 1.5 倍",
		"lore": "谢谢大家，欢迎批评指正。"},
	"calc7": {"kind": "relic", "name": "按什么都等于 7 的计算器", "rarity": UNCOMMON, "price": 24,
		"desc": "每次成功引出束流时，都有 7% 的概率让本次科研价值提高至原来的 3 倍。", "big": "成功引出束流时，有 7% 的概率获得 3 倍科研价值",
		"lore": "按什么都等于7。"},
	# —— M3 第 7 批：书籍 / 吉祥物 ——
	"impossible": {"kind": "relic", "name": "《这个结果不可能》", "rarity": LEGEND, "price": 52,
		"desc": "当加速结果为完美同步时，如果本次抽取前的完美同步概率低于 5%，当前科研价值就会提高至原来的 5 倍。每次实验最多触发一次。", "big": "达到完美同步时，有较低的概率获得 5 倍科研价值",
		"lore": "审稿人要求解释实验结果，作者表示自己也想知道。"},
	"schrodinger": {"kind": "relic", "name": "薛定谔的实验报告", "rarity": LEGEND, "price": 54,
		"desc": "发生束流丢失时，你可以选择「结束」或「再加速一次」。选择结束可以保留当前科研价值的 30%；选择继续加速，如果成功，就能撤销这次束流丢失并继续实验，如果失败，之前积累的科研价值就会全部清零。每个阶段只能使用一次。", "big": "发生束流丢失时，可以选择保留当前结果，或者重新尝试一次",
		"lore": ""},
	"qm_book2": {"kind": "relic", "name": "量子力学（第二册）", "rarity": RARE, "price": 36,
		"desc": "每次达到完美同步时，都有 30% 的概率额外提升 1 级能级。", "big": "达到完美同步时，有 30% 的概率额外提升 1 级能级",
		"lore": "第一册永远都是找不到的。"},
	"plant": {"kind": "relic", "name": "楼道里没人浇水的盆栽", "rarity": COMMON, "price": 14,
		"desc": "每个阶段开始时，都可以额外获得 $6 经费。", "big": "每个阶段开始时，额外获得 $6 经费",
		"lore": "活的比培养皿的微生物好。"},
	"lab_cat": {"kind": "relic", "name": "不属于任何课题组的猫", "rarity": LEGEND, "price": 56,
		"desc": "每次实验第一次发生束流丢失时，有 50% 的概率将这次结果改为「完美同步」。", "big": "第一次发生束流丢失时，有 50% 的概率将实验结果改为完美同步",
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
## 基础池（DECISIONS Q36 → M5-10）：首局就会出现的 25 件
const BASE := [   # M5-10：首局 25 件（设备 7 + 饰品 18），其余在教授办公室借阅解锁
	"beam_dump", "collimator", "rf_backup", "bpm", "magnet_sc", "quad_array", "diagnostic",
	"tape_roll", "bandaid", "chair", "duty_roster", "koi", "lucky_cat", "marker", "wipes",
	"coin", "eraser", "third_draft", "rejected", "reimburse", "coffee", "note100", "red_flag", "dean_paper", "lab_cat"]

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
