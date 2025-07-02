extends Node2D

@export var asteroid_texture: Texture2D


func _on_asteroid_created(asteroid_mesh: Mesh):

	var mesh_copy = asteroid_mesh.duplicate(true)

	var new_child = MeshInstance2D.new()
	new_child.texture = asteroid_texture
	new_child.mesh = mesh_copy
	# new_child.transform = asteroid_transform
	# new_child.position *= 0.001
	# new_child.scale *= 0.001

	add_child(new_child)

func _on_asteroid_transform_updated(idx: int, asteroid_transform: Transform2D):
	var c = get_child(idx) as Node2D
	c.transform = asteroid_transform
