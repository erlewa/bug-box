# State used when the player is in a match
extends State

@onready var ready_button: Button = %ReadyButton
@onready var change_bug_button: Button = %ChangeBugButton

func enter() -> void:
	ready_button.visible = false
	change_bug_button.visible = false
