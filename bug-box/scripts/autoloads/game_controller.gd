# Handles changing game state, ie. swaping levels, starting game
extends Node

signal game_start
signal round_over(winning_role: String)
signal round_started
signal player_tagged(tagger_id: int, tagged_id: int, hiders_left: int)

var round_active: bool = false
var host_is_seeker: bool = false

var hider_win_timer: Timer

# Currently active game level
var current_scene: Node

var multiplayer_spawner: MultiplayerSpawner
const PlayerSpawner = preload("uid://cx3pv13o45f7c")

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(-1)
	
	# Setup Player Spawner
	multiplayer_spawner = MultiplayerSpawner.new()
	multiplayer_spawner.add_spawnable_scene("res://scenes/player.tscn")
	multiplayer_spawner.set_script(PlayerSpawner)
	add_child(multiplayer_spawner, true)
	multiplayer_spawner.spawn_path = multiplayer_spawner.get_path()
	
	# Setup Hider Win Timer
	hider_win_timer = Timer.new()
	hider_win_timer.wait_time = 120.0
	hider_win_timer.one_shot = true
	hider_win_timer.timeout.connect(func(): 
		print("Starting hider win timer...")
		end_round("hider")
	)
	add_child(hider_win_timer)
	
	current_scene.load_level.connect(goto_scene)
	print(str(current_scene.get_signal_connection_list("load_level")))
	MultiplayerController.player_disconnected.connect(_on_player_disconnected)

#############
#  Helpers  #
#############

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

##########################
#  Change Current Level  #
##########################
# See https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func _deferred_goto_scene(path):
	print(path)
	current_scene.free()
	var new_scene = ResourceLoader.load(path)
	current_scene = new_scene.instantiate()
	get_tree().root.add_child(current_scene)

	# Make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene
	print("Player " + str(multiplayer.get_unique_id()) + " calling player_loaded()")
	if Globals.game_starting:
		MultiplayerController.rpc("player_loaded")


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
 	# Assign each player a random spawn location
	for child in multiplayer_spawner.get_children():
		if child is Player and current_scene is Level:
			child.position = current_scene.get_spawn_location()
	
	# Start timer for hider win condition
	hider_win_timer.start()
	
	# Assign Variables to signal game start
	Globals.game_starting = false
	round_active = true
	emit_signal("game_start") # One of these two should go away
	round_started.emit()      # This being the other of the two
	print("GAME STARTING NOW!")
 
################
#  Game Logic  #
################

func end_round(winning_role: String) -> void:
	if !multiplayer.is_server() or !round_active:
		return
	print("end_round called, round_active = ", round_active)
	print_stack()
	print("players: ", MultiplayerController.players)
	round_active = false
	announce_round_over.rpc(winning_role)
	
@rpc("authority", "call_local", "reliable")
func announce_round_over(winning_role: String) -> void:
	#something graphical here using player names
	print("ROUND OVER - winner: ", winning_role)
	round_active = false
	round_over.emit(winning_role)
	
func stop_round(): # turn off roles and win logic
	if !multiplayer.is_server():
		return
	round_active = false
	for id in MultiplayerController.players:
		MultiplayerController.players[id]["role"] = "none"
	assign_roles_to_players.rpc(MultiplayerController.players)

func tag_player(tagger_id: int, tagged_id: int) -> void:
	if !multiplayer.is_server() or !round_active:
		return
	print("tag_player was called")
	var info = MultiplayerController.players.get(tagged_id, {})
	if info.get("eliminated", false):
		return
	info["eliminated"] = true          # server-side, instantly
	eliminate_player.rpc(tagger_id, tagged_id)    # replicate to clients

	for id in MultiplayerController.players:
		var p = MultiplayerController.players[id]
		if p.get("role") == "hider" and not p.get("eliminated", false):
			return   # at least one hider is still free
	end_round("seeker")

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
