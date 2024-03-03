extends RigidBody2D

const UNITS_TO_PIXELS : float = 3.2
const PIXELS_TO_UNITS : float = 1/3.2

@export var isActive : bool
#@onready var dice_rb = $"."
@onready var dice_rb = $"."
@onready var dice_collision_shape = $CollisionShape2D2
#@onready var area_collision_shape = $CollisionShape2D
#@onready var dice_collision_shape = $RigidBody2D/CollisionShape2D
@onready var timer = $Timer2
@onready var dice_radius = dice_collision_shape.shape.radius
var is_moving = false
var timed_out = false
var arrow_scene = preload("res://Scenes/arrow.tscn")
var calculate_power = true;
var display_arrow = true
var update_origin = false
var old_transform = null
var rb_offset = null


# Called when the node enters the scene tree for the first time.
func _ready():
	mouse_entered.connect(dice_mouse_entered)
	mouse_exited.connect(dice_mouse_exited)
	call_deferred("load_dice_deferred")
	
	var arrow = arrow_scene.instantiate()
	add_child(arrow)		
	
	if isActive:
		call_deferred("active_dice_deferred")
		
	print("Old Area", transform)	
	print("Old RB ", dice_rb.transform)	
	old_transform = dice_rb.transform.origin
	rb_offset = dice_rb.transform.origin - transform.origin 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if !isActive:
		if(has_node("Arrow")): 			
			get_node("Arrow").hide()		
	
	if isActive && display_arrow:
		if(has_node("Arrow")): 			
			get_node("Arrow").show()	
										
									
	if isActive:
		var current_angle = dice_rb.transform.origin.angle_to_point(get_local_mouse_position())
		var dice_centre_position = dice_rb.transform.origin	
		var current_point_on_circle = calculate_circle_point(dice_radius, current_angle, dice_centre_position)
		var distance_from_dice = (get_local_mouse_position() - dice_centre_position).length() - (dice_radius * UNITS_TO_PIXELS)	
		
		print("Dice Centre ", dice_centre_position)
		print("Global ", get_global_mouse_position())
		print("Local ", get_local_mouse_position())
		print("Area ", transform.origin)		
		print("RB ", dice_rb.transform.origin)
		
		#line.add_point(get_local_mouse_position() / 2)
		#3.2 pixels = 1 unit
		#line.add_point(current_point_on_circle * UNITS_TO_PIXELS)
		
		#print(get_local_mouse_position())
		
		if(has_node("Arrow")): 
			get_node("Arrow").position = current_point_on_circle * UNITS_TO_PIXELS
			get_node("Arrow").rotation = current_angle	
		
		if Input.is_action_just_pressed("ui_accept"):
			move_dice(dice_centre_position)								
			#is_active_dice.emit(self)
			
		#print("RB ", dice_rb.transform.origin)
		#print("Area2D ", transform.origin)
		
		transform.origin = dice_rb.transform.origin - rb_offset
		print("New Area", transform.origin)
			
		if timed_out && abs(dice_rb.linear_velocity.x) < 10 && abs(dice_rb.linear_velocity.y) < 10:
			#TODO Lerp values for smoother finish
			#dice_rb.linear_velocity = Vector2.ZERO
			
			#TODO Bug: Breaks after first pass (need to get/set values)
			#var newtransform = dice_rb.transform.origin - old_transform
			#print("Current RB: ", dice_rb.transform.origin)
			#print("Current Area: ", transform.origin)
			#print("Offset: ", rb_offset)
			#print("new RB - offset", dice_rb.transform.origin - rb_offset)					
			#transform.origin = dice_rb.transform.origin - rb_offset
			#print("New Area", transform.origin)
			
			
			#print("Transform Calc: ", transform.origin, "+= (", dice_rb.transform.origin, "-", old_transform)
			#transform.origin += Vector2(newtransform)
			#transform.origin = dice_rb.transform.origin - rb_offset
			#print("Updated Transform: ", transform.origin)
			#print("New Old RB: ", dice_rb.transform.origin)			
			#old_transform = dice_rb.transform.origin			
			#SignalManager.active_dice_stationary.emit("show")		
			calculate_power = true
			timed_out = false		
			display_arrow = true		
		
		if(calculate_power): 
			SignalManager.power_value.emit(clampf((clampf((get_local_mouse_position() - dice_centre_position).length(), dice_collision_shape.shape.radius * 3.2, INF) - (dice_collision_shape.shape.radius * 3.2)) * 10, 0, 3000))

func calculate_circle_point(radius : float, angle : float, offset : Vector2) -> Vector2:
	var point_x_on_circle : float = radius * cos(angle)
	var point_y_on_circle : float = radius * sin(angle)
	var point_on_circle : Vector2 = (offset * PIXELS_TO_UNITS) + Vector2(point_x_on_circle, point_y_on_circle)
	return point_on_circle

#TODO Factor in viewport size
func move_dice(dice_centre_position : Vector2):
	#Take into account position of dice
	var mouse_to_dice_position = get_local_mouse_position() - dice_centre_position
	
	#We're inside the dice shape
	if(mouse_to_dice_position.length() < dice_radius * UNITS_TO_PIXELS):		
		return
	
	#Prevent square rooting a negative number (failsafe for above statement)
	var safe_mouse_position = clampf(mouse_to_dice_position.length(), dice_radius * UNITS_TO_PIXELS, INF)
	var impulse_strength = clampf((safe_mouse_position - (dice_radius * UNITS_TO_PIXELS)) * 10, 0, 3000)
	SignalManager.power_value.emit(impulse_strength)
	var dir = mouse_to_dice_position.normalized()
	get_node("Arrow").hide()
	#SignalManager.active_dice_in_motion.emit("hide")
	display_arrow = false
	timer.start(1)	
	calculate_power = false		
	#Make a bar which represents this clamped value
	dice_rb.apply_central_impulse(-dir * impulse_strength)	


#Grace period for velocity check
func _on_timer_timeout() -> void:	
	print(timed_out)
	timed_out = true


#Sent reference of dice to main to add to array
func load_dice_deferred():
	SignalManager.load_dice.emit(self)


#Send reference of dice to set as active dice
func active_dice_deferred():
	SignalManager.get_active_dice.emit(self)


#Send reference of dice to set currently hovered dice
func dice_mouse_entered():
	SignalManager.mouse_enter.emit(self)


#Remove hovered in main
func dice_mouse_exited():
	SignalManager.mouse_exit.emit()


func set_arrow_visiblity(visibility):
	if visibility == show:
		get_node("Arrow").show()
	elif visibility == hide:
		get_node("Arrow").hide()
	
