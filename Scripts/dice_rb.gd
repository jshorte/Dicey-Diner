extends RigidBody2D

const UNITS_TO_PIXELS : float = 3.2
const PIXELS_TO_UNITS : float = 1/3.2

var dice_status := Global.DiceState.DISABLED
var floating_text = preload("res://Scenes/floating_text.tscn")
@onready var TEST_PROJECTILE = $CharacterBody2D

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
@onready var padlock_sprite = $PadlockSprite

var affected_by_garlic = false
var is_moving = false
var transmit_moving_signals = true
var dice_locked = false
var timed_out = false
var score_updated = false
var arrow_scene = preload("res://Scenes/arrow.tscn")
var bam_scene = preload("res://Scenes/bam.tscn")
var calculate_power = true
var display_arrow = false
var update_arrow = false
var update_origin = false
var old_transform = null
var rb_offset = null
var arrow = null
var collisions = 0
var current_value = 0
var total_score = 0
var available_values_index = 0;

#Resource Defined
var dice_name = ""
var min_value = 0
var max_value = 0
var interval = 0
var roll_animation_path = ""
var type = 0

var available_values := []

func _init() -> void:
	SignalManager.connect("initialise_dice_values", initialise_dice)
	SignalManager.connect("update_dice_position", update_position)
	SignalManager.connect("set_active_dice", active_dice)

# Called when the node enters the scene tree for the first time.
func _ready():	
	#isActive = true
	
	mouse_entered.connect(dice_mouse_entered)
	mouse_exited.connect(dice_mouse_exited)
	call_deferred("load_dice_deferred")
	
	arrow = arrow_scene.instantiate()
	add_child(arrow)
	
	#if isActive:
	#	call_deferred("active_dice_deferred")

	#old_transform = dice_rb.transform.origin
	rb_offset = dice_rb.transform.origin - transform.origin 
	
	roll_animation.set_sprite_frames(load(dice_template.dice_sprite_animation_path))
	roll_animation.frame = available_values_index
	
	#dice_template = load("res://Resources/basic_dice.tres")
	#print("Set Template ", dice_template)
	
	#print("Path", dice_template.get_path())
	#dice_template.resource_path = "res://Resources/basic_dice.tres"
	
	#if(dice_template):
		#initialise_dice(self)
		#Get values from Resource
		#min_value = dice_template.dice_min
		#max_value = dice_template.dice_max
		#interval = dice_template.dice_interval		
		#type = dice_template.dice_type		
		
		#Add each available value from the min to max value in steps of interval
		#for n in range(min_value, max_value + 1, interval):
		#	available_values.append(n)
		
		#Randomise initial number to use and display
		#available_values_index = randi() % available_values.size()
		#current_value = available_values[available_values_index]
		
		#Load animation & display initial frame
		#roll_animation_path = dice_template.dice_sprite_animation_path		
		#roll_animation.set_sprite_frames(load(roll_animation_path))
		#roll_animation.frame = available_values_index
		
	disable_dice(self)

func _process(delta: float) -> void:	
	queue_redraw()	
	
func _draw():	
	if (isActive && (dice_status == Global.DiceState.ACTIVE)):
		draw_path()
		#draw_line(get_global_mouse_position() - dice_rb.transform.origin, current_point_on_circle  * UNITS_TO_PIXELS, Color.RED, 2)
		#draw_line(Vector2(0,0), -get_local_mouse_position(), Color.RED, 10)
		#print("Velocity = Impulse: ", impulse_strength, " / Mass: ", mass)
	
func draw_path():
	var current_angle = dice_rb.transform.origin.angle_to_point(get_global_mouse_position())
	var dice_centre_position = dice_rb.transform.origin	
	var current_point_on_circle = calculate_circle_point(dice_radius * PIXELS_TO_UNITS, current_angle, dice_centre_position)
	var current_point_on_circle_line = calculate_circle_point(-dice_radius, current_angle, Vector2.ZERO)
	var mouse_to_dice_position = get_global_mouse_position() - dice_centre_position
	var distance_from_dice = (get_local_mouse_position() - dice_centre_position).length() - (dice_radius * UNITS_TO_PIXELS)
	var safe_mouse_position = clampf(mouse_to_dice_position.length(), dice_radius, INF)
	var impulse_strength = clampf((safe_mouse_position - (dice_radius)) * 10, 0, 3000)
	var dir = mouse_to_dice_position.normalized()	
	
	var velocity : Vector2 = (impulse_strength / mass) * -dir * 100
	#var line_start = #Vector2(0,0)
	var line_start = global_position
	var line_end
	var timestep = 0.05
	var colours = [Color.RED, Color.BLUE]
	
	#TEST_PROJECTILE.global_position = line_start	
	
	for i in 70:
		line_end = line_start + (velocity * timestep)
		velocity = velocity * clampf(timestep, 0, 1)		
		
		#var collision = TEST_PROJECTILE.move_and_collide(velocity * timestep)
		#if collision:
		#	velocity = velocity.bounce(collision.get_normal())
		#	draw_line(to_local(line_start), to_local(TEST_PROJECTILE.global_position), Color.YELLOW)
		#	line_start = TEST_PROJECTILE.global_position
		#	continue
		
		var ray := raycast_query2d(line_start, line_end)
		
		if not ray.is_empty():
			velocity = velocity.bounce(ray.normal)
			draw_line(to_local(line_start), to_local(ray.position), Color.YELLOW)
			line_start = ray.position
			continue
		
		draw_line(to_local(line_start), to_local(line_end), colours[i%2])
		line_start = line_end
		
func raycast_query2d(pointA, pointB) -> Dictionary:
	var space_state = get_world_2d().direct_space_state
	#print("Space state ", get_viewport_rect())
	var query = PhysicsRayQueryParameters2D.create(pointA, pointB, 1)
	var result = space_state.intersect_ray(query)
	
	if result:
		return result
		
	return {}

func _on_body_entered(body:Node):
	var face_value = available_values[roll_animation.frame]
	
	if body is RigidBody2D: #Collided with a dice		
		if body.dice_template.dice_type == Global.DiceType.BASIC: #Pizza dice
			print("Pizza entered")
		elif body.dice_template.dice_type == Global.DiceType.GARLIC: #Garlic dice
			print("Garlic entered")
			if !affected_by_garlic && (!dice_template.dice_type == Global.DiceType.GARLIC):
				print("Not affected by garlic - calculate score")
				print("Face Value: ", face_value, "Collisions ", collisions, " Garlic Value: ", body.available_values[body.roll_animation.frame], " Total Score: ", face_value * (collisions + body.available_values[body.roll_animation.frame]))
				total_score *= (collisions + body.available_values[body.roll_animation.frame])
				affected_by_garlic = true
				

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:	
	#if !isActive:		
		#arrow.hide()	
	#Generic collision
	if !get_colliding_bodies().is_empty():
		#TODO: Lets work out collion scoring smarter
		if (dice_template.dice_type == Global.DiceType.BASIC):
			collisions += 1
			
		var new_bam = bam_scene.instantiate()
		get_parent().add_child(new_bam)
		new_bam.global_position = dice_rb.transform.origin		
		print("Collisions ", get_colliding_bodies())		
		
		var floating_text_instance = floating_text.instantiate()
		floating_text_instance.value = collisions
		add_child(floating_text_instance)
		#TODO: Set position relative to size of currently applied sprite
		#floating_text_instance.set_position
	
		var timer := Timer.new()
		add_child(timer)
		timer.wait_time = 0.2
		timer.one_shot = true
		timer.start()
		timer.connect("timeout", bam_timeout.bind(new_bam))
		
	#Dice has been placed and ready to be fired
	if (isActive && (dice_status == Global.DiceState.ACTIVE)):
		var display_arrow = true
		var current_angle = dice_rb.transform.origin.angle_to_point(get_global_mouse_position())
		var dice_centre_position = dice_rb.transform.origin	
		var current_point_on_circle = calculate_circle_point(dice_radius * PIXELS_TO_UNITS, current_angle, dice_centre_position)
		var current_point_on_circle_line = calculate_circle_point(-dice_radius, current_angle, Vector2.ZERO)
		var mouse_to_dice_position = get_global_mouse_position() - dice_centre_position
		var distance_from_dice = (get_local_mouse_position() - dice_centre_position).length() - (dice_radius * UNITS_TO_PIXELS)	
		print("Position ", dice_rb.transform.origin)
		#NOTE: update_arrow only true when dice is active (currently) so use Global.DiceState.ACTIVE as conditional
		#if update_arrow:			
		arrow.global_position = current_point_on_circle * UNITS_TO_PIXELS
		arrow.rotation = current_angle - dice_rb.rotation	

		if Input.is_action_just_pressed("ui_accept"):
			move_active_dice(dice_centre_position, mouse_to_dice_position)			
			passive_dice(self)
			SignalManager.unset_active_dice.emit(self)
			SignalManager.close_all_panels.emit(true)
			SignalManager.set_gamestate.emit(Global.GameState.PLAY)			
			score_updated = false
			#TEST_PROJECTILE.queue_free()
			#is_active_dice.emit(self)		

	#Dice has come to a halt
	if  (timed_out && (dice_status == Global.DiceState.PASSIVE) && (abs(dice_rb.linear_velocity.x) < 10) && (abs(dice_rb.linear_velocity.y) < 10)):
		#TODO Lerp values for smoother finish
		dice_rb.linear_velocity = Vector2.ZERO
		is_moving = false
		#SignalManager.active_dice_stationary.emit("show")		
		calculate_power = true
		timed_out = false		
		#display_arrow = true		
		roll_animation.pause()
					
		#Update value to reflect that of the paused frame
		#print("Available Values ", available_values)	
		#print("Frame ", roll_animation.frame)		
		current_value = available_values[roll_animation.frame]
		total_score = current_value + collisions 
		
		#TODO: Have phases (Selecting Phase / Active Phase / Scoring Phase)
		#The reciver will look await scoring phase (probably updated here) and then calculate
		#and update the score panel for each dice, comprised of its face value + bonus modifiers
		if(!score_updated):
			SignalManager.update_dice_count.emit(0, 1)
			SignalManager.update_dice_score.emit(self)				
			score_updated = true
		#SignalManager.update_total_score.emit()	
		
		transmit_moving_signals = true

	#If the dice has any velocity set its state to is_moving to start roll animation
	if(abs(dice_rb.linear_velocity.x) > 1 || abs(dice_rb.linear_velocity.y) > 0):
		is_moving = true
	
	if(calculate_power): 
		var dice_centre_position = dice_rb.transform.origin				
		SignalManager.power_value.emit(clampf((clampf((get_global_mouse_position() - dice_centre_position).length(), dice_radius, INF) - dice_radius) * 10, 0, 3000))
		
	#Dice is moving on the playing field
	if (dice_status == Global.DiceState.PASSIVE && is_moving && transmit_moving_signals):
		if(!dice_locked):
			roll_animation.play()
		SignalManager.update_dice_count.emit(1, 0)
		score_updated = false
		transmit_moving_signals = false		

func calculate_circle_point(radius : float, angle : float, offset : Vector2) -> Vector2:
	var point_x_on_circle : float = radius * cos(angle)
	var point_y_on_circle : float = radius * sin(angle)
	var point_on_circle : Vector2 = (offset * PIXELS_TO_UNITS) + Vector2(point_x_on_circle, point_y_on_circle)
	return point_on_circle

#TODO Factor in viewport size
func move_active_dice(dice_centre_position, mouse_to_dice_position):	
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
	timer.start(0.1)	
	#Make a bar which represents this clamped value
	dice_rb.apply_central_impulse(-dir * impulse_strength)
	print("Dice Locked = ", dice_locked)
	if(!dice_locked):
		roll_animation.play()
	is_moving = true

#Grace period for velocity check
func _on_timer_timeout() -> void:	
	timed_out = true

#Sent reference of dice to main to add to array
func load_dice_deferred():
	SignalManager.load_dice.emit(self)

#Send reference of dice to set as active dice
#func active_dice_deferred():
	#SignalManager.set_active_dice.emit(self)

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
		dice_name = dice_template.dice_name
		min_value = dice_template.dice_min
		max_value = dice_template.dice_max
		interval = dice_template.dice_interval
		type = dice_template.dice_type
		
		for n in range(min_value, max_value + 1, interval):
			available_values.append(n)
		
		#Randomise initial number to use and display
		available_values_index = randi() % available_values.size()
		current_value = available_values[available_values_index]
	
#TODO Notes: Dice have three states
#1: Dice in holding area offscreen 
#2: Dice has been placed, ready to be used
#3: Dice has been used and remains of the field
#
#For 1, we need to deactivate everything
#For 2, we need to activate everything, make it the focus for aiming commands and display arrow
#For 3, we need to keep the dice active, but remove focus and arrow

func active_dice(dice):
	if dice == self:
		dice_status = Global.DiceState.ACTIVE
		update_arrow = true
		arrow.show()
		print("Activated")		

func passive_dice(dice):
	if dice == self:
		dice_status = Global.DiceState.PASSIVE
		update_arrow = false
		print("Passive")
		arrow.hide()
		
func disable_dice(dice):
	if dice == self:
		dice_status = Global.DiceState.DISABLED
		update_arrow = false
		dice_rb.sleeping = true
		print("Disabled")
		arrow.hide()
		
func update_position(dice):
	if(dice == self):
		#TODO HACK: Have to print the global position otherwise it goes to incorrect position
		print("Posi ", dice.global_position)
		dice.global_position = get_global_mouse_position()

func draw_pressed():
	print("Pressed Draw")
	SignalManager.redraw_dice.emit(self)
	
func roll_pressed():
	print("Pressed Roll")
	available_values_index = randi() % available_values.size()
	roll_animation.frame = available_values_index
	current_value = available_values[available_values_index]
	#current_value = available_values[roll_animation.frame]
	SignalManager.update_dice_sprite.emit(self)
	
#TODO: Could make this one function and pass through bool
func set_lock_option_pressed(locked):
	dice_locked = locked
	padlock_sprite.set_visible(locked)
	SignalManager.set_lock_option_visibility.emit(self, dice_locked)

#######################################################
###						CODE BANK					###
#######################################################

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
