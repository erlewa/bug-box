# State used when the player is in a match
extends State

@onready var ready_button: Button = %ReadyButton

func enter() -> void:
	ready_button.visible = false
