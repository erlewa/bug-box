extends CharacterBody3D
class_name Player

# https://ezcha.net/news/5-7-26-multiplayer-in-godot-is-easier-than-you-think

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var peer_id: int = 1 # The peer that controls this player
var local: bool = true # If this player belongs to the local peer


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

func _physics_process(delta: float) -> void:
	if !(local):
		return
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var jump = Input.is_action_just_pressed("ui_accept")
	process_physics.rpc_id(1, delta, input_dir, jump)


@rpc("any_peer", "call_local", "reliable", 0)
func process_physics(delta, input_dir, jump):
	if !(multiplayer.is_server()):
		return
	if peer_id != multiplayer.get_remote_sender_id():
		return
	
	_update_camera(delta)

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3

func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input :
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
		print(Vector2(_rotation_input,_tilt_input))

@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var MOUSE_SENSITIVITY : float = 0.5 

func _update_camera(delta):
	
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
