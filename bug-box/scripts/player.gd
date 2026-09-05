extends CharacterBody3D
class_name Player

# https://ezcha.net/news/5-7-26-multiplayer-in-godot-is-easier-than-you-think
@onready var ray_cast_3d: RayCast3D = %RayCast3D
@onready var basis_label: Label = %BasisLabel
@onready var physics_label: Label = %PhysicsLabel
@onready var debug: Control = %Debug

const SPEED = 5.0
const JUMP_VELOCITY = 4.5


@export var peer_id: int = 1 # The peer that controls this player
var local: bool = true # If this player belongs to the local peer
@export var gravity_dir: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var gravity_mag = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree() -> void:
	# Set node authority
	
	print("IN _enter_tree():\n\tPlayer peer_id: " + str(peer_id) 
	+ "\n\tMultiplayer Unique id: " + str(multiplayer.get_unique_id()) 
	+ "\n\tLocal: " + str(local))

func _ready() -> void:
	print("IN _ready():\n\tPlayer peer_id: " + str(peer_id) 
	+ "\n\tMultiplayer Unique id: " + str(multiplayer.get_unique_id()) 
	+ "\n\tLocal: " + str(local)
	+ "\n**********\n")
	local = (peer_id == multiplayer.get_unique_id())
	if (local):
		# Activate the camera if local
		$Camera3D.make_current()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	basis_label.text = (
		"Basis: " + str(global_transform.basis) +
		"\nGravity Dir: " + str(gravity_dir)
	)
	if Input.is_action_just_pressed("debug_mode"):
		debug.visible = !debug.visible
	

func _physics_process(delta: float) -> void:
	if !(local):
		return
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var jump = Input.is_action_just_pressed("ui_accept")
	process_physics.rpc_id(1, delta, input_dir, jump)
	
	if 	ray_cast_3d.is_colliding():
		change_gravity.rpc_id(1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("ESCAPED")

func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input :
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY



@rpc("any_peer", "call_local", "reliable", 0)
func change_gravity():
	if !(multiplayer.is_server()):
		return
	if peer_id != multiplayer.get_remote_sender_id():
		return
	if !(ray_cast_3d.is_colliding()):
		return
	
	gravity_dir = ray_cast_3d.get_collision_normal().normalized() * -1
	velocity = Vector3(0.0, 0.0, 0.0)
	vel_speed = Vector3(SPEED, SPEED, SPEED)
	
	var obj = ray_cast_3d.get_collider()
	ray_cast_3d.enabled = false
	
	var tween = create_tween()
	var start_basis = global_transform.basis
	var target_basis = obj.global_transform.basis
	
	tween.tween_method(
		func(weight: float):
			global_transform.basis = start_basis.slerp(target_basis, weight),
		0.0, 1.0, 0.5
	)
	tween.tween_callback(
		func():
			up_direction = global_transform.basis.y
			apply_floor_snap()
			await get_tree().create_timer(0.5).timeout
			ray_cast_3d.enabled = true
	)

var vel_speed = Vector3(SPEED, 0, SPEED)
@rpc("any_peer", "call_local", "reliable", 0)
func process_physics(delta, input_dir, jump):
	if !(multiplayer.is_server()):
		return
	if peer_id != multiplayer.get_remote_sender_id():
		return
	
	_update_camera(delta)
	
	# Handle jump.
	if jump and is_on_floor():
		vel_speed = abs(global_transform.basis.x * SPEED) + global_transform.basis.y * JUMP_VELOCITY + abs(global_transform.basis.z * SPEED)
		
	## Add gravity.
	if not is_on_floor():
		vel_speed += gravity_dir * gravity_mag * delta
		
	var direction := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() + global_transform.basis.y
	
	physics_label.text = (
		"Input_dir: " + str(input_dir) +
		"\nDirection: " + str(direction) +
		"\nVel Speed: " + str(vel_speed) + 
		"\nD*VS (Velocity): " + str(direction * vel_speed) +
		"\nOn Ground: " + str(is_on_floor()) +
		"\nUp Direction: " + str(up_direction)
	)
	
	if direction:
		velocity = direction * vel_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	move_and_slide()


var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3


@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var MOUSE_SENSITIVITY : float = 0.5 

func _update_camera(delta):
	
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y = _rotation_input * delta

	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	# TO-DO(erlewa): Need to respect pre-existing alterations to global_transform.basis
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.y, _mouse_rotation.y)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
