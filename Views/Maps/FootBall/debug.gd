extends Label




func _physics_process(delta):
	if Input.is_action_just_pressed("debug"):
		if visible:
			hide()
		else:
			show()
