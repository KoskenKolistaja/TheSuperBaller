extends Control

@export var world : Node3D

var opacity_tween : Tween




func _ready():
	# One-time steps.
	# Pick a voice. Here, we arbitrarily pick the first English voice.
	var voices = DisplayServer.tts_get_voices_for_language("en")
	var voice_id = voices[0]
	
	PlayerData.init_player_data()
	


func change_to_menu():
	if opacity_tween and opacity_tween.is_valid():
		opacity_tween.kill()
	
	%PlayerPositionContainer.accept_input = false
	
	%MenuButtonContainer.visible = true
	%GameLogo.visible = true
	
	opacity_tween = create_tween()
	opacity_tween.set_parallel(true)
	
	opacity_tween.tween_property(%MenuButtonContainer, "modulate:a", 1.0, 0.3)
	opacity_tween.tween_property(%SelectionButtonContainer, "modulate:a", 0.0, 0.3)
	opacity_tween.tween_property(%GameLogo, "modulate:a", 1.0, 0.3)
	
	opacity_tween.chain().tween_callback(func():
		%SelectionButtonContainer.visible = false
	)
	
	
	world.change_to_menu()

func change_to_selection():
	
	%PlayerPositionContainer.init_data()
	%PlayerPositionContainer.accept_input = true
	
	if opacity_tween and opacity_tween.is_valid():
		opacity_tween.kill()
	
	%SelectionButtonContainer.visible = true
	
	opacity_tween = create_tween()
	opacity_tween.set_parallel(true)

	opacity_tween.tween_property(%MenuButtonContainer, "modulate:a", 0.0, 0.3)
	opacity_tween.tween_property(%SelectionButtonContainer, "modulate:a", 1.0, 0.3)
	opacity_tween.tween_property(%GameLogo, "modulate:a", 0.0, 0.3)

	# runs AFTER tween finishes
	opacity_tween.chain().tween_callback(func():
		%MenuButtonContainer.visible = false
		%GameNameLabel.visible = false
		%GameLogo.visible
	)

	world.change_to_selection()


func _on_start_button_pressed():
	change_to_selection()
	%swoosh1.play()

func _on_start_match_button_pressed():
	var player_ids : Array = %PlayerPositionContainer.get_player_ids()
	var hats : Dictionary = %PlayerPositionContainer.get_hats()
	var names = {}
	
	for id in player_ids:
		names[id] = PlayerData.player_names[id]
	
	print(names)
	
	get_parent().start_match(player_ids,hats,names)
	self.queue_free()

func _on_back_button_pressed():
	change_to_menu()
	%swoosh2.play()

func _on_exit_button_pressed():
	get_tree().quit()


func _on_replays_button_pressed():
	get_parent().change_to_replays()
	self.queue_free()
