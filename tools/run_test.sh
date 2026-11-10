#!/usr/bin/env bash
# 渲染测试：不抢焦点、不碰鼠标（窗口移出屏幕 + 点击穿透）。用法: tools/run_test.sh <test.gd> [args...]
cd "$(dirname "$0")/.."
# 测试结束、被中断、超时都要删掉 override.cfg：它留在项目里会让正式运行的游戏窗口跑到屏幕外（灰屏）
trap 'rm -f override.cfg' EXIT INT TERM HUP
cat > override.cfg <<'CFG'
[display]
window/size/no_focus=true
window/size/initial_position_type=0
window/size/initial_position=Vector2i(-2600, 40)
window/size/always_on_top=false
window/size/window_width_override=1920
window/size/window_height_override=1080

[autoload]
TestWindow="*res://tests/test_window.gd"
CFG
script="$1"; shift
/e/godot/godot47/Godot_v4.7-stable_win64_console.exe --path . --resolution 1920x1080 -s "$script" "$@"
code=$?
rm -f override.cfg
exit $code
