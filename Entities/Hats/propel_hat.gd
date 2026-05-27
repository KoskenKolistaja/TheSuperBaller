extends MeshInstance3D





func _physics_process(delta):
	$Propel.rotation_degrees.y += 10
