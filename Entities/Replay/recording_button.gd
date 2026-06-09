extends Button
class_name RecordingButton

signal recording_deleted(recording_name)

func get_delete_button():
	return %DeleteButton


func _on_delete_button_pressed():
	recording_deleted.emit(text)
