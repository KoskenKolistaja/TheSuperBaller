extends Node3D

var cartoon_colors: Array[Color] = [
	Color(1.0, 0.3, 0.3),   # bright red
	Color(1.0, 0.6, 0.2),   # orange
	Color(1.0, 0.9, 0.2),   # yellow
	Color(0.3, 1.0, 0.4),   # lime green
	Color(0.2, 0.9, 0.8),   # turquoise
	Color(0.3, 0.6, 1.0),   # sky blue
	Color(0.5, 0.3, 1.0),   # violet
	Color(1.0, 0.3, 0.8),   # pink
	Color(1.0, 0.4, 0.6),   # coral
	Color(0.9, 0.2, 1.0),   # magenta
]



func _ready():
	randomize_color()



func randomize_color():
	var random_color = cartoon_colors.pick_random()
	var mesh : MeshInstance3D = %PlayerMesh
	var mat : StandardMaterial3D = mesh.get_surface_override_material(0)
	mat.albedo_color = random_color

func set_color(exported_color):
	var mesh : MeshInstance3D = %PlayerMesh
	var mat : StandardMaterial3D = mesh.get_surface_override_material(0)
	mat.albedo_color = exported_color


func set_hat(hat_name : String):
	var hat_instance = ItemData.hats[hat_name].instantiate()
	%HatSlot.add_child(hat_instance)

func reset_hat():
	for c in %HatSlot.get_children():
		c.queue_free()


func show_name(exported_name):
	%NameLabel.text = exported_name
	%NameLabel.show()
