extends MultiplayerSpawner
const PLAYER = preload("uid://cad3tk841gia0")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		Lobby.player_connected.connect(spawn_player)
		spawn_players()

# Spawn a single player
func spawn_player(peer_id, player_info):
	print(str(peer_id), ": ", player_info)
	if !(multiplayer.is_server()):
		return
	var player = PLAYER.instantiate()
	player.peer_id = peer_id
	player.role = player_info.get("role", "hider")
	add_child(player, true)

# Spawn all currently connected players
func spawn_players():
	if !(multiplayer.is_server()):
		return

	for id in Lobby.players:
		spawn_player(id, Lobby.players[id])
