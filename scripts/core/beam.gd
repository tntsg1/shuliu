class_name Beam
extends RefCounted
## 一束粒子的状态（一次实验）。结果判定与饰品效果在 Run 里统一处理

var energy := 1
var charge := 0
var lock_left := 0
var lock_used := false     # 充能锁相（每束一次）
var presses := 0
var streak := 0            # 连续成功（成功/完美）
var alive := true
## 本次实验内的饰品状态
var coin_used := false
var diag_used := false
var coffee_used := false
var koi := 0
var chair := 0.0           # 好椅子累计的额外倍率
var cat_last := false
var guaranteed_next := false   # 便利贴：下一次至少成功
var full_sync := false     # 校准记录：本段锁相为完全同步
var calib_used := false
var draft := 0.0           # 第三版修改稿累计倍率
var draft_stable := 0      # 修改稿：本束稳定次数，用于每两次补充锁相充能
var alarm_used := false    # 凌晨四点的闹钟
var had_detune := false    # 白板笔：本次出现过失谐
var wipes := false         # 消毒湿巾：本次实验全程生效
var tape_used := false
var screw_mult := 1.0       # 螺丝：潜在成果翻倍的累计倍数
var red_mult := 1.0         # 红色按钮 ×10
var red_used := false
var cat_used := false       # 实验室的猫
var imp_mult := 1.0         # 《这个结果不可能》×5
var sch_pending := false    # 薛定谔：等玩家选“结束 / 再加速一次”
var route := "std"          # 束流形态路线（注入时定）
var peak := 1               # 束流形态：这一束到过的最高能级（掉档不退化）
var saved := false          # 被饰品救回来过（劫后余生）
var synced := false         # 进过完全同步
var crowned := false        # 出过超级同步
var sch_gamble := false     # 薛定谔：这一下是赌命的“再加速一次”

func value_base() -> int:
	return Odds.value_at(energy)

func locked() -> bool:
	return lock_left > 0
