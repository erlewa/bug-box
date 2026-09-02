extends Control

@onready var ip_input: TextEdit = %IPInput

func _on_join_pressed() -> void:
	Lobby.join_game(ip_input.text)


func _on_host_pressed() -> void:
	Lobby.create_game()
