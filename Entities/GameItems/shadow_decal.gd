extends Decal





@export var raycast : RayCast3D















func _physics_process(delta):
	if not raycast:
		return
	var collision_point = raycast.get_collision_point()
	
	if collision_point:
		global_position = raycast.get_collision_point()
	
	raycast.global_position = get_parent().global_position
