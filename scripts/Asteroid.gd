
class_name Asteroid
extends Node2D

## determines the density of the asteroid
const ASTEROID_MASS_PER_TILE := 1000.0
const CollisionConstants := preload("res://scripts/CollisionConstants.gd")

var mesh_node: MeshInstance2D
var rigid_body: RigidBody2D
var collision_quads: Array[Rect2]
var _tile_coords: Dictionary
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

func initialize(tile_coords_in: Dictionary, tile_size_in: Vector2) -> void:
	_tile_coords = tile_coords_in.duplicate()
	_tile_size = tile_size_in
	rigid_body.mass = ASTEROID_MASS_PER_TILE * _tile_coords.size()

	rigid_body.collision_layer = CollisionConstants.DEFAULT | CollisionConstants.ASTEROID
	rigid_body.collision_mask = CollisionConstants.DEFAULT | CollisionConstants.CHARACTER | CollisionConstants.ASTEROID

func update_collider() -> void:
	var working_tiles = _tile_coords.duplicate()

	if working_tiles.size() == 0:
		return

	var current_rect := Rect2i()
	current_rect.position = working_tiles.keys()[0]
	current_rect.size = Vector2i.ONE
	working_tiles.erase(current_rect.position)

	var quads := [] as Array[Rect2i]

	while working_tiles.size() > 0:
		var expansion_right := current_rect
		expansion_right.position += current_rect.size * Vector2i.RIGHT
		expansion_right.size = Vector2i(1, current_rect.size.y)

		var expansion_down := current_rect
		expansion_down.position += current_rect.size * Vector2i.DOWN
		expansion_down.size = Vector2i(current_rect.size.x, 1)

		var expansion_left := current_rect
		expansion_left.position += Vector2i.LEFT
		expansion_left.size = Vector2i(1, current_rect.size.y)

		var expansion_up := current_rect
		expansion_up.position += Vector2i.UP
		expansion_up.size = Vector2i(current_rect.size.x, 1)

		var found_expansion = false

		for expansion in [expansion_right, expansion_down, expansion_left, expansion_up]:
			var expansion_is_valid = true

			for i in range(expansion.position.x, expansion.end.x, 1):
				for j in range(expansion.position.y, expansion.end.y, 1):
					var v = Vector2i(i, j)

					if v not in working_tiles:
						expansion_is_valid = false
			
			if expansion_is_valid:

				for i in range(expansion.position.x, expansion.end.x, 1):
					for j in range(expansion.position.y, expansion.end.y, 1):
						var v = Vector2i(i, j)
						working_tiles.erase(v)

				current_rect = current_rect.merge(expansion)
				found_expansion = true
				break
		
		if not found_expansion:
			quads.append(current_rect)

			current_rect.position = working_tiles.keys()[0]
			current_rect.size = Vector2i.ONE
			working_tiles.erase(current_rect.position)
	

	collision_quads = []
	for quad in quads:
		var collision_quad = Rect2()
		collision_quad.position = _tile_size * Vector2(quad.position)
		collision_quad.size = _tile_size * Vector2(quad.size)
		collision_quads.append(collision_quad)

	
	for child_node in rigid_body.get_children():
		rigid_body.remove_child(child_node)
		child_node.queue_free()

	for quad: Rect2 in collision_quads:
		var collision_shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = quad.size
		collision_shape.shape = rect_shape
		collision_shape.position = quad.position + quad.size / 2

		# add the new collision shape to the asteroid's rigidbody
		rigid_body.add_child(collision_shape)

func update_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv = 0.0
	for i in range(_tile_coords.size()):
		var quad := Rect2i()
		quad.position = _tile_coords.keys()[i]
		quad.size = Vector2i.ONE
		var v1 := _tile_size *  Vector2(quad.position)
		var v2 := _tile_size *  Vector2(quad.position + quad.size * Vector2i(1, 0))
		var v3 := _tile_size *  Vector2(quad.position + quad.size * Vector2i(1, 1))
		var v4 := _tile_size *  Vector2(quad.position + quad.size * Vector2i(0, 1))

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

