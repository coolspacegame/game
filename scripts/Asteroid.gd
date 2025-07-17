class_name Asteroid
extends Node2D

## determines the density of the asteroid
const ASTEROID_MASS_PER_TILE := 1000.0
const COLLIDER_SMOOTH_ITERATIONS = 2
const CollisionConstants := preload("res://scripts/CollisionConstants.gd")

var mesh_node: MeshInstance2D
var rigid_body: RigidBody2D
var _tile_coords: Dictionary
var _border_coords: Array
var _tile_size: Vector2


func _init():
	var m = MeshInstance2D.new()
	add_child(m)
	mesh_node = get_child(0)

	var r = RigidBody2D.new()
	add_child(r)
	rigid_body = get_child(1)


func _process(_delta: float) -> void:
	mesh_node.transform = rigid_body.transform


func initialize(tile_coords_in: Dictionary, border_coords_in: Array, tile_size_in: Vector2) -> void:
	_tile_coords = tile_coords_in.duplicate()
	_tile_size = tile_size_in
	_border_coords = border_coords_in.duplicate()
	rigid_body.mass = ASTEROID_MASS_PER_TILE * _tile_coords.size()

	rigid_body.collision_layer = CollisionConstants.DEFAULT | CollisionConstants.ASTEROID
	rigid_body.collision_mask = (
		CollisionConstants.DEFAULT | CollisionConstants.CHARACTER | CollisionConstants.ASTEROID
	)


func update_collider() -> void:
	# clear all collider children
	for child_node in rigid_body.get_children():
		rigid_body.remove_child(child_node)
		child_node.queue_free()

	# this will be the border polygon that forms the surface colliders that the player walks on
	var polygon := PackedVector2Array()

	# these square collider tiles will be used for detecting destruction of tiles
	for tile: Vector2i in _border_coords:
		var area := Area2D.new()
		var collision_shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = _tile_size
		collision_shape.shape = rect_shape
		collision_shape.position = _tile_size * Vector2(tile) + rect_shape.size / 2

		polygon.append(_tile_size * Vector2(tile) + rect_shape.size / 2)

		# add the new collision shape to the asteroid's rigidbody
		area.add_child(collision_shape)
		rigid_body.add_child(area)

	# smooth out the surface collider so it's easier to walk on
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
