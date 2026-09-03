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
