extends Control

signal ready_up

@onready var ready_button: Button = %ReadyButton

func _on_ready_button_pressed() -> void:
	emit_signal("ready_up")


func hide_ready_button():
	print("Hiding ready button")
	ready_button.visible = false
