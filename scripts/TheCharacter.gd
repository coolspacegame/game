extends RigidBody2D

signal input_torque_applied(torque: float)
signal input_force_applied(force: Vector2)
signal position_updated(position: Vector2)
signal rotation_updated(rotation: float)

var _mouse_update: Vector2 = Vector2.ZERO
var _input_dir_state: Vector2i = Vector2i.ZERO
var _mouse_button_pressed: bool = false
var touch_start_position: Vector2 = Vector2.ZERO
var touch_was_pressed: bool = false

var nearby_asteroid_bodies: Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _mouse_button_pressed:
			_mouse_update += event.relative
	elif event is InputEventMouseButton:
		_mouse_update = Vector2.ZERO
		_mouse_button_pressed = event.pressed
	elif event is InputEventKey:
		if event.keycode == KEY_W:
			_input_dir_state += Vector2i.UP * (1 if event.pressed else -1)
		elif event.keycode == KEY_A:
			_input_dir_state += Vector2i.LEFT * (1 if event.pressed else -1)
		# elif event.keycode == KEY_S:
		# 	_input_dir_state += Vector2i.DOWN * (1 if event.pressed else -1)
		elif event.keycode == KEY_D:
			_input_dir_state += Vector2i.RIGHT * (1 if event.pressed else -1)
		_input_dir_state = Vector2i(
			clamp(_input_dir_state.x, -1, 1),
			clamp(_input_dir_state.y, -1, 1)
		)
	elif event is InputEventScreenDrag:
		if touch_was_pressed:
			var p = event.position - touch_start_position - Vector2(get_viewport().size) / 2 
			var new_state = Vector2i(0, 0)
			if abs(p.x) > 100:
				new_state += Vector2i(1 if p.x > 0 else -1, 0)
			if abs(p.y) > 100:
				new_state += Vector2i(0, 1 if p.y > 0 else -1)
			_input_dir_state = new_state
	elif event is InputEventScreenTouch:
		if event.pressed:
			if touch_was_pressed:
				pass
			else:
				touch_start_position = event.position - Vector2(get_viewport().size) / 2 
				touch_was_pressed = true
		else:
			touch_was_pressed = false
			_input_dir_state = Vector2i(0,0)

func _on_asteroid_body_created(body: RigidBody2D):
	# nearby_asteroid_bodies.append(body)
	pass


# func _on_gravity_area_entered(area: Area2D):
# 	if is_ancestor_of(area):
# 		pass

# func _ready() -> void:
# 	nearby_asteroid_bodies = {}

func _process(delta: float) -> void:
	pass

func _on_asteroid_approaching(asteroid: RigidBody2D):
	nearby_asteroid_bodies[asteroid.get_rid()] = asteroid
	# print("{0} asteroid entering".format([asteroid.get_rid()]))

func _on_asteroid_exiting(asteroid: RigidBody2D):
	nearby_asteroid_bodies.erase(asteroid.get_rid())
	# print("{0} asteroid leaving".format([asteroid.get_rid()]))

func _physics_process(delta: float) -> void:
	# const meteor_mass := 5000000.0
	# const character_mass := 1.0
	const gravitational_constant := 200.0
	# var bodies = $Area2D.get_overlapping_bodies() as Array[Node2D]

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

	# var cs = $CollisionShape2D as CollisionShape2D
	# var boundary_rect = cs.shape.get_rect()
	var gravity_force = max_force

	# apply_torque(-100.0 * max_force.normalized().cross(transform.basis_xform(Vector2.DOWN)) - 0.7 * angular_velocity)
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

	# apply_torque(-1000.0 * acos(v1.dot(v2) / (v1.length() * v2.length())))


	if abs(_input_dir_state.y) < 0.1:
		apply_central_force(gravity_force)
	# apply_force(max_force, boundary_rect.get_support(Vector2.DOWN))



	var input_force := 20000.0 * _input_dir_state.y * Vector2.UP
	input_force = transform.basis_xform(input_force).rotated(PI)
	apply_central_force(input_force)

	var input_torque := 100000.0 * _input_dir_state.x
	apply_torque(input_torque)

	emit_signal("input_torque_applied", input_torque)
	emit_signal("input_force_applied", input_force)
	emit_signal("position_updated", global_position)
	emit_signal("rotation_updated", global_rotation)


func _on_the_generator_asteroid_approaching_character(asteroid:RigidBody2D) -> void:
	pass # Replace with function body.
