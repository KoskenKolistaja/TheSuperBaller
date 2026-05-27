extends RigidBody3D



var default_kick_strength = 50.0

var current_player


func _physics_process(delta):
	$LabelPivot.global_position = self.global_position


func kick(kicker_position : Vector3,is_pass : bool = false, kicker = null):
	var vector = self.global_position - kicker_position
	vector.y = 0
	var kick_direction = vector.normalized()
	if is_pass:
		kick_direction *= default_kick_strength*0.5
		kick_direction.y = 0.0
	else:
		kick_direction *= default_kick_strength
		kick_direction.y = default_kick_strength * 0.2
	
	if kicker:
		current_player = kicker
		update_label()
	
	$KickSFX.play()
	apply_central_impulse(kick_direction)

func slop(kicker_position : Vector3,kicker = null):
	var vector = self.global_position - kicker_position
	vector.y = 0
	var kick_direction = vector.normalized()
	kick_direction *= default_kick_strength * 0.3
	kick_direction.y = default_kick_strength * 0.5
	
	if kicker:
		current_player = kicker
		update_label()
	
	$KickSFX.play()
	apply_central_impulse(kick_direction)


func explode(explosion_position):
	var vector = self.global_position - explosion_position
	vector.y = 0
	var kick_direction = vector.normalized()
	kick_direction *= default_kick_strength
	
	kick_direction.y = default_kick_strength * 0.2
	
	apply_central_impulse(kick_direction)




func update_label():
	var player_name = PlayerData.player_names[current_player.player_id]
	%PlayerNameLabel.text = str(player_name)


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		current_player = body
		update_label()
