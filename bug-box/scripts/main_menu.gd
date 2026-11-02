extends Control

signal load_level(Resource)

@onready var ip_input: TextEdit = %IPInput

# Bug index
var bugindex = 0

func _on_join_pressed() -> void:
	MultiplayerController.join_game(ip_input.text, bugindex)
	emit_signal("load_level", Globals.LOBBY_LEVEL)


func _on_host_pressed() -> void:
	MultiplayerController.create_game(bugindex)
	print("Emitting load_level(LOBBY)")
	emit_signal("load_level", Globals.LOBBY_LEVEL)


func _on_bug_selected(index: int) -> void:
	bugindex = index
	print("Bug ", bugindex, " selected")
