extends RigidBody3D

var default_kick_strength = 15.0


func kick(kicker_position : Vector3):
	var vector = self.global_position - kicker_position
	vector.y = 0
	var kick_direction = vector.normalized()
	kick_direction *= default_kick_strength
	
	kick_direction.y = default_kick_strength * 0.4
	
	apply_central_impulse(kick_direction)


func _ready():
	await get_tree().create_timer(10).timeout
	var bodies = $Area3D.get_overlapping_bodies()
	
	for b in bodies:
		b.explode(self.global_position)
	
	queue_free()
