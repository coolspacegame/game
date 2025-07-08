extends MeshInstance2D

const BOOSTERS_ENABLED_COLOR: Color = Color.LIGHT_GREEN
const BOOSTERS_DISABLED_COLOR: Color = Color.PALE_VIOLET_RED

func _on_the_character_boosters_enabled_updated(enabled:bool) -> void:
    if enabled:
        self_modulate = BOOSTERS_ENABLED_COLOR
    else:
        self_modulate = BOOSTERS_DISABLED_COLOR


