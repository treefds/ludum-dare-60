extends TextureButton

func _ready() -> void:
	button_down.connect(
		func():
			$Code.position.y = 1
	)
	button_up.connect(
		func():
			$Code.position.y = 0
	)

func _process(delta: float) -> void:
	$Code.visible = not disabled
