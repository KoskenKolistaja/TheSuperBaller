extends Node3D

@export var player_prop : PackedScene

var player_id = null
var hat : String = "none"





func _physics_process(delta):
	update_label()



func update_label():
	if not player_id:
		return
	if PlayerData.player_names.has(player_id):
		%PlayerNameLabel.text = PlayerData.player_names[player_id]


func free_platform():
	for c in $PlayerContainer.get_children():
		print(c)
		c.queue_free()
	player_id = null
	%PlayerNameLabel.text = ""



func spawn_player(exported_player_id,hat : String):
	player_id = exported_player_id
	var p_instance = player_prop.instantiate()
	%PlayerContainer.add_child(p_instance)
	p_instance.set_hat(hat)
	show()
