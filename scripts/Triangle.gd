extends Node2D

var _new_scale: Vector2 = Vector2.ONE

func on_input_force_applied(force: Vector2) -> void:
	# print(force.length())
	# lerp(0.0, 10.0, clamp())
	# scale = 
	var scaled_force = force.length() * 0.05

	var unit_force = force.normalized()
	var angle = atan2(unit_force.y, unit_force.x)

	var new_scale = Vector2(clamp(scaled_force, 0.0, 2.0), 1.0)
	set_scale(new_scale)
	# set_rotation(angle)
	set_global_rotation(angle)

func on_input_torque_applied(torque: float) -> void:
	# print(abs(torque))
	# lerp(0.0, 10.0, clamp())
	# scale = 
	var scaled_torque = abs(torque) * 0.01

	# var unit_force = 
	# var angle = atan2(unit_force.y, unit_force.x)

	var new_scale = Vector2(clamp(scaled_torque, 0.0, 1.0), 1.0)
	set_scale(new_scale)
	set_rotation(0 if torque > 0 else PI)

