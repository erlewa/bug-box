extends Control

signal ready_up

var _role_label: Label
var _result_label: Label

func _ready() -> void:
	_build_labels()
	
func _build_labels() -> void:
	_role_label = Label.new()
	_role_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_role_label.offset_top = 12
	_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_role_label.add_theme_font_size_override("font_size", 32)
	_role_label.visible = false
	add_child(_role_label)

	_result_label = Label.new()
	_result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_label.add_theme_font_size_override("font_size", 64)
	_result_label.visible = false
	add_child(_result_label)

func set_role(role: String) -> void:
	if role == "none":
		_role_label.visible = false
		return
	_role_label.visible = true
	_role_label.text = "ROLE: " + role.to_upper()
	_role_label.add_theme_color_override(
		"font_color", Color.RED if role == "seeker" else Color.LIME_GREEN)

func show_result(winning_role: String) -> void:
	_result_label.text = winning_role.to_upper() + " WINS!"
	_result_label.visible = true
