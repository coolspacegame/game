extends Node2D
class_name TheCharacter

const CollisionConstants = preload("res://scripts/CollisionConstants.gd")
const TheEnvironment = preload("res://scripts/TheEnvironment.gd")

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
var _show_debug_indicators := true

var _time_since_last_mined := 0.0

var _is_jumping := false

var _requested_jump := false

var _remaining_jumping_time := MAX_JUMPING_TIME

var _net_force_filter := []

var _arrows_to_draw: Array[Dictionary] = []

## Scale of the gravititational force from asteroids on the character
const GRAVITATIONAL_CONSTANT := 1.0
const FORCE_FILTER_SIZE := 6
const MAX_JUMPING_TIME := 0.5
const HORIZONTAL_JUMP_SCALE := 0.80
const AUTOMATIC_ROTATION_TORQUE_SPRING_CONSTANT := 20000000.0
const AUTOMATIC_ROTATION_TORQUE_DAMPING_CONSTANT := 3000000.0
const REQUESTED_MOVEMENT_FORCE_SCALE := 20000.0
const REQUESTED_MOVEMENT_TORQUE_SCALE := 100000.0
const DEBUG_INDICATOR_LINE_WIDTH := 10.0
const DEBUG_INDICATOR_LINE_LENGTH := 85.0
const DEBUG_INDICATOR_ARROW_TIP_SIZE := 10.0
const BOOSTERS_ENABLED_COLOR := Color.LIGHT_GREEN
const BOOSTERS_DISABLED_COLOR := Color.PALE_VIOLET_RED
const WALKING_SPEED := 250.0
const WALKING_MOVEMENT_FORCE_SCALE := 50000.0
const JUMPING_FORCE_SCALE := 4000000.0
const MINING_COOLDOWN := 0.5


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


func _on_request_jump_active(active: bool) -> void:
    _requested_jump = active


## A callback used internally for the $ProximityDetector to notify this script that there is potentially nearby asteroid
func _on_body_entered_proximity(body: Node2D):
    if body is RigidBody2D:
        var body_parent := body.get_parent()
        if body_parent is Asteroid:
            # TODO there should be a better key to use other than the rigid body's RID
            _nearby_asteroids[body.get_rid()] = body_parent


## A callback used internally for the $ProximityDetector to notify this script that potentially asteroid is moving away from the character
func _on_body_exited_proximity(body: Node2D):
    if body is RigidBody2D:
        var body_parent := body.get_parent()
        if body_parent is Asteroid:
            _nearby_asteroids.erase(body.get_rid())


func _init() -> void:
    for i in range(FORCE_FILTER_SIZE):
        _net_force_filter.append(Vector2.ZERO)


func _update_net_force_filter(net_force: Vector2) -> Vector2:
    _net_force_filter.append(net_force)
    _net_force_filter.pop_front()

    var sum := Vector2.ZERO
    for value in _net_force_filter:
        sum += value
    return sum / _net_force_filter.size()


func _physics_process(delta: float) -> void:
    # in this section we are seeking the strongest gravitational pull of the nearby asteroids,
    # and we will apply it to the character

    var strongest_gravity_force := Vector2.ZERO
    var summed_gravity_force := Vector2.ZERO
    var character_body := $PhysicsBody as RigidBody2D
    var character_mass := character_body.mass

    const MAX_ASTEROID_RADIUS := TheEnvironment.MAX_ASTEROID_RADIUS

    for asteroid: Asteroid in _nearby_asteroids.values():
        var asteroid_body := asteroid.rigid_body as RigidBody2D
        var asteroid_mass := asteroid_body.mass
        var relative_position := (
            asteroid_body.global_position + asteroid.center_of_mass - character_body.global_position
        )
        var radius := relative_position.length()
        var gravity_force_magnitude := (
            # this is an approximation of what the gravitational pull should be, if we assume a circular evenly-distributed asteroid
            # This is not an 'accurate' value, but should be good enough. It takes the force as if the character were distance
            GRAVITATIONAL_CONSTANT
            * asteroid_mass
            * character_mass
            * radius
            / (MAX_ASTEROID_RADIUS * MAX_ASTEROID_RADIUS)
        )
        var gravity_force_direction := relative_position.normalized()
        var gravity_force := gravity_force_magnitude * gravity_force_direction

        summed_gravity_force += gravity_force

        if gravity_force_magnitude > strongest_gravity_force.length():
            strongest_gravity_force = gravity_force

    var chosen_gravity_direction := summed_gravity_force.normalized()
    var character_orientation := character_body.transform.basis_xform(Vector2.DOWN).normalized()

    var space_rid := get_world_2d().space
    var space_state := PhysicsServer2D.space_get_direct_state(space_rid)

    var net_force := Vector2.ZERO

    # only apply input force/torque if there is requested movement
    var boosters_are_active := _requested_movement != Vector2i.ZERO and _boosters_enabled

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
        net_force += requested_movement_force
        character_body.apply_torque(requested_movement_torque)

    var jumping_force := Vector2.ZERO
    var walking_force := Vector2.ZERO
    var adjusted_gravity_force := strongest_gravity_force

    character_body.freeze = false

    # if we are not in booster mode at all, then attempt to walk on the surface of the asteroid
    if not _boosters_enabled:
        # now we are going to check for the surface normal under the character, in order to move along the surface
        var character_shape := ($PhysicsBody/CollisionShape2D as CollisionShape2D).shape
        var collision_mask := CollisionConstants.ASTEROID

        var proximity_detector_shape := (
            ($ProximityDetector/CollisionShape2D as CollisionShape2D).shape
        )
        var proximity_detector_shape_rect := proximity_detector_shape.get_rect()

        var surface_normal_sum := Vector2.ZERO
        var surface_position_sum := Vector2.ZERO
        var surface_normal_count := 0
        var offset_range_size := character_shape.get_rect().size.x
        var offset_range_idx_start_inclusive := -1
        var offset_range_idx_end_exclusive := 2
        var offset_step_magnitude := (
            offset_range_size
            / (offset_range_idx_end_exclusive - 1 - offset_range_idx_start_inclusive)
        )

        for offset in range(offset_range_idx_start_inclusive, offset_range_idx_end_exclusive):
            var rotation_cast_from := (
                character_body.global_position
                + character_body.transform.basis_xform(
                    Vector2.RIGHT * offset * offset_step_magnitude
                )
            )
            var rotation_cast_to := (
                rotation_cast_from
                + chosen_gravity_direction * proximity_detector_shape_rect.size.y / 2
            )

            var rotation_ray_query := PhysicsRayQueryParameters2D.create(
                rotation_cast_from, rotation_cast_to, collision_mask
            )
            var rotation_ray_query_result := space_state.intersect_ray(rotation_ray_query)

            if rotation_ray_query_result.size() > 0:
                surface_normal_sum += rotation_ray_query_result.normal.normalized()
                surface_position_sum += rotation_ray_query_result.position
                surface_normal_count += 1

        if surface_normal_count > 0:
            var surface_normal := surface_normal_sum.normalized()
            var surface_position := surface_position_sum / surface_normal_count
            var surface_normal_negated := -surface_normal
            var surface_tangent := surface_normal.rotated(PI / 2)

            var surface_vector := surface_position - character_body.global_position
            var surface_distance := surface_vector.length()
            var surface_distance_normalized := (
                surface_distance / (proximity_detector_shape_rect.size.y / 2.0)
            )
            var surface_distance_normalized_clamped := (
                clamp(surface_distance_normalized, 0.0, 1.0) as float
            )
            adjusted_gravity_force = (
                strongest_gravity_force.length()
                * lerp(
                    surface_normal_negated.normalized(),
                    strongest_gravity_force.normalized(),
                    surface_distance_normalized_clamped
                )
            )

            # angle of the normal vector relative to +x
            var normal_vector_angle := atan2(surface_normal_negated.y, surface_normal_negated.x)

            # angle of the character orientation vector relative to +x
            var character_rotation_angle := atan2(character_orientation.y, character_orientation.x)
            var angle_delta := normal_vector_angle - character_rotation_angle

            if abs(angle_delta) > PI:
                angle_delta -= sign(angle_delta) * TAU

            character_body.apply_torque(
                (
                    AUTOMATIC_ROTATION_TORQUE_SPRING_CONSTANT * angle_delta
                    - AUTOMATIC_ROTATION_TORQUE_DAMPING_CONSTANT * character_body.angular_velocity
                )
            )

            var shape_query := PhysicsShapeQueryParameters2D.new()

            # this will be a shape query of the character shape, to see if it is intersecting with an asteroid
            shape_query.shape = character_shape
            shape_query.transform = character_body.global_transform
            shape_query.collide_with_bodies = true
            shape_query.collision_mask = collision_mask
            shape_query.margin = 15.0

            var shape_query_result := space_state.get_rest_info(shape_query)

#            var asteroid_vel := Vector2.ZERO

            # if the query result dictionary has entries, then there was a hit
            if shape_query_result.size() > 0:
                walking_force = (
                    WALKING_MOVEMENT_FORCE_SCALE * _requested_movement.x * surface_tangent
                )

                if not _is_jumping and _requested_jump:
                    jumping_force = (
                        character_body.transform.basis_xform(Vector2.UP)
                        * JUMPING_FORCE_SCALE
                        * _remaining_jumping_time
                        / MAX_JUMPING_TIME
                    )
                    _is_jumping = true

#                asteroid_vel = shape_query_result.linear_velocity

                # if walking, then we will apply a force to negate gravity. This is to reduce friction and allow walking
                if walking_force.length() > 0.01:
                    net_force -= adjusted_gravity_force.dot(surface_normal) * surface_normal

    net_force += walking_force + jumping_force + adjusted_gravity_force
    var net_force_filtered := _update_net_force_filter(net_force)

    if _is_jumping:
        # update the remaining jumping time, such that it will run out after some time
        _remaining_jumping_time = max(_remaining_jumping_time - delta, 0.0)
        if _remaining_jumping_time <= 0.0:
            _is_jumping = false

    else:
        _remaining_jumping_time = min(_remaining_jumping_time + delta, MAX_JUMPING_TIME)

    # send the signal out that will notify other nodes that the character has moved
    body_transform_updated.emit(character_body.global_transform)

    # update the other children to match that of the rigid body
    for child in get_children():
        if child == character_body:
            continue

        # this is to make sure the _draw() method is called each frame
        child.transform = character_body.transform

    # this is to make sure the _draw() method is called each frame
    var tile_detection_shape_node := $TileDetector/CollisionShape2D as CollisionShape2D
    var tile_detection_shape := tile_detection_shape_node.shape

    _time_since_last_mined += delta

    if _mining_active and _time_since_last_mined > MINING_COOLDOWN:
        var shape_query := PhysicsShapeQueryParameters2D.new()
        shape_query.shape = tile_detection_shape
        shape_query.transform = tile_detection_shape_node.global_transform
        shape_query.collide_with_areas = true
        shape_query.collision_mask = CollisionConstants.ASTEROID_TILE

        var query_result := space_state.intersect_shape(shape_query)

        if query_result.size() > 0:
            _time_since_last_mined = 0

            for collision_dict in query_result:
                var colliding_area := collision_dict.collider as Area2D
                destroyed_asteroid_tile.emit(colliding_area)

    character_body.apply_central_force(net_force)

#    var arrow_vector_force  := (
#        _requested_movement.y
#        * Vector2.DOWN.rotated(character_body.rotation)
#        * DEBUG_INDICATOR_LINE_LENGTH
#    )
#    var arrow_vector_torque := (
#        _requested_movement.x
#        * Vector2.RIGHT.rotated(character_body.rotation)
#        * DEBUG_INDICATOR_LINE_LENGTH
#    )

    var arrow_vector_input_force := (
        net_force_filtered.normalized() * clampf(net_force_filtered.length() * 0.002, 50.0, 300.0)
    )

    _arrows_to_draw.clear()
    if _show_debug_indicators:
#        _arrows_to_draw.append({
#            "from": character_body.global_position,
#            "to": character_body.global_position + arrow_vector_force,
#            "color": Color.WHITE,
#        })
#        _arrows_to_draw.append({
#            "from": character_body.global_position,
#            "to": character_body.global_position + arrow_vector_torque,
#            "color": Color.WHITE,
#        })
        (
            _arrows_to_draw
            . append(
                {
                    "from": character_body.global_position,
                    "to": character_body.global_position + arrow_vector_input_force,
                    "color": Color.YELLOW,
                }
            )
        )

    # this is to make sure the _draw() method is called each frame
    queue_redraw()


func _draw() -> void:
    for arrow_vector_dict in _arrows_to_draw:
        var debug_arrow_from = arrow_vector_dict.from
        var debug_arrow_to = arrow_vector_dict.to
        var debug_arrow_color = arrow_vector_dict.color
        var arrow_vector = debug_arrow_to - debug_arrow_from

        draw_line(
            debug_arrow_from, debug_arrow_to, debug_arrow_color, DEBUG_INDICATOR_LINE_WIDTH, false
        )
        var arrow_tip_points := PackedVector2Array()
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
        var arrow_tip_colors := PackedColorArray()
        arrow_tip_colors.append(debug_arrow_color)
        arrow_tip_colors.append(debug_arrow_color)
        arrow_tip_colors.append(debug_arrow_color)
        draw_polygon(arrow_tip_points, arrow_tip_colors)
