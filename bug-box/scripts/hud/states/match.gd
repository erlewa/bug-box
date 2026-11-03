# State used when the player is in a match
extends State

@onready var ready_button: Button = %ReadyButton
@onready var hider_timer: Label = %HiderTimer

func enter() -> void:
	ready_button.visible = false
	hider_timer.visible = true

func process_update(_delta: float) -> void:
	var time_left = ceili(GameController.hider_win_timer.time_left)
	hider_timer.text = str(time_left / 60) + ":" + str(time_left % 60).pad_zeros(2)
