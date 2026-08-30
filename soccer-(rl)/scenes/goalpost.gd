extends Node3D


@export var player: CharacterBody3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Ball:
		print("GOAL")
		player.ai_controller.done = true
		player.ai_controller.needs_reset = true
		
		player.ai_controller.reward += 100.0
		
