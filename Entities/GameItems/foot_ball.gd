extends RigidBody3D



var default_kick_strength = 50.0

var current_player

var was_kicked = false


func _physics_process(delta):
	$LabelPivot.global_position = self.global_position


func kick(kicker_position : Vector3,is_pass : bool = false, kicker = null):
	var vector = self.global_position - kicker_position
	vector.y = 0
	var kick_direction = vector.normalized()
	if is_pass:
		kick_direction *= default_kick_strength*0.5
		kick_direction.y = 0.0
	else:
		kick_direction *= default_kick_strength
		kick_direction.y = default_kick_strength * 0.2
	
	if kicker:
		current_player = kicker
		update_label()
	
	$KickSFX.play()
	apply_central_impulse(kick_direction)
	was_kicked = true
	if kicker:
		get_parent().update_last_touch(kicker)

func slop(kicker_position : Vector3,kicker = null):
	var vector = self.global_position - kicker_position
	vector.y = 0
	var kick_direction = vector.normalized()
	kick_direction *= default_kick_strength * 0.3
	kick_direction.y = default_kick_strength * 0.5
	
	if kicker:
		current_player = kicker
		update_label()
	
	$KickSFX.play()
	apply_central_impulse(kick_direction)
	was_kicked = true
	if kicker:
		get_parent().update_last_touch(kicker)

func explode(explosion_position):
	var vector = self.global_position - explosion_position
	vector.y = 0
	var kick_direction = vector.normalized()
	kick_direction *= default_kick_strength
	
	kick_direction.y = default_kick_strength * 0.2
	
	apply_central_impulse(kick_direction)


func get_state() -> Dictionary:
	var dic = {}
	dic["position"] = global_position
	dic["rotation"] = global_rotation
	dic["kick"] = was_kicked
	
	was_kicked = false
	
	return dic

func update_label():
	var player_name = PlayerData.player_names[current_player.player_id]
	%PlayerNameLabel.text = str(player_name)


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		current_player = body
		update_label()
		get_parent().update_last_touch(body)


## Saves a recording dictionary to the local appdata directory as a JSON file.
func save_recording(recording_name: String, data_to_save: Dictionary) -> bool:
	# Clean up the file name to prevent path traversal issues
	var safe_name = recording_name.validate_filename()
	var path = "user://" + safe_name + ".json"
	
	# Open the file for writing
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		print("Failed to open file for writing (Error code: ", err, "): ", path)
		return false
	
	# Convert the dictionary to a JSON string
	# Set the second argument to "\t" if you want pretty-printed, readable JSON files
	var json_string = JSON.stringify(data_to_save, "") 
	
	# Store the string and close
	file.store_string(json_string)
	print("Successfully saved recording to: ", OS.get_user_data_dir() + "/" + safe_name + ".json")
	return true


## Loads a recording dictionary from the local appdata directory.
## Returns an empty dictionary if the file doesn't exist or is corrupted.
func load_recording(recording_name: String) -> Dictionary:
	var safe_name = recording_name.validate_filename()
	var path = "user://" + safe_name + ".json"
	
	# Check if the file even exists before trying to read it
	if not FileAccess.file_exists(path):
		print("Recording file does not exist: ", path)
		return {}
		
	# Open the file for reading
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		print("Failed to open file for reading (Error code: ", err, "): ", path)
		return {}
		
	# Read the raw text
	var json_string = file.get_as_text()
	
	# Parse the JSON string back into a Godot Dictionary
	var data = JSON.parse_string(json_string)
	if data == null:
		print("Failed to parse JSON from file: ", path)
		return {}
		
	print("Successfully loaded recording: ", recording_name)
	return data
