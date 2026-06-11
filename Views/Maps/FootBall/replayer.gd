extends Node3D

@export var replay_player_scene : PackedScene
@export var replay_ball_scene : PackedScene
@export var loop_playback : bool = true 

@export var replay_overlay : Control

var dictionaries = {}
var playback_data = {} 

var tick_timer := 0.0
var TICK_RATE := 10
var TICK_INTERVAL := 1.0 / TICK_RATE

var playing = false
var ball_instance: Node3D = null

var highlight_playlist : Array = []  
var current_playlist_index : int = 0  
@export var loops_per_highlight : int = 1 
var current_loop_count : int = 0      

# Timeline scrubbing variables
var current_frame_index : int = 0
var max_frames : int = 0
var is_scrubbing : bool = false

# Signal to tell the UI to move the slider handle
signal frame_changed(current_frame: int, max_frames: int)

var _current_clip_backup := {} 


func update_tick_interval(animation_speed):
	TICK_INTERVAL = 1.0 / TICK_RATE
	for p in %ReplayPlayers.get_children():
		p.update_animation_speed(animation_speed)

func init_replay(custom_clip_data = null):
	dictionaries.clear()
	playback_data.clear() 
	cleanup_replay() 
	if replay_overlay:
		replay_overlay.set_text("Nothing interesting happened...")
	
	highlight_playlist.clear()
	current_playlist_index = 0
	current_loop_count = 0
	
	if custom_clip_data is Array:
		highlight_playlist = custom_clip_data
		if highlight_playlist.is_empty():
			return
		load_clip_from_playlist(0)
	elif custom_clip_data is Dictionary and not custom_clip_data.is_empty():
		setup_clip_structures(custom_clip_data)
	else:
		setup_clip_structures(ReplayManager.dictionaries)

func load_clip_from_playlist(index: int):
	if highlight_playlist.is_empty():
		return
		
	current_playlist_index = index % highlight_playlist.size()
	current_loop_count = 0
	playback_data.clear()
	
	var clip_name = highlight_playlist[current_playlist_index]["name"]
	if replay_overlay:
		replay_overlay.set_text(clip_name)
	
	var clip_payload = highlight_playlist[current_playlist_index]["data"]
	setup_clip_structures(clip_payload)
	
	playing = true


func setup_clip_structures(source_material: Dictionary):
	_current_clip_backup = source_material.duplicate(true)
	cleanup_replay() 
	playback_data.clear() 
	tick_timer = 0.0
	current_frame_index = 0
	max_frames = 0
	
	# Calculate total length of the clip based on the longest data array
	for key in source_material:
		if str(key) == "ball":
			dictionaries["ball"] = source_material["ball"].duplicate(true)
			max_frames = max(max_frames, dictionaries["ball"].size())
		else:
			var id = key
			dictionaries[id] = source_material[id]["states"].duplicate(true)
			max_frames = max(max_frames, dictionaries[id].size())

	# Instantiate entities
	if dictionaries.has("ball") and not dictionaries["ball"].is_empty():
		if replay_ball_scene:
			ball_instance = replay_ball_scene.instantiate()
			add_child(ball_instance)
			
	for key in source_material:
		if str(key) != "ball":
			var id = key
			var player_instance = replay_player_scene.instantiate()
			player_instance.id = id
			%ReplayPlayers.add_child(player_instance)
			player_instance.set_hat(source_material[id]["appearance"]["hat"])
			player_instance.set_color(source_material[id]["appearance"]["color"])
			player_instance.name = source_material[id]["appearance"]["name"]

	# Snap everything to frame 0 immediately
	apply_frame(0, true)
	frame_changed.emit(current_frame_index, max_frames)


func _physics_process(delta):
	if not playing or is_scrubbing:
		return
	tick_timer += delta
	
	while tick_timer >= TICK_INTERVAL:
		tick()
		if not playing or is_scrubbing: 
			return
		tick_timer -= TICK_INTERVAL
	
	var t = clamp(tick_timer / TICK_INTERVAL, 0.0, 1.0)
	interpolate_entities(t)


func interpolate_entities(t: float):
	var players = %ReplayPlayers.get_children()
	for p in players:
		var id = p.id
		if playback_data.has(id):
			var data = playback_data[id]
			p.global_position = data["start_pos"].lerp(data["target_pos"], t)
			var blended_quat = data["start_rot"].slerp(data["target_rot"], t)
			p.global_rotation = blended_quat.get_euler()
			
	if ball_instance and playback_data.has("ball"):
		var data = playback_data["ball"]
		ball_instance.global_position = data["start_pos"].lerp(data["target_pos"], t)
		var blended_quat = data["start_rot"].slerp(data["target_rot"], t)
		ball_instance.global_rotation = blended_quat.get_euler()


func cleanup_replay():
	playing = false
	dictionaries.clear()
	playback_data.clear()

	for player in %ReplayPlayers.get_children():
		%ReplayPlayers.remove_child(player)
		player.queue_free()

	if ball_instance and is_instance_valid(ball_instance):
		ball_instance.get_parent().remove_child(ball_instance)
		ball_instance.queue_free()

	ball_instance = null
	tick_timer = 0.0
	current_frame_index = 0


func tick():
	# If we hit the end of the clip lengths
	if current_frame_index >= max_frames - 1:
		if loop_playback:
			current_loop_count += 1
			if not highlight_playlist.is_empty() and current_loop_count >= loops_per_highlight:
				load_clip_from_playlist(current_playlist_index + 1)
			else:
				restart_replay_loop()
		else:
			playing = false
		return

	current_frame_index += 1
	apply_frame(current_frame_index, false)
	frame_changed.emit(current_frame_index, max_frames)


## Forces all entities to a specific frame index. If teleport is true, removes interpolation artifacts.
func apply_frame(frame_idx: int, teleport: bool = false):
	current_frame_index = clamp(frame_idx, 0, max_frames - 1)
	
	var players = %ReplayPlayers.get_children()
	for p in players:
		var id = p.id
		var array: Array = dictionaries.get(id, [])
		if frame_idx < array.size():
			var dic = array[frame_idx]
			if teleport:
				p.global_position = dic["position"]
				p.global_rotation = dic["rotation"]
				playback_data.erase(id) # Clear old lerp targets
			else:
				update_playback_targets(id, p.global_position, p.global_rotation, dic)
			p.set_animation(dic["animation"])
			
	if ball_instance and dictionaries.has("ball"):
		var ball_array: Array = dictionaries["ball"]
		if frame_idx < ball_array.size():
			var dic = ball_array[frame_idx]
			if teleport:
				ball_instance.global_position = dic["position"]
				ball_instance.global_rotation = dic["rotation"]
				playback_data.erase("ball")
			else:
				update_playback_targets("ball", ball_instance.global_position, ball_instance.global_rotation, dic)
			
			if not teleport and dic.get("kick", false) and ball_instance.has_method("play_kick_fx"):
				ball_instance.play_kick_fx()


func set_scrub_position(frame_idx: int):
	apply_frame(frame_idx, true)
	tick_timer = 0.0


func restart_replay_loop():
	current_loop_count = 0
	set_scrub_position(0)


func update_playback_targets(id, current_pos: Vector3, current_rot: Vector3, dic: Dictionary):
	if not playback_data.has(id):
		playback_data[id] = {
			"start_pos": current_pos,
			"target_pos": dic["position"],
			"start_rot": Quaternion.from_euler(current_rot),
			"target_rot": Quaternion.from_euler(dic["rotation"])
		}
	else:
		playback_data[id]["start_pos"] = playback_data[id]["target_pos"]
		playback_data[id]["target_pos"] = dic["position"]
		playback_data[id]["start_rot"] = playback_data[id]["target_rot"]
		playback_data[id]["target_rot"] = Quaternion.from_euler(dic["rotation"])
