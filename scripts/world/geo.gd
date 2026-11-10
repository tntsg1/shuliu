class_name Geo
## 场景几何（世界坐标 1920×1080，侧视剖面）

const W := 1920.0
const FLOOR := 800.0
const CEIL := 200.0
const BEAMY := 520.0
const CHAMBER := Vector2(1100, 520)
const CH_SIZE := Vector2(560, 300)
const CONSOLE_X := 880.0          # 控制台左缘
const CONSOLE_STAND := 905.0      # 玩家站位
const TERMINAL_X := 430.0
const DETECTOR_X := 1600.0
const SCREEN := Rect2(1572, 224, 256, 136)
const WALK_MIN := 120.0
const WALK_MAX := 1560.0
# —— 地下储藏室（M5a）：和主实验室一样高的完整房间，货梯上下 ——
const B_CEIL := 822.0             # 储藏室天花板 = 实验室楼板下沿
const B_FLOOR := 1420.0           # 储藏室地面
const LIFT_X := 565.0             # 货梯中心（采购终端和主环平面图之间）
const LIFT_HW := 42.0             # 货梯半宽
const LOST_X := 860.0             # 失物招领箱中心
const B_CAM_Y := 1000.0           # 在储藏室时镜头中心的 y
