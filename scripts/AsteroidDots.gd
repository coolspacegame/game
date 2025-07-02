extends Node2D

@export var asteroid_texture: Texture2D

func _on_asteroid_updated(asteroid_mesh: Mesh, asteroid_transform: Transform2D):

    var mesh_copy = asteroid_mesh.duplicate(true)

    var new_child = MeshInstance2D.new()
    new_child.texture = asteroid_texture
    new_child.mesh = mesh_copy
    new_child.transform = asteroid_transform
    # new_child.position *= 0.001
    # new_child.scale *= 0.001

    add_child(new_child)
