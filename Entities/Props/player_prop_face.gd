extends Node3D

enum mouth_shapes {
	SMILE,
	LAUGH,
	FROWN,
	SURPRISED,
}

enum brow_shapes {
	SAD,
	ANGRY,
	SURPRISED,
}

@export var overridden : bool = false

var eyes_closed = 0.0
# Add a variable to keep track of the active expression tween
var expression_tween : Tween

func _ready():
	blinking()
	if not overridden:
		face_changing()
	else:
		proud()


func face_changing():
	face_change()
	await get_tree().create_timer(randf_range(3,6)).timeout
	face_changing()

func change_face_by_string(string_name):
	
	match string_name:
		"sad":
			sad()
		"awkward":
			awkward()
		"angry":
			angry()
		"proud":
			proud()
		"neutral":
			neutral()
		"devilish":
			devilish()
		"surprised":
			suprised()


func face_change():
	var expressions = ["sad","awkward","angry","proud","neutral","devilish","surprised"]
	var random = expressions.pick_random()
	match random:
		"sad":
			sad()
		"awkward":
			awkward()
		"angry":
			angry()
		"proud":
			proud()
		"neutral":
			neutral()
		"devilish":
			devilish()
		"surprised":
			suprised()

func blinking():
	blink()
	await get_tree().create_timer(randf_range(3,6)).timeout
	blinking()

func blink():
	$Eyes.set_blend_shape_value(0,0)
	# Blinking gets its own local tween because we WANT it to 
	# happen at the same time as the expressions without interrupting them!
	var tween = create_tween()
	tween.tween_property($Eyes,"blend_shapes/Closed",1.0,0.1)
	tween.tween_property($Eyes,"blend_shapes/Closed",0.0,0.1)




# Helper function to handle the tweening so we don't repeat code!
func apply_expression(m_smile: float, m_laugh: float, m_frown: float, m_surprised: float, b_sad: float, b_angry: float, b_surprised: float):
	# If an expression tween is already running, kill it to prevent overlaps
	if expression_tween and expression_tween.is_valid():
		expression_tween.kill()
		
	# Create the new global tween
	expression_tween = create_tween()
	expression_tween.set_parallel(true)
	
	expression_tween.tween_property($Mouth,"blend_shapes/Smile", m_smile, 0.1)
	expression_tween.tween_property($Mouth,"blend_shapes/Laugh", m_laugh, 0.1)
	expression_tween.tween_property($Mouth,"blend_shapes/Frown", m_frown, 0.1)
	expression_tween.tween_property($Mouth,"blend_shapes/Surprised", m_surprised, 0.1)
	
	expression_tween.tween_property($Brows,"blend_shapes/Sad", b_sad, 0.1)
	expression_tween.tween_property($Brows,"blend_shapes/Angry", b_angry, 0.1)
	expression_tween.tween_property($Brows,"blend_shapes/Surprised", b_surprised, 0.1)


func angry():
	apply_expression(0.0, 0.0, 1.0, 0.25, 0.0, 0.75, -0.35)

func proud():
	apply_expression(1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5)
	
func neutral():
	apply_expression(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

func awkward():
	apply_expression(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0)

func devilish():
	apply_expression(1.0, 0.0, 0.0, 0.0, 0.0, 0.3, -0.35)

func sad():
	apply_expression(0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0)

func suprised():
	apply_expression(0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.75)
