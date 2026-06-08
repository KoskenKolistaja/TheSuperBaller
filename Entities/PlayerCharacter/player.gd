extends RigidBody3D


var rotation_direction = Vector3.ZERO

@export var action_item : Node3D

var active = false

var player_id
var player_name

var initial_position : Vector3

var current_hat = null

enum PlayerState {
	NORMAL,
	EXPLODED
}

var state : PlayerState = PlayerState.NORMAL

# =========================================================
# INPUT STATE (works with phone press/release events)
# =========================================================
var input_left := false
var input_right := false
var input_up := false
var input_down := false


# =========================================================
# TUNING (adjust for game feel)
# =========================================================
@export var max_speed := 11.0
@export var acceleration := 55.0
@export var braking := 70.0
@export var turn_speed := 10.0
@export var sideways_drag := 6.0   # reduces ice skating


# =========================================================
# PHONE INPUT SYSTEM
# key = "LEFT","RIGHT","UP","DOWN"
# event_type = "down" or "up"
# =========================================================
func incoming_input(key:String, event_type:String):

	var pressed := event_type == "down"

	match key:
		"LEFT":
			input_left = pressed
		"RIGHT":
			input_right = pressed
		"UP":
			input_up = pressed
		"DOWN":
			input_down = pressed
		"A":
			action1()
		"B":
			action2()

func action1():
	if action_item:
		action_item.action1()

func action2():
	if action_item:
		action_item.action2()



# =========================================================
# MAIN LOOP
# =========================================================
func _physics_process(delta):
	if active:
		if state == PlayerState.NORMAL:
			simulate_buttons()   # remove later on phone
			move_character(delta)
			rotate_visual(delta)


func _ready():
	await get_tree().physics_frame
	name = PlayerData.get_player_name(player_id)



# =========================================================
# MOVEMENT (GOOD GAME FEEL SECTION)
# =========================================================
func move_character(delta):

	# Build input vector from button states
	var x := int(input_right) - int(input_left)
	var z := int(input_down) - int(input_up)

	var input_dir := Vector3(x, 0, z)

	var vel := linear_velocity
	var flat_vel := Vector3(vel.x, 0, vel.z)

	# -----------------------------
	# PLAYER IS MOVING
	# -----------------------------
	
	if input_dir.length() > 0:
		%AnimationPlayer.play("Walk")
	else:
		%AnimationPlayer.play("Idle")
	
	
	if input_dir.length() > 0:

		input_dir = input_dir.normalized()

		var target_velocity = input_dir * max_speed
		var velocity_change = target_velocity - flat_vel

		# strong responsive acceleration
		apply_central_force(velocity_change * acceleration)

		# remove sideways sliding (VERY important for football feel)
		var forward := flat_vel.normalized()
		if flat_vel.length() > 0.1:
			var sideways = flat_vel - forward * flat_vel.dot(forward)
			apply_central_force(-sideways * sideways_drag)

	# -----------------------------
	# NO INPUT → BRAKE
	# -----------------------------
	else:
		apply_central_force(-flat_vel * braking)

func explode(from_position: Vector3, force := 25.0):

	if state == PlayerState.EXPLODED:
		return
	input_left = false
	input_right = false
	input_up = false
	input_down = false
	state = PlayerState.EXPLODED
	active = false   # disable control

	# allow physics rotation temporarily
	axis_lock_angular_x = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false

	var dir = (global_position - from_position)
	dir.y = 2.6   # upward kick
	dir = dir.normalized()

	# clear current motion
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	var torque_strength = 3
	
	#apply_central_impulse(Vector3(randf_range(0,1),randf_range(0,1),randf_range(0,1)))
	apply_torque_impulse(dir*torque_strength)
	apply_central_impulse(dir * force)

	%AnimationPlayer.play("Hit")

	# start recovery
	recover_after_explosion()


# =========================================================
# VISUAL ROTATION
# =========================================================
func rotate_visual(delta):

	var vel := linear_velocity
	vel.y = 0

	if vel.length() < 0.15:
		return
	
	rotation_direction = rotation_direction.move_toward(vel.normalized(),0.2)
	
	var dir = -rotation_direction

	# Godot forward = -Z
	var target_basis := Basis().looking_at(dir, Vector3.UP)

	$Visual.global_basis = $Visual.global_basis.slerp(
	target_basis,
	turn_speed * delta
	)


func recover_after_explosion():
	await get_tree().create_timer(1.2).timeout

	# wait until mostly stopped
	while linear_velocity.length() > 0.5:
		await get_tree().physics_frame

	stand_up_smooth()

func stand_up_smooth(duration := 0.5):
	# 1. FREEZE the body! This tells the physics engine to ignore it temporarily, 
	# preventing those "theoretical powers" from blasting other objects away.
	freeze = true

	var start_basis = global_basis
	var target_basis = Basis.IDENTITY
	# Keep the current Y rotation so the player doesn't spin around
	target_basis = target_basis.rotated(Vector3.UP, $Visual.global_rotation.y)

	# 2. Use a Tween instead of a while loop. It manages time and easing perfectly.
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CUBIC) # Built-in smooth easing (similar to smoothstep)
	tween.set_ease(Tween.EASE_IN_OUT)

	# 3. Animate the rotation using a lambda function to properly Slerp the basis
	tween.tween_method(
		func(weight: float): global_basis = start_basis.slerp(target_basis, weight),
		0.0,
		1.0,
		duration
	)

	await tween.finished

	# 4. Snap to the exact final rotation and kill any residual momentum
	global_basis = target_basis
	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO # Optional, but good for stability

	# Re-lock axes
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

	# 5. UNFREEZE to wake the physics engine back up safely
	freeze = false

	state = PlayerState.NORMAL
	active = true

	%AnimationPlayer.play("Idle")

# =========================================================
# DEBUG DESKTOP INPUT (REMOVE ON PHONE)
# =========================================================
func simulate_buttons():

	if Input.is_action_just_pressed("ui_up"):
		incoming_input("UP","down")
	if Input.is_action_just_pressed("ui_down"):
		incoming_input("DOWN","down")
	if Input.is_action_just_pressed("ui_left"):
		incoming_input("LEFT","down")
	if Input.is_action_just_pressed("ui_right"):
		incoming_input("RIGHT","down")
	if Input.is_action_just_pressed("ui_accept"):
		incoming_input("A","down")
	if Input.is_action_just_pressed("b"):
		incoming_input("B","down")

	if Input.is_action_just_released("ui_up"):
		incoming_input("UP","up")
	if Input.is_action_just_released("ui_down"):
		incoming_input("DOWN","up")
	if Input.is_action_just_released("ui_left"):
		incoming_input("LEFT","up")
	if Input.is_action_just_released("ui_right"):
		incoming_input("RIGHT","up")

func set_hat(hat_name : String):
	var hat_instance = ItemData.hats[hat_name].instantiate()
	current_hat = hat_name
	%HatSlot.add_child(hat_instance)

func set_color(exported_color):
	var mesh : MeshInstance3D = %Cube
	var mat : StandardMaterial3D = mesh.get_surface_override_material(0)
	mat.albedo_color = exported_color

func get_color() -> Color:
	var mesh : MeshInstance3D = %Cube
	var mat : StandardMaterial3D = mesh.get_surface_override_material(0)
	return mat.albedo_color

func deactivate():
	active = false
	%AnimationPlayer.play("Idle")

func get_replay_state() -> Dictionary:
	var returned = {}
	returned["position"] = global_position
	returned["rotation"] = %Visual.global_rotation
	returned["animation"] = %AnimationPlayer.assigned_animation
	return returned

func get_appearance():
	var returned = {}
	returned["color"] = get_color()
	returned["hat"] = current_hat
	returned["name"] = name
	return returned
