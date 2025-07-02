extends Node2D

# @export var _noise: FastNoiseLite
# @export var additive_noise: Array[FastNoiseLite]

@export var detail_noise: FastNoiseLite


signal asteroid_mesh_created(mesh: Mesh)
signal asteroid_transform_updated(idx: int, transform: Transform2D)
signal asteroid_body_created(body: RigidBody2D)

class TileInfo:
	var is_border_tile = false

var generated_chunks := {}
var generated_tiles := {}

const SQUARE_CHUNK_SIZE := 512.0

# How many times the chunk is subdivided to get the fine grid
const FINE_GRID_DEPTH := 5


func rand_point_in_rect(min: Vector2, max: Vector2) -> Vector2:
	return Vector2(randf_range(min.x, max.x), randf_range(min.y, max.y))

func generate_chunk(chunk_coord: Vector2i):
	var fine_grid_resolution = int(pow(2, FINE_GRID_DEPTH) + 0.5)
	var fine_grid_chunk_coord = chunk_coord * fine_grid_resolution
	var fine_grid_size = SQUARE_CHUNK_SIZE / fine_grid_resolution

	var asteroid_spacing_factor := 1000.0
	var max_radius := asteroid_spacing_factor / 3.7
	var num_candidates_factor := 5

	var rect_min :=  Vector2(chunk_coord) * SQUARE_CHUNK_SIZE
	var rect_max := Vector2(chunk_coord + Vector2i.ONE) * SQUARE_CHUNK_SIZE

	seed(hash(chunk_coord))

	var initial_point := rand_point_in_rect(rect_min, rect_max)
	var active_points = [initial_point]
	var final_points = [initial_point]

	while len(active_points) > 0:
		var active = active_points.pop_back()


		for i in range(num_candidates_factor):
			var candidate_dist = randf_range(asteroid_spacing_factor, 2*asteroid_spacing_factor)
			var candidate_angle = randf_range(0.0, 2.0 * PI)
			var candidate = active + Vector2(candidate_dist * cos(candidate_angle), candidate_dist * sin(candidate_angle))

			var candidate_is_valid = true

			for p in final_points:
				if (candidate - p).length() < asteroid_spacing_factor \
				or candidate.x > rect_max.x \
				or candidate.x < rect_min.x \
				or candidate.y > rect_max.y \
				or candidate.y < rect_min.y:
					candidate_is_valid = false
					break

			if candidate_is_valid:
				active_points.push_back(candidate)
				final_points.push_back(candidate)




	for point in final_points:

		var asteroid_tiles = {}

		detail_noise.seed += 1

		var noise_img = detail_noise.get_seamless_image(1000, 1)

		for angle_inc in range(1000):
			var angle = angle_inc / 1000.0 * 2 * PI
			var noise = noise_img.get_pixel(angle_inc, 0).r
			noise = noise * 0.5 + 0.5
			var max_distance = noise * max_radius

			for d in range(0.0, max_distance, fine_grid_size/2):
				var new_point = d * Vector2(cos(angle), sin(angle)) + point
				var new_tile = Vector2i(new_point / fine_grid_size)
				asteroid_tiles[new_tile] = true


		var centroid = Vector2.ZERO
		for tile in asteroid_tiles.keys():
			centroid += Vector2(tile) * fine_grid_size / len(asteroid_tiles)

		var asteroid = TheAsteroid.new()
		var rigid_body = RigidBody2D.new()


		var asteroid_center = centroid

		rigid_body.mass = 100.0 * asteroid_tiles.size()
		rigid_body.transform = rigid_body.transform.translated(asteroid_center)

		asteroid.generate_mesh(asteroid_tiles.keys(), fine_grid_size, asteroid_center)
		asteroid_mesh_created.emit(asteroid.mesh_node.mesh)

		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = asteroid.collision_shape

		rigid_body.add_child(collision_shape)
		rigid_body.add_child(asteroid)

		add_child(rigid_body)

		var body := get_child(get_child_count() - 1) as RigidBody2D
		asteroid_body_created.emit(body)


		body.apply_central_impulse(10 * (Vector2(randf(), randf()) * 2 - Vector2.ONE))
		body.apply_torque_impulse(100 * (randf() * 2 - 1))


func _process(delta: float) -> void:
	for child_idx in range(get_child_count()):
		var child = get_child(child_idx) as Node2D
		# var r = child as RigidBody2D

		asteroid_transform_updated.emit(child_idx, child.transform)

# func _physics_process(delta: float) -> void:
# 	for child in get_children():
# 		var rigid_body = child as RigidBody2D



func _ready() -> void:
	const SIZE := 5
	for i in range(-SIZE / 2, SIZE / 2):

		for j in range(-SIZE / 2, SIZE / 2):
			var c = Vector2i(i, j)
			# print_debug(c)
			generate_chunk(c)
