extends RigidBody2D

const UNITS_TO_PIXELS : float = 3.2
const PIXELS_TO_UNITS : float = 1/3.2

@export var dice_template : Resource = null
@export var isActive : bool
#@onready var dice_rb = $"."
@onready var dice_rb = $"."
@onready var dice_collision_shape = $CollisionShape2D
@onready var dice_line = $Line2D
#@onready var area_collision_shape = $CollisionShape2D
#@onready var dice_collision_shape = $RigidBody2D/CollisionShape2D
@onready var timer = $Timer
@onready var dice_radius = dice_collision_shape.shape.radius
@onready var roll_animation = $AnimatedSprite2D

var is_moving = false
var timed_out = false
var arrow_scene = preload("res://Scenes/arrow.tscn")
var bam_scene = preload("res://Scenes/bam.tscn")
var calculate_power = true;
var display_arrow = true
var update_origin = false
var old_transform = null
var rb_offset = null
var arrow = null
var collisions = 0
var current_value = 0
var available_values_index = 0;

#Resource Defined
var min_value = 0
var max_value = 0
var interval = 0
var roll_animation_path = ""
var type = 0

var available_values := []

func _init() -> void:
	SignalManager.connect("initialise_dice_values", initialise_dice)

# Called when the node enters the scene tree for the first time.
func _ready():	
	mouse_entered.connect(dice_mouse_entered)
	mouse_exited.connect(dice_mouse_exited)
	call_deferred("load_dice_deferred")
	
	arrow = arrow_scene.instantiate()
	add_child(arrow)
	
	if isActive:
		call_deferred("active_dice_deferred")

	old_transform = dice_rb.transform.origin
	rb_offset = dice_rb.transform.origin - transform.origin 
	
	#dice_template = load("res://Resources/basic_dice.tres")
	#print("Set Template ", dice_template)
	
	#print("Path", dice_template.get_path())
	#dice_template.resource_path = "res://Resources/basic_dice.tres"
	
	if(dice_template):
		#Get values from Resource
		min_value = dice_template.dice_min
		max_value = dice_template.dice_max
		interval = dice_template.dice_interval		
		type = dice_template.dice_type
		
		#Add each available value from the min to max value in steps of interval
		for n in range(min_value, max_value + 1, interval):
			available_values.append(n)
		
		#Randomise initial number to use and display
		available_values_index = randi() % available_values.size()
		current_value = available_values[available_values_index]
		
		#Load animation & display initial frame
		roll_animation_path = dice_template.dice_sprite_animation_path		
		roll_animation.set_sprite_frames(load(roll_animation_path))
		roll_animation.frame = available_values_index


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	#print(get_global_mouse_position())
	if !isActive:		
		arrow.hide()
		
	if !get_colliding_bodies().is_empty():		
		var new_bam = bam_scene.instantiate()
		get_parent().add_child(new_bam)
		new_bam.global_position = dice_rb.transform.origin		
		collisions += 1
		#print("Collisions ", collisions)
		
		var timer := Timer.new()
		add_child(timer)
		timer.wait_time = 0.2
		timer.one_shot = true
		timer.start()
		timer.connect("timeout", bam_timeout.bind(new_bam))
		
	if isActive:
		var display_arrow = true
		var current_angle = dice_rb.transform.origin.angle_to_point(get_global_mouse_position())
		var dice_centre_position = dice_rb.transform.origin	
		var current_point_on_circle = calculate_circle_point(dice_radius * PIXELS_TO_UNITS, current_angle, dice_centre_position)
		var current_point_on_circle_line = calculate_circle_point(-dice_radius, current_angle, Vector2.ZERO)
		var mouse_to_dice_position = get_global_mouse_position() - dice_centre_position
		var distance_from_dice = (get_local_mouse_position() - dice_centre_position).length() - (dice_radius * UNITS_TO_PIXELS)	
		
		if display_arrow:		
			arrow.show()
			arrow.global_position = current_point_on_circle * UNITS_TO_PIXELS
			arrow.rotation = current_angle - dice_rb.rotation
			
			#print("Mouse Pos ", get_global_mouse_position())
			#print("Dice Centre", dice_centre_position)
			#print("Angle ", current_angle)			
			
			#dice_line.clear_points()
			#dice_line.add_point(current_point_on_circle_line)
			#dice_line.add_point(current_point_on_circle_line + current_point_on_circle_line) 
			#clampf((clampf((get_global_mouse_position() - dice_centre_position).length(), dice_radius, INF) - dice_radius) * 0.5, 0, 3000)))
			
			#dice_line.add_point(dice_centre_position)
			#dice_line.add_point(dice_centre_position + Vector2(100,100))
			
			#dice_line.add_point(current_point_on_circle * PIXELS_TO_UNITS * PIXELS_TO_UNITS)
			#dice_line.add_point(current_point_on_circle * PIXELS_TO_UNITS)
			
		else:
			arrow.hide()

		if Input.is_action_just_pressed("ui_accept"):
			move_dice(dice_centre_position, mouse_to_dice_position)							
			#is_active_dice.emit(self)

		if timed_out && abs(dice_rb.linear_velocity.x) < 10 && abs(dice_rb.linear_velocity.y) < 10:
			#TODO Lerp values for smoother finish
			dice_rb.linear_velocity = Vector2.ZERO
			#SignalManager.active_dice_stationary.emit("show")		
			calculate_power = true
			timed_out = false		
			display_arrow = true		
			roll_animation.pause()			
			#Update value to reflect that of the paused frame			
			current_value = available_values[roll_animation.frame]
		
		
		if(calculate_power): 			
			SignalManager.power_value.emit(clampf((clampf((get_global_mouse_position() - dice_centre_position).length(), dice_radius, INF) - dice_radius) * 10, 0, 3000))


func calculate_circle_point(radius : float, angle : float, offset : Vector2) -> Vector2:
	var point_x_on_circle : float = radius * cos(angle)
	var point_y_on_circle : float = radius * sin(angle)
	var point_on_circle : Vector2 = (offset * PIXELS_TO_UNITS) + Vector2(point_x_on_circle, point_y_on_circle)
	return point_on_circle

#TODO Factor in viewport size
func move_dice(dice_centre_position, mouse_to_dice_position):	
	#We're inside the dice shape
	if(mouse_to_dice_position.length() < dice_radius):	
		return
	
	#Prevent square rooting a negative number (failsafe for above statement)
	var safe_mouse_position = clampf(mouse_to_dice_position.length(), dice_radius, INF)
	var impulse_strength = clampf((safe_mouse_position - (dice_radius)) * 10, 0, 3000)	
	var dir = mouse_to_dice_position.normalized()
	#get_node("Arrow").hide()
	#SignalManager.active_dice_in_motion.emit("hide")
	SignalManager.power_value.emit(impulse_strength)
	display_arrow = false	
	calculate_power = false		
	timer.start(1)	
	#Make a bar which represents this clamped value
	dice_rb.apply_central_impulse(-dir * impulse_strength)	
	roll_animation.play()


#Grace period for velocity check
func _on_timer_timeout() -> void:	
	timed_out = true


#Sent reference of dice to main to add to array
func load_dice_deferred():
	SignalManager.load_dice.emit(self)


#Send reference of dice to set as active dice
func active_dice_deferred():
	SignalManager.set_active_dice.emit(self)


#Send reference of dice to set currently hovered dice
func dice_mouse_entered():
	SignalManager.mouse_enter.emit(self)


#Remove hovered in main
func dice_mouse_exited():
	SignalManager.mouse_exit.emit()
	
func bam_timeout(sprite) -> void:
	sprite.queue_free()

#Receieved when deckmanager has created this instance and assigned resource template
func initialise_dice(dice):
	if dice == self:
		#template has been assigned, update our values
		min_value = dice_template.dice_min
		max_value = dice_template.dice_max
		interval = dice_template.dice_interval
		roll_animation_path = dice_template.dice_sprite_animation_path
		type = dice_template.dice_type
