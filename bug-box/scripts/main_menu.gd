extends Control
const LOBBY = preload("uid://13pjbvkins6l")
@onready var ip_input: TextEdit = %IPInput

func load_lobby():
	get_tree().change_scene_to_packed(LOBBY)

func _on_join_pressed() -> void:
	Lobby.join_game(ip_input.text)
	load_lobby()


func _on_host_pressed() -> void:
	Lobby.create_game()
	load_lobby()
