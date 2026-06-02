extends Node3D















func setup(player_dictionary):
	
	if not player_dictionary:
		return
	
	var name = player_dictionary["name"]
	%WinLabel.text = name + " is the Super Baller™!"
	
	$PlayerProp.set_hat(player_dictionary["hat"])


func _on_button_pressed():
	get_parent().change_to_main_menu()
	queue_free()
