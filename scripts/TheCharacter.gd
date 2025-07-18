extends Node2D
class_name TheCharacter

const CollisionConstants = preload("res://scripts/CollisionConstants.gd")

## This signal is emitted when the internal physics body (RigidBody2D) changes its transform.
## Primarily position and rotation are used, though scale could also be used.
signal body_transform_updated(global_transform: Transform2D)

## This is used to notify the controller of the asteroid that a tile has been destroyed/mined by the character
signal destroyed_asteroid_tile(tile_area: Area2D)

## The state of the last requested input movement (one of four directions, or zero)
var _requested_movement := Vector2i.ZERO

## The state of the boosters, as most recently requested
var _boosters_enabled := true

var _mining_active := false

## asteroids that are detected within the radius of the $ProximityDetector node
var _nearby_asteroids: Dictionary[RID, Asteroid] = {}

## Whether to show the arrows that indicate player acceleration/torque in space (when boosters are on)
var _show_debug_indicators = true

var _time_since_last_mined = 0.0

## Scale of the gravititational force from asteroids on the character
const GRAVITATIONAL_CONSTANT := 200.0
const AUTOMATIC_ROTATION_TORQUE_SPRING_CONSTANT = 5000000.0
const AUTOMATIC_ROTATION_TORQUE_DAMPING_CONSTANT = 800000.0
const REQUESTED_MOVEMENT_FORCE_SCALE = 20000.0
const REQUESTED_MOVEMENT_TORQUE_SCALE = 100000.0
const DEBUG_INDICATOR_LINE_WIDTH = 10.0
const DEBUG_INDICATOR_LINE_LENGTH = 85.0
const DEBUG_INDICATOR_ARROW_TIP_SIZE = 10.0
const BOOSTERS_ENABLED_COLOR: Color = Color.LIGHT_GREEN
const BOOSTERS_DISABLED_COLOR: Color = Color.PALE_VIOLET_RED
const WALKING_SPEED = 250.0
const JUMPING_FORCE_SCALE = 500000.0
const MINING_COOLDOWN = 0.5


## this is for incoming signals to notify this script that the "pickaxe" (or mining tool) is being used
func _on_set_mining_active(active: bool) -> void:
	self._mining_active = active


## This is for incoming signals to notify this script to set the "boosters enabled" state
## This should probably be replaced once a Skelly player/game state is integrated,
## and there are distinct "On asteroid" and "in space" states
func _on_set_boosters_enabled(enabled: bool) -> void:
	if enabled:
		$RenderMesh.self_modulate = BOOSTERS_ENABLED_COLOR
	else:
		$RenderMesh.self_modulate = BOOSTERS_DISABLED_COLOR

	_boosters_enabled = enabled


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


func _physics_process(delta: float) -> void:
	# in this section we are seeking the strongest gravitational pull of the nearby asteroids,
	# and we will apply it to the character

	var strongest_gravity_force := Vector2.ZERO
	var character_body := $PhysicsBody as RigidBody2D
	var character_mass := character_body.mass

	for asteroid: Asteroid in _nearby_asteroids.values():
		var asteroid_body := asteroid.rigid_body as RigidBody2D
		var asteroid_mass := asteroid_body.mass
		var relative_position := asteroid_body.global_position - character_body.global_position
		var radius := relative_position.length()
		var gravity_force_magnitude := (
			GRAVITATIONAL_CONSTANT * asteroid_mass * character_mass / (radius * radius)
		)
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

	var space_rid := get_world_2d().space
	var space_state := PhysicsServer2D.space_get_direct_state(space_rid)

	# correct the angle delta such that we will always rotate the character the shortest distance. This is necessary for example when
	# one vector is close to +180 degrees, and the other close to -180 degrees. Without this correction, the character would rotate almost a full 360,
	# when really we only need to move a few degrees (We are actually working in radians)
	if angle_delta > PI:
		angle_delta = angle_delta - 2 * PI
	elif angle_delta < -PI:
		angle_delta = angle_delta + 2 * PI

	# only apply input force/torque if there is requested movement
	var boosters_are_active = _requested_movement != Vector2i.ZERO and _boosters_enabled

	if boosters_are_active:
		# apply the force and torque as requested, presumably as a signal from the player input controller
		# TODO for now I am adding a portion (90 percent) of the gravity force because otherwise the player will have trouble
		# boosting away from a strong gravitational pull. My thinking is that more fuel should be burned in a way that is proportional
		# to how much force is applied, but for now I'm faking it to allow movement from asteroid to space
		var requested_movement_force := (
			(REQUESTED_MOVEMENT_FORCE_SCALE + strongest_gravity_force.length() * 0.9)
			* _requested_movement.y
			* Vector2.DOWN.rotated(character_body.rotation)
		)
		var requested_movement_torque := REQUESTED_MOVEMENT_TORQUE_SCALE * _requested_movement.x
		character_body.apply_central_force(requested_movement_force)
		character_body.apply_torque(requested_movement_torque)

	# if we are not in booster mode at all, then attempt to walk on the surface of the asteroid
	if not _boosters_enabled:
		# now we are going to check for the surface normal under the character, in order to move along the surface
		var character_shape := ($PhysicsBody/CollisionShape2D as CollisionShape2D).shape
		var collision_mask = CollisionConstants.ASTEROID
		var shape_query := PhysicsShapeQueryParameters2D.new()

		# this will be a shape query of the character shape, to see if it is intersecting with an asteroid
		shape_query.shape = character_shape
		shape_query.transform = character_body.global_transform
		shape_query.collide_with_bodies = true
		shape_query.collision_mask = collision_mask
		shape_query.margin = 5.0

		var shape_query_result = space_state.collide_shape(shape_query)

		# this will be the default vector for movement if there is not a hit. In other words,
		# currently the player is allowed to move sideways even if not touching anything
		var movement_dir = character_body.transform.basis_xform(Vector2.RIGHT).normalized()

		# if the query result dictionary has entries, then there was a hit
		if shape_query_result.size() > 0:
			var cast_from = character_body.global_position

			# there can be multiple hits, so average the position of them.
			# the array we are going through has pairs of collision points between this shape collider and the
			# one it is intersecting with
			var i = 0
			var cast_to = Vector2.ZERO
			while i < shape_query_result.size():
				cast_to += shape_query_result[i]
				i += 2
			cast_to /= (shape_query_result.size() as float / 2.0)

			# now that we know there is a hit, we will find the surface normal by
			# doing a raycast and using the result from that
			var ray_query := PhysicsRayQueryParameters2D.create(cast_from, cast_to, collision_mask)
			var ray_query_result = space_state.intersect_ray(ray_query)

			if ray_query_result.size() > 0:
				var surface_normal = ray_query_result.normal.normalized()
				var surface_tangent = surface_normal.rotated(PI / 2)

				# if we got here, then we can determine movement direction using the surface tangent
				movement_dir = surface_tangent

			# additionally, if we are on a surface, we want the ability to jump if the player requests it
			var jumping_force = (
				character_body.transform.basis_xform(Vector2.DOWN)
				* _requested_movement.y
				* JUMPING_FORCE_SCALE
			)
			character_body.apply_central_force(jumping_force)

			# finally update the horizontal movement
			character_body.position += delta * WALKING_SPEED * _requested_movement.x * movement_dir

		# if boosters are not active, then apply torque for the automatic rotation to
		# orient towards the asteroid
		var torque_spring_component = AUTOMATIC_ROTATION_TORQUE_SPRING_CONSTANT * angle_delta
		var torque_damping_component = (
			AUTOMATIC_ROTATION_TORQUE_DAMPING_CONSTANT * character_body.angular_velocity
		)
		var automatic_rotation_torque = -torque_spring_component - torque_damping_component
		character_body.apply_torque(automatic_rotation_torque)

	character_body.apply_central_force(strongest_gravity_force)

	# send the signal out that will notify other nodes that the character has moved
	body_transform_updated.emit(character_body.global_transform)

	# update the other children to match that of the rigid body
	for child in get_children():
		if child == character_body:
			continue
		child.transform = character_body.transform

	var tile_detection_shape_node := $TileDetector/CollisionShape2D as CollisionShape2D
	var tile_detection_shape := tile_detection_shape_node.shape

	_time_since_last_mined += delta

	if _mining_active and _time_since_last_mined > MINING_COOLDOWN:
		var shape_query := PhysicsShapeQueryParameters2D.new()
		shape_query.shape = tile_detection_shape
		shape_query.transform = tile_detection_shape_node.global_transform
		shape_query.collide_with_areas = true
		shape_query.collision_mask = CollisionConstants.ASTEROID_TILE

		var query_result = space_state.intersect_shape(shape_query)

		if query_result.size() > 0:
			_time_since_last_mined = 0

			for collision_dict in query_result:
				var colliding_area = collision_dict.collider as Area2D
				destroyed_asteroid_tile.emit(colliding_area)

	# this is to make sure the _draw() method is called each frame
	queue_redraw()


func _draw() -> void:
	var character_body := $PhysicsBody as RigidBody2D

	# if enabled, show an arrow indicated the input acceleration given by the requested movement
	if _show_debug_indicators:
		var arrow_vector_force = (
			_requested_movement.y
			* Vector2.DOWN.rotated(character_body.rotation)
			* DEBUG_INDICATOR_LINE_LENGTH
		)
		var arrow_vector_torque = (
			_requested_movement.x
			* Vector2.RIGHT.rotated(character_body.rotation)
			* DEBUG_INDICATOR_LINE_LENGTH
		)

		for arrow_vector in [arrow_vector_force, arrow_vector_torque]:
			var debug_arrow_from = character_body.position
			var debug_arrow_to = character_body.position + arrow_vector
			draw_line(
				debug_arrow_from, debug_arrow_to, Color.WHITE, DEBUG_INDICATOR_LINE_WIDTH, false
			)
			var arrow_tip_points = PackedVector2Array()
			arrow_tip_points.append(
				arrow_vector.normalized() * DEBUG_INDICATOR_ARROW_TIP_SIZE + debug_arrow_to
			)
			arrow_tip_points.append(
				(
					arrow_vector.normalized().rotated(PI / 2) * DEBUG_INDICATOR_ARROW_TIP_SIZE
					+ debug_arrow_to
				)
			)
			arrow_tip_points.append(
				(
					arrow_vector.normalized().rotated(-PI / 2) * DEBUG_INDICATOR_ARROW_TIP_SIZE
					+ debug_arrow_to
				)
			)
			var arrow_tip_colors = PackedColorArray()
			arrow_tip_colors.append(Color.WHITE)
			arrow_tip_colors.append(Color.WHITE)
			arrow_tip_colors.append(Color.WHITE)
			draw_polygon(arrow_tip_points, arrow_tip_colors)
