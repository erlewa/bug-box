extends Node3D

var transition_duration: float = 0.3 # seconds
var target_up = Vector3.UP
var current_up = Vector3.UP
var player
var tween

func _ready() -> void:
	player = get_parent() as CharacterBody3D

func _physics_process(_delta: float) -> void:
	var new_target = Vector3.UP
	if player.is_on_wall():
		new_target = player.get_wall_normal()
	elif player.is_on_floor() and target_up != Vector3.UP:
		new_target = target_up
	
	if new_target != target_up:
		target_up = new_target
		start_up_transition(target_up)

	player.up_direction = current_up
	align_camera_to_up(current_up)

func start_up_transition(to_up: Vector3) -> void:
	if tween and tween.is_running():
		tween.kill() # stop transition if no longer transitioning

	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "current_up", to_up, transition_duration)

func align_camera_to_up(new_up: Vector3) -> void:
	var current_forward = -global_transform.basis.z
	var target_forward = (current_forward - current_forward.project(new_up)).normalized()
	global_transform = global_transform.looking_at(global_transform.origin + target_forward, new_up)
