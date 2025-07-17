extends Node
signal request_character_movement(direction: Vector2i)
signal request_character_set_booster_mode(enabled: bool)

var _last_booster_key_pressed_state = false
var _last_booster_enabled_state = true


func _physics_process(_delta: float) -> void:
	var input_dir_state = Vector2i.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir_state += Vector2i.UP
	if Input.is_key_pressed(KEY_A):
		input_dir_state += Vector2i.LEFT
	if Input.is_key_pressed(KEY_D):
		input_dir_state += Vector2i.RIGHT

	request_character_movement.emit(input_dir_state)

	if Input.is_key_pressed(KEY_C) and not _last_booster_key_pressed_state:
		_last_booster_enabled_state = !_last_booster_enabled_state
		request_character_set_booster_mode.emit(_last_booster_enabled_state)

	_last_booster_key_pressed_state = Input.is_key_pressed(KEY_C)
