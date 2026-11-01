extends Node3D
class_name Level

@onready var player_spawn_path: Path3D = %PlayerSpawnPath

# Returns a random position on the Path3D used for spawning players
func get_spawn_location():
	var curve = player_spawn_path.curve
	var length = curve.get_baked_length()
	var curve_pos = randf() * length
	var local_pos = curve.sample_baked(curve_pos)
	return player_spawn_path.to_global(local_pos)
