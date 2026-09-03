extends Control

const LOBBY_LEVEL = preload("uid://b5kvgaua51lq4")
@onready var ip_input: TextEdit = %IPInput

func load_lobby():
	get_tree().change_scene_to_packed(LOBBY_LEVEL)

func _on_join_pressed() -> void:
	Lobby.join_game(ip_input.text)
	load_lobby()


func _on_host_pressed() -> void:
	Lobby.create_game()
	load_lobby()
