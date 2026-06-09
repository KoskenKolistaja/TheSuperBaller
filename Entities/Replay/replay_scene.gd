extends Control


@export var recording_button_scene : PackedScene

var deleted = []

func _ready():
	update_recordings()


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
		
		
		button.connect("recording_deleted",on_recording_deleted,)
		
		%RecordingsContainer.add_child(button)
		button.pressed.connect(start_replay.bind(r))


func _on_exit_button_pressed():
	%Replayer.cleanup_replay()
	%RecordingsPanel.show()

func start_replay(replay_name : String):
	%Replayer.init_replay(ReplayManager.load_recording(replay_name))
	%Replayer.playing = true
	%RecordingsPanel.hide()


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
