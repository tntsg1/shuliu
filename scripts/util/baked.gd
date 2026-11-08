class_name Baked
extends Node2D
## 烘焙层：不变的画面只画一次，之后只在 key 变化或换配色时重画。
## 会动的部分靠移动 position / rotation / modulate，不重画。
## 用法：var b := Baked.make(self, func(ci): ..., true)；每帧 b.set_key([...]) 和 b.position = ...
## behind=true 时垫在父节点自己画的东西下面（show_behind_parent）。

var paint: Callable
var key = null

static func make(parent: Node, p: Callable, behind := false) -> Baked:
	var b := Baked.new()
	b.paint = p
	b.show_behind_parent = behind
	parent.add_child(b)
	return b

func _ready() -> void:
	Pal.changed.connect(queue_redraw)

func set_key(k) -> void:
	if k != key:
		key = k
		queue_redraw()

func _draw() -> void:
	if paint.is_valid():
		paint.call(self)
