extends Node
signal request_character_movement(direction: Vector2i)

func _physics_process(_delta: float) -> void:
	var input_dir_state = Vector2i.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir_state += Vector2i.UP
	if Input.is_key_pressed(KEY_A):
		input_dir_state += Vector2i.LEFT
	if Input.is_key_pressed(KEY_D):
		input_dir_state += Vector2i.RIGHT
		
	request_character_movement.emit(input_dir_state)
