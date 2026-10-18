extends Node2D
class_name Fog

var mask : Array[bool] = []

var active : bool = true

func _ready() -> void:
	for i in range(16):
		mask.append(false)
	Bus.fog = self


func _draw() -> void:
	if not active:
		z_index = -100
		draw_rect(Rect2(0, -5000, 1024, 4700), Color(0.2, 0.72, 0.98))
		return
	draw_rect(Rect2(0, -192.0, 1024.0, 192.0), Color(0.05, 0.03, 0.08), true)
	draw_rect(Rect2(0, 3 * 192.0, 1024.0, 192.0), Color(0.05, 0.03, 0.08), true)
	for y in range(3):
		for x in range(4):
			if mask[y * 4 + x]:
				continue
			draw_rect(Rect2(x * 256.0, y * 192.0, 256.0, 192.0), Color(0.15, 0.13, 0.2), true)
