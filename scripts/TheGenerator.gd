extends Node2D

# @export var _noise: FastNoiseLite
@export var additive_noise: Array[FastNoiseLite]
@export var noise_threshold_min: float = -1.0
@export var noise_threshold_max: float = -0.85

signal asteroid_mesh_updated(mesh: Mesh, transform: Transform2D)

var generated_chunks := {}
var generated_tiles := {}

const SQUARE_CHUNK_SIZE := 512.0

# How many times the chunk is subdivided to get the fine grid
const FINE_GRID_DEPTH := 5

func get_noise(noise_offset: Vector2):
	var result := 0.0

	for noise in additive_noise:
		result += noise.get_noise_2dv(noise_offset)

	return result / len(additive_noise)


func generate_chunk(chunk_coord: Vector2i) -> void:
	# chunk location in world coordinates
	# var chunk_start = SQUARE_CHUNK_SIZE * Vector2(chunk_coord.x, chunk_coord.y)
	# var chunk_size = SQUARE_CHUNK_SIZE * Vector2.ONE
	# var chunk_bounds = Rect2(chunk_start, chunk_size)

	var fine_grid_resolution = int(pow(2, FINE_GRID_DEPTH) + 0.5)
	# chunk location in fine grid coordinates
	var fine_grid_chunk_coord = chunk_coord * fine_grid_resolution

	var fine_grid_size = SQUARE_CHUNK_SIZE / fine_grid_resolution

	var p = TheAsteroid.GenerateParameters.new()
	p.square_tile_size = fine_grid_size
	p.noise_min = noise_threshold_min
	p.noise_max = noise_threshold_max
	# p.noise_source = _spawn_noise

	# we are assuming that the chunk doesn't already exist for now
	assert(chunk_coord not in generated_chunks.keys())

	generated_chunks[chunk_coord] = []

	var noise_in_range = func(noise: float) -> bool:
		return noise > p.noise_min and noise < p.noise_max

	var fine_grid_tiles := {}
	for i in range(fine_grid_resolution):
		for j in range(fine_grid_resolution):
			fine_grid_tiles[fine_grid_chunk_coord + Vector2i(i, j)] = TheAsteroid.Tile.new()

	# while there's still possible asteroids to generate
	while fine_grid_tiles.size() > 0:
		var asteroid_tiles := []
		var coords := fine_grid_tiles.keys()
		var coord = coords[0]
		# var tile = fine_grid_tiles[coord]

		# visited.append(coord)
		var world_pos = Vector2(coord.x, coord.y) * fine_grid_size + Vector2.ONE * fine_grid_size / 2.0
		var noise = get_noise(world_pos)

		# repeat until there's a valid seed
		while not noise_in_range.call(noise) or coord in generated_tiles.keys():
			fine_grid_tiles.erase(coord)
			# if there's no tiles left to check, then there's no valid asteroid seeds and the chunk is finished
			if fine_grid_tiles.size() == 0:
				return
			coords = fine_grid_tiles.keys()
			coord = coords[0]
			# tile = fine_grid_tiles[coord]
			# visited.append(coord)
			world_pos = Vector2(coord.x, coord.y) * fine_grid_size + Vector2.ONE * fine_grid_size / 2.0
			noise = get_noise(world_pos)


		# if we made it this far, we have an asteroid seed

		var stack := [coord]
		var visited := {}

		var current = coord

		while stack.size() > 0:
			current = stack[-1]
			visited[current] = true

			if current in  fine_grid_tiles.keys():
				fine_grid_tiles.erase(current)
			stack.pop_back()

			var directions = [
				Vector2i.UP,
				Vector2i.LEFT,
				Vector2i.RIGHT,
				Vector2i.DOWN
			]
			for d in directions:
				var neighbor = current + d
				var pos_world = Vector2(neighbor.x, neighbor.y) * fine_grid_size + Vector2.ONE * fine_grid_size / 2.0
				noise = get_noise(pos_world)
				if not visited.has(neighbor) and noise_in_range.call(noise):
					stack.append(neighbor)
				

		var max_corner = Vector2(-INF, -INF)
		var min_corner = Vector2(INF, INF)

		for t in visited.keys():
			var v = Vector2(t.x, t.y) * p.square_tile_size
			if v.x > max_corner.x:
				max_corner.x = v.x
			if v.y > max_corner.y:
				max_corner.y = v.y
			if v.x < min_corner.x:
				min_corner.x = v.x
			if v.y < min_corner.y:
				min_corner.y = v.y

			generated_chunks[chunk_coord].append(t)

			assert(t not in generated_tiles.keys())
			generated_tiles[t] = chunk_coord

			asteroid_tiles.append(t)

		# easy way to clean up the noise
		if asteroid_tiles.size() == 1:
			continue

		var asteroid = TheAsteroid.new()
		var rigid_body = RigidBody2D.new()
		var collision_shape = CollisionShape2D.new()

		var shape = RectangleShape2D.new()
		shape.size = max_corner - min_corner
		collision_shape.shape = shape

		var asteroid_center = (max_corner + min_corner) / 2.0

		rigid_body.mass = 10.0 * asteroid_tiles.size()
		rigid_body.transform = rigid_body.transform.translated(asteroid_center)

		asteroid.generate_mesh(asteroid_tiles, p.square_tile_size, asteroid_center)
		asteroid_mesh_updated.emit(asteroid.mesh_node.mesh, rigid_body.transform)

		rigid_body.add_child(collision_shape)
		rigid_body.add_child(asteroid)
		add_child(rigid_body)


func _ready() -> void:
	const SIZE := 5
	for i in range(-SIZE / 2, SIZE / 2):
		for j in range(-SIZE / 2, SIZE / 2):
			generate_chunk(Vector2i(i, j))
