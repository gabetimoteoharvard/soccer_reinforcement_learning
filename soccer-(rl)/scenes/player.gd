class_name Player
extends CharacterBody3D

var curr_target = null

#movement parameters
var player_wobble = false
var wobble_dir = "left"
@export var wobble_speed := 3
var last_rotation_z = 0

#speed parameters
@export var rotate_speed = 2
var player_speed: float
@export var MAX_SPEED = 1.6

# environment paramaters
@onready var facing_dir = $RayCast3D

@export var ball: RigidBody3D
@export var goalpost: Node3D
@export var field: MeshInstance3D

@export var vision_distance := 10
	
# ball kick timer
var kick_cooldown_frames := 0
const KICK_COOLDOWN_DURATION := 30  # number of physics frames before another kick can register

# ball reward parameters
var MIN_DISTANCE_REWARD = 0.05
var check_reward = false
var check_reward_timer = 10
var position_at_touch

var has_kicked_ball : bool



# reinforcement learning parameters
@onready var ai_controller = $AIController3D

var prev_distance_ball: float
var prev_distance_goal: float
var reward_scale = 0.3

var episode_time := 0.0
const MAX_EPISODE_TIME := 30.0

var count = 0
var GOAL_THRESHOLD = 0.5



func _ready():
	ai_controller.init(self)
	

	
	player_speed = 1.4
	has_kicked_ball = false

	prev_distance_ball = (ball.global_position - global_position).length()
	prev_distance_goal = (goalpost.global_position - ball.global_position).length()
	
	
func _physics_process(delta: float) -> void:
	
	ball.goal_ray_cast.look_at(goalpost.global_position)
	ball.goal_ray_cast.force_raycast_update()

	
	episode_time += delta
	
	if episode_time >= MAX_EPISODE_TIME:
		
		episode_time = 0.0
		
		
		ai_controller.reward -= 10.0
			
		ai_controller.done = true
		ai_controller.needs_reset = true
	
	if ai_controller.needs_reset:
		
		ai_controller.reset()
		ball.reset()
		reset()
		return
	
	
	velocity += get_gravity() * delta
	
	if ai_controller.heuristic != "human":
		set_target(ai_controller.pos)

	
	movement(delta)	#moves to a target if one exists
	wobble(delta) #wobbling movement when moving
	
	ball_kick_cooldown() # ball cooldown for kicking
	
	get_ball_distance_reward() # rewards for moving closer to ball
	give_ball_reward()
	
	move_and_slide()
	detect_ball_collision()
	
func movement(delta):
	if curr_target == null: # if there is no current target, set our velocity to be zero, and return
		velocity.x = 0
		velocity.z = 0
		return
	
	#player wobbles while moving
	player_wobble = true
	
	#vector we want our ray cast to be
	var target_vector = (Vector3(curr_target.x, global_position.y, curr_target.y) - global_position).normalized() 
	rotate_self(target_vector, delta)
	
	#adjust our player velocity
	var velocity_dir = (target_vector)*player_speed
	velocity.x = velocity_dir.x
	velocity.z = velocity_dir.z
	
	#if the difference between the target and our position is small enough (tolerance of 0.07), we have reached the target
	var diff = Vector2(global_position.x , global_position.z) - curr_target
	if sqrt(diff.x * diff.x + diff.y * diff.y) <= 0.07:
		player_wobble = false
		curr_target = null
	
func wobble(delta):
	
	if not player_wobble:
		
		last_rotation_z = 0 #set our last rotation to 0 
		
		#smooth stop wobbling
		if rotation.z != 0:
			if rotation.z < 0 :
				rotation.z = min(0, wobble_speed*delta + rotation.z)
			else:
				rotation.z = max(0, -wobble_speed*delta + rotation.z)	
		return

		
	if wobble_dir == "left": #wobble to the left
		rotation.z = rotation.z + wobble_speed*delta
		if rotation.z >= deg_to_rad(30):
			wobble_dir = "right"
			
	if wobble_dir == "right": #wobble to the right
		rotation.z = rotation.z - wobble_speed*delta
		if rotation.z <= deg_to_rad(-30):
			wobble_dir = "left"
			
	#once direction changes, do a little hop
	if (sign(rotation.z) != sign(last_rotation_z)) and is_on_floor():
		velocity.y = 1
	
	last_rotation_z = rotation.z #update our last rotation
	
func rotate_self(target_vector, delta=1):
	"""Makes a small rotation towards a target_vector"""
	
	var current_facing = facing_dir.global_transform.basis.z.normalized() #vector of our ray cast
	
	var angle = atan2(target_vector.x, target_vector.z) - atan2(current_facing.x, current_facing.z)
	angle = rad_to_deg(wrapf(angle, -PI, PI))
	
	
	#if the angle is higher than 1 (our tolerance threshold), rotate character
	
	if abs(angle) > 2.0:

		#take cross product of vectors to determine what direction to turn
		var cross_2d = current_facing.x*target_vector.z - current_facing.z*target_vector.x
		
		if cross_2d >= 0:
			rotation.y = rotation.y - rotate_speed*delta
		else:
			rotation.y = rotation.y + rotate_speed*delta
		
		return false
	return true

func ball_kick_cooldown():
	if kick_cooldown_frames > 0:
		kick_cooldown_frames -= 1

	return
	
func detect_ball_collision():
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is Ball and kick_cooldown_frames <= 0:
			kick_ball()  
		
func kick_ball():
		
	var force = ai_controller.kick_dir * ai_controller.kick_strength # kick  chosen by AI
	
	ball.apply_central_impulse(force)
	
	check_reward = true
	position_at_touch = ball.global_position
	
	kick_cooldown_frames = KICK_COOLDOWN_DURATION
	

	return

func give_ball_reward():
	if check_reward:
		check_reward_timer -= 1
		
		if check_reward_timer == 0:
			
			check_reward = false
			check_reward_timer = 10
			
			var ball_displac = (ball.global_position - position_at_touch).length()
			
			if ball_displac >= MIN_DISTANCE_REWARD:
				ai_controller.reward += 1.0
				
			
				
				has_kicked_ball = true
				
	return
	
func reset():
	ai_controller.zero_reward()
	
	
	global_position.x = field.global_position.x 
	global_position.z = field.global_position.z
	global_position.y = 1.0
	
	prev_distance_goal = (goalpost.global_position - ball.global_position).length()
	prev_distance_ball = (ball.global_position - global_position).length()
	
	has_kicked_ball = false
	
	kick_cooldown_frames = 0
	episode_time = 0.0
	
func set_target(pos: Vector2):
	var curr_target_x = clamp(pos.x, global_position.x - vision_distance, global_position.x + vision_distance)
	var curr_target_y = clamp(pos.y, global_position.z - vision_distance, global_position.z + vision_distance)
	
	curr_target = Vector2(curr_target_x, curr_target_y)
	return

func get_ball_distance_reward():
	if has_kicked_ball:
		return
		
	if ball.linear_velocity.length() > 0.15:
		prev_distance_ball = (ball.global_position - global_position).length()  # resync, don't penalize
		return
	
	var current_distance = (ball.global_position - global_position).length()
	var delta_distance = prev_distance_ball - current_distance
	ai_controller.reward += delta_distance * reward_scale
	
	
	prev_distance_ball = current_distance

func get_goal_distance_reward():
	
	
	var current_distance = (goalpost.global_position - ball.global_position).length()
	
	if current_distance <= GOAL_THRESHOLD:
		prev_distance_goal = current_distance
		return  # too close to farm — only scoring itself pays off from here
		
	var delta_distance = prev_distance_goal - current_distance
	ai_controller.reward += 3.0 * delta_distance * reward_scale
	

	prev_distance_goal = current_distance
