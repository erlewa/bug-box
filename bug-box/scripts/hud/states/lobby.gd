# HUD state used when in the lobby level
extends State

@onready var ready_button: Button = %ReadyButton

func enter() -> void:
	ready_button.visible = true
	GameController.game_start.connect(transition_to_match)
	ready_button.connect("pressed", _on_ready_button_pressed)

func transition_to_match() -> void:
	emit_signal("transition", self, "match")

func _on_ready_button_pressed() -> void:
	Globals.emit_signal("ready_up")
