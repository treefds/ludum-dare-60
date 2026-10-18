extends Camera2D


const ROOM_WIDTH = 16 * 16
const ROOM_HEIGHT = 16 * 12
var parent: Player

func _ready() -> void:
	parent = get_parent()

var map_transition : float = 0.0

func _process(delta: float) -> void:
	if parent == null:
		return
	
	var target_position := Vector2(0.0, 0.0)
	@warning_ignore("integer_division")
	target_position.x = (int(parent.global_position.x) / ROOM_WIDTH) * ROOM_WIDTH + ROOM_WIDTH / 2
	@warning_ignore("integer_division")
	target_position.y = (int(parent.global_position.y) / ROOM_HEIGHT) * ROOM_HEIGHT + ROOM_HEIGHT / 2
	
	# very unoptimized but fine
	var mask_index = clamp(int(parent.global_position.x / ROOM_WIDTH) + int(parent.global_position.y / ROOM_HEIGHT) * 4, 0, 15)
	var old = Bus.fog.mask[mask_index]
	Bus.fog.mask[mask_index] = true
	if not old:
		Bus.fog.queue_redraw()
	
	var center_position = Vector2(512.0, 288.0)

	if parent.looking_at_map:
		map_transition = move_toward(map_transition, 1.0, delta * 2.0)
	else:
		map_transition = move_toward(map_transition, 0.0, delta * 2.0)

	if Bus.cutscening:
		global_position = lerp(global_position, Bus.rocket.rocket_center.global_position, delta * 2.0)
	else:
		global_position = lerp(target_position, center_position, map_transition)
	if Bus.cutscening:
		var newval = lerp(zoom.x, 0.5, 3.0 * delta)
		if abs(newval - 0.5) < 0.01:
			newval = 0.5
		zoom.x = newval
		zoom.y = newval
	else:
		zoom.x = lerp(1.0, 0.25, map_transition)
		zoom.y = lerp(1.0, 0.25, map_transition)
		
