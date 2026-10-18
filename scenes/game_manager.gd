extends Control
class_name GameManager


var codable_map : Dictionary[String, Node] = { }

var terminal_active : bool = false:
	set(value):
		if terminal_active and not value:
			if Bus.player.machine != null:
				Bus.player.machine.cached_passcodes = $Terminal.passcodes
		elif not terminal_active and value:
			if Bus.player.machine != null:
				$Terminal.passcodes = Bus.player.machine.cached_passcodes
				for i in range($Terminal.coderefs.size()):
					$Terminal.coderefs[i].frame = 15
				for i in range($Terminal.passcodes.size()):
					$Terminal.coderefs[i].frame = $Terminal.passcodes[i]
		terminal_active = value
		$Terminal.visible = terminal_active
		
		

func set_terminal_mask(mask: int):
	$Terminal.set_mask(mask)

func _ready():
	Bus.game_manager = self
	$ThxForPlaying.visible = false
	$ThxForPlaying.modulate.a = 0.
	
	
	for node in get_tree().get_nodes_in_group("Codable"):
		if not node.get("codename"):
			continue
		
		codable_map[node.get("codename")] = node

func _process(delta: float) -> void:
	if Bus.player.global_position.y < -1000:
		$ThxForPlaying.visible = true
		$ThxForPlaying.modulate.a = lerp($ThxForPlaying.modulate.a, 1.0, delta * 1.0)
