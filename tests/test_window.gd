extends Node
# Loaded only while tools/run_test.sh runs: the test window lets every mouse
# click through to whatever is underneath and sits off-screen, so tests never
# take the user's mouse or keyboard.

func _ready() -> void:
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]))
	var scr := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_position(scr.position + scr.size - Vector2i(24, 24))
