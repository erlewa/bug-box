extends Node

# Autoload named Lobby

var lobby_id : int = 0
var peer: SteamMultiplayerPeer
var is_host : bool = false
var is_joining : bool = false

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

signal peer_level_loaded(peer_id)
var loaded_peers := {}

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name", "role": "none", "bugindex": 0}


var players_loaded = 0
var players_ready = 0


func _ready():
	print("Steam initialized: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	
func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		
		var error = peer.create_host(0)
		
		print("HOST CREATE RESULT: ", error)

		if error != OK:
			print("HOST CREATION FAILED")
			return
		
		multiplayer.multiplayer_peer = peer
		
		players[1] = player_info
		player_connected.emit(1, player_info)
		
		print("Lobby created: ", lobby_id)
		print("Host Steam ID: ", Steam.getSteamID())
		print(players)


func _on_lobby_joined(lobby_id: int, permission : int, locked: bool, response: int):
	if !is_joining:
		print("this player isn't actually joining rn")
		return
	
	print("\n========== LOBBY JOINED ==========")
	print("Lobby ID: ", lobby_id)
	print("Response: ", response)

	# Verify Steam actually accepted the lobby join.
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("STEAM LOBBY JOIN FAILED")
		is_joining = false
		return
	
	var lobbyOwnerId = Steam.getLobbyOwner(lobby_id)
	
	if lobbyOwnerId == Steam.getSteamID():
		print("ONLOBBYJOINED BUT Lobby owner matches our steam id, silly")
	else:
		self.lobby_id = lobby_id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		var error = peer.create_client(lobbyOwnerId, 0)
		print("Create client error: ", error)

		if error != OK:
			print("FAILED TO CREATE CLIENT PEER")
			is_joining = false
			return
		
		multiplayer.multiplayer_peer = peer
		
		print("Done joining lobby")
	is_joining = false


# Called from Join Game button
func join_game(address = "", name = "", bugindex = 0):
	player_info["bugindex"] = bugindex
	player_info["name"] = name
	
	is_joining = true
	Steam.joinLobby(address.to_int())
	
	#if address.is_empty():
		#address = DEFAULT_SERVER_IP
	#var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_client(address, PORT)
	#if error:
		#return error
	#multiplayer.multiplayer_peer = peer


# Called from Host Game button
func create_game(name = "", bugindex = 0):
	player_info["bugindex"] = bugindex
	player_info["name"] = name
	
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 10)
	is_host = true
	#print("Creating Game")
	#var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_server(PORT, MAX_CONNECTIONS)
	#if error:
		#return error
	#multiplayer.multiplayer_peer = peer
#
	#player_info["bugindex"] = bugindex
	#player_info["name"] = name
	#players[1] = player_info
	#player_connected.emit(1, player_info)

func remove_multiplayer_peer():
	print("REMOVE MULTIPLAYER PEER")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	
# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("authority", "call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		print("Server recieved player loaded")
		players_loaded += 1
		print("Players loaded: ", str(players_loaded))
		if players_loaded == players.size() && Globals.game_starting:
			print("All ", str(players.size()), " Players Loaded")
			GameController.start_game.rpc()

# Every peer will call this when they have readied up from lobby.
@rpc("any_peer", "call_local", "reliable")
func player_ready(ready_up: bool):
	if multiplayer.is_server():
		players_ready += (1 if ready_up else -1)
		print("Players Ready After: ", str(players_ready))
		if players.size() > 1 and players_ready == players.size():
			print("\n***********************\n    STARTING GAME\n")
			GameController.transition_to_level.rpc()


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	print("ON PLAYER CONNECTED: ", id, player_info, multiplayer.get_unique_id())
	print()
	_register_player.rpc_id(id, player_info)


@rpc("any_peer", "call_local", "reliable")
func _register_player(new_player_info):
	print("register player ", new_player_info)
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


func _on_player_disconnected(id):
	print("ON PLAYER DISCONNECTED")
	players.erase(id)
	player_disconnected.emit(id)

#func _on_connected_ok():
	#print("\nON CONNECTED OK, CONNECTED TO SERVER!\n")
	#var peer_id = multiplayer.get_unique_id()
	#players[peer_id] = player_info.duplicate()
	#player_connected.emit(peer_id, players[peer_id])


func _on_connected_fail():
	print("ON CONNECTED FAIL")
	remove_multiplayer_peer()


func _on_server_disconnected():
	print("ON SERVER DISCONNECTED")
	remove_multiplayer_peer()
	players.clear()
	server_disconnected.emit()

@rpc("any_peer", "reliable")
func report_level_loaded():
	if !multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	loaded_peers[id] = true
	peer_level_loaded.emit(id)
