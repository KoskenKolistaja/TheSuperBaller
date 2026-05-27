extends Node3D








func update_scores(l_score,r_score):
	var text = str(l_score) + " - " + str(r_score)
	%PointsLabel.text = text



func update_time(exported_time):
	var text = format_time(exported_time)
	%TimeLabel.text = text


func format_time(wait_time: float) -> String:
	var total_seconds := int(wait_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	
	return "%d:%02d" % [minutes, seconds]
