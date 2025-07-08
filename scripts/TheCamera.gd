
extends RigidBody2D

signal position_updated(position: Vector2)

func on_character_position_updated(pos: Vector2) -> void:
	const spring_constant := 100.0
	const damping_constant := 20.0
	var spring_force := -spring_constant * (global_position - pos) - damping_constant * linear_velocity
	apply_central_force(spring_force)

func on_character_rotation_updated(rot: float) -> void:
	const spring_constant := 10000.0
	const damping_constant := 800.0

	var rd := global_rotation - rot
	if rd > PI:
		rd = rd - 2 * PI
	if rd < -PI:
		rd = rd + 2 * PI

	var spring_torque := -spring_constant * rd - damping_constant * angular_velocity
	apply_torque(spring_torque)
	# global_rotation = rot

func _physics_process(delta: float) -> void:
	emit_signal("position_updated", position)
