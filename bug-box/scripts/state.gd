class_name State
extends Node
# This implementation is based heavily on work done in this video:
#       https://www.youtube.com/watch?v=ow_Lum-Agbs

@warning_ignore("unused_signal")
signal transition(state, new_state_name)


# Called when a state is first entered
func enter() -> void:
	pass


# Called when a state is exited
func exit() -> void:
	pass


# Called from physics_process(delta: float)
func physics_update(_delta: float) -> void:
	pass


# Called from process(delta: float)
func process_update(_delta: float) -> void:
	pass
