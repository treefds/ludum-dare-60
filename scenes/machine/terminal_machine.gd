extends Area2D
class_name TerminalMachine

@export_flags_2d_physics() var key_mask: int

var cached_passcodes = [ ]

func _ready() -> void:
	body_entered.connect(
		func(_body):
			Bus.player.terminal_count += 1
			Bus.player.machine = self
			$Hint.visible = true
	)
	body_exited.connect(
		func(_body):
			Bus.player.terminal_count -= 1
			Bus.player.machine = null
			$Hint.visible = false
	)
	
