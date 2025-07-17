class_name Asteroid
extends Node2D

## determines the density of the asteroid
const ASTEROID_MASS_PER_TILE := 1000.0
const COLLIDER_SMOOTH_ITERATIONS = 1
const CollisionConstants := preload("res://scripts/CollisionConstants.gd")

var mesh_node: MeshInstance2D
var rigid_body: RigidBody2D
var _tile_coords: Dictionary
var _tile_size: Vector2
var _dirty = false


func queue_destroy_tile(tile_area: Area2D):
	var pos_scaled = tile_area.position / _tile_size
	var tile_coord = Vector2i(floori(pos_scaled.x), floori(pos_scaled.y))
	_tile_coords.erase(tile_coord)
	_dirty = true


func _destroy_queued_tiles():
	if _dirty:
		update_collider()
		update_mesh()
		_dirty = false


func _init():
	var m = MeshInstance2D.new()
	add_child(m)
	mesh_node = get_child(0)

	var r = RigidBody2D.new()
	add_child(r)
	rigid_body = get_child(1)


func _process(_delta: float) -> void:
	mesh_node.transform = rigid_body.transform


func initialize(tile_coords_in: Dictionary, tile_size_in: Vector2) -> void:
	_tile_coords = tile_coords_in.duplicate()
	_tile_size = tile_size_in
	rigid_body.mass = ASTEROID_MASS_PER_TILE * _tile_coords.size()

	rigid_body.collision_layer = CollisionConstants.DEFAULT | CollisionConstants.ASTEROID
	rigid_body.collision_mask = (
		CollisionConstants.DEFAULT | CollisionConstants.CHARACTER | CollisionConstants.ASTEROID
	)


func sort_tiles_by_angle(a: Vector2i, b: Vector2i) -> bool:
	return atan2(a.y, a.x) < atan2(b.y, b.x)


func update_collider() -> void:
	# clear all collider children
	for child_node in rigid_body.get_children():
		rigid_body.remove_child(child_node)
		child_node.queue_free()

	# this will be the border polygon that forms the surface colliders that the player walks on
	var polygon := PackedVector2Array()

	# in this section we are going to do the "Moore neighborhood" algorithm to find the border polygon
	# https://en.wikipedia.org/wiki/Moore_neighborhood

	# first step is to find the bounds of the asteroid
	var bounds_min = Vector2i(1 << 32, 1 << 32)
	var bounds_max = -1 * bounds_min
	for tile in _tile_coords:
		if tile.x < bounds_min.x:
			bounds_min.x = tile.x
		if tile.y < bounds_min.y:
			bounds_min.y = tile.y
		if tile.x > bounds_max.x:
			bounds_max.x = tile.x
		if tile.y > bounds_max.y:
			bounds_max.y = tile.y

	# next we are looking for the starting point, the first tile that is occupied going frorm bottom-up and left-right
	#  Note: the single-letter variable names primarily take from the algorithm listed on the wikipedia page
	# s: starting point
	# b: 'backtrack' point, or the point from which the current point in consideration was entered
	# c: current point under consideration
	# p: current point on the polygon/boundary
	var s = Vector2i.ZERO
	var b = s
	for y in range(bounds_max.y, bounds_min.y - 1, -1):
		var found = false
		for x in range(bounds_min.x, bounds_max.x + 1, 1):
			if Vector2i(x, y) in _tile_coords:
				s = Vector2i(x, y)
				b = Vector2(x, y + 1) if x == bounds_min.x else Vector2(x - 1, y)
				found = true
				break

		if found:
			break

	assert(_tile_coords.size() > 0)

	var border: Array[Vector2i] = []
	var p = s
	border.append(s)

	var rotate_eighth := func(center: Vector2i, current: Vector2i) -> Vector2i:
		var difference = Vector2(current - center)
		# var at_tile_center =  difference + 0.5 * Vector2.ONE
		var rotated_to_next = difference.rotated(PI / 4)

		return Vector2i(roundi(rotated_to_next.x), roundi(rotated_to_next.y)) + center

	var c = rotate_eighth.call(p, b)

	while c != s:
		if c in _tile_coords:
			border.append(c)
			b = p
			p = c
		else:
			b = c

		c = rotate_eighth.call(p, b)

	# these square collider tiles will be used for detecting destruction of tiles
	for tile: Vector2i in border:
		var area := Area2D.new()
		area.collision_layer = CollisionConstants.ASTEROID_TILE
		var collision_shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = _tile_size
		collision_shape.shape = rect_shape
		area.position = _tile_size * Vector2(tile) + rect_shape.size / 2

		polygon.append(_tile_size * Vector2(tile) + rect_shape.size / 2)

		# add the new collision shape to the asteroid's rigidbody
		area.add_child(collision_shape)
		rigid_body.add_child(area)
		var body_collision_shape := collision_shape.duplicate() as CollisionShape2D
		body_collision_shape.position = area.position

	# smooth out the surface collider so it's easier to walk on
	# https://www.cs.unc.edu/~dm/UNC/COMP258/LECTURES/Chaikins-Algorithm.pdf
	for _i in range(COLLIDER_SMOOTH_ITERATIONS):
		var new_poly = polygon.duplicate()

		for j in range(polygon.size()):
			var p0 = polygon[j]
			var p1 = polygon[(j + 1) % polygon.size()]
			var new_p0 = p0.lerp(p1, 0.25)
			var new_p1 = p0.lerp(p1, 0.75)

			new_poly[j] = new_p0
			new_poly[(j + 1) % new_poly.size()] = new_p1
		polygon = new_poly

	# add the surface polygon to the rigidbody as a collision shape
	var collision_polygon := CollisionPolygon2D.new()
	collision_polygon.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	collision_polygon.polygon = polygon
	rigid_body.add_child(collision_polygon)


func update_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv = 0.0
	for i in range(_tile_coords.size()):
		var quad := Rect2i()
		quad.position = _tile_coords.keys()[i]
		quad.size = Vector2i.ONE
		var v1 := _tile_size * Vector2(quad.position)
		var v2 := _tile_size * Vector2(quad.position + quad.size * Vector2i(1, 0))
		var v3 := _tile_size * Vector2(quad.position + quad.size * Vector2i(1, 1))
		var v4 := _tile_size * Vector2(quad.position + quad.size * Vector2i(0, 1))

		st.set_uv(Vector2(uv, 0))

		uv += 1.0 / (_tile_coords.size() as float)

		st.add_vertex(Vector3(v1.x, v1.y, 0.0))
		st.add_vertex(Vector3(v2.x, v2.y, 0.0))
		st.add_vertex(Vector3(v3.x, v3.y, 0.0))

		st.add_vertex(Vector3(v1.x, v1.y, 0.0))
		st.add_vertex(Vector3(v3.x, v3.y, 0.0))
		st.add_vertex(Vector3(v4.x, v4.y, 0.0))

	st.index()
	mesh_node.mesh = st.commit()


func _physics_process(_delta: float) -> void:
	_destroy_queued_tiles()
