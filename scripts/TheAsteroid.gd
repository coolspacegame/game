
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



var mesh_node: MeshInstance2D
var collision_shape: ConvexPolygonShape2D

func _init():
	var m = MeshInstance2D.new()
	add_child(m)
	mesh_node = get_child(0)

func generate_mesh(tile_coords: Array, square_tile_size: float, asteroid_origin: Vector2) -> void:
	# Generate two mesh triangles for every tile
	# TODO do this more efficiently, reuse vertices (use SurfaceTool.indices())
	# TODO maybe smooth out the mesh or add noise so it doesn't look blocky

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# var asteroid_origin3 = Vector3(asteroid_origin.x, asteroid_origin.y, 0)

	var vertices_list := PackedVector2Array()
	for tile_v in tile_coords:
		var v1 := square_tile_size * Vector2(tile_v.x, tile_v.y) - asteroid_origin
		var v2 := square_tile_size * Vector2(tile_v.x, tile_v.y + 1) - asteroid_origin
		var v3 := square_tile_size * Vector2(tile_v.x + 1, tile_v.y + 1) - asteroid_origin
		var v4 := square_tile_size * Vector2(tile_v.x + 1, tile_v.y) - asteroid_origin

		st.add_vertex(Vector3(v1.x, v1.y, 0.0))
		st.add_vertex(Vector3(v2.x, v2.y, 0.0))
		st.add_vertex(Vector3(v3.x, v3.y, 0.0))
		st.add_vertex(Vector3(v1.x, v1.y, 0.0))
		st.add_vertex(Vector3(v3.x, v3.y, 0.0))
		st.add_vertex(Vector3(v4.x, v4.y, 0.0))

		vertices_list.append(v1)
		vertices_list.append(v2)
		vertices_list.append(v3)
		vertices_list.append(v4)
	
	st.index()

	# Piece together the vertices to make the mesh
	# var arr_mesh = ArrayMesh.new()
	# var arrays = []
	# arrays.resize(Mesh.ARRAY_MAX)
	# arrays[Mesh.ARRAY_VERTEX] = vertices_list

	# arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_node.mesh = st.commit()

	# collision_shape = CollisionShape2D.new()
	collision_shape = ConvexPolygonShape2D.new()
	collision_shape.set_point_cloud(vertices_list)
