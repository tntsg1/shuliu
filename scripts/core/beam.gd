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

func value_base() -> int:
	return Odds.value_at(energy)

func locked() -> bool:
	return lock_left > 0
