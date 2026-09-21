# Handles changing game state, ie. swaping levels, starting game
extends Node

var current_scene: Node

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(-1)
	
	current_scene.load_level.connect(goto_scene)
	print(str(current_scene.get_signal_connection_list("load_level")))


##########################
#  Change Current Level  #
##########################
# See https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)


func _deferred_goto_scene(path):
	print(path)
	current_scene.free()
	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)

	# Make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene


#####################
#  Role Assignment  #
#####################

func assign_roles():
	if !multiplayer.is_server():
		return
		
	var player_ids = Lobby.players.keys()
	var seeker_id = player_ids[randi() % player_ids.size()]
	
	for peer_id in player_ids:
		Lobby.players[peer_id]["role"] = "seeker" if peer_id == seeker_id else "hider"
	assign_roles_to_players.rpc(Lobby.players)
	
@rpc("any_peer", "call_local", "reliable")
func assign_roles_to_players(updated_players):
	# Check that server initiated
	if multiplayer.get_remote_sender_id() != 1:
		return
	Lobby.players = updated_players
	print(str(multiplayer.get_unique_id()), ": ", Lobby.players)

################
#  Start Game  #
################

@rpc("authority", "call_local", "reliable")
func start_game():
	Lobby.players_loaded = 0
	# Assign Roles
	assign_roles()
	
	# Select Level
	goto_scene(Globals.LEVEL_0)
