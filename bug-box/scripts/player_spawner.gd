extends MultiplayerSpawner
const PLAYER = preload("uid://cad3tk841gia0")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		Lobby.player_connected.connect(_on_player_connected)
		var player = PLAYER.instantiate()
		add_child(player)

func _on_player_connected(peer_id, player_info):
	print(player_info)
	if !(multiplayer.is_server()):
		return
	var player = PLAYER.instantiate()
	player.peer_id = peer_id
	add_child(player, true)
