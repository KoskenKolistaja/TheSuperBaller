extends Control






func set_text(exp_text):
	%InfoLabel.text = exp_text


func hide_overlay():
	self.hide()
	%SaveReplayPanel.hide()


func _on_save_replay_button_pressed():
	%SaveReplayPanel.show()


func _on_save_button_pressed():
	if %TextEdit.text.is_empty():
		return
	
	ReplayManager.save_recording(%TextEdit.text,ReplayManager.dictionaries)
	%SaveReplayPanel.hide()
