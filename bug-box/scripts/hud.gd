extends Control

signal ready_up

func _on_ready_button_pressed() -> void:
	# TO-DO(erlewa): Make button change color when pressed
	emit_signal("ready_up")
