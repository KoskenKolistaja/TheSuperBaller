extends Node3D



var menu_angle = 30.0
var selection_angle = -90.0


var scene_change_tween : Tween







func change_to_menu():
	
	if scene_change_tween and scene_change_tween.is_valid():
		scene_change_tween.kill()
	scene_change_tween = create_tween().set_trans(Tween.TRANS_SPRING)
	var y = deg_to_rad(menu_angle)
	var vector = %MenuCamera.rotation
	vector.y = y
	scene_change_tween.tween_property(%MenuCamera,"rotation", vector, 0.75)
	#%MenuCamera.rotation_degrees.y = lerp(%MenuCamera.rotation_degrees.y,menu_angle,0.1)



func change_to_selection():
	if scene_change_tween and scene_change_tween.is_valid():
		scene_change_tween.kill()
	scene_change_tween = create_tween().set_trans(Tween.TRANS_SPRING)
	var y = deg_to_rad(selection_angle)
	var vector = %MenuCamera.rotation
	vector.y = y
	scene_change_tween.tween_property(%MenuCamera,"rotation", vector, 0.75)
