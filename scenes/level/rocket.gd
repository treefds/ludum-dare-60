extends Node2D
class_name Rocket

# CUTSCENE MANAGER

var started : bool = false
@onready var rocket_center: Node2D = $RocketCenter
@export var bg_tilemap_layer: TileMapLayer

func _ready() -> void:
	assert(bg_tilemap_layer != null)
	$RocketCenter/Scaffold.position = Vector2.ZERO
	Bus.rocket = self
	pass

func launch():
	if started:
		return
	started = true
	Bus.cutscening = true
	Bus.fog.active = false
	Bus.fog.queue_redraw()
	
	Bus.player.reparent(self)
	
	$ClosurePlayer.play()
	$RocketCenter/HGate2.target_queue.append(0)
	
	$RocketCenter/Scaffold.position.y = 48.0
	var tween = get_tree().create_tween()
	tween.tween_property($RocketCenter/Scaffold, "position", Vector2(0., 136.0), 10.0)
	await tween.finished
	
	await get_tree().create_timer(2.5).timeout
	$RocketCenter/Scaffold/GPUParticleL.emitting = true
	$RocketCenter/Scaffold/GPUParticleR.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	
	Bus.player.velocity = Vector2.ZERO
	Bus.player.looking_at_map = false
	
	var rocket_tiles: TileMapLayer = $TileMapLayerRocket
	var rocket_bounds := rocket_tiles.get_used_rect()
	var tile_size := Vector2(rocket_tiles.tile_set.tile_size)
	

	
	var roof_left := rocket_tiles.to_global(Vector2(rocket_bounds.position) * tile_size)
	var roof_right := rocket_tiles.to_global(Vector2(rocket_bounds.end) * tile_size)
	var roof_offset_y := roof_left.y - global_position.y
	var left_column := bg_tilemap_layer.local_to_map(bg_tilemap_layer.to_local(roof_left)).x
	var right_column := bg_tilemap_layer.local_to_map(bg_tilemap_layer.to_local(roof_right - Vector2(1.0, 0.0))).x
	var first_row := bg_tilemap_layer.local_to_map(bg_tilemap_layer.to_local(roof_left - Vector2(0.0, 1.0))).y
	var last_row := first_row
	for cell in bg_tilemap_layer.get_used_cells():
		if cell.x >= left_column and cell.x <= right_column and cell.y <= first_row:
			last_row = mini(last_row, cell.y)
	
	# go to ceiling before starting breaking
	tween = get_tree().create_tween()
	tween.tween_property(self, "position:y", position.y + 6.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# close up gate with filler blocks
	var gate_cell := rocket_tiles.local_to_map(rocket_tiles.to_local($RocketCenter/HGate2.global_position))
	rocket_tiles.set_cell(gate_cell, 0, Vector2i(2, 6))
	rocket_tiles.set_cell(gate_cell + Vector2i.RIGHT, 0, Vector2i(2, 6))
	rocket_tiles.set_cell(gate_cell + Vector2i.LEFT, 0, Vector2i(2, 6))
	
	for row in range(first_row, last_row - 1, -1):
		var progress := float(first_row - row) / maxf(first_row - last_row, 1.0)
		var speed := lerpf(24.0, 240.0, progress)
		var hit_roof := false
		for column in range(left_column, right_column + 1):
			var cell := Vector2i(column, row)
			if bg_tilemap_layer.get_cell_source_id(cell) != -1:
				hit_roof = true
				bg_tilemap_layer.erase_cell(cell)
		
		if hit_roof:
			# bursts
			$RockPlayer.play()
			var debris: GPUParticles2D = $RoofParticle.duplicate()
			add_child(debris)
			debris.global_position = Vector2((roof_left.x + roof_right.x) * 0.5, roof_offset_y + global_position.y)
			debris.local_coords = false
			debris.explosiveness = 1.0
			debris.finished.connect(debris.queue_free)
			debris.restart()
			debris.emitting = true
			await get_tree().create_timer(lerpf(0.12, 0.02, progress)).timeout
		
		var next_roof_y = bg_tilemap_layer.to_global(bg_tilemap_layer.map_to_local(Vector2i(left_column, row))).y - bg_tilemap_layer.tile_set.tile_size.y * 0.5
		tween = get_tree().create_tween()
		tween.tween_property(self, "global_position:y", next_roof_y - roof_offset_y, absf(next_roof_y - (roof_offset_y + global_position.y)) / speed)
		await tween.finished
	
	$AudioStreamPlayer.play()
	var flight_duration = maxf((global_position.y + 4000.0) / 240.0, 0.0)
	var space_bg: Sprite2D = $Bg
	space_bg.position = rocket_center.position
	space_bg.modulate.a = 0.0
	space_bg.show()
	tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, "global_position:y", -4000.0, flight_duration)
	tween.tween_property(space_bg, "modulate:a", 1.0, minf(6.0, flight_duration))
	tween.tween_property(space_bg, "position:y", space_bg.position.y + flight_duration * 4.0, flight_duration)
	await tween.finished
	
	# done?
