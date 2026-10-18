extends CharacterBody2D
class_name Player

const SPEED = 48.0
const GRAVITY = 600.0
const FRICTION = 400.0

@onready var game_manager : GameManager = get_tree().get_first_node_in_group("Holder")

var terminal_count = 0
var machine : TerminalMachine = null

var map_unlocked : bool = false
var looking_at_map : bool = false


var stuck_query := PhysicsShapeQueryParameters2D.new()
var stuck_timer : float = 0.0
var last_safe_position : Vector2





func _ready() -> void:
	Bus.player = self
	$AudioListener2D.make_current()
	
	stuck_query.shape = ($CollisionShape2D.shape.duplicate() as RectangleShape2D)
	stuck_query.shape.size -= Vector2(1.0, 1.0)
	stuck_query.collision_mask = collision_mask
	stuck_query.exclude = [get_rid()]
	last_safe_position = global_position
	

func _process(delta: float) -> void:
	var direction := 0.0
	
	if machine != null:
		last_safe_position = machine.global_position
	
	if not looking_at_map:
		direction = Input.get_axis("move_left", "move_right")

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y -= 150.0
			$AudioStreamPlayer.play()
	
	if direction != 0.0:
		velocity.x = direction * SPEED
		if not $WalkPlayer.playing and is_on_floor():
			$WalkPlayer.play()
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	
	velocity.y += GRAVITY * delta
	if (velocity.y > 250.0):
		velocity.y = 250.0
	
	move_and_slide()
	
	
	stuck_query.transform = $CollisionShape2D.global_transform
	var overlapping : bool = not get_world_2d().direct_space_state.intersect_shape(stuck_query, 1).is_empty()
	if overlapping:
		stuck_timer += delta
		if stuck_timer > 1.5:
			global_position = last_safe_position
			velocity = Vector2.ZERO
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0


	# Terminal-related
	if game_manager.terminal_active:
		if direction != 0.0 or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
			game_manager.terminal_active = false
	
	else:
		if terminal_count > 0 and machine != null and Input.is_action_just_pressed("interact"):
			game_manager.terminal_active = true
			game_manager.set_terminal_mask(machine.key_mask)
	
	# Map-related
	if Input.is_action_just_pressed("bigmap") and map_unlocked and not game_manager.terminal_active:
		looking_at_map = not looking_at_map
	
	# Anim
	if direction < -0.1:
		$Sprite2D.flip_h = true
	elif direction > 0.1:
		$Sprite2D.flip_h = false
	
	if abs(velocity.x) > 10.0:
		$AnimationPlayer.play("run")
	else:
		$AnimationPlayer.play("idle")
	
	
	
