extends MultiplayerSpawner
const PLAYER = preload("uid://cad3tk841gia0")
const SPACING := 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !multiplayer.is_server():
		# Tell the server this client's level is loaded and ready for spawns
		if Globals.game_starting:
			MultiplayerController.report_level_loaded.rpc_id(1)
		return
	MultiplayerController.player_connected.connect(spawn_player)
	MultiplayerController.peer_level_loaded.connect(_on_peer_level_loaded)
	spawn_players()

func spawn_player(peer_id, player_info):
	print(str(peer_id), ": ", player_info)
	if !(multiplayer.is_server()):
		return
	# During the lobby -> level transition, wait for that client to report in
	if Globals.game_starting and peer_id != 1 \
			and not MultiplayerController.loaded_peers.has(peer_id):
		return
	var player = PLAYER.instantiate()
	player.peer_id = peer_id
	player.position = _spawn_position(peer_id, player.position)
	add_child(player, true)

func _on_peer_level_loaded(id) -> void:
	if MultiplayerController.players.has(id):
		spawn_player(id, MultiplayerController.players[id])

# Spawn all currently connected players
func spawn_players():
	if !(multiplayer.is_server()):
		return
	for id in MultiplayerController.players:
		spawn_player(id, MultiplayerController.players[id])
		
func _spawn_position(peer_id: int, default_pos: Vector3) -> Vector3:
	var ids = MultiplayerController.players.keys()
	var index = maxi(ids.find(peer_id), 0)
	
	var n = ids.size()
	if n < 2:
		return default_pos
	var radius = SPACING / (2.0 * sin(PI / n))
	var angle = TAU * index / n
	return default_pos + Vector3(cos(angle), 0.0, sin(angle)) * radius
