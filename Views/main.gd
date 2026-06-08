extends Node

@export var match_scene : PackedScene
@export var winner_scene : PackedScene
@export var menu_scene : PackedScene
@export var replay_scene : PackedScene

func _ready():
	randomize()


func start_match(player_ids : Array , hats : Dictionary,names: Dictionary):
	
	var match_scene_instance = match_scene.instantiate()
	add_child(match_scene_instance)
	match_scene_instance.setup(player_ids,hats,names)

func change_to_main_menu():
	var menu_instance = menu_scene.instantiate()
	add_child(menu_instance)


func change_to_winner_scene(player_dictionary):
	var winner_scene_instance = winner_scene.instantiate()
	add_child(winner_scene_instance)
	winner_scene_instance.setup(player_dictionary)

func change_to_replays():
	var replay_scene_instance = replay_scene.instantiate()
	add_child(replay_scene_instance)
