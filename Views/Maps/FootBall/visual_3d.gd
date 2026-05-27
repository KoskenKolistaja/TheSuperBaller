extends Node3D


var eliminated_players = ""


func eliminate_player(dictionary):
	var player_prop = %EliminatedPlayer
	player_prop.reset_hat()
	player_prop.set_hat(dictionary["hat"])
	player_prop.show()
	eliminated_players += " " + dictionary["name"]
	player_prop.show_name(eliminated_players)
	await get_tree().create_timer(5).timeout
	player_prop.hide()
	eliminated_players = ""


func set_match_info(number,group_matches_left,players_left):
	var match_text = "Elimination Stage"
	
	
	if players_left < 3:
		match_text = "Grand Final"
	elif players_left < 5:
		match_text = "Semi Final"
	elif group_matches_left > 0:
		match_text = "Group Stage"
	
	%MatchInfo.text = "Match " + str(number) + "\n" + "-" + "\n" + match_text

func hide_lineup():
	$PlayerPositions.hide()
	%MatchInfo.hide()

func show_lineup(left_team : Dictionary , right_team : Dictionary):
	for c in %LeftTeamPositions.get_children():
		c.hide()
	for c in %RightTeamPositions.get_children():
		c.hide()
	
	%MatchInfo.show()
	$PlayerPositions.show()
	
	for id in left_team:
		var player_prop = get_first_hidden_left()
		player_prop.set_color(Color(1,0.5,0.5))
		player_prop.show_name(left_team[id]["name"])
		player_prop.reset_hat()
		player_prop.set_hat(left_team[id]["hat"])
		player_prop.show()
	
	for id in right_team:
		var player_prop = get_first_hidden_right()
		player_prop.set_color(Color(0.5,0.5,1))
		player_prop.show_name(right_team[id]["name"])
		player_prop.reset_hat()
		player_prop.set_hat(right_team[id]["hat"])
		player_prop.show()




func get_first_hidden_left():
	for i in %LeftTeamPositions.get_children():
		if not i.visible:
			return i

func get_first_hidden_right():
	for i in %RightTeamPositions.get_children():
		if not i.visible:
			return i
