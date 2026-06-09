extends Node3D

@export var replay_player_scene : PackedScene
@export var replay_ball_scene : PackedScene
@export var loop_playback : bool = true # Toggle this to turn looping on/off

@export var replay_overlay : Control

var dictionaries = {}
var playback_data = {} 

var tick_timer := 0.0
var TICK_RATE := 10
var TICK_INTERVAL := 1.0 / TICK_RATE

var playing = false
var ball_instance: Node3D = null

var highlight_playlist : Array = []   # Holds the list of clips to play
var current_playlist_index : int = 0  # Which clip we are looking at
@export var loops_per_highlight : int = 1 # Play each clip exactly 1 time
var current_loop_count : int = 0      # Tracks current loop iteration

# Keeps a pristine master copy of the highlight clip to reload from when looping
var _current_clip_backup := {} 


func update_tick_interval(animation_speed):
	TICK_INTERVAL = 1.0 / TICK_RATE
	for p in %ReplayPlayers.get_children():
		p.update_animation_speed(animation_speed)

func init_replay(custom_clip_data = null):
	print(ReplayManager.saved_highlights.size())
	
	if custom_clip_data is Array:
		print(custom_clip_data.size())
		print(custom_clip_data.is_empty())
	
	dictionaries.clear()
	playback_data.clear() 
	cleanup_replay() 
	if replay_overlay:
		replay_overlay.set_text("Nothing interesting happened...")
	# Reset playlist tracking
	highlight_playlist.clear()
	current_playlist_index = 0
	current_loop_count = 0
	
	if custom_clip_data is Array:
		# We received a whole playlist of clips!
		highlight_playlist = custom_clip_data
		print(highlight_playlist)
		if highlight_playlist.is_empty():
			print("HIGHLIGHT PLAYLIST IS EMPTY")
			return
		load_clip_from_playlist(0)
	elif custom_clip_data is Dictionary and not custom_clip_data.is_empty():
		# We received just a single raw clip dictionary
		setup_clip_structures(custom_clip_data)
	else:
		push_error("WENT TO FALLBACK!" + str(ReplayManager.dictionaries))
		# Default fallback: Play the entire recorded match history
		setup_clip_structures(ReplayManager.dictionaries)

func load_clip_from_playlist(index: int):
	print("LOADING FROM PLAYLIST")
	if highlight_playlist.is_empty():
		print("IS ENPTY?")
		return
		
	current_playlist_index = index % highlight_playlist.size()
	current_loop_count = 0
	playback_data.clear()
	
	var clip_name = highlight_playlist[current_playlist_index]["name"]
	replay_overlay.set_text(clip_name)
	
	var clip_payload = highlight_playlist[current_playlist_index]["data"]
	setup_clip_structures(clip_payload)
	
	# CRITICAL FIX: Turn playback back on after cleanup_replay() turned it off!
	playing = true


func setup_clip_structures(source_material: Dictionary):
	_current_clip_backup = source_material.duplicate(true)
	
	# Wipe old node configurations completely
	cleanup_replay() 
	
	# Clear out stale interpolation vectors so old clip positions don't carry over
	playback_data.clear() 
	tick_timer = 0.0
	
	for key in source_material:
		if str(key) == "ball":
			dictionaries["ball"] = source_material["ball"].duplicate(true)
			if replay_ball_scene and not dictionaries["ball"].is_empty():
				ball_instance = replay_ball_scene.instantiate()
				add_child(ball_instance)
				
				# CRITICAL FIX: Grab the first frame of the ball data
				var first_ball_frame = dictionaries["ball"][0]
				# Hard-teleport the ball instantly to prevent sliding from (0,0,0)
				ball_instance.global_position = first_ball_frame["position"]
				ball_instance.global_rotation = first_ball_frame["rotation"]
		else:
			var id = key
			dictionaries[id] = source_material[id]["states"].duplicate(true)
			
			if not dictionaries[id].is_empty():
				var player_instance = replay_player_scene.instantiate()
				player_instance.id = id
				%ReplayPlayers.add_child(player_instance)
				
				# Set cosmetic appearances
				player_instance.set_hat(source_material[id]["appearance"]["hat"])
				player_instance.set_color(source_material[id]["appearance"]["color"])
				player_instance.name = source_material[id]["appearance"]["name"]
				
				# CRITICAL FIX: Grab the first frame of this specific player's data
				var first_player_frame = dictionaries[id][0]
				# Hard-teleport the player instantly to prevent sliding from (0,0,0)
				player_instance.global_position = first_player_frame["position"]
				player_instance.global_rotation = first_player_frame["rotation"]
				player_instance.set_animation(first_player_frame["animation"])

func _physics_process(delta):
	if not playing:
		return
	tick_timer += delta
	
	while tick_timer >= TICK_INTERVAL:
		tick()
		if not playing: 
			return
		tick_timer -= TICK_INTERVAL
	
	var t = clamp(tick_timer / TICK_INTERVAL, 0.0, 1.0)
	
	# Interpolate active players
	var players = %ReplayPlayers.get_children()
	for p in players:
		var id = p.id
		if playback_data.has(id):
			var data = playback_data[id]
			p.global_position = data["start_pos"].lerp(data["target_pos"], t)
			var blended_quat = data["start_rot"].slerp(data["target_rot"], t)
			p.global_rotation = blended_quat.get_euler()
			
	# Interpolate the ball
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
		%ReplayPlayers.remove_child(player) # Remove immediately from tree queries
		player.queue_free()

	if ball_instance and is_instance_valid(ball_instance):
		# Remove the ball immediately too
		ball_instance.get_parent().remove_child(ball_instance)
		ball_instance.queue_free()

	ball_instance = null
	tick_timer = 0.0


func tick():
	var clip_finished := false
	
	# 1. Check if ANY essential entity has completely run out of frames before updating
	var players = %ReplayPlayers.get_children()
	for p in players:
		if dictionaries[p.id].is_empty():
			clip_finished = true
			break
			
	if ball_instance and dictionaries.get("ball", []).is_empty():
		clip_finished = true

	# 2. If the clip is done, handle looping/playlist advancement here and exit safely
	if clip_finished:
		if loop_playback:
			current_loop_count += 1
			if not highlight_playlist.is_empty() and current_loop_count >= loops_per_highlight:
				load_clip_from_playlist(current_playlist_index + 1)
			else:
				restart_replay_loop()
		else:
			playing = false
			cleanup_replay()
		return

	# 3. Process Player frames safely knowing data definitely exists for this tick
	for p in players:
		var id = p.id
		var array : Array = dictionaries[id]
		
		var dic = array[0]
		update_playback_targets(id, p.global_position, p.global_rotation, dic)
		p.set_animation(dic["animation"])
		array.remove_at(0)
		
	# 4. Process Ball frames safely
	if ball_instance and dictionaries.has("ball"):
		var ball_array : Array = dictionaries["ball"]
			
		var dic = ball_array[0]
		update_playback_targets("ball", ball_instance.global_position, ball_instance.global_rotation, dic)
		
		if dic.get("kick", false) and ball_instance.has_method("play_kick_fx"):
			ball_instance.play_kick_fx()
			
		ball_array.remove_at(0)

func stop_replay():
	cleanup_replay()
	playing = false

## Resets the data structures and snaps items back to the beginning frame seamlessly
func restart_replay_loop():
	playback_data.clear()
	tick_timer = 0.0
	
	# 1. Refill data arrays from pristine backup copies
	for key in _current_clip_backup:
		if str(key) == "ball":
			dictionaries["ball"] = _current_clip_backup["ball"].duplicate(true)
		else:
			dictionaries[key] = _current_clip_backup[key]["states"].duplicate(true)
			
	# 2. Snap living entities instantly to frame 0 positions 
	# (Prevents interpolation from dragging items backwards from end-of-clip to start-of-clip)
	var players = %ReplayPlayers.get_children()
	for p in players:
		var id = p.id
		if not dictionaries[id].is_empty():
			var first_frame = dictionaries[id][0]
			p.global_position = first_frame["position"]
			p.global_rotation = first_frame["rotation"]
			p.set_animation(first_frame["animation"])
			
	if ball_instance and dictionaries.has("ball") and not dictionaries["ball"].is_empty():
		var first_ball_frame = dictionaries["ball"][0]
		ball_instance.global_position = first_ball_frame["position"]
		ball_instance.global_rotation = first_ball_frame["rotation"]


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
