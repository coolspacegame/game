
class_name Asteroid
extends Node2D

class GenerateParameters:
	# var noise_source: Noise
	var noise_min: float
	var noise_max: float
	var square_tile_size: float

class Tile:
	pass

var mesh_node: MeshInstance2D
var rigid_body: RigidBody2D
var collision_polygon: PackedVector2Array

func _init():
	var m = MeshInstance2D.new()
	add_child(m)
	mesh_node = get_child(0)

func _process(_delta: float) -> void:
	mesh_node.transform = rigid_body.transform

func generate_mesh(tile_coords: Array, square_tile_size: float, asteroid_origin: Vector2) -> void:

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

	var num_smooth_iterations = 3

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
