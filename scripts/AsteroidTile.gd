class_name AsteroidTile
extends Area2D


func _init() -> void:
	add_child(CollisionShape2D.new())

	var shape = get_child(0)
	var r = RectangleShape2D.new()
	r.size = Vector2.ONE
	shape.shape = r
	collision_layer = 0b1000
	collision_mask = 0b0
