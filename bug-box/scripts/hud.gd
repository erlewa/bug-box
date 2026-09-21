extends Control

signal ready_up

@onready var ready_button: Button = %ReadyButton

var ready_state: bool = false
var base_style = StyleBoxFlat.new()
var ready_style = StyleBoxFlat.new()


func _ready() -> void:
	base_style.bg_color = Color(0.169, 0.239, 0.255, 1.0)
	ready_style.bg_color = Color(0.0, 0.71, 0.0, 1.0)


func _on_ready_button_pressed() -> void:
	# TO-DO(erlewa): Make button change color when pressed
	emit_signal("ready_up")
	ready_state = !ready_state
	ready_button.add_theme_stylebox_override("normal", base_style if !ready else ready_style)

func hide_ready_button():
	print("Hiding ready button")
	ready_button.visible = false
