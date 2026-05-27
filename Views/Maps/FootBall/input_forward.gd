extends Node3D






func incoming_input(player_id,key,event_type):

	var players = get_tree().get_nodes_in_group("player")
	var player = null
	
	#print("PLAYERS: " + str(players))
	
	#print("Incoming player id: " + str(player_id))
	
	#for item in players:
		#print(item.player_id)
	
	for p in players:
		if str(p.player_id) == player_id:
			player = p
	
	if player:
		player.incoming_input(key,event_type)
		print("INPUT FORWARDING TO PLAYER")
