extends Node



var player_characters = {}
var player_names = {}
var player_hats = {}
var player_avatar_ids = {}





func get_player(exp_id):
	push_warning(player_characters[exp_id])
	return player_characters[exp_id]["character"]

func get_player_character(exp_id):
	if not player_characters.has(exp_id):
		return null
	elif not player_characters[exp_id].has("character"):
		return null
	else:
		return player_characters[exp_id]["character"]

func get_player_name(exp_id):
	return player_names[exp_id]

func init_player_data():
	player_characters = {}
	player_names = {}
	player_hats = {}
	player_avatar_ids = {}
