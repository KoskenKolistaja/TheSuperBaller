extends Control

@export var recording_button_scene : PackedScene

var deleted = []

func _ready():
	update_recordings()
	# Connect the replayer signal to update this UI slider
	%Replayer.frame_changed.connect(_on_replayer_frame_changed)
	
	# Configure slider behavior so it doesn't trigger updates during code modifications
	%HSlider.step = 1


func on_recording_deleted(recording_name):
	ReplayManager.delete_recording(recording_name)
	deleted.append(recording_name)
	update_recordings()


func update_recordings():
	for c in %RecordingsContainer.get_children():
		c.queue_free()
	
	var recordings = ReplayManager.get_saved_recordings()
	
	for r in recordings:
		if deleted.has(r):
			continue
		
		var button = recording_button_scene.instantiate()
		button.name = r
		button.text = r
		
		button.connect("recording_deleted", on_recording_deleted)
		%RecordingsContainer.add_child(button)
		button.pressed.connect(start_replay.bind(r))


func _on_exit_button_pressed():
	%Replayer.cleanup_replay()
	%RecordingsPanel.show()


func start_replay(replay_name : String):
	%Replayer.init_replay(ReplayManager.load_recording(replay_name))
	%Replayer.playing = true
	%RecordingsPanel.hide()
	update_play_pause_button_text()


# --- TIMELINE & CONTROLS ---

# Called via signal from %Replayer whenever a new tick passes
func _on_replayer_frame_changed(current_frame: int, max_frames: int):
	# Set slider boundaries safely without re-triggering signal calculations
	%HSlider.max_value = max_frames - 1
	
	if not %Replayer.is_scrubbing:
		%HSlider.set_value_no_signal(current_frame)


# Connect this to your HSlider's 'drag_started' signal
func _on_h_slider_drag_started():
	%Replayer.is_scrubbing = true


# Connect this to your HSlider's 'drag_ended' signal
func _on_h_slider_drag_ended(value_changed):
	%Replayer.is_scrubbing = false
	%Replayer.set_scrub_position(int(%HSlider.value))


# Connect this to your HSlider's 'value_changed' signal
func _on_h_slider_value_changed(value):
	# Allows scrubbing instantly while holding down/moving the slider
	if %Replayer.is_scrubbing:
		%Replayer.set_scrub_position(int(value))


# Create a Button named PlayPauseButton and connect its pressed signal here
func _on_play_pause_button_pressed():
	%Replayer.playing = !%Replayer.playing
	update_play_pause_button_text()


func update_play_pause_button_text():
	if %PlayPauseButton:
		%PlayPauseButton.text = "Pause" if %Replayer.playing else "Play"


# --- SPEED CONTROLS ---

func _on_tenth_button_pressed():
	%Replayer.TICK_RATE = 1
	%Replayer.update_tick_interval(0.1)
func _on_half_button_pressed():
	%Replayer.TICK_RATE = 5
	%Replayer.update_tick_interval(0.5)
func _on_normal_button_pressed():
	%Replayer.TICK_RATE = 10
	%Replayer.update_tick_interval(1.0)
func _on_double_button_pressed():
	%Replayer.TICK_RATE = 20
	%Replayer.update_tick_interval(2.0)
func _on_triple_button_pressed():
	%Replayer.TICK_RATE = 30
	%Replayer.update_tick_interval(3.0)


func _on_button_pressed():
	get_parent().change_to_main_menu()
	self.queue_free()
