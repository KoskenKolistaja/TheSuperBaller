extends Node3D

@export var bomb : PackedScene
@export var player_scene : PackedScene

signal shortcut

var match_number = 0
var match_time = 20
var winner_dictionary = {}

var left_team_score : int = 0
var right_team_score : int = 0

var active = false
var last_match = false
var golden_goal = false
var cup_phase = false

var player_ids = []
var player_hats = {}
var player_names = {}

var group_matches_amount : int = 0
var players_played = []

var left_team_players = []
var right_team_players = []
var elimination_matches = []

# --- ROUND-ROBIN LEAGUE VARIABLES ---
var is_round_robin : bool = false
var is_rr_final : bool = false
var rr_match_index : int = 0
var rr_matches : Array = []
var rr_leaderboard : Dictionary = {} 
var rr_goals_diff : Dictionary = {} # New: Tracks { player_id: goals_scored - goals_conceded }

var last_toucher_name = null

var rotating = true

func setup(exported_player_ids, exported_hats, exported_names):
	player_ids = exported_player_ids
	player_hats = exported_hats
	player_names = exported_names
	
	if player_ids.is_empty():
		change_to_win_scene()
		return
		
	if player_ids.size() == 1:
		setup_solo_cup()
	elif player_ids.size() == 2:
		setup_two_player_final()
	elif player_ids.size() == 3:
		setup_three_player_round_robin()
	elif player_ids.size() <= 4:
		setup_micro_cup()
	elif player_ids.size() <= 7:
		setup_small_cup()
	else:
		setup_big_cup()


func _ready():
	%IdleMusic.play()


# --- GAMEMODE SETUPS ---

func setup_two_player_final():
	group_matches_amount = 0
	cup_phase = true
	last_match = false # Will be flagged inside setup_next_match right before starting
	print("GAMEMODE: 2-Player Straight to Grand Final!")
	setup_next_match()


func setup_three_player_round_robin():
	is_round_robin = true
	is_rr_final = false
	rr_match_index = 0
	cup_phase = false
	last_match = false
	rr_leaderboard.clear()
	rr_goals_diff.clear() # Reset tiebreaker map
	
	for id in player_ids:
		rr_leaderboard[id] = 0
		rr_goals_diff[id] = 0 # Initialize at 0 net goals
		
	rr_matches = [
		[player_ids[0], player_ids[1]], 
		[player_ids[1], player_ids[2]], 
		[player_ids[0], player_ids[2]]  
	]
	
	print("GAMEMODE: 3-Player Round Robin with Goal Differential Tiebreaker!")
	setup_next_match()


func setup_solo_cup():
	group_matches_amount = 0
	cup_phase = true
	last_match = true
	setup_next_match()


func setup_micro_cup():
	group_matches_amount = 0
	cup_phase = true
	setup_next_match()


func setup_small_cup():
	group_matches_amount = player_ids.size() - 4
	setup_next_match()


func setup_big_cup():
	group_matches_amount = player_ids.size() - 8
	setup_next_match()


func setup_next_match():
	# Clean Termination Check: If the last match just concluded, wrap up immediately.
	if last_match and match_number > 0:
		change_to_win_scene()
		%StartButton.hide()
		return

	match_number += 1
	
	if is_round_robin:
		if rr_match_index < rr_matches.size():
			setup_round_robin_match()
		elif not is_rr_final:
			setup_round_robin_final()
		else:
			change_to_win_scene()
			%StartButton.hide()
	elif player_ids.size() <= 1:
		last_match = true
		cup_phase = true
		setup_solo_match()
	elif group_matches_amount > 0:
		setup_group_match()
	else:
		# Elimination phase logic
		cup_phase = true
		if player_ids.size() == 2:
			last_match = true
		setup_elimination_match()


func change_to_win_scene():
	get_parent().change_to_winner_scene(winner_dictionary)
	queue_free()


func process_match_losers():
	if is_round_robin:
		if not is_rr_final:
			process_round_robin_results()
		else:
			process_grand_final_results()
		return

	var losing_team_ids = []
	if left_team_score > right_team_score:
		losing_team_ids.append_array(right_team_players)
	elif right_team_score > left_team_score:
		losing_team_ids.append_array(left_team_players)
	else:
		losing_team_ids.append_array(left_team_players)
		losing_team_ids.append_array(right_team_players)
		
	if last_match:
		var winning_team_ids = []
		if left_team_score > right_team_score or player_ids.size() == 1:
			winning_team_ids = left_team_players
		elif right_team_score > left_team_score:
			winning_team_ids = right_team_players
		
		if winning_team_ids.size() > 0:
			var winner_id = winning_team_ids[0]
			winner_dictionary["hat"] = player_hats[winner_id]
			winner_dictionary["name"] = player_names[winner_id]
		
	if not cup_phase:
		if not losing_team_ids.is_empty():
			eliminate_specific_player(losing_team_ids.pick_random())
	else:
		for id in losing_team_ids:
			eliminate_specific_player(id)


# --- ROUND ROBIN & GRAND FINAL LOGIC ---

func setup_round_robin_match():
	var current_matchup = rr_matches[rr_match_index]
	var left_id = current_matchup[0]
	var right_id = current_matchup[1]
	
	var left_team = { left_id: {"name": player_names[left_id], "hat": player_hats[left_id]} }
	var right_team = { right_id: {"name": player_names[right_id], "hat": player_hats[right_id]} }
	
	%Visual3D.show_lineup(left_team, right_team)
	%Visual3D.set_match_info(match_number, rr_matches.size() + 1 - match_number, player_ids.size())
	setup_lineup(left_team, right_team)


func process_round_robin_results():
	var current_matchup = rr_matches[rr_match_index]
	var left_id = current_matchup[0]
	var right_id = current_matchup[1]
	
	# 1. Update Match Points (3 for Win, 1 for Tie)
	if left_team_score > right_team_score:
		rr_leaderboard[left_id] += 3
	elif right_team_score > left_team_score:
		rr_leaderboard[right_id] += 3
	else:
		rr_leaderboard[left_id] += 1
		rr_leaderboard[right_id] += 1
		
	# 2. Update Goal Differential (Goals For minus Goals Against)
	rr_goals_diff[left_id] += (left_team_score - right_team_score)
	rr_goals_diff[right_id] += (right_team_score - left_team_score)
		
	rr_match_index += 1


func setup_round_robin_final():
	is_rr_final = true
	last_match = true
	cup_phase = true 
	
	var sorted_players = player_ids.duplicate()
	
	# Advanced sorting lambda: Check points first, fallback to goal differential if equal
	sorted_players.sort_custom(func(a, b): 
		if rr_leaderboard[a] == rr_leaderboard[b]:
			return rr_goals_diff[a] > rr_goals_diff[b]
		return rr_leaderboard[a] > rr_leaderboard[b]
	)
	
	var top_1 = sorted_players[0]
	var top_2 = sorted_players[1]
	var bottom_player = sorted_players[2]
	
	print("Eliminating 3rd place player: ", player_names[bottom_player], " (GD: ", rr_goals_diff[bottom_player], ")")
	eliminate_specific_player(bottom_player)
	
	var left_team = { top_1: {"name": player_names[top_1], "hat": player_hats[top_1]} }
	var right_team = { top_2: {"name": player_names[top_2], "hat": player_hats[top_2]} }
	
	print("GRAND FINAL: ", player_names[top_1], " VS ", player_names[top_2])
	
	%Visual3D.show_lineup(left_team, right_team)
	%Visual3D.set_match_info(match_number, 0, player_ids.size())
	setup_lineup(left_team, right_team)


func process_grand_final_results():
	var winning_team_ids = []
	if left_team_score > right_team_score:
		winning_team_ids = left_team_players
	elif right_team_score > left_team_score:
		winning_team_ids = right_team_players
		
	if winning_team_ids.size() > 0:
		var winner_id = winning_team_ids[0]
		winner_dictionary["hat"] = player_hats[winner_id]
		winner_dictionary["name"] = player_names[winner_id]
		print("🏆 TOURNAMENT CHAMPION: ", player_names[winner_id])


# --- LAYOUT MANAGEMENT ---

func setup_solo_match():
	var left_team = {}
	var right_team = {}
	var solo_id = player_ids[0]
	left_team[solo_id] = {"name": player_names[solo_id], "hat": player_hats[solo_id]}
	%Visual3D.show_lineup(left_team, right_team)
	%Visual3D.set_match_info(match_number, group_matches_amount, player_ids.size())
	setup_lineup(left_team, right_team)


func setup_elimination_match():
	var left_team = {}
	var right_team = {}
	var left_team_ids = []
	var right_team_ids = []
	
	var match_size = 4 if player_ids.size() > 4 else 2
	if player_ids.size() < match_size:
		match_size = player_ids.size()
		if match_size <= 1:
			setup_solo_match()
			return
		
	var available_players = []
	for id in player_ids:
		if not id in players_played:
			available_players.append(id)
			
	if available_players.size() < match_size:
		players_played.clear()
		available_players = player_ids.duplicate()
		
	var left = true
	for i in range(match_size):
		if available_players.is_empty():
			break
		var chosen_one = available_players.pick_random()
		available_players.erase(chosen_one)
		players_played.append(chosen_one)
		
		if left:
			left_team_ids.append(chosen_one)
		else:
			right_team_ids.append(chosen_one)
		left = !left
	
	if left_team_ids.size() > 1 and right_team_ids.is_empty():
		right_team_ids.append(left_team_ids.pop_back())
	
	for id in left_team_ids:
		left_team[id] = {"name": player_names[id], "hat": player_hats[id]}
	for id in right_team_ids:
		right_team[id] = {"name": player_names[id], "hat": player_hats[id]}
	
	%Visual3D.show_lineup(left_team, right_team)
	%Visual3D.set_match_info(match_number, group_matches_amount, player_ids.size())
	setup_lineup(left_team, right_team)


func eliminate_specific_player(player_id_to_eliminate):
	if not player_id_to_eliminate in player_ids:
		return
		
	player_ids.erase(player_id_to_eliminate)
	var player_dictionary = {
		"hat": player_hats[player_id_to_eliminate],
		"name": player_names[player_id_to_eliminate]
	}
	%Visual3D.eliminate_player(player_dictionary)


func setup_group_match():
	%Visual3D.set_match_info(match_number, group_matches_amount, player_ids.size())
	group_matches_amount -= 1
	var player_list = player_ids.duplicate()
	
	var left_team_ids = []
	var right_team_ids = []
	var left_team = {}
	var right_team = {}
	
	var left = true
	while player_list.size() > 0:
		var chosen_one = player_list.pick_random()
		player_list.erase(chosen_one)
		if left:
			left_team_ids.append(chosen_one)
		else:
			right_team_ids.append(chosen_one)
		left = !left
	
	for id in left_team_ids:
		left_team[id] = {"name": player_names[id], "hat": player_hats[id]}
	for id in right_team_ids:
		right_team[id] = {"name": player_names[id], "hat": player_hats[id]}
	
	%Visual3D.show_lineup(left_team, right_team)
	setup_lineup(left_team, right_team)
	%MatchTimer.wait_time = match_time


func delete_players():
	for c in %PlayerContainer.get_children():
		c.queue_free()
	for c in %LeftTeamPositions.get_children():
		c.hide()
	for c in %RightTeamPositions.get_children():
		c.hide()
	left_team_players.clear()
	right_team_players.clear()


func setup_lineup(left_team, right_team):
	
	for id in left_team:
		var player_position_node = get_first_hidden_left()
		if not player_position_node: break
		var player_instance = player_scene.instantiate()
		player_instance.set_color(Color(1, 0.5, 0.5))
		player_instance.player_id = id
		player_instance.name = PlayerData.get_player_name(id)
		player_instance.set_hat(left_team[id]["hat"])
		player_position_node.show()
		%PlayerContainer.add_child(player_instance)
		player_instance.global_position = player_position_node.global_position
		player_instance.initial_position = player_position_node.global_position
		player_instance.rotation_degrees.y = 90
		left_team_players.append(id)
	
	for id in right_team:
		var player_position_node = get_first_hidden_right()
		if not player_position_node: break
		var player_instance = player_scene.instantiate()
		player_instance.set_color(Color(0.5, 0.5, 1.0))
		player_instance.player_id = id
		player_instance.set_hat(right_team[id]["hat"])
		player_position_node.show()
		%PlayerContainer.add_child(player_instance)
		player_instance.global_position = player_position_node.global_position
		player_instance.initial_position = player_position_node.global_position
		player_instance.rotation_degrees.y = -90
		right_team_players.append(id)


func get_first_hidden_left():
	for i in %LeftTeamPositions.get_children():
		if not i.visible:
			return i


func get_first_hidden_right():
	for i in %RightTeamPositions.get_children():
		if not i.visible:
			return i


func reset_player_positions():
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		p.global_position = p.initial_position


func start_match():
	last_toucher_name = null
	rotating = false
	move_ball_to_center()
	$FootBall.freeze = true
	golden_goal = false
	%MatchTimer.wait_time = match_time
	left_team_score = 0
	right_team_score = 0
	%UI3D.hide()
	%MatchMusic.play()
	%IdleMusic.stop()
	ReplayManager.init_replay()
	await get_tree().create_timer(2.88).timeout
	ReplayManager.recording = true
	%WhistleSFX.play()
	active = true
	activate_players()
	%MatchTimer.start()
	$FootBall.freeze = false
	move_ball_to_center()

func activate_players():
	for c in %PlayerContainer.get_children():
		c.active = true


func deactivate_players():
	for c in %PlayerContainer.get_children():
		c.deactivate()


func match_over():
	ReplayManager.recording = false
	active = false
	%WinJingle.play()
	if last_match:
		$SuperBaller.start()
	else:
		$MatchOver.start()
	deactivate_players()
	%MatchMusic.stop()
	%OvertimeMusic.stop()
	%MatchTimer.stop()
	await get_tree().create_timer(10).timeout
	rotating = true
	$SuperBaller.stop()
	$MatchOver.stop()
	process_match_losers()
	%ReplayMusic.play()
	%UI3D.show()
	%Visual3D.hide_lineup()
	delete_players()
	await shortcut
	%UI3D.hide()
	%ReplayOverlay.show()
	activate_replay_camera()
	play_highlights()
	await shortcut
	%Replayer.stop_replay()
	%UI3D.show()
	%ReplayOverlay.hide_overlay()
	%ReplayMusic.stop()
	%IdleMusic.play()
	activate_normal_camera()
	setup_next_match()
	%StartButton.show()

func play_highlights():
	if ReplayManager.saved_highlights.is_empty():
		print("No highlights saved yet!")
		return
		
	%Replayer.init_replay(ReplayManager.saved_highlights)
	%Replayer.playing = true


func _physics_process(delta):
	%PointTable.update_time(%MatchTimer.time_left)
	%PointTable.update_scores(left_team_score, right_team_score)
	if Input.is_action_just_pressed("force_match_over"):
		force_match_over()
	
	if rotating:
		%CinematicCameraPivot.rotation_degrees.y += 0.1
	else:
		%CinematicCameraPivot.rotation_degrees.y = 0
	
	if Input.is_action_just_pressed("ui_accept"):
		shortcut.emit()


func activate_normal_camera():
	%NormalCamera.current = true
	%ReplayCamera.current = false

func activate_replay_camera():
	%NormalCamera.current = false
	%ReplayCamera.current = true

func force_match_over():
	if randf_range(0, 1) < 0.5:
		left_team_score += 1
	else:
		right_team_score += 1
	match_over()


func move_ball_to_center():
	var football : RigidBody3D = get_tree().get_first_node_in_group("football")
	if football:
		football.global_position = Vector3(0, 10, 0)
		football.linear_velocity = Vector3.ZERO
		football.angular_velocity = Vector3.ZERO


func left_team_scored():
	if not active:
		return
	if not golden_goal:
		reset_player_positions()
	left_team_score += 1
	update_point_table()
	move_ball_to_center()
	if golden_goal:
		match_over()
	ReplayManager.capture_highlight(last_toucher_name + " scored " + str(left_team_score) +" - " + str(right_team_score) + " goal" , 5.0)

func right_team_scored():
	if not active:
		return
	if not golden_goal:
		reset_player_positions()
	right_team_score += 1
	update_point_table()
	move_ball_to_center()
	if golden_goal:
		match_over()
	ReplayManager.capture_highlight(last_toucher_name + " scored " + str(left_team_score) +" - " + str(right_team_score) + " goal" , 5.0)

func update_point_table():
	%PointTable.update_scores(left_team_score, right_team_score)


func _on_left_goal_area_body_entered(body):
	if body.is_in_group("football"):
		right_team_scored()


func _on_right_goal_area_body_entered(body):
	if body.is_in_group("football"):
		left_team_scored()


func _on_match_timer_timeout():
	if cup_phase and left_team_score == right_team_score and player_ids.size() > 1:
		print("SUDDEN DEATH!")
		%MatchTimer.wait_time = 30
		%MatchTimer.start()
		golden_goal = true
		if not %OvertimeMusic.playing:
			%OvertimeMusic.play()
		return
	
	match_over()


func _on_bomb_timer_timeout():
	spawn_bomb()


func spawn_bomb():
	var bomb_instance = bomb.instantiate()
	add_child(bomb_instance)
	bomb_instance.global_position = Vector3(0, 20, 0)


func _on_start_button_pressed():
	start_match()
	%StartButton.hide()

func update_last_touch(player):
	last_toucher_name = player.name
