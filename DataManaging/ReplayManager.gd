extends Node

var index = 0

var tick_timer := 0.0
const TICK_RATE := 10
const TICK_INTERVAL := 1.0 / TICK_RATE

var dictionaries = {}
var _node_to_id = {}
var recording = false

var saved_highlights = []

func init_replay():
	print("Tried to init")
	dictionaries.clear()
	_node_to_id.clear()
	index = 0 
	
	# Initialize ball entry OUTSIDE the player loop so it isn't overwritten
	dictionaries["ball"] = []
	
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var id = get_free_id()
		_node_to_id[player] = id
		
		dictionaries[id] = {}
		dictionaries[id]["states"] = []
		dictionaries[id]["appearance"] = player.get_appearance()


func _physics_process(delta):
	if not recording:
		return
	tick_timer += delta
	
	while tick_timer >= TICK_INTERVAL:
		tick()
		tick_timer -= TICK_INTERVAL


func tick():
	# 1. Record Players
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if not _node_to_id.has(player):
			continue
			
		var id = _node_to_id[player]
		if dictionaries.has(id):
			dictionaries[id]["states"].append(player.get_replay_state())
		
	# 2. Record Ball OUTSIDE the player loop so it records exactly once per tick
	var ball = get_tree().get_first_node_in_group("football")
	if ball:
		dictionaries["ball"].append(ball.get_state())

func capture_highlight(clip_name: String, seconds: float):
	var clip_data = {}
	var total_frames_needed = int(TICK_RATE * seconds)
	
	for key in dictionaries:
		if str(key) == "ball":
			var ball_array = dictionaries["ball"]
			var start_idx = max(0, ball_array.size() - total_frames_needed)
			# Take a deep copy slice of the ball's recent history
			clip_data["ball"] = ball_array.slice(start_idx).duplicate(true)
		else:
			var player_data = dictionaries[key]
			var states_array = player_data["states"]
			var start_idx = max(0, states_array.size() - total_frames_needed)
			
			# Rebuild the identical player structure for just this time window
			clip_data[key] = {
				"appearance": player_data["appearance"].duplicate(true),
				"states": states_array.slice(start_idx).duplicate(true)
			}
			
	# Package it nicely with a name tag
	var highlight_package = {
		"name": clip_name,
		"data": clip_data
	}
	
	saved_highlights.append(highlight_package)
	print("Saved highlight: ", clip_name, " (", seconds, " seconds long)")

func get_free_id():
	index += 1
	return index

## Saves a recording dictionary to the local appdata directory using Godot's binary format.
func save_recording(recording_name: String, data_to_save: Dictionary) -> bool:
	var safe_name = recording_name.validate_filename()
	# Changed extension to .dat to reflect that it is a binary data file
	var path = "user://" + safe_name + ".dat"
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		print("Failed to open file for writing (Error code: ", err, "): ", path)
		return false
	
	# store_var handles Vectors, Colors, and Dictionaries natively and securely
	file.store_var(data_to_save)
	
	print("Successfully saved recording to: ", OS.get_user_data_dir() + "/" + safe_name + ".dat")
	return true


## Loads a recording dictionary from the local appdata directory.
func load_recording(recording_name: String) -> Dictionary:
	var safe_name = recording_name.validate_filename()
	var path = "user://" + safe_name + ".dat"
	
	if not FileAccess.file_exists(path):
		print("Recording file does not exist: ", path)
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		print("Failed to open file for reading (Error code: ", err, "): ", path)
		return {}
		
	# get_var reconstructs the Dictionary and all Vector types perfectly
	var data = file.get_var()
	
	if not data is Dictionary:
		print("Failed to parse data as a Dictionary from file: ", path)
		return {}
		
	print("Successfully loaded recording: ", recording_name)
	return data

## Returns an Array of recording names (Strings) found in the user:// directory.
func get_saved_recordings() -> Array[String]:
	var recording_names: Array[String] = []
	var path = "user://"
	
	# Get all files in the user:// directory
	var files = DirAccess.get_files_at(path)
	
	for file in files:
		# Filter for our recording extension
		if file.ends_with(".dat"):
			# CHANGED: 'trim_suffix' is the correct Godot method
			var clean_name = file.trim_suffix(".dat")
			recording_names.append(clean_name)
			
	return recording_names
