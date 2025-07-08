
class_name TheAsteroid
extends Node2D

class GenerateParameters:
	# var noise_source: Noise
	var noise_min: float
	var noise_max: float
	var square_tile_size: float

class Tile:
	pass

# Empty, as in your C# code



var collision_shapes: Array[CollisionShape2D]
var mesh_node: MeshInstance2D
var rigid_body: RigidBody2D

var collision_polygon: PackedVector2Array
var border_tiles: Dictionary
var tile_size: float


func _on_tile_destroyed(tile: AsteroidTile):
	rigid_body.remove_child(tile)
	tile.queue_free()

	update_asteroid()


func _init():
	var m = MeshInstance2D.new()
	var r = RigidBody2D.new()


	r.add_child(m)
	add_child(r)
	rigid_body = get_child(0)
	mesh_node = rigid_body.get_child(0)
	rigid_body.collision_layer = 0b101
	rigid_body.collision_mask = 0b111

func update_asteroid() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var border_points: PackedVector2Array = []

	# var collision_shapes := []

	for child in rigid_body.get_children():
		if child is AsteroidTile:
			border_points.append(child.position)
		elif child is CollisionShape2D:
			rigid_body.remove_child(child)
			child.queue_free()

	for p in border_points:
		st.add_vertex(Vector3(p.x, p.y, 0))

	var indices = Geometry2D.triangulate_polygon(border_points)

	for i in range(indices.size() - 1, -1, -1):
		st.add_index(indices[i])

	mesh_node.mesh = st.commit()

	var num_smooth_iterations = 5
	for _i in range(num_smooth_iterations):
		var new_poly = border_points.duplicate()

		for j in range(border_points.size()):
			var p0 = border_points[j]
			var p1 = border_points[(j + 1) % border_points.size()]
			var new_p0 = p0.lerp(p1, 0.25)
			var new_p1 = p0.lerp(p1, 0.75)

			new_poly[j] = new_p0
			new_poly[(j + 1) % new_poly.size()] = new_p1

		border_points = new_poly

	collision_polygon = border_points


	var p = collision_polygon
	var hulls = Geometry2D.decompose_polygon_in_convex(p)
	for hull in hulls:
		var collision_shape := CollisionShape2D.new()
		collision_shape.shape = ConvexPolygonShape2D.new()
		collision_shape.shape.points = hull
		rigid_body.add_child(collision_shape)


func generate_mesh(tile_coords: Array, square_tile_size: float, asteroid_origin: Vector2) -> void:
	tile_size = square_tile_size

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


	var border_points: PackedVector2Array = []

	for tile_v in tile_coords:
		var center := square_tile_size * (Vector2(tile_v.x, tile_v.y) + 0.5 * Vector2.ONE) - asteroid_origin
		border_points.append(center)

	for p in border_points:
		st.add_vertex(Vector3(p.x, p.y, 0))

	var indices = Geometry2D.triangulate_polygon(border_points)

	for i in range(indices.size() - 1, -1, -1):
		st.add_index(indices[i])

	mesh_node.mesh = st.commit()

	for point in border_points:
		var t = AsteroidTile.new()
		t.transform = Transform2D().translated(point)

		t.add_child(CollisionShape2D.new())
		# s.position = point
		rigid_body.add_child(t)
		t = rigid_body.get_child(rigid_body.get_child_count() - 1)
		t.monitoring = true
		t.monitorable = true

		t.destroyed.connect(self._on_tile_destroyed)

		var s := t.get_child(t.get_child_count() - 1) as CollisionShape2D
		var r := RectangleShape2D.new()
		r.size = square_tile_size * Vector2.ONE
		s.shape = r
	# MeshConvexDecompositionSettings.


	var num_smooth_iterations = 5

	for _i in range(num_smooth_iterations):
		var new_poly = border_points.duplicate()

		for j in range(border_points.size()):
			var p0 = border_points[j]
			var p1 = border_points[(j + 1) % border_points.size()]
			var new_p0 = p0.lerp(p1, 0.25)
			var new_p1 = p0.lerp(p1, 0.75)

			new_poly[j] = new_p0
			new_poly[(j + 1) % new_poly.size()] = new_p1

		border_points = new_poly
	collision_polygon = border_points

	rigid_body.mass = 2000.0 * tile_coords.size()
	rigid_body.global_position = asteroid_origin

	var p = collision_polygon
	var hulls = Geometry2D.decompose_polygon_in_convex(p)
	for hull in hulls:
		var collision_shape := CollisionShape2D.new()
		# var collision_polygon = CollisionPolygon2D.new()
		# collision_polygon.pol
		collision_shape.shape = ConvexPolygonShape2D.new()
		collision_shape.shape.points = hull
		rigid_body.add_child(collision_shape)

	# rigid_body.add_child(asteroid)
	# add_child(rigid_body)
	rigid_body.apply_central_impulse(100 * (Vector2(randf(), randf()) * 2 - Vector2.ONE))
	rigid_body.apply_torque_impulse(100 * (randf() * 2 - 1))
