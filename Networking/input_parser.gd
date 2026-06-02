extends Node











# This function receives actions
# Keys are: "LEFT","RIGHT","UP","DOWN","A" and "B"
# event_type is "down" or "up" meaning that button was pressed or released

func forward_player_input(player_id,key,event_type):
	print("Forwarding")
	get_tree().call_group("input_receiver" , "incoming_input" , player_id,key, event_type)

func _ready():
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var network = get_tree().get_first_node_in_group("network")
	network.input_parser = self


func _physics_process(delta):
	if Input.is_action_just_pressed("1"):
		forward_player_input("1","A","down")
		PlayerData.player_names["1"] = "Player1"
	if Input.is_action_just_pressed("2"):
		forward_player_input("2","A","down")
		PlayerData.player_names["2"] = "Player2"
	if Input.is_action_just_pressed("3"):
		forward_player_input("3","A","down")
		PlayerData.player_names["3"] = "Player3"
	if Input.is_action_just_pressed("4"):
		forward_player_input("4","A","down")
		PlayerData.player_names["4"] = "Player4"
	if Input.is_action_just_pressed("5"):
		forward_player_input("5","A","down")
		PlayerData.player_names["5"] = "Player5"
	if Input.is_action_just_pressed("6"):
		forward_player_input("6","A","down")
		PlayerData.player_names["6"] = "Player6"
	if Input.is_action_just_pressed("7"):
		forward_player_input("7","A","down")
		PlayerData.player_names["7"] = "Player7"
	if Input.is_action_just_pressed("8"):
		forward_player_input("8","A","down")
		PlayerData.player_names["8"] = "Player8"
	if Input.is_action_just_pressed("9"):
		forward_player_input("9","A","down")
		PlayerData.player_names["9"] = "Player9"
	if Input.is_action_just_pressed("10"):
		forward_player_input("10","A","down")
		PlayerData.player_names["10"] = "Player10"
	if Input.is_action_just_pressed("11"):
		forward_player_input("11","A","down")
		PlayerData.player_names["11"] = "Player11"
	if Input.is_action_just_pressed("12"):
		forward_player_input("12","A","down")
		PlayerData.player_names["12"] = "Player12"
	if Input.is_action_just_pressed("13"):
		forward_player_input("13","A","down")
		PlayerData.player_names["13"] = "Player13"
	if Input.is_action_just_pressed("14"):
		forward_player_input("14","A","down")
		PlayerData.player_names["14"] = "Player14"
	if Input.is_action_just_pressed("15"):
		forward_player_input("15","A","down")
		PlayerData.player_names["15"] = "Player15"
	if Input.is_action_just_pressed("16"):
		forward_player_input("16","A","down")
		PlayerData.player_names["16"] = "Player16"
	if Input.is_action_just_pressed("17"):
		forward_player_input("17","A","down")
		PlayerData.player_names["17"] = "Player17"
	if Input.is_action_just_pressed("18"):
		forward_player_input("18","A","down")
		PlayerData.player_names["18"] = "Player18"
	if Input.is_action_just_pressed("19"):
		forward_player_input("19","A","down")
		PlayerData.player_names["19"] = "Player19"
	
	
	# --- Controller Device 0 ---
	var controller_player_id := "controller1"
	
	# D-Pad
	if Input.is_action_just_pressed("pad_up"):
		forward_player_input(controller_player_id, "UP", "down")
		PlayerData.player_names[controller_player_id] = "Controller"
	if Input.is_action_just_released("pad_up"):
		forward_player_input(controller_player_id, "UP", "up")

	if Input.is_action_just_pressed("pad_down"):
		forward_player_input(controller_player_id, "DOWN", "down")
		PlayerData.player_names[controller_player_id] = "Controller"
	if Input.is_action_just_released("pad_down"):
		forward_player_input(controller_player_id, "DOWN", "up")

	if Input.is_action_just_pressed("pad_left"):
		forward_player_input(controller_player_id, "LEFT", "down")
		PlayerData.player_names[controller_player_id] = "Controller"
	if Input.is_action_just_released("pad_left"):
		forward_player_input(controller_player_id, "LEFT", "up")

	if Input.is_action_just_pressed("pad_right"):
		forward_player_input(controller_player_id, "RIGHT", "down")
		PlayerData.player_names[controller_player_id] = "Controller"
	if Input.is_action_just_released("pad_right"):
		forward_player_input(controller_player_id, "RIGHT", "up")

	# A Button
	if Input.is_action_just_pressed("pad_a"):
		forward_player_input(controller_player_id, "A", "down")
		PlayerData.player_names[controller_player_id] = "Controller"
	if Input.is_action_just_released("pad_a"):
		forward_player_input(controller_player_id, "A", "up")

	# X Button (mapped as B)
	if Input.is_action_just_pressed("pad_x"):
		forward_player_input(controller_player_id, "B", "down")
		PlayerData.player_names[controller_player_id] = "Controller"
	if Input.is_action_just_released("pad_x"):
		forward_player_input(controller_player_id, "B", "up")
