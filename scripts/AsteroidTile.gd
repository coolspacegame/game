class_name AsteroidTile
extends Area2D

signal destroyed()

func _init() -> void:
	collision_layer = 0b1000
	collision_mask = 0b0

func emit_destroyed():
	destroyed.emit()
