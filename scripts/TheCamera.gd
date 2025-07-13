
extends RigidBody2D

signal position_updated(position: Vector2)

const SPRING_CONSTANT := 20.0
const DAMPING_CONSTANT := 2.0

## This function updates the camera as if it's attached to a spring-arm connected to the character.
## It also assigns the character's body rotation to the camera.
func _on_character_transform_updated(character_body_transform: Transform2D):

	var pos := character_body_transform.get_origin()
	var spring_force := -SPRING_CONSTANT * (global_position - pos) - DAMPING_CONSTANT * linear_velocity
	apply_central_force(spring_force)

	global_rotation = character_body_transform.get_rotation()

func _physics_process(_delta: float) -> void:
	position_updated.emit(position)
