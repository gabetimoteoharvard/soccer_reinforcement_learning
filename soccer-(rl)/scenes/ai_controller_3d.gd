extends AIController3D

var pos: Vector2
var kick_dir: Vector3
var kick_strength: float
var player_speed: float

func get_obs() -> Dictionary:
	
	var player_pos = _player.global_position
	var ball_pos = _player.ball.global_position
	var goalpost_pos = _player.goalpost.global_position
	
	# get ball to goal raycast 
	var rayc = _player.ball.goal_ray_cast
	rayc.look_at(goalpost_pos) 
	rayc.force_raycast_update()
	
	var goal_shot_clear = 1.0 if not rayc.is_colliding() else 0.0
	
	var obs = [player_pos.x, player_pos.z,
			   ball_pos.x, ball_pos.z,
			   goalpost_pos.x, goalpost_pos.z,
			   (goalpost_pos - ball_pos).normalized().x,  # extra: direction hint
			   (goalpost_pos - ball_pos).normalized().z,
			   goal_shot_clear]
			
	return {"obs": obs}
	
func get_reward() -> float:
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"target_location" : {
			"size": 2,
			"action_type": "continuous"
		},	
		"kick_direction" : {
			"size": 3,
			"action_type": "continuous"
		},
		"kick_strength" : {
			"size": 1,
			"action_type": "continuous"
		},
	}

func set_action(action) -> void:
	
	pos = Vector2(action["target_location"][0] * 10, action["target_location"][1] * 10)
	
	kick_dir = Vector3(action["kick_direction"][0], action["kick_direction"][1], action["kick_direction"][2]).normalized()
	
	kick_strength = clamp(action["kick_strength"][0]*3, 1.0, 3.0)
	
