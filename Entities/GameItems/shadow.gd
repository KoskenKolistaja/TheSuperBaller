extends Node3D












func _physics_process(delta):
	var p_position = get_parent().global_position
	self.global_position = Vector3(p_position.x,0.01,p_position.z)
	scale_shadow_by_height()


func scale_shadow_by_height():

	var height = abs(get_parent().global_position.y)

	var max_height := 15.0
	var min_scale := 0.4
	var max_scale := 1.6

	var t = clamp(height / max_height, 0.0, 1.0)

	# Bigger when closer to ground
	var scale_value = lerp(max_scale, min_scale, t)

	scale = Vector3(scale_value, scale_value, 1.0)
