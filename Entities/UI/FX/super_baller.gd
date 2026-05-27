extends Control

@onready var word_container: HBoxContainer = $WordContainer

@export var shake_speed := 7.0
@export var rotation_strength := 5.0
@export var scale_strength := 0.06

var noise := FastNoiseLite.new()
var time := 0.0

var active = false

func start():
	await get_tree().create_timer(2).timeout
	$AnimationPlayer.play("SuperBaller")
	active = true

func stop():
	$AnimationPlayer.play("RESET")

func _ready():
	
	
	noise.seed = randi()
	noise.frequency = 1.2

	# Center pivot so rotation looks natural
	for child in word_container.get_children():
		if child is Label:
			await get_tree().process_frame
			child.pivot_offset = child.size * 0.5


func _process(delta):
	if not active:
		return
	
	time += delta * shake_speed

	var i := 0
	for child in word_container.get_children():
		if child is Label:
			_shake_label(child, i)
			i += 1


func _shake_label(label: Label, index: int):
	var t = time + index * 6.0

	var rot_noise = noise.get_noise_2d(t, 0.0)
	var scale_noise = noise.get_noise_2d(0.0, t)

	# 🎬 cinematic rotation
	label.rotation = deg_to_rad(rot_noise * rotation_strength)

	# 🎬 subtle power pulse
	var s = 1.0 + scale_noise * scale_strength
	label.scale = Vector2.ONE * s
