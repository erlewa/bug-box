# Handles changing game state, ie. swaping levels, starting game
extends Node

signal game_start

signal round_over(winning_role: String, tagger_id: int, tagged_id: int)
signal round_started
signal player_tagged(tagger_id: int, tagged_id: int, hiders_left: int)

var round_active: bool = false
var host_is_seeker: bool = true


var current_scene: Node

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(-1)
	
	current_scene.load_level.connect(goto_scene)
	print(str(current_scene.get_signal_connection_list("load_level")))
	MultiplayerController.player_disconnected.connect(_on_player_disconnected)

##########################
#  Change Current Level  #
##########################
# See https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func display_name(id: int) -> String:
	var n = MultiplayerController.players.get(id, {}).get("name", "")
	if n == "" or n == "Name":
		return "Seeker" if id == 1 else "Player " + str(id)
	return n
	
func count_hiders() -> int:
	var count := 0
	for id in MultiplayerController.players:
		var p = MultiplayerController.players[id]
		if p.get("role") == "hider" and not p.get("eliminated", false):
			count += 1
	return count

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
		
	var player_ids = MultiplayerController.players.keys()
	if player_ids.is_empty():
		return

	var seeker_id = 1 if (host_is_seeker and 1 in player_ids) else player_ids[randi() % player_ids.size()]
	for peer_id in player_ids:
		MultiplayerController.players[peer_id]["role"] = "seeker" if peer_id == seeker_id else "hider"
	_ensure_seeker()
	assign_roles_to_players.rpc(MultiplayerController.players)
	
@rpc("any_peer", "call_local", "reliable")
func assign_roles_to_players(updated_players):
	# Check that server initiated
	if multiplayer.get_remote_sender_id() != 1:
		return
	MultiplayerController.players = updated_players
	print(str(multiplayer.get_unique_id()), ": ", MultiplayerController.players)

################
#  Start Game  #
################

# Called when all players have pressed "Ready Up" from lobby
@rpc("authority", "call_local", "reliable")
func transition_to_level():
	# Modify Game State
	Globals.game_starting = true
	MultiplayerController.players_loaded = 0
	MultiplayerController.players_ready = 0
	MultiplayerController.loaded_peers.clear()
	
	# Assign Roles
	assign_roles()
	
	# Select Level
	goto_scene(Globals.LEVEL_0)

# Called when all players have succesfully loaded into the level
@rpc("authority", "call_local", "reliable")
func start_game():
	Globals.game_starting = false
	round_active = true
	emit_signal("game_start")
	round_started.emit()
	print("GAME STARTING NOW!")
	# TO-DO: Add game starting logic, ie. give hiders some time to run away do something with the seekers
	
@rpc("authority", "call_local", "reliable")
func announce_round_over(winning_role: String, tagger_id: int, tagged_id: int) -> void:
	#something graphical here using player names
	print("ROUND OVER - winner: ", winning_role)
	print(tagger_id, " tagged ", tagged_id) 
	round_active = false
	round_over.emit(winning_role, tagger_id, tagged_id)
	
func stop_round(): # turn off roles and win logic
	if !multiplayer.is_server():
		return
	round_active = false
	for id in MultiplayerController.players:
		MultiplayerController.players[id]["role"] = "none"
	assign_roles_to_players.rpc(MultiplayerController.players)

func end_round(winning_role: String, tagger_id: int, tagged_id: int) -> void:
	if !multiplayer.is_server() or !round_active:
		return
	print("end_round called, round_active = ", round_active)
	print_stack()
	print("players: ", MultiplayerController.players)
	round_active = false
	announce_round_over.rpc(winning_role, tagger_id, tagged_id)

func tag_player(tagger_id: int, tagged_id: int) -> void:
	if !multiplayer.is_server() or !round_active:
		return
	var info = MultiplayerController.players.get(tagged_id, {})
	if info.get("eliminated", false):
		return
	info["eliminated"] = true          # server-side, instantly
	eliminate_player.rpc(tagger_id, tagged_id)    # replicate to clients

	for id in MultiplayerController.players:
		var p = MultiplayerController.players[id]
		if p.get("role") == "hider" and not p.get("eliminated", false):
			return   # at least one hider is still free
	end_round("seeker", tagger_id, tagged_id)

@rpc("authority", "call_local", "reliable")
func eliminate_player(tagger_id: int, tagged_id: int) -> void:
	if MultiplayerController.players.has(tagged_id):
		MultiplayerController.players[tagged_id]["eliminated"] = true
	player_tagged.emit(tagger_id, tagged_id, count_hiders())

func _on_player_disconnected(_id) -> void:
	if !multiplayer.is_server() or !round_active:
		return
	if MultiplayerController.players.size() < 2:
		stop_round()
		return
	_ensure_seeker()
	assign_roles_to_players.rpc(MultiplayerController.players)

func _ensure_seeker():
	var ids = MultiplayerController.players.keys()
	if ids.is_empty():
		return
	for id in ids:
			if MultiplayerController.players[id].get("role") == "seeker":
				return
	MultiplayerController.players[ids[randi() % ids.size()]]["role"] = "seeker"
