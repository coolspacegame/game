extends RigidBody2D

signal input_torque_applied(torque: float)
signal input_force_applied(force: Vector2)
signal position_updated(position: Vector2)
signal rotation_updated(rotation: float)

var _input_dir_state: Vector2i = Vector2i.ZERO
var nearby_asteroid_bodies: Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_W:
			_input_dir_state += Vector2i.UP * (1 if event.pressed else -1)
		elif event.keycode == KEY_A:
			_input_dir_state += Vector2i.LEFT * (1 if event.pressed else -1)
		elif event.keycode == KEY_D:
			_input_dir_state += Vector2i.RIGHT * (1 if event.pressed else -1)
		_input_dir_state = Vector2i(
			clamp(_input_dir_state.x, -1, 1),
			clamp(_input_dir_state.y, -1, 1)
		)

func _on_asteroid_approaching(asteroid: RigidBody2D):
	nearby_asteroid_bodies[asteroid.get_rid()] = asteroid

func _on_asteroid_exiting(asteroid: RigidBody2D):
	nearby_asteroid_bodies.erase(asteroid.get_rid())

func _physics_process(_delta: float) -> void:
	const gravitational_constant := 200.0

	var max_force = Vector2.ZERO

	for body in nearby_asteroid_bodies.values():
		var asteroid_mass = body.mass
		var character_mass = mass
		var radius = (body.global_position - global_position).length()
		var force_magnitude = gravitational_constant * asteroid_mass * character_mass / (radius * radius)
		var force_dir = (body.global_position - global_position).normalized()
		var force = force_magnitude * force_dir

		if force_magnitude > max_force.length():
			max_force = force

	var gravity_force = max_force

	var v1 = gravity_force.normalized()
	var v2 = transform.basis_xform(Vector2.DOWN).normalized()

	var a1 = atan2(v1.y, v1.x)
	var a2 = atan2(v2.y, v2.x)
	var ad = a2 - a1

	if ad > PI:
		ad = ad - 2*PI
	elif ad < -PI:
		ad = ad + 2*PI


	if abs(_input_dir_state.x) < 0.1:
		apply_torque((-1000.0 * ad  - 300.0 * angular_velocity) * gravity_force.length())

	if abs(_input_dir_state.y) < 0.1:
		apply_central_force(gravity_force)

	var input_force := 20000.0 * _input_dir_state.y * Vector2.UP
	input_force = transform.basis_xform(input_force).rotated(PI)
	apply_central_force(input_force)

	var input_torque := 100000.0 * _input_dir_state.x
	apply_torque(input_torque)

	emit_signal("input_torque_applied", input_torque)
	emit_signal("input_force_applied", input_force)
	emit_signal("position_updated", global_position)
	emit_signal("rotation_updated", global_rotation)
