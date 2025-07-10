extends Node2D
class_name TheCharacter

## This signal is emitted when the internal physics body (RigidBody2D) changes its transform.
## Primarily position and rotation are used, though scale could also be used.
signal body_transform_updated(global_transform: Transform2D)

## The state of the last requested input movement (one of four directions, or zero)
var _requested_movement := Vector2i.ZERO

## asteroids that are detected within the radius of the $ProximityDetector node
var _nearby_asteroids: Dictionary[RID, Asteroid] = {}

var _show_debug_indicators = true

## Scale of the gravititational force from asteroids on the character
const GRAVITATIONAL_CONSTANT := 200.0
const AUTOMATIC_ROTATION_TORQUE_SPRING_CONSTANT = 1000.0
const AUTOMATIC_ROTATION_TORQUE_DAMPING_CONSTANT = 300.0
const REQUESTED_MOVEMENT_FORCE_SCALE = 20000.0
const REQUESTED_MOVEMENT_TORQUE_SCALE = 100000.0 
const DEBUG_INDICATOR_LINE_WIDTH = 10.0
const DEBUG_INDICATOR_LINE_LENGTH = 85.0
const DEBUG_INDICATOR_ARROW_TIP_SIZE = 10.0

# (TODO update this comment once "walking" mode is implemented)
## This is intended for incoming signals to notify this object that the player is requesting movement with the given direction.
## The magnitude of direction.x corresponds to enabling rotation, and the sign of direction.x determines if the character will rotate
## clockwise (> 0) or counterclockwise (< 0). Similarily, the direction.y movement determines acceleration relative to the character's
## forward axis. A positive direction.y value means the character will accelerate forward.
func _on_request_movement(direction: Vector2i):
	_requested_movement = direction

## A callback used internally for the $ProximityDetector to notify this script that there is potentially nearby asteroid
func _on_body_entered_proximity(body: Node2D):
	if body is RigidBody2D:
		var body_parent = body.get_parent()
		if body_parent is Asteroid:
			# TODO there should be a better key to use other than the rigid body's RID
			_nearby_asteroids[body.get_rid()] = body_parent

## A callback used internally for the $ProximityDetector to notify this script that potentially asteroid is moving away from the character
func _on_body_exited_proximity(body: Node2D):
	if body is RigidBody2D:
		var body_parent = body.get_parent()
		if body_parent is Asteroid:
			_nearby_asteroids.erase(body.get_rid())


func _physics_process(_delta: float) -> void:


	# in this section we are seeking the strongest gravitational pull of the nearby asteroids,
	# and we will apply it to the character

	var strongest_gravity_force := Vector2.ZERO
	var character_body := $PhysicsBody as RigidBody2D
	var character_mass := character_body.mass

	for asteroid: Asteroid in _nearby_asteroids.values():
		var asteroid_body := (asteroid.rigid_body as RigidBody2D)
		var asteroid_mass := asteroid_body.mass
		var relative_position := (asteroid_body.global_position - character_body.global_position)
		var radius := relative_position.length()
		var gravity_force_magnitude := GRAVITATIONAL_CONSTANT * asteroid_mass * character_mass / (radius * radius)
		var gravity_force_direction := relative_position.normalized()
		var gravity_force := gravity_force_magnitude * gravity_force_direction

		if gravity_force_magnitude > strongest_gravity_force.length():
			strongest_gravity_force = gravity_force


	# here we are determining the orientation of the character relative to the asteroid with the strongest pull.
	# This will be used to rotate the character to align with the surface of the asteroid, providing a "landing" effect
	var chosen_gravity_direction = strongest_gravity_force.normalized()
	var character_orientation = character_body.transform.basis_xform(Vector2.DOWN).normalized()

	# angle of the gravity vector relative to +x
	var gravity_vector_angle = atan2(chosen_gravity_direction.y, chosen_gravity_direction.x)

	# angle of the character orientation vector relative to +x
	var character_rotation_angle = atan2(character_orientation.y, character_orientation.x)
	var angle_delta = character_rotation_angle - gravity_vector_angle


	# correct the angle delta such that we will always rotate the character the shortest distance. This is necessary for example when
	# one vector is close to +180 degrees, and the other close to -180 degrees. Without this correction, the character would rotate almost a full 360,
	# when really we only need to move a few degrees (We are actually working in radians)
	if angle_delta > PI:
		angle_delta = angle_delta - 2*PI
	elif angle_delta < -PI:
		angle_delta = angle_delta + 2*PI

	# only apply input force/torque if there is requested movement
	var should_apply_player_input = _requested_movement != Vector2i.ZERO

	# if we are not receiving a direct request for movement/acceleration, then apply force/torque due to gravity and the automatic rotation to 
	# orient towards the asteroid
	if not should_apply_player_input:
		var torque_spring_component = AUTOMATIC_ROTATION_TORQUE_SPRING_CONSTANT * angle_delta
		var torque_damping_component = AUTOMATIC_ROTATION_TORQUE_DAMPING_CONSTANT * character_body.angular_velocity
		var automatic_rotation_torque = -torque_spring_component - torque_damping_component
		var scaled_automatic_rotation_torque = automatic_rotation_torque * strongest_gravity_force.length()

		character_body.apply_torque(scaled_automatic_rotation_torque)
		character_body.apply_central_force(strongest_gravity_force)


	# apply the force and torque as requested, presumably as a signal from the player input controller
	var requested_movement_force := REQUESTED_MOVEMENT_FORCE_SCALE * _requested_movement.y * Vector2.DOWN.rotated(character_body.rotation)
	var requested_movement_torque := REQUESTED_MOVEMENT_TORQUE_SCALE * _requested_movement.x
	character_body.apply_central_force(requested_movement_force)
	character_body.apply_torque(requested_movement_torque)

	# send the signal out that will notify other nodes that the character has moved
	body_transform_updated.emit(character_body.global_transform)

	# update the rigidbody's siblings to be in the same position as the rigidbody
	var character_mesh := $RenderMesh as MeshInstance2D
	var character_proximity_detector = $ProximityDetector as Area2D

	character_mesh.transform = character_body.transform
	character_proximity_detector.transform = character_body.transform

	# this is to make sure the _draw() method is called each frame
	queue_redraw()

func _draw() -> void:

	var character_body := $PhysicsBody as RigidBody2D
	
	# if enabled, show an arrow indicated the input acceleration given by the requested movement
	if _show_debug_indicators:
		var arrow_vector_force = _requested_movement.y * Vector2.DOWN.rotated(character_body.rotation) * DEBUG_INDICATOR_LINE_LENGTH
		var arrow_vector_torque = _requested_movement.x * Vector2.RIGHT.rotated(character_body.rotation) * DEBUG_INDICATOR_LINE_LENGTH
		
		for arrow_vector in [arrow_vector_force, arrow_vector_torque]:
			var debug_arrow_from = character_body.position
			var debug_arrow_to = character_body.position + arrow_vector
			draw_line(debug_arrow_from, debug_arrow_to, Color.WHITE, DEBUG_INDICATOR_LINE_WIDTH, false)
			var arrow_tip_points = PackedVector2Array()
			arrow_tip_points.append(arrow_vector.normalized() * DEBUG_INDICATOR_ARROW_TIP_SIZE + debug_arrow_to)
			arrow_tip_points.append(arrow_vector.normalized().rotated(PI/2) * DEBUG_INDICATOR_ARROW_TIP_SIZE + debug_arrow_to)
			arrow_tip_points.append(arrow_vector.normalized().rotated(-PI/2) * DEBUG_INDICATOR_ARROW_TIP_SIZE + debug_arrow_to)
			var arrow_tip_colors = PackedColorArray()
			arrow_tip_colors.append(Color.WHITE)
			arrow_tip_colors.append(Color.WHITE)
			arrow_tip_colors.append(Color.WHITE)
			draw_polygon(arrow_tip_points, arrow_tip_colors)
