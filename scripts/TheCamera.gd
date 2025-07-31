extends RigidBody2D

signal position_updated(position: Vector2)

const LINEAR_SPRING_CONSTANT := 50.0
const LINEAR_DAMPING_CONSTANT := 10.0
const ANGULAR_SPRING_CONSTANT := 10000.0
const ANGULAR_DAMPING_CONSTANT := 3500.0


## This function updates the camera position and rotation as if it's attached to a spring-arm connected to the character.
## The linear spring force and angular spring torque are calculated independently with different spring constants.
func _on_character_transform_updated(character_body_transform: Transform2D):
    var pos := character_body_transform.get_origin()
    var spring_force := (
        -LINEAR_SPRING_CONSTANT * (global_position - pos)
        - LINEAR_DAMPING_CONSTANT * linear_velocity
    )
    apply_central_force(spring_force)


    var angle_delta := global_rotation - character_body_transform.get_rotation()
    # correct the angle delta such that we will always rotate the camera the shortest distance. This is necessary for example when
    # one vector is close to +180 degrees, and the other close to -180 degrees. Without this correction, the camera would rotate almost a full 360,
    # when really we only need to move a few degrees (We are actually working in radians)
    if angle_delta > PI:
        angle_delta = angle_delta - 2 * PI
    elif angle_delta < -PI:
        angle_delta = angle_delta + 2 * PI

    var spring_torque := (
        -ANGULAR_SPRING_CONSTANT * angle_delta
        - ANGULAR_DAMPING_CONSTANT * angular_velocity
    )
    apply_torque(spring_torque)


func _physics_process(_delta: float) -> void:
    position_updated.emit(position)
