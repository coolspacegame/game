extends Node2D

const CollisionConstants := preload("res://scripts/CollisionConstants.gd")

@export var _global_seed := 111
@export var _detail_noise: FastNoiseLite
@export var _size_noise: FastNoiseLite

var _rng = RandomNumberGenerator.new()

signal asteroid_mesh_created(asteroid_mesh: Mesh)
signal asteroid_transform_updated(idx: int, transform: Transform2D)

## the size of a "chunk", a square region of the environment that is generated as a unit
const SQUARE_CHUNK_SIZE := 4096

## How many times the chunk is subdivided to get the tile grid
const TILE_GRID_SUBDIVISION_FACTOR := 7

## The size of a tile used for asteroid generation
const TILE_SIZE := SQUARE_CHUNK_SIZE / pow(2, TILE_GRID_SUBDIVISION_FACTOR)

## How many tiles across a chunk is
const TILES_PER_CHUNK_LENGTH := SQUARE_CHUNK_SIZE / TILE_SIZE

## Approximately how far apart the asteroid centers will be from each other
const ASTEROID_SPACING_FACTOR := 1500.0

## the maximum possible distance from an asteroid center to a border tile
const MAX_ASTEROID_RADIUS := 1500.0

## determines the density of the asteroid
const ASTEROID_MASS_PER_TILE := 2000.0

## This value represents the change in angle used to generate the border points for an asteroid.
## The border points are generated in a circular fashion around the asteroid center.
## This value is calculated using sqrt(2) * TILE_SIZE / MAX_ASTEROID_RADIUS,
## an upper limit on how many tile-lengths the circumference of the bounding circle will be for the asteroid. 
const ASTEROID_BORDER_GENERATION_ANGULAR_INCREMENT := atan(sqrt(2) * TILE_SIZE / MAX_ASTEROID_RADIUS)

## How many steps we take around the circle as determined by the calculated increment, ASTEROID_BORDER_GENERATION_ANGULAR_INCREMENT
const ASTEROID_BORDER_GENERATION_NUM_ANGLES = ceili(2 * PI / ASTEROID_BORDER_GENERATION_ANGULAR_INCREMENT)

## When generating the asteroid centers using Poisson Disk Sampling, this
## is the maximum number of candidate points used in each iteration of the algorithm
const POISSON_DISK_SMAPLING_NUM_CANDIDATES := 20

## this is the size of the padding used during generation to prevent adjacent
## chunks from having overlapping asteroids
const CHUNK_PADDING := Vector2.ONE * ASTEROID_SPACING_FACTOR / 2.0

## Given a bounding region, generate a series of random points
## that are guaranteed to be a distance greater than or equal to spacing_factor from each other
func poisson_disk_sampling(sampling_region: Rect2, spacing_factor: float = ASTEROID_SPACING_FACTOR, rng: RandomNumberGenerator = _rng) -> Array[Vector2]:

	# choose an initial point for the algorithm
	var initial_x = rng.randf_range(sampling_region.position.x, sampling_region.end.x)
	var initial_y = rng.randf_range(sampling_region.position.y, sampling_region.end.y)
	var initial_point := Vector2(initial_x, initial_y)

	# this will hold the active points, or the points that we have not yet used to generate other candidate points
	var active_points := [initial_point]
	# this array will contain the result of the algorithm
	var result_points: Array[Vector2] = [initial_point]

	# while we still have valid points we have not checked
	while len(active_points) > 0:
		# get the next active point
		var active_point = active_points.pop_back()

		# We will attempt to generate POISSON_DISK_SMAPLING_NUM_CANDIDATES number of points.
		# There is some chance (that increases as the area becomes more crowded) that we will not actually 
		# achieve this number of new points, as some of them will be invalid (too close to existing points,
		# or outside the bounds of the sampling region) 
		for i in range(POISSON_DISK_SMAPLING_NUM_CANDIDATES):

			# Generate a candidate within in an annulus centered at the current active_point
			var candidate_point_distance = rng.randf_range(spacing_factor, 2*spacing_factor)
			var candidate_point_angle = rng.randf_range(0.0, TAU)
			var candidate = active_point + candidate_point_distance * Vector2(cos(candidate_point_angle), sin(candidate_point_angle))

			# check of the candidate breaks any of the validity checks.
			# i.e. is it outside the sampling bounds (the chunk), or is it too close to another point
			var candidate_is_valid = true
			for p in result_points:
				
				var candidate_out_of_bounds =  \
					   candidate.x > sampling_region.end.x \
					or candidate.x < sampling_region.position.x \
					or candidate.y > sampling_region.end.y \
					or candidate.y < sampling_region.position.y
				var candidate_too_close = (candidate - p).length() < spacing_factor

				if candidate_too_close or candidate_out_of_bounds:
					candidate_is_valid = false
					break

			# if the candidate didn't fail the checks, then we keep it
			if candidate_is_valid:
				active_points.push_back(candidate)
				result_points.push_back(candidate)

	return result_points

## This function generates all the asteroids in a chunk for a given chunk coordinate.
## This coordinate specifies how many chunks away from the origin these asteroids will generate.
func generate_chunk(chunk_coord: Vector2i):

	# these are the 'start' and 'end' of the chunk in world coordinates. In other words,
	# the top-left and bottom-right corners of the chunk
	var chunk_start :=  Vector2(chunk_coord) * SQUARE_CHUNK_SIZE + CHUNK_PADDING
	var chunk_end := Vector2(chunk_coord + Vector2i.ONE) * SQUARE_CHUNK_SIZE - CHUNK_PADDING

	# setting the generation seed to be the _global_seed parameter XOR'd with the hashed chunk coordinate/index.
	# Given the same _global_seed and the same chunk_coord, the generated asteroids will always be the same in the chunk.
	# Given that the _global_seed never changes, the same environment is always generated.
	# Changing the global seed will generate a completely new environment.
	_rng.seed = _global_seed ^ hash(chunk_coord)

	var sampling_region = Rect2()
	sampling_region.position = chunk_start
	sampling_region.end = chunk_end

	# here we generate the center points of the asteroids within the chunk.
	# They will all be within the sampling region and will be at least ASTEROID_SPACING_FACTOR
	# apart from one another. 
	var asteroid_center_points = poisson_disk_sampling(sampling_region)

	# For each of the center points, generate the polygon outline of the asteroid using a noise image
	for center_point in asteroid_center_points:
		# this will be the resulting border for each iteration of this for loop
		var asteroid_border_tiles = []

		# we want each asteroid to look different, so give the noise generation a random seed
		_detail_noise.seed = _rng.randi()

		# this is an "image" that has dimensions ASTEROID_BORDER_GENERATION_NUM_ANGLES x 1.
		# It is essential a very long, very thin, seamless image. Meaning, the start and end pixels are around the same value. 
		# It will, in a sense, be projected circularly around the circumference of the asteroid bounds to generate the surface of the asteroid.
		var noise_img = _detail_noise.get_seamless_image(ASTEROID_BORDER_GENERATION_NUM_ANGLES, 1)

		# use a separate noise that is continuous across the terrain to scale each asteroid.
		# this creates the effect of having neighboring asteroids likely to be similar in size,
		# at least as long as neighboring noise values are similar (meaning the frequency of the noise is low enough)
		var asteroid_scale = (_size_noise.get_noise_2dv(center_point) + 1) / 2

		# for each step around the circle
		for i in range(ASTEROID_BORDER_GENERATION_NUM_ANGLES):
			# the angle of the location we are at along the border
			var tile_angle = i * ASTEROID_BORDER_GENERATION_ANGULAR_INCREMENT

			# the noise used to offset the border circle to generate the bumpy surface.
			# Note: the image is grayscale so the first channel is used arbitrarily
			var noise = noise_img.get_pixel(i, 0).r

			# remap the noise from the range [0, 1] to [0.5, 1]
			noise = noise * 0.5 + 0.5

			# the resulting distance of the tile from the center of the asteroid
			var tile_distance = noise * MAX_ASTEROID_RADIUS * asteroid_scale

			# the location of the tile center in cartesian coordinates
			var tile_center_point = tile_distance * Vector2(cos(tile_angle), sin(tile_angle)) + center_point

			# the location of the tile in grid coordinates
			var new_tile_coord = Vector2i(tile_center_point / TILE_SIZE)

			# append this tile to the list of border tiles, but first checking that the tile is not repeated from the
			# previous iteration of this loop. This is possible because the angle increment is only the minimum for a change in 
			# tile coordinate to occur. It is possible to repeat tiles a couple times in a row. 
			if i == 0 or asteroid_border_tiles[-1] != new_tile_coord:
				asteroid_border_tiles.append(new_tile_coord)


		# Now we need to create the necessary nodes
		var asteroid = Asteroid.new()
		var rigid_body = RigidBody2D.new()

		rigid_body.mass = ASTEROID_MASS_PER_TILE * asteroid_border_tiles.size()

		asteroid.generate_mesh(asteroid_border_tiles, TILE_SIZE, center_point)
		asteroid_mesh_created.emit(asteroid.mesh_node.mesh)

		# The asteroid generate_mesh() function calculates a collision polygon that is a smoothed
		# version of the asteroid polygon border. Here, we are generating a series of convex hulls that, when composed together,
		# allow for fast collision calculations with the complex asteroid shape. 
		var convex_hulls = Geometry2D.decompose_polygon_in_convex(asteroid.collision_polygon)
		for hull in convex_hulls:
			var collision_shape := CollisionShape2D.new()
			collision_shape.shape = ConvexPolygonShape2D.new()
			collision_shape.shape.points = hull

			# add the new collision shape to the asteroid's rigidbody
			rigid_body.add_child(collision_shape)
		
		rigid_body.collision_layer = CollisionConstants.DEFAULT | CollisionConstants.ASTEROID
		rigid_body.collision_mask = CollisionConstants.DEFAULT | CollisionConstants.CHARACTER | CollisionConstants.ASTEROID

		asteroid.add_child(rigid_body)
		asteroid.position = center_point
		asteroid.rigid_body = rigid_body

		# add the asteroid we just generated to this Environment node as a child
		add_child(asteroid)
		asteroid = get_child(get_child_count() - 1)

		# Give the new asteroid a small amount of random movement to start with
		asteroid.rigid_body.apply_central_impulse(100 * (Vector2(_rng.randf(), _rng.randf()) * 2 - Vector2.ONE))
		asteroid.rigid_body.apply_torque_impulse(100 * (_rng.randf() * 2 - 1))

func _process(_delta: float) -> void:
	for child_idx in range(get_child_count()):
		var child := get_child(child_idx) as Asteroid
		asteroid_transform_updated.emit(child_idx, child.rigid_body.global_transform)

func _ready() -> void:
	_size_noise.seed = _global_seed
	const SIZE := 5
	const EXTENT := floori(SIZE / 2.0)

	for i in range(-EXTENT, EXTENT):
		for j in range(-EXTENT, EXTENT):
			generate_chunk(Vector2i(i, j))
