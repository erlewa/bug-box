extends CharacterBody3D
class_name Player

# https://ezcha.net/news/5-7-26-multiplayer-in-godot-is-easier-than-you-think
@onready var ray_cast_3d: RayCast3D = %RayCast3D
@onready var basis_label: Label = %BasisLabel
@onready var physics_label: Label = %PhysicsLabel
@onready var player_label: Label = %PlayerLabel
@onready var debug: Control = %Debug
@onready var gravity_label: Label = %GravityLabel

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


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var peer_id: int = 1 # The peer that controls this player
@export var role: String = "hider"
var local: bool = true # If this player belongs to the local peer
@export var gravity_dir: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var gravity_mag = ProjectSettings.get_setting("physics/3d/default_gravity")

var ready_up: bool = false

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
	if Input.is_action_just_pressed("debug_mode") and local:
		debug.visible = !debug.visible
		
	player_label.text = (
		"Name: " + str(self.name) +
		"\nRole: " + str(self.role)
	)
	
func _physics_process(delta: float) -> void:
	if !(local):
		return
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var jump = Input.is_action_just_pressed("jump")
	process_physics.rpc_id(1, delta, input_dir, jump)
	
	if 	ray_cast_3d.is_colliding():
		change_gravity.rpc_id(1)

func _input(event: InputEvent) -> void:
	if !(local):
		return
	if event.is_action_pressed("escape"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if !(local):
		return
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input :
		var ri = -event.relative.x * MOUSE_SENSITIVITY
		var ti = -event.relative.y * MOUSE_SENSITIVITY
		update_camera_input.rpc_id(1, ri, ti)
		

@rpc("any_peer", "call_local", "reliable")
func update_camera_input(rotation_input, tilt_input):
	_rotation_input = rotation_input
	_tilt_input = tilt_input
	
@rpc("any_peer", "call_local", "reliable", 0)
func change_gravity():
	if !(multiplayer.is_server()):
		return
	if peer_id != multiplayer.get_remote_sender_id():
		return
	if !(ray_cast_3d.is_colliding()):
		return
	
	velocity = Vector3(0.0, 0.0, 0.0)
	
	var obj = ray_cast_3d.get_collider()
	var norm = ray_cast_3d.get_collision_normal()
	ray_cast_3d.enabled = false
	
	#var surface_forward = global_transform.basis.z.cross(norm).normalized() # Always want + so player orientation doesnt effect rotation axis
	#var rot_axis = surface_forward.cross(norm).normalized()
	
	var g = global_transform.basis
	var proj_x = (g.x - ((g.x.dot(norm) / pow(norm.length(), 2)) * norm)).normalized()
	var target_basis = global_transform.basis.rotated(proj_x, global_transform.basis.y.angle_to(norm))
	
	gravity_label.text = (
		"Starting Basis: " + str(global_transform.basis) +
		"\nRotation: " + str(rad_to_deg(global_transform.basis.y.angle_to(norm))) +
		"\nNormal: " + str(norm) +
		"\nProjected X: " + str(proj_x) +
		#"\nSurface Forward: " + str(surface_forward) +
		#"\nRotation Axis: " + str(rot_axis) +
		"\nNormal Target: " + str(target_basis) +
		"\nObject Basis: " + str(obj.global_transform.basis)
	)
	
	
	# TO-DO(erlewa): Rotation should be based on surface normal not basis,
	# 		to enable more complex surface walking
	var tween = create_tween()
	var start_basis = global_transform.basis
	
	tween.tween_method(
		func(weight: float):
			global_transform.basis = start_basis.slerp(target_basis.orthonormalized(), weight),
		0.0, 1.0, 0.25
	)
	tween.tween_callback(
		func():
			up_direction = global_transform.basis.y
			gravity_dir = -up_direction
			
			vel_speed = abs(global_transform.basis.x * SPEED) + global_transform.basis.y * 0 + abs(global_transform.basis.z * SPEED)
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
		
	var direction: Vector3 = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() + abs(global_transform.basis.y)
	
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
	
	physics_label.text = (
		"Input_dir: " + str(input_dir) +
		"\nDirection: " + str(direction) +
		"\nVel Speed: " + str(vel_speed) + 
		"\nD*VS (Velocity): " + str(direction * vel_speed) +
		"\nOn Ground: " + str(is_on_floor()) +
		"\nUp Direction: " + str(up_direction)
	)
	
	move_and_slide()

func _update_camera(delta):
	if !(multiplayer.is_server()):
		return
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

func _on_hud_ready_up() -> void:
	print("READY UP!")
	ready_up = !ready_up
	print("Ready State: ", str(ready_up))
	Lobby.player_ready.rpc_id(1, ready_up)
