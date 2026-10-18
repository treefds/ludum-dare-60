extends Control

var passcodes = []
var coderefs : Array[Sprite2D] = []
var keyrefs : Array[TextureButton] = []

var found_node : Platform = null

func _ready() -> void:
	for i in range(15):
		var node := get_node(str("Sprite/Buttons/ButtonA", i + 1))
		assert(node is TextureButton, "??")
		node = node as TextureButton
		node.button_down.connect(
			func():
				insert_code(i)
		)
		keyrefs.append(node)
	
	for i in range(10):
		var node : Sprite2D = get_node(str("Sprite/Screen/Code", i))
		node.frame = 15
		coderefs.append(node)
	
	$Sprite/ButtonDel.button_down.connect(delete_code)
	$Sprite/ButtonEnt.button_down.connect(confirm_code)
	


func insert_code(code: int) -> bool:
	$ClickPlayer.play()
	var length = passcodes.size()
	if length >= 10:
		return false
	passcodes.append(code)
	coderefs[length].frame = code
	return true

func delete_code() -> bool:
	$ClickPlayer.play()
	var length = passcodes.size()
	if length == 0:
		return false
	
	passcodes.pop_back()
	coderefs[length - 1].frame = 15
	return true

func set_mask(mask: int) -> void:
	for i in range(15):
		var b = mask & 1<<i
		keyrefs[i].disabled = not b


var highlight_start = 0
var highlight_end = 0
var highlight_color = 0  # 0 = red, 1 = yellow, 2 = green


var confirm_lock : bool = false
func confirm_code() -> bool:
	$ClickPlayer.play()
	# consequential
	if confirm_lock:
		return false
	confirm_lock = true
	
	
	var flag = parse()
	if flag >= 2:
		$SuccessPlayer.play()
	else:
		$FailurePlayer.play()
	for i in range(highlight_start, highlight_end):
		coderefs[i].modulate = Color(1, 0, 0, 1) if highlight_color == 0 else Color(1, 1, 0, 1) if highlight_color == 1 else Color(0, 1, 0, 1)
	await get_tree().create_timer(0.1).timeout
	for i in range(0, coderefs.size()):
		coderefs[i].modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	for i in range(highlight_start, highlight_end):
		coderefs[i].modulate = Color(1, 0, 0, 1) if highlight_color == 0 else Color(1, 1, 0, 1) if highlight_color == 1 else Color(0, 1, 0, 1)
	await get_tree().create_timer(0.8).timeout
	for i in range(0, coderefs.size()):
		coderefs[i].modulate = Color(1, 1, 1, 1)
		coderefs[i].frame = 15
	
	if flag == 3:
		Bus.rocket.launch()
		Bus.game_manager.terminal_active = false
	elif flag == 2:
		# commit actions
		
		assert(found_node != null, "?")
		found_node.target_queue = [ ]
		var slot : int = found_node.current_slot
		for i in range(0, passcodes.size()):
			if passcodes[i] != 3 and passcodes[i] != 4:
				break
			slot += 1 if passcodes[i] == 3 else -1
			found_node.target_queue.append(slot)
		
		print(found_node.target_queue)
		passcodes = [ ]
		# close terminal
		Bus.game_manager.terminal_active = false
	passcodes = [ ]
	
	confirm_lock = false
	
	return flag == 2
	
	
	
	





func parse() -> int:
	# parser
	# How does this work?
	# A. check non-empty
	# B. check first symbols (UP or DOWN)
	# C. check name section prefix, see if recognize
	# D. check name section, see if recognize
	# E. check if command executable
	
	# A
	if passcodes.is_empty():
		highlight_start = 0
		highlight_end = 0
		highlight_color = 0
		return 0
	
	# B. check until non arrows
	var ptr : int = 0
	while ptr < passcodes.size():
		if passcodes[ptr] != 3 and passcodes[ptr] != 4:
			break
		ptr += 1
	
	if ptr == 0 or ptr == passcodes.size():
		highlight_start = 0
		highlight_end = 1
		highlight_color = 0
		return 0
	
	# C. check name prefix
	var infix : int = ptr
	if infix not in [0, 1, 2]:
		highlight_start = infix
		highlight_end = infix + 1
		highlight_color = 0
		return 0
	
	# D. check name
	if ptr == passcodes.size():
		highlight_start = 0
		highlight_end = ptr
		highlight_color = 0
		return 0
	
	var parsed_codename : String = ""
	while ptr < passcodes.size():
		parsed_codename += char(passcodes[ptr] + 97)
		ptr += 1
	
	if parsed_codename == "cnkdnidd":
		highlight_start = infix + 1
		highlight_end = passcodes.size()
		highlight_color = 2
		return 3
	
	
	
	found_node = null
	# D2. look up name
	if not Bus.game_manager.codable_map.has(parsed_codename):
		highlight_start = infix + 1
		highlight_end = passcodes.size()
		highlight_color = 0
		return 0
	
	# just came across me if multiple procedures are modifying it
	# there will be a data race! how fun. Thankfully it is readonly
	var target : Platform = Bus.game_manager.codable_map[parsed_codename]
	found_node = target
	
	# E. check if action is legal
	var slot : int = target.current_slot
	
	var overflow :bool = false
	for idx in range(infix):
		slot += 1 if passcodes[idx] == 3 else -1
		if slot < 0 or slot >= target.slot_positions.size():
			overflow = true
			break
		# trigger something
		if target.dependency != null and target.dependency.current_slot == 0 and slot > target.dependency_leg:
			overflow = true
			break
	
	if overflow or not target.target_queue.is_empty():
		highlight_start = 0
		highlight_end = infix
		highlight_color = 1
		return 1
	
	# Finally done!
	highlight_start = 0
	highlight_end = passcodes.size()
	highlight_color = 2
	
	return 2
