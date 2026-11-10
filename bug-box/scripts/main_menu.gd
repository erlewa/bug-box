extends Control

signal load_level(Resource)

@onready var ip_input: TextEdit = %IPInput
@onready var name_input: TextEdit = %NameInput
@onready var join_input_label: Label = $JoinInputLabel
@onready var mp_type_selector: CheckButton = $SteamSelector

# Bug index
var bugindex = 0
var isSteam = false

func _ready():
	mp_type_selector.disabled = !Globals.steam_initialized
	

func _on_join_pressed() -> void:
	MultiplayerController.join_game(isSteam, ip_input.text, name_input.text, bugindex)
	emit_signal("load_level", Globals.LOBBY_LEVEL)


func _on_host_pressed() -> void:
	MultiplayerController.create_game(isSteam, name_input.text, bugindex)
	print("Emitting load_level(LOBBY)")
	emit_signal("load_level", Globals.LOBBY_LEVEL)


func _on_bug_selected(index: int) -> void:
	bugindex = index
	print("Bug ", bugindex, " selected")


func _on_steam_selector_toggled(toggled_on: bool) -> void:
	print("Steam selected ", toggled_on)
	join_input_label.text = "Lobby ID" if toggled_on else "Host IP"
	isSteam = toggled_on
