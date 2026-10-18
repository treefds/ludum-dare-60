@tool
extends AnimatableBody2D
class_name Platform



# from low to high
@export var current_slot: int = 0:
	set(value):
		#if Engine.is_editor_hint() and (value < 0 or value >= len(slot_positions)):
			#return
		current_slot = value
		if Engine.is_editor_hint() and current_slot < slot_positions.size():
			position = slot_positions[current_slot]
			queue_redraw()

# list of positions
@export var slot_positions : Array[Vector2] = [ ]:
	set(value):
		slot_positions = value
		queue_redraw()

@export var dependency : Platform = null
@export var dependency_leg : int = 0

#Name used by terminal
@export var codename : String = ""
@export var audio_player : AudioStreamPlayer2D

# target slot queue
var target_queue: Array[int] = [ ]
# move progress
var move_timer : float = 0.0
# move flag
enum MoveFlag {IDLE = 0, LAUNCH, MOVING}
var move_flag : MoveFlag = MoveFlag.IDLE


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	#
	#if Input.is_action_just_pressed("ui_up"):
		#target_queue.append(1 - current_slot)
	
	# moving...
	if not target_queue.is_empty():
		do_move(delta)
		if audio_player and not audio_player.playing:
			audio_player.play()
	
	
func do_move(delta):
	assert(not target_queue.is_empty(), "oops")
	var target = target_queue[0]
	
	if move_flag == MoveFlag.IDLE:  #IDLE
		move_flag = MoveFlag.LAUNCH
		move_timer = 0.0
		# trigger shake
	elif move_flag == MoveFlag.LAUNCH:
		move_timer += delta
		if (move_timer > 0.35):
			move_flag = MoveFlag.MOVING
			move_timer = 0.0
			if $AnimationPlayer.has_animation("running") and not $AnimationPlayer.is_playing():
				$AnimationPlayer.play("running")
	else:
		
		position = position.move_toward(slot_positions[target], 48.0 * delta)
		if position == slot_positions[target]:
			move_flag = MoveFlag.IDLE
			current_slot = target
			target_queue.pop_front()
			$AnimationPlayer.stop()
		
		






func _draw() -> void:
	if Engine.is_editor_hint():
		for pos in slot_positions:
			draw_circle(pos - position, 8.0, Color.MAGENTA, true)
		for i in range(0, len(slot_positions) - 1):
			draw_line(slot_positions[i] - position,
				slot_positions[i + 1] - position, Color.YELLOW, 3.0)
		return
	
	
