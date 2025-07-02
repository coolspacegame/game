extends MeshInstance2D


func _on_character_position_updated(p: Vector2):
    position = p

func _on_character_rotation_updated(r: float):
    rotation = r
