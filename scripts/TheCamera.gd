
extends RigidBody2D

signal position_updated(position: Vector2)

const LINEAR_SPRING_CONSTANT := 50.0
const LINEAR_DAMPING_CONSTANT := 5.0
const ANGULAR_SPRING_CONSTANT := 10000.0
const ANGULAR_DAMPING_CONSTANT := 1200.0

## This function updates the camera position and rotation as if it's attached to a spring-arm connected to the character.
## The linear spring force and angular spring torque are calculated independently with different spring constants. 
func _on_character_transform_updated(character_body_transform: Transform2D):

	var pos := character_body_transform.get_origin()
	var spring_force := -LINEAR_SPRING_CONSTANT * (global_position - pos) - LINEAR_DAMPING_CONSTANT * linear_velocity
	apply_central_force(spring_force)

	global_rotation = character_body_transform.get_rotation()

func _physics_process(_delta: float) -> void:
	position_updated.emit(position)
