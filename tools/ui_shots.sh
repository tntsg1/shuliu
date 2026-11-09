#!/usr/bin/env bash
# 界面整改前后截图：跑现有截图测试，把关键几张复制到 shots/art_ui/<tag>_*.png。用法: tools/ui_shots.sh before|after
cd "$(dirname "$0")/.."
tag="$1"
mkdir -p shots/art_ui
for t in title_shots shop_card_shots tutorial_shots hud_shots review_shots; do
	timeout 150 bash tools/run_test.sh tests/$t.gd > /dev/null 2>&1 || echo "fail $t"
done
for n in title_01 title_04_settings shop_cards_light shop_cards_dark shop_card_mouse_tip tut_02_letter_full hud_01_short hud_04_freq_open rv_01_tally rv_03_review rv_04_passed; do
	cp "shots/$n.png" "shots/art_ui/${tag}_$n.png" 2>/dev/null || echo "missing $n"
done
echo "ui shots $tag done"
