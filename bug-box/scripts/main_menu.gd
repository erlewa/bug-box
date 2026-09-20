extends Control

signal load_level(Resource)

@onready var ip_input: TextEdit = %IPInput

func _on_join_pressed() -> void:
	Lobby.join_game(ip_input.text)
	emit_signal("load_level", Globals.LOBBY_LEVEL)

func _on_host_pressed() -> void:
	Lobby.create_game()
	print("Emitting load_level(LOBBY)")
	emit_signal("load_level", Globals.LOBBY_LEVEL)
