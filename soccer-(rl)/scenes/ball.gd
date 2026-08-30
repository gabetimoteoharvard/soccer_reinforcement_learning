class_name Ball
extends RigidBody3D

@export var field: MeshInstance3D
@onready var goal_ray_cast = $RayCast3D

func _ready() -> void:
	reset()

	
	contact_monitor = true
	max_contacts_reported = 4
	
func reset():
	var dist = 0
	var x_
	var y_
	
	while dist < 0.5:
	
		x_ = field.global_position.x + randf_range(-4, 4)
		y_ = field.global_position.z + randf_range(-2.5, 2.5)
		
		dist = (Vector3(x_, 1.0, y_) - Vector3(field.global_position.x, 1.0, field.global_position.z) ).length()
	
	global_position.x = x_
	global_position.z = y_
	global_position.y = 1.0
	
	linear_velocity = Vector3(0,0,0)
	angular_velocity = Vector3(0,0,0)
	constant_force = Vector3(0,0,0)
	constant_torque = Vector3(0,0,0)
