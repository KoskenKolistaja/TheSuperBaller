extends Node

# CONFIGURATION
var host := "127.0.0.1" 
var port := 9000

var tcp := StreamPeerTCP.new()
var buffer := ""

var reconnect_timer := 0.0
const RECONNECT_INTERVAL := 1.0 # Try connecting every 1 second

# Dictionary to store connected players info
# Format: { "P123": { "name": "CoolGuy", "avatar": 1 } }
var players = {}

@export var input_parser : Node

var server_pid = -1


func _ready():
	self.add_to_group("network")
	start_local_server()
	connect_to_server()





func start_local_server():
	var exe_dir = OS.get_executable_path().get_base_dir()
	var server_path = exe_dir + "/server.exe"
	
	# Fallback for testing inside the Godot Editor
	if OS.has_feature("editor"):
		server_path = ProjectSettings.globalize_path("res://PartyServer/server.exe")
	
	print("Starting local server at: ", server_path)
	
	# Launch the executable silently in the background
	server_pid = OS.create_process(server_path, [])
	
	if server_pid == -1:
		push_error("Failed to start server.exe")

# Ensure the server closes when the Godot game is closed
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if server_pid > 0:
			print("Shutting down local server...")
			OS.kill(server_pid)




func connect_to_server():
	print("🔗 Attempting connection to ", host, ":", port)
	var err = tcp.connect_to_host(host, port)
	if err != OK:
		print("❌ Failed to initialize connection.")

func _process(delta):
	tcp.poll()
	var status = tcp.get_status()
	
	if status == StreamPeerTCP.STATUS_CONNECTED:
		_check_for_messages()
	
	elif status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
		# The server isn't ready yet, or crashed. Let's retry!
		reconnect_timer -= delta
		if reconnect_timer <= 0.0:
			reconnect_timer = RECONNECT_INTERVAL
			connect_to_server()

func _check_for_messages():
	var available_bytes = tcp.get_available_bytes()
	if available_bytes > 0:
		var chunk = tcp.get_utf8_string(available_bytes)
		buffer += chunk

		while buffer.find("\n") != -1:
			var line_end = buffer.find("\n")
			var line = buffer.substr(0, line_end).strip_edges()
			buffer = buffer.substr(line_end + 1)
			
			if line != "":
				_handle_json_command(line)

func _handle_json_command(json_str: String):
	# Parse the JSON string
	var json = JSON.new()
	var error = json.parse(json_str)
	
	if error != OK:
		print("⚠️ JSON Parse Error: ", json.get_error_message())
		return

	var data = json.data
	
	# We now look for a "type" field to know if it's Settings or Input
	var msg_type = data.get("type", "input") # Default to input if missing
	var player_id = data.get("id")

	# --- 1. HANDLE SETTINGS (NAME/AVATAR) ---
	if msg_type == "config":
		var p_name = data.get("name")
		var p_avatar = data.get("avatar")
		
		# Store/Update player info
		
		#if not PlayerData.players.has(player_id):
			#PlayerData.players[player_id] = {}
		
		p_name = p_name.left(20)
		
		PlayerData.player_names[player_id] = p_name
		PlayerData.player_avatar_ids[player_id] = p_avatar
		print("👤 PLAYER CONFIG: ", p_name, " (ID: ", player_id, ") Skin: ", p_avatar)
		
		
		# Optional: If your input_parser needs to know about new players, call it here
		# var input_parser = get_tree().get_first_node_in_group("input_parser")
		# if input_parser.has_method("register_player"):
	# --- 2. HANDLE INPUT (BUTTONS) ---
	elif msg_type == "input":
		var key = data.get("key")
		var event_type = data.get("event") # "down" or "up"

		#print("🎮 Input: ", player_id, " | Key: ", key, " | ", event_type)
		
		_route_input_to_game(player_id, key, event_type)




func _route_input_to_game(player_id, key, event_type):
	# 1. Forward to your custom input parser
	if input_parser:
		input_parser.forward_player_input(player_id, key, event_type)
	else:
		push_error("Input parser not found!")
		return
	
	# 2. Debug printing (Preserved from your code)
	#if key == "A" and event_type == "down":
		#print(player_id, " Just Jumped!")
	
	#if key == "B" and event_type == "down":
		#print(player_id, " Just used action!")
	
	#if key == "LEFT":
		#if event_type == "down":
			#print(player_id, " moving left")
		#else:
			#print(player_id, " stopped moving left")
