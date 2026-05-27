extends Node3D

@export var bomb : PackedScene
@export var player_scene : PackedScene

var match_number = 0

var match_time = 120

var winner_dictionary = {}

var left_team_score : int = 0
var right_team_score : int = 0

var active = false

var last_match = false

var player_ids = []
var player_hats = {}
var player_names = {}

var group_matches_amount : int = 0

var players_played = []

var left_team_players = []
var right_team_players = []

var elimination_matches = []

var golden_goal = false
var cup_phase = false



func setup(exported_player_ids,exported_hats,exported_names):
	player_ids = exported_player_ids
	player_hats = exported_hats
	player_names = exported_names
	if player_ids.size() > 7:
		setup_big_cup()
	elif player_ids.size() > 4:
		setup_small_cup()
	


func _ready():
	%IdleMusic.play()


func setup_small_cup():
	group_matches_amount = player_ids.size() - 4
	print("GROUP MATCHES: " + str(group_matches_amount))
	setup_next_match()

func setup_big_cup():
	group_matches_amount = player_ids.size() - 8
	print("GROUP MATCHES: " + str(group_matches_amount))
	setup_next_match()

func setup_next_match():
	match_number += 1
	
	if group_matches_amount:
		setup_group_match()
	elif not last_match:
		cup_phase = true
		setup_elimination_match()
	else:
		change_to_win_scene()
		%StartButton.hide()


func change_to_win_scene():
	get_parent().change_to_winner_scene(winner_dictionary)
	queue_free()


func process_match_losers():
	var losing_team_ids = []
	
	if left_team_score > right_team_score:
		losing_team_ids.append_array(right_team_players)
	elif right_team_score > left_team_score:
		losing_team_ids.append_array(left_team_players)
	else:
		# It's a tie! 
		losing_team_ids.append_array(left_team_players)
		losing_team_ids.append_array(right_team_players)
		
	# 🏆 If this was the final match, store the winner
	if last_match:
		var winning_team_ids = []
		
		if left_team_score > right_team_score:
			winning_team_ids = left_team_players
		elif right_team_score > left_team_score:
			winning_team_ids = right_team_players
		
		# Since final is 1v1, there will only be one winner
		if winning_team_ids.size() > 0:
			var winner_id = winning_team_ids[0]
			winner_dictionary["hat"] = player_hats[winner_id]
			winner_dictionary["name"] = player_names[winner_id]
		
	# Elimination logic
	if not cup_phase:
		# Group Stage: Only eliminate 1 random person from the losing team
		eliminate_specific_player(losing_team_ids.pick_random())
	else:
		# Elimination Stage (Cup Phase): Eliminate EVERYONE on the losing team
		for id in losing_team_ids:
			eliminate_specific_player(id)


func setup_elimination_match():
	var left_team = {}
	var right_team = {}
	
	var left_team_ids = []
	var right_team_ids = []
	
	# If > 4 players, it's a 2v2 (4 players total). Otherwise, 1v1 (2 players total).
	var match_size = 4 if player_ids.size() > 4 else 2
	
	# Flag the grand final
	if player_ids.size() == 2:
		last_match = true
		
	# Find players who haven't played in this specific bracket round yet
	var available_players = []
	for id in player_ids:
		if not id in players_played:
			available_players.append(id)
			
	# If everyone remaining has played, the round is over. Reset for the next bracket phase!
	if available_players.size() < match_size:
		players_played.clear()
		available_players = player_ids.duplicate()
		
	# Draft the players
	var left = true
	for i in range(match_size):
		var chosen_one = available_players.pick_random()
		available_players.erase(chosen_one)
		players_played.append(chosen_one) # Mark them as having played this round
		
		if left:
			left_team_ids.append(chosen_one)
		else:
			right_team_ids.append(chosen_one)
		left = !left
	
	print(left_team_ids)
	print(player_names)
	
	# Build the dictionaries for the visuals and lineup setup
	for id in left_team_ids:
		left_team[id] = {}
		left_team[id]["name"] = player_names[id]
		left_team[id]["hat"] = player_hats[id]
	
	for id in right_team_ids:
		right_team[id] = {}
		right_team[id]["name"] = player_names[id]
		right_team[id]["hat"] = player_hats[id]
	
	%Visual3D.show_lineup(left_team, right_team)
	%Visual3D.set_match_info(match_number,group_matches_amount,player_ids.size())
	setup_lineup(left_team, right_team)

func eliminate_specific_player(player_id_to_eliminate):
	# Safety check
	if not player_id_to_eliminate in player_ids:
		return
		
	player_ids.erase(player_id_to_eliminate)
	print("Eliminated Player ID: ", player_id_to_eliminate)
	
	var player_dictionary = {}
	player_dictionary["hat"] = player_hats[player_id_to_eliminate]
	player_dictionary["name"] = player_names[player_id_to_eliminate]
	
	%Visual3D.eliminate_player(player_dictionary)


func setup_group_match():
	%Visual3D.set_match_info(match_number,group_matches_amount,player_ids.size())
	group_matches_amount -= 1
	var player_list = player_ids.duplicate()
	
	var teams_dictionary = {}
	
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
		left_team[id] = {}
		left_team[id]["name"] = player_names[id]
		left_team[id]["hat"] = player_hats[id]
	
	for id in right_team_ids:
		right_team[id] = {}
		right_team[id]["name"] = player_names[id]
		right_team[id]["hat"] = player_hats[id]
	
	%Visual3D.show_lineup(left_team,right_team)

	setup_lineup(left_team,right_team)
	%MatchTimer.wait_time = match_time

func setup_lineup(left_team,right_team):
	
	for c in %PlayerContainer.get_children():
		c.queue_free()
	
	for c in %LeftTeamPositions.get_children():
		c.hide()
	for c in %RightTeamPositions.get_children():
		c.hide()
	
	left_team_players.clear()
	right_team_players.clear()
	
	for id in left_team:
		var player_position_node = get_first_hidden_left()
		var player_instance = player_scene.instantiate()
		player_instance.set_color(Color(1,0.5,0.5))
		player_instance.player_id = id
		player_instance.set_hat(left_team[id]["hat"])
		player_position_node.show()
		%PlayerContainer.add_child(player_instance)
		player_instance.global_position = player_position_node.global_position
		player_instance.initial_position = player_position_node.global_position
		player_instance.rotation_degrees.y = 90
		left_team_players.append(id)
	
	for id in right_team:
		var player_position_node = get_first_hidden_right()
		var player_instance = player_scene.instantiate()
		player_instance.set_color(Color(0.5,0.5,1.0))
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
	move_ball_to_center()
	$FootBall.freeze = true
	golden_goal = false
	%MatchTimer.wait_time = match_time
	left_team_score = 0
	right_team_score = 0
	%Visual3D.hide()
	%MatchMusic.play()
	%IdleMusic.stop()
	await get_tree().create_timer(2.88).timeout
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
	$SuperBaller.stop()
	$MatchOver.stop()
	process_match_losers()
	%IdleMusic.play()
	#eliminate_random_player()
	%Visual3D.show()
	%Visual3D.hide_lineup()
	await get_tree().create_timer(10).timeout
	setup_next_match()
	%StartButton.show()

func eliminate_random_player():
	var players_to_eliminate = []
	
	if left_team_score > right_team_score:
		players_to_eliminate.append_array(right_team_players)
	elif right_team_score > left_team_score:
		players_to_eliminate.append_array(left_team_players)
	else:
		players_to_eliminate.append_array(left_team_players)
		players_to_eliminate.append_array(right_team_players)
	
	var player_id_to_eliminate = players_to_eliminate.pick_random()
	player_ids.erase(player_id_to_eliminate)
	
	print(player_id_to_eliminate)
	
	var player_dictionary = {}
	player_dictionary["hat"] = player_hats[player_id_to_eliminate]
	player_dictionary["name"] = player_names[player_id_to_eliminate]
	
	%Visual3D.eliminate_player(player_dictionary)


func _physics_process(delta):
	%PointTable.update_time(%MatchTimer.time_left)
	%PointTable.update_scores(left_team_score,right_team_score)
	if Input.is_action_just_pressed("force_match_over"):
		force_match_over()
	



func force_match_over():
	if randf_range(0,1) < 0.5:
		left_team_score += 1
	else:
		right_team_score += 1
	match_over()

func move_ball_to_center():
	var football : RigidBody3D = get_tree().get_first_node_in_group("football")
	football.global_position = Vector3(0,10,0)
	football.linear_velocity = Vector3.ZERO
	football.angular_velocity = Vector3.ZERO



func left_team_scored():
	if not active:
		return
	
	#%WhistleSFX.play()
	
	if not golden_goal:
		reset_player_positions()
	
	left_team_score += 1
	update_point_table()
	move_ball_to_center()
	if golden_goal:
		match_over()

func right_team_scored():
	if not active:
		return
	
	#%WhistleSFX.play()
	
	if not golden_goal:
		reset_player_positions()
	
	right_team_score += 1
	update_point_table()
	move_ball_to_center()
	
	if golden_goal:
		match_over()


func update_point_table():
	%PointTable.update_scores(left_team_score,right_team_score)


func _on_left_goal_area_body_entered(body):
	if body.is_in_group("football"):
		right_team_scored()


func _on_right_goal_area_body_entered(body):
	if body.is_in_group("football"):
		left_team_scored()


func _on_match_timer_timeout():
	# Only go to golden goal if it's a cup phase AND the score is tied
	if cup_phase and left_team_score == right_team_score:
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
	bomb_instance.global_position = Vector3(0,20,0)


func _on_start_button_pressed():
	start_match()
	%StartButton.hide()
