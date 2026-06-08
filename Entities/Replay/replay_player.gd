extends Node3D

var id = -1

func _ready():
	show_name()
	

func _physics_process(delta):
	show_name()

func update_animation_speed(new_speed):
	%AnimationPlayer.speed_scale = new_speed

func show_name():
	%NameLabel.text = name
	%NameLabel.show()

func hide_name():
	%NameLabel.text = name
	%NameLabel.hide()

func set_hat(hat_name : String):
	var hat_instance = ItemData.hats[hat_name].instantiate()
	%HatSlot.add_child(hat_instance)


func set_color(exported_color):
	var mesh : MeshInstance3D = %Cube
	var mat : StandardMaterial3D = mesh.get_surface_override_material(0)
	mat.albedo_color = exported_color


func set_animation(animation_name):
	%AnimationPlayer.play(animation_name)
