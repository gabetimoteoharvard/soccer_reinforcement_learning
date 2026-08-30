extends Area3D

@export var player: CharacterBody3D


func _on_body_entered(body: Node3D) -> void:
	

	if body is Player:
		body.ai_controller.done = true
		body.ai_controller.needs_reset = true

		
	
	if body is Ball:
		player.ai_controller.done = true
		player.ai_controller.needs_reset = true
		

	

		
	
