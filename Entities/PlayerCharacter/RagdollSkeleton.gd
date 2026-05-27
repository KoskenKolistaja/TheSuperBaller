extends Node3D

## Configuration
@export_group("References")
@export var skeleton: Skeleton3D
@export var simulator: PhysicalBoneSimulator3D

@export_group("Active Ragdoll Physics")
@export var stiffness: float = 2000.0    ## How hard the bones try to match animation
@export var damping: float = 150.0       ## Prevents jitter and overshoot
@export var max_torque: float = 500.0    ## Limits violent spinning
@export var max_force: float = 5000.0    ## Limits root bone force
@export var master_strength: float = 1.0 ## 1.0 = stiff animation, 0.0 = limp ragdoll

# Internal cache
var physical_bones: Array[PhysicalBone3D] = []
var bone_indices: Array[int] = []
var _target_global_poses: Array[Transform3D] = []

func _ready() -> void:
	if not skeleton or not simulator:
		push_error("ActiveRagdoll: Please assign Skeleton and Simulator in the Inspector.")
		return
	_initialize_bone_map()

	var parent_body = get_parent()
	if parent_body is CollisionObject3D:
		simulator.physical_bones_add_collision_exception(parent_body.get_rid())

	simulator.physical_bones_start_simulation()

func _initialize_bone_map() -> void:
	physical_bones.clear()
	bone_indices.clear()
	_target_global_poses.clear()

	for child in simulator.get_children():
		if child is PhysicalBone3D:
			var bone_id = child.get_bone_id()
			if bone_id != -1:
				physical_bones.append(child)
				bone_indices.append(bone_id)
				_target_global_poses.append(Transform3D.IDENTITY)
				# Enable custom integrator so we can apply forces each frame properly
				child.custom_integrator = true

# Snapshot animated poses AFTER AnimationPlayer runs but BEFORE physics
func _process(_delta: float) -> void:
	if not skeleton:
		return
	for i in range(physical_bones.size()):
		_target_global_poses[i] = skeleton.global_transform * skeleton.get_bone_global_pose(bone_indices[i])

func _physics_process(delta: float) -> void:
	_drive_bones(delta)

# We attach a custom integrator to each bone using _integrate_forces.
# Since GDScript can't override _integrate_forces per-instance on existing nodes,
# we instead use a helper: subclass approach or direct force via apply_impulse workaround.
# 
# The correct approach for PhysicalBone3D without apply_torque_impulse is to
# apply two equal and opposite impulses offset from the center to produce a torque.
func _simulate_torque(p_bone: PhysicalBone3D, torque: Vector3, delta: float) -> void:
	# Decompose torque into 3 axis pairs of opposing impulses.
	# For each world axis, apply force at +offset and -force at -offset.
	# torque = r x F => F = torque / |r|, applied at offset r perpendicular to torque axis.
	var offset := 0.5  # meters from center — bone-size-appropriate
	
	# We split torque into per-axis components and apply impulse pairs for each.
	var axes := [
		p_bone.global_transform.basis.x,
		p_bone.global_transform.basis.y,
		p_bone.global_transform.basis.z
	]
	var torque_components := [torque.x, torque.y, torque.z]
	
	# For torque around local axis[i], apply force along a perpendicular local axis
	var perp_axes := [
		p_bone.global_transform.basis.y,  # perp to X is Y
		p_bone.global_transform.basis.z,  # perp to Y is Z
		p_bone.global_transform.basis.x   # perp to Z is X
	]

	for i in 3:
		var t_component: float = torque_components[i]
		if abs(t_component) < 0.0001:
			continue
		# Force magnitude: |torque| = |r| * |F| => |F| = |torque| / |r|
		var force_magnitude: float = t_component / offset
		var force_dir: Vector3 = perp_axes[i] * force_magnitude * delta
		var pos_offset: Vector3 = axes[i] * offset

		# Apply equal and opposite impulses at +offset and -offset
		p_bone.apply_impulse(force_dir, pos_offset)
		p_bone.apply_impulse(-force_dir, -pos_offset)

func _apply_rotation_drive(p_bone: PhysicalBone3D, current_basis: Basis, target_basis: Basis, delta: float) -> void:
	var q_current := current_basis.get_rotation_quaternion()
	var q_target := target_basis.get_rotation_quaternion()

	# Shortest path
	if q_current.dot(q_target) < 0.0:
		q_target = -q_target

	var q_error := q_target * q_current.inverse()

	# Safe axis-angle extraction from quaternion
	var angle := 2.0 * acos(clampf(q_error.w, -1.0, 1.0))
	if angle > PI:
		angle -= 2.0 * PI

	var spring_torque := Vector3.ZERO
	if abs(angle) > 0.0001:
		var sin_half := sqrt(max(0.0, 1.0 - q_error.w * q_error.w))
		var axis: Vector3
		if sin_half > 0.0001:
			axis = Vector3(q_error.x, q_error.y, q_error.z) / sin_half
		else:
			axis = Vector3.UP
		spring_torque = axis * angle * stiffness * master_strength

	# Damping always applied
	var damp_torque := -p_bone.angular_velocity * damping
	var torque := (spring_torque + damp_torque).limit_length(max_torque)

	_simulate_torque(p_bone, torque, delta)

func _apply_linear_drive(p_bone: PhysicalBone3D, current_pos: Vector3, target_pos: Vector3, delta: float) -> void:
	var pos_error := target_pos - current_pos
	var force := (pos_error * stiffness * master_strength) - (p_bone.linear_velocity * damping)
	force = force.limit_length(max_force)
	p_bone.apply_central_impulse(force * delta)

# Called from _physics_process, drives all bones each frame
func _drive_bones(delta: float) -> void:
	if not simulator.is_simulating_physics():
		return

	var root_bones := skeleton.get_parentless_bones()
	var root_bone_idx := root_bones[0] if root_bones.size() > 0 else -1

	for i in range(physical_bones.size()):
		var p_bone := physical_bones[i]
		var b_idx := bone_indices[i]
		var target := _target_global_poses[i]
		var current := p_bone.global_transform

		_apply_rotation_drive(p_bone, current.basis, target.basis, delta)

		if b_idx == root_bone_idx:
			_apply_linear_drive(p_bone, current.origin, target.origin, delta)
