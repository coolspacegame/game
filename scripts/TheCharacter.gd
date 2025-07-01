extends RigidBody2D

signal input_torque_applied(torque: float)
signal input_force_applied(force: Vector2)
signal position_updated(position: Vector2)
signal rotation_updated(rotation: float)

var _mouse_update: Vector2 = Vector2.ZERO
var _input_dir_state: Vector2i = Vector2i.ZERO
var _mouse_button_pressed: bool = false

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
		elif event.keycode == KEY_S:
			_input_dir_state += Vector2i.DOWN * (1 if event.pressed else -1)
		elif event.keycode == KEY_D:
			_input_dir_state += Vector2i.RIGHT * (1 if event.pressed else -1)
		_input_dir_state = Vector2i(
			clamp(_input_dir_state.x, -1, 1),
			clamp(_input_dir_state.y, -1, 1)
		)
		
	elif event is InputEventScreenTouch:
		if event.pressed:
			var p = event.position - get_viewport().size / 2 
			var new_state = Vector2i(0, 0)
			if abs(p.x) > 0.1:
				new_state += Vector2i(1 if p.x > 0 else -1, 0)
			if abs(p.y) > 0.1:			
				new_state += Vector2i(0, 1 if p.y > 0 else -1)
			_input_dir_state = new_state
		else:
			_input_dir_state = Vector2i(0,0)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# const meteor_mass := 5000000.0
	# const character_mass := 1.0
	# const gravitational_constant := 10.0

	# var force_dir := -1.0 * global_position.normalized()
	# var radius := global_position.length()
	# var force_magnitude := gravitational_constant * meteor_mass * character_mass / (radius * radius)
	# apply_central_force(force_magnitude * force_dir)
	# var input_force := 1.0 * _mouse_update

	var input_force := 50000.0 * _input_dir_state.y * Vector2.UP
	input_force = transform.basis_xform(input_force).rotated(PI)
	apply_central_force(input_force)

	var input_torque := 200000.0 * _input_dir_state.x
	apply_torque(input_torque)

	emit_signal("input_torque_applied", input_torque)
	emit_signal("input_force_applied", input_force)
	emit_signal("position_updated", global_position)
	emit_signal("rotation_updated", global_rotation)
