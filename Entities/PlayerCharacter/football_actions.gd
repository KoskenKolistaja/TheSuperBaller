extends Area3D


@export var player : RigidBody3D


func action1():
	var bodies = get_overlapping_bodies()
	if bodies:
		bodies[0].kick(player.global_position,false,player)

func action2():
	var bodies = get_overlapping_bodies()
	if bodies:
		bodies[0].slop(player.global_position,player)
