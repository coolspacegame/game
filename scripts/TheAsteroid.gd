
class_name TheAsteroid
extends Node2D

class GenerateParameters:
	var noise_source: Noise
	var noise_min: float
	var noise_max: float
	var square_tile_size: float

class Tile:
	pass

# Empty, as in your C# code



var _mesh_node: MeshInstance2D

func _init():
	var m = MeshInstance2D.new()
	add_child(m)
	_mesh_node = get_child(0)

func generate_mesh(tile_coords: Array, square_tile_size: float, asteroid_origin: Vector2) -> void:
	# Generate two mesh triangles for every tile
	# TODO do this more efficiently, reuse vertices
	# TODO maybe smooth out the mesh or add noise so it doesn't look blocky

	var vertices_list = PackedVector2Array()
	for tile_v in tile_coords:
		vertices_list.append(square_tile_size * Vector2(tile_v.x, tile_v.y) - asteroid_origin)
		vertices_list.append(square_tile_size * Vector2(tile_v.x, tile_v.y + 1) - asteroid_origin)
		vertices_list.append(square_tile_size * Vector2(tile_v.x + 1, tile_v.y + 1) - asteroid_origin)
		vertices_list.append(square_tile_size * Vector2(tile_v.x, tile_v.y) - asteroid_origin)
		vertices_list.append(square_tile_size * Vector2(tile_v.x + 1, tile_v.y + 1) - asteroid_origin)
		vertices_list.append(square_tile_size * Vector2(tile_v.x + 1, tile_v.y) - asteroid_origin)

	# Piece together the vertices to make the mesh
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices_list

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_node.mesh = arr_mesh
