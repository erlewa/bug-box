extends Control

signal ready_up

var _role_label: Label
var _result_label: Label
var _feed: VBoxContainer
var _hiders_label: Label

func _ready() -> void:
	_build_labels()
	_build_killfeed()
	
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
	
func _build_killfeed() -> void:
	_feed = VBoxContainer.new()
	_feed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_feed.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_feed.offset_top = 12
	_feed.offset_right = -12
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_feed)

	_hiders_label = Label.new()
	_hiders_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hiders_label.offset_left = 12
	_hiders_label.offset_top = 12
	_hiders_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hiders_label.add_theme_font_size_override("font_size", 28)
	_hiders_label.visible = false
	add_child(_hiders_label)

func set_hiders_left(n: int) -> void:
	if n < 0:
		_hiders_label.visible = false
		return
	_hiders_label.visible = true
	_hiders_label.text = "HIDERS LEFT: " + str(n)

func on_player_tagged(tagger_id: int, tagged_id: int, hiders_left: int) -> void:
	var text = "%s tagged %s  (%d left)" % [
		GameController.display_name(tagger_id),
		GameController.display_name(tagged_id),
		hiders_left]
	add_feed_entry(text)

func add_feed_entry(text: String) -> void:
	var entry = Label.new()
	entry.text = text
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry.add_theme_font_size_override("font_size", 22)
	entry.add_theme_color_override("font_color", Color.RED)
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.add_child(entry)

	while _feed.get_child_count() > 5:
		var old = _feed.get_child(0)
		_feed.remove_child(old)
		old.queue_free()

# remove after a bit
	get_tree().create_timer(6.0).timeout.connect(func():
		if is_instance_valid(entry):
			entry.queue_free())
