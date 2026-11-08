class_name Forms
## 束流形态（design/束流形态.md 第二版）：同一束流越养越怪。
## 主体 = 路线（持有最多的饰品标签）× 档（幼体/成形/成熟），或传说；附加称号叠在上面，不覆盖主体。
## 加成只看引出时的能级档，标签只改样子不改收益。

const TIER_E := [1, 7, 13]
const TIER_NAMES := ["幼体", "成形", "成熟"]
const BONUS := [0.0, 0.10, 0.25]          # 可调：M4 平衡时按实际出现频率再定

## 第一批：标准、纸张、吉祥物三条路线（其余标签第二批补；没做的标签暂走标准路线）
const ROUTE_TAG := {"paper": "纸张", "mascot": "吉祥物"}
const ROUTES := {
	"std": {"names": ["标准束团", "同步束", "对撞之花"], "desc": [
		"教科书上画的那种。",
		"两股束流手拉手，谁也不肯先松开。",
		"轨迹一圈圈交织成花瓣。能级越高，花瓣越多。"]},
	"paper": {"names": ["纸团束", "纸鹤束流", "论文风暴"], "desc": [
		"束流卷起了几页草稿纸。",
		"纸页拼成一只纸鹤，翅膀跟着加速扇。",
		"几百页论文围着束芯卷成龙卷风。"]},
	"mascot": {"names": ["毛线球束", "猫形轨迹", "橘猫束流"], "desc": [
		"轨迹缠成了一团毛线。",
		"毛线拉出了猫耳朵和尾巴。",
		"束流团成一只橘猫，束芯是它甩来甩去的尾巴。"]},
}

## 传说（按优先级）：门槛 E16 / E20 / E25（用户 2026-11-08 定）
const LEGENDS := [
	{"id": "foil", "e": 25, "name": "二向箔", "desc": "整束流被拍成了一张纸。"},
	{"id": "door", "e": 20, "need": "lab8_key", "name": "第八号实验室的门", "desc": "舱里出现了一扇不存在的门，门缝里透出光。"},
	{"id": "bigbang", "e": 20, "name": "宇宙大爆炸", "desc": "一个点炸开成了整片宇宙。"},
	{"id": "blackhole", "e": 16, "name": "黑洞（别担心）", "desc": "周围的径迹都被吸了进去。旁边贴着一张便条：别担心。"},
]

const TRAITS := {
	"saved": {"prefix": "劫后余生的", "name": "劫后余生", "desc": "被饰品救回来过，束芯上留着补丁。"},
	"synced": {"prefix": "完全同步的", "name": "完全同步", "desc": "进过完全同步，外圈多一层严丝合缝的同步环。"},
	"crowned": {"prefix": "戴冠的", "name": "戴冠", "desc": "出过超级同步，束芯上方一圈小冠。"},
}

static func tier_of(e: int) -> int:
	return 2 if e >= TIER_E[2] else (1 if e >= TIER_E[1] else 0)

static func bonus(e: int) -> float:
	return BONUS[tier_of(e)]

## 路线：持有饰品里数量最多的“有路线的”标签；并列取最近买的（列表靠后）
static func route_of(items: Array) -> String:
	var cnt := {}
	var last := {}
	for i in items.size():
		var tg: String = Items.tag_of(items[i])
		for r in ROUTE_TAG:
			if ROUTE_TAG[r] == tg:
				cnt[r] = cnt.get(r, 0) + 1
				last[r] = i
	var best := "std"
	for r in cnt:
		if best == "std" or cnt[r] > cnt[best] or (cnt[r] == cnt[best] and last[r] > last[best]):
			best = r
	return best

static func legend_of(peak: int, items: Array) -> Dictionary:
	for l in LEGENDS:
		if peak >= l.e and (not l.has("need") or items.has(l.need)):
			return l
	return {}

## 预兆：离下一个传说还差几级（0..1，越近越大）
static func omen(e: int, peak: int, items: Array) -> float:
	var best := 0.0
	for l in LEGENDS:
		if l.has("need") and not items.has(l.need):
			continue
		if peak >= l.e:
			continue
		best = maxf(best, clampf(1.0 - float(l.e - e) / 4.0, 0.0, 1.0))
	return best

static func traits_of(b: Beam) -> Array:
	var out: Array = []
	if b.saved: out.append("saved")
	if b.synced: out.append("synced")
	if b.crowned: out.append("crowned")
	return out

## 这一束现在是什么（引出时用它出成果卡）
static func of(run: Run) -> Dictionary:
	var b: Beam = run.beam
	var e: int = b.energy
	var peak: int = maxi(b.peak, e)
	return describe(route_of(run.relics), e, peak, traits_of(b), legend_of(peak, run.relics + run.devices))

static func describe(route: String, e: int, peak: int, traits: Array, leg: Dictionary) -> Dictionary:
	var pt := tier_of(peak)
	var body: String = ROUTES[route].names[pt]
	var d := {"route": route, "tier": pt, "energy": e, "peak": peak, "traits": traits, "legend": leg.get("id", ""),
		"bonus": bonus(e), "damaged": tier_of(e) < pt}
	var prefix := ""
	for tr in traits:
		prefix += TRAITS[tr].prefix
	if leg.is_empty():
		d["id"] = "%s_%d" % [route, pt]
		d["body"] = body
		d["rank"] = TIER_NAMES[pt]
		d["desc"] = ROUTES[route].desc[pt]
		d["from"] = ""
	else:
		d["id"] = leg.id
		d["body"] = leg.name
		d["rank"] = "传说"
		d["desc"] = leg.desc
		d["from"] = "由%s演化而来" % body
	d["name"] = prefix + d.body
	return d

# —— 成果图鉴（user://codex.cfg 的 forms 段；-s 测试不写）——
static func record(d: Dictionary) -> bool:
	var first := Memes.seen_count_in("forms", d.id) == 0
	if Memes._testing():
		return first
	var c := ConfigFile.new()
	c.load(Memes.CODEX)
	c.set_value("forms", d.id, int(c.get_value("forms", d.id, 0)) + 1)
	for tr in d.traits:
		c.set_value("form_traits", tr, int(c.get_value("form_traits", tr, 0)) + 1)
	c.save(Memes.CODEX)
	return first
