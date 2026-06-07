extends Node3D

var accept_input = false


@onready var platforms = [
	$PlayerPlatform,
	$PlayerPlatform2,
	$PlayerPlatform3,
	$PlayerPlatform4,
	$PlayerPlatform5,
	$PlayerPlatform6,
	$PlayerPlatform7,
	$PlayerPlatform8,
	$PlayerPlatform9,
	$PlayerPlatform10,
	$PlayerPlatform11,
	$PlayerPlatform12,
	$PlayerPlatform13,
	$PlayerPlatform14,
	$PlayerPlatform15,
	$PlayerPlatform16,
	$PlayerPlatform17,
	$PlayerPlatform18,
]

var hats = [
	"banana",
	"cap",
	"fedora",
	"hair1",
	"hair2",
	"fur_cap",
	"hard_hat",
	"headset",
	"top_hat",
	"propel_hat",
	"traffic_cone",
	"viking_helmet",
	"chicken_hat",
	"party_hat",
	"chef_hat",
	"none",
	"none2",
	"none3",
]


var hats_in_use = []


var player_ids = []
var player_hats = {}
var player_names = {}


func get_hats():
	return player_hats

func get_player_ids():
	return player_ids


func incoming_input(player_id,key,event_type):
	
	if not accept_input:
		return
	
	if key == "A":
		if not player_ids.has(player_id):
			print("A")
			spawn_player(player_id)
	if key == "B":
		if player_ids.has(player_id):
			print("B")
			delete_player(player_id)


func delete_player(exported_id):
	free_platform_by_id(exported_id)
	player_ids.erase(exported_id)
	player_hats.erase(exported_id)

func spawn_player(exported_id):
	# Get free platform
	var platform = get_free_platform()
	if platform == null:
		push_error("No free platforms!")
		return
	
	# Build list of hats that are NOT in use
	var hats_to_pick = hats.filter(func(h):
		return not hats_in_use.has(h)
	)
	
	print(hats_to_pick)
	
	# Safety check (no hats left)
	if hats_to_pick.is_empty():
		push_error("No hats available!")
		return

	# Pick random unused hat
	var random_hat = hats_to_pick.pick_random()

	# Register usage
	hats_in_use.append(random_hat)
	player_ids.append(exported_id)
	player_hats[exported_id] = random_hat

	# Spawn player
	platform.spawn_player(exported_id, random_hat)

func get_free_platform():
	for p in platforms:
		if not p.player_id:
			return p


func init_data():
	init_platforms()
	hats_in_use.clear()
	player_ids.clear()
	player_hats.clear()

func init_platforms():
	for p in platforms:
		p.free_platform()
	hats_in_use.clear()


func free_platform_by_id(exported_player_id):
	if player_hats.has(exported_player_id):
		var hat = player_hats[exported_player_id]
		hats_in_use.erase(hat)
	
	for p in platforms:
		if p.player_id == exported_player_id:
			p.free_platform()
			return
