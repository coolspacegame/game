
extends RigidBody2D

signal position_updated(position: Vector2)

func on_character_position_updated(pos: Vector2) -> void:
	const spring_constant := 20.0
	const damping_constant := 2.0
	var spring_force := -spring_constant * (global_position - pos) - damping_constant * linear_velocity
	apply_central_force(spring_force)

func on_character_rotation_updated(rot: float) -> void:
	global_rotation = rot

func _physics_process(delta: float) -> void:
	emit_signal("position_updated", position)
