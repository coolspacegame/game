extends VBoxContainer

@export var _asteroid_texture: Texture2D
var _character_indicator_node: Node2D
var _asteroid_indicators_node: Node2D
var _minimap_camera_node: Node2D


func _ready() -> void:
	# TODO this probably isn't the best way to reference great-great-grandchildren nodes.
	# If the path changes, we will need to update these lines
	_character_indicator_node = \
		$BottomRow/MinimapPanelContainer/MinimapSubViewportContainer/SubViewport/MinimapWorld/CharacterIndicator as Node2D
	_asteroid_indicators_node = \
		$BottomRow/MinimapPanelContainer/MinimapSubViewportContainer/SubViewport/MinimapWorld/AsteroidIndicators as Node2D
	_minimap_camera_node = \
		$BottomRow/MinimapPanelContainer/MinimapSubViewportContainer/SubViewport/MinimapWorld/MinimapCamera as Node2D

func _process(_delta: float) -> void:
	($FPSCounter as Label).text = "FPS: %d" % Engine.get_frames_per_second()

func _on_character_transform_updated(character_body_transform: Transform2D):
	_character_indicator_node.position = character_body_transform.get_origin()
	_minimap_camera_node.position = character_body_transform.get_origin()
	_character_indicator_node.rotation = character_body_transform.get_rotation()

func _on_asteroid_mesh_created(asteroid_mesh: Mesh):

	# create a copy of the asteroid mesh, and create a new node to attach it to for the minimap
	var mesh_copy = asteroid_mesh.duplicate()
	var new_child = MeshInstance2D.new()

	# use the predefined texture as well as the mesh we duplicated
	new_child.texture = _asteroid_texture
	new_child.mesh = mesh_copy

	_asteroid_indicators_node.add_child(new_child)

func _on_asteroid_transform_updated(child_index: int, asteroid_transform: Transform2D):
	# There might be a better way of identifying the asteroids, but right now it's assumed
	# that the caller (or signal emitter) is keeping track if which order the asteroids were added in.
	# This works as long as the order of the children on this node stays the same.
	# TODO Might be a problem if asteroids are destroyed
	var target_asteroid = _asteroid_indicators_node.get_child(child_index) as MeshInstance2D

	target_asteroid.transform = asteroid_transform
