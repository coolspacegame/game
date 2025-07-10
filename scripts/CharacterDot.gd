extends MeshInstance2D

## This function is used to update the minimap player icon to the same position and rotation as that of the player character
func _on_character_transform_updated(character_body_transform: Transform2D):
    position = character_body_transform.get_origin()
    rotation = character_body_transform.get_rotation()
