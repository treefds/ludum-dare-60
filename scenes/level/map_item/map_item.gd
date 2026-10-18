extends Area2D


var floaty_timer : float = 0.0
var unlocked : bool = false

var sprite_base_y = 0.0

func _ready() -> void:
	$HintSprite.visible = false
	body_entered.connect(_on_entered)
	pass

func _process(delta: float) -> void:
	floaty_timer += delta
	
	if floaty_timer > 4 * PI:
		floaty_timer -= 2 * PI
	
	$Sprite2D.position.y = sin(floaty_timer) * 2.0 + sprite_base_y
	$HintSprite.position.y = sin(floaty_timer) * 2.0 - 48.0

func _on_entered(other : Node2D):
	if unlocked:
		return
	if other != Bus.player:
		print("??")
		return
	unlocked = true
	# Realizing how bad this pattern of programming is.
	# every external object editing the player directly...!
	Bus.player.map_unlocked = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "sprite_base_y", -16.0, 1.5)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	await tween.finished
	
	
	$GPUParticles2D.amount = 28
	await get_tree().create_timer(2.0).timeout
	$GPUParticles2D.emitting = false
	$Sprite2D.visible = false
	$HintSprite.visible = true
	
