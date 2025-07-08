extends RigidBody2D

signal booster_torque_applied(torque: float)
signal booster_force_applied(force: Vector2)
signal position_updated(position: Vector2)
signal rotation_updated(rotation: float)
signal boosters_enabled_updated(enabled: bool)

@export var physics_shape: CollisionShape2D

var _input_force: Vector2 = Vector2.ZERO
var _input_torque: float = 0.0
var _input_dir: Vector2i = Vector2i.ZERO
var _boosters_enabled: bool = true
var _nearby_asteroid_bodies: Dictionary = {}
const GRAVITATIONAL_CONSTANT := 200.0


func _on_asteroid_body_created(body: RigidBody2D):
	pass


func _process(delta: float) -> void:
	boosters_enabled_updated.emit(_boosters_enabled)

func _on_asteroid_approaching(asteroid: RigidBody2D):
	_nearby_asteroid_bodies[asteroid.get_rid()] = asteroid

func _on_asteroid_exiting(asteroid: RigidBody2D):
	_nearby_asteroid_bodies.erase(asteroid.get_rid())


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_boosters"):
		_boosters_enabled = !_boosters_enabled;

	var max_force = Vector2.ZERO
	for body in _nearby_asteroid_bodies.values():
		var asteroid_mass = body.mass
		var character_mass = mass
		var radius = (body.global_position - global_position).length()
		var force_magnitude = GRAVITATIONAL_CONSTANT * asteroid_mass * character_mass / (radius * radius)
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

	var debounce_filter_size := 2

	if Input.is_action_pressed("move_right"):
		_input_dir.x = clamp(_input_dir.x + 1, -debounce_filter_size, debounce_filter_size)
	elif Input.is_action_pressed("move_left"):
		_input_dir.x = clamp(_input_dir.x - 1, -debounce_filter_size, debounce_filter_size)
	else:
		_input_dir.x -= sign(_input_dir.x)

	if Input.is_action_pressed("move_up"):
		_input_dir.y = clamp(_input_dir.y + 1, 0, debounce_filter_size)
	else:
		_input_dir.y -= sign(_input_dir.y)

	var booster_force = Vector2.ZERO
	var booster_torque = 0.0

	if _boosters_enabled:
		_input_force = 20000.0 * _input_dir.y * Vector2.DOWN
		_input_force = transform.basis_xform(_input_force).rotated(PI)
		_input_torque = 20000.0 * _input_dir.x

		booster_force = _input_force
		booster_torque = _input_torque
	else:

		var cast_from = global_position
		var cast_to = global_position + gravity_force.normalized() * physics_shape.shape.get_rect().size.y * 0.6
		var casting_mask = collision_mask

		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(cast_from, cast_to, casting_mask)

		var collision_result = space_state.intersect_ray(query)

		if collision_result:
			var surface_normal = collision_result.normal as Vector2
			var surface_tangent := surface_normal.rotated(PI / 2)
			_input_force = surface_tangent * _input_dir.x * 20000.0
		else:
			_input_force = Vector2.ZERO

		_input_torque = 0.0


	booster_force_applied.emit(booster_force)
	booster_torque_applied.emit(booster_torque)

	if not _boosters_enabled:
		apply_torque((-1000.0 * ad  - 300.0 * angular_velocity) * gravity_force.length())

	apply_central_force(gravity_force)
	apply_central_force(_input_force)
	apply_torque(_input_torque)

	position_updated.emit(global_position)
	rotation_updated.emit(global_rotation)
