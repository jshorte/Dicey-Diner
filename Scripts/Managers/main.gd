extends Node2D

var hud_scene = preload("res://Scenes/hud.tscn")
var dice_array : Array = []
var active_dice = null
var hovered_dice = null
var hovered_dice_ui = null
var selected_dice_ui = null
var hovered_dice_sprite = null
var power_label : Label = null
var current_dice_mouse_entered
var current_dice_offscreen = 0
var dice_selected = false;
#TODO DEBUG
var first_active = true
@onready var hud = $HUD
@onready var dice_area = $"HUD/Bottom Bar/Dice Area"
@onready var playable_area = $"HUD/Bottom Bar/Current Dice/VBoxContainer/HBoxContainer"
@onready var holding_area = $"HUD/Holding Area/VBoxContainer"

func _init() -> void:
	SignalManager.connect("load_dice", load_dice)
	#SignalManager.connect("set_active_dice", set_active_dice)
	SignalManager.connect("unset_active_dice", unset_active_dice)
	SignalManager.connect("power_value", set_power_label_text)
	SignalManager.connect("active_dice_in_motion", update_sprites)
	SignalManager.connect("active_dice_stationary", update_sprites)	
	SignalManager.connect("mouse_enter", mouse_entered_main)
	SignalManager.connect("mouse_exit", mouse_exited_main)	
	SignalManager.connect("add_dice_to_upcoming", update_upcoming_panel)	
	SignalManager.connect("add_dice_to_playable", update_playable_panel)
	SignalManager.connect("move_dice_offscreen", move_dice_offscreen)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	#var hud = hud_scene.instantiate()	
	#add_child(hud)
	power_label = hud.get_node("Power Bar")
	dice_area.mouse_entered.connect(mouse_enter_upcoming_panel)
	dice_area.mouse_exited.connect(mouse_exit_upcoming_panel)
	
var update_timer = 1 # Set the update frequency here
var elapsed_time = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#elapsed_time += delta	
	#print(get_global_mouse_position())
	
	#TODO: Select active dice
	#if(Input.is_action_just_pressed("ui_accept") && hovered_dice != null):	
		#if (hovered_dice != active_dice):
			#active_dice.isActive = false
			#hovered_dice.get_node("Arrow").show
			#hovered_dice.isActive = true
			#set_active_dice(hovered_dice)
			
	#TODO: Set bool for select method
	#is_action_pressed true for mousedown, false for mouse up (good for confirm on release)
	#is_action_just_pressed will set to true and not set back to false, (good for click to confirm)
	if(Input.is_action_just_pressed("ui_select") && hovered_dice_ui != null && hovered_dice_sprite != null && !dice_selected):	
		#if (hovered_dice != active_dice):
		print("Selected ", hovered_dice_ui, "with value", hovered_dice_ui.current_value)
		#TODO: Update Panel when dice is selected
		#hud.get_node("Bottom Bar/Upcoming Dice/VBoxContainer/HBoxContainer").remove_child(hovered_dice_ui)
		dice_selected = true
	#User has clicked while having a mouse selected, determine where the pointer is and either place or reset
	elif(Input.is_action_just_pressed("ui_select") && dice_selected):
		if not (dice_area.get_rect().has_point(get_local_mouse_position())):
		#mouse_exited_upcoming(hovered_dice_ui, hovered_dice_sprite)
			#hovered_dice_ui.transform.origin = get_global_mouse_position()
			hovered_dice_ui.position = Vector2(get_global_mouse_position())
			hovered_dice_sprite.queue_free()
			dice_selected = false
			
			hovered_dice_ui.isActive = true
			set_active_dice(hovered_dice_ui)
			SignalManager.update_dice_position.emit(hovered_dice_ui)
			SignalManager.add_dice_to_score.emit(hovered_dice_ui)
			first_active = false			
			
			#TODO: DEBUG
			#if(first_active):
			#	hovered_dice_ui.isActive = true
			#	set_active_dice(hovered_dice_ui)
			#	SignalManager.update_dice_position.emit(hovered_dice_ui)
			#	first_active = false
		else:			
			var temp_array = [hovered_dice_ui]
			hovered_dice_sprite.queue_free()
			dice_selected = false
			update_playable_panel(temp_array)
	
	if(dice_selected):
		dice_follow_mouse(hovered_dice_sprite)

#Add each configured dice
func load_dice(dice):
	dice_array.append(dice)
	dice_array.back().mouse_entered.connect(mouse_entered_main)
	dice_array.back().mouse_exited.connect(mouse_exited_main)
	#TODO Add a label to the HUD for each dice
	print("Dice Array ", dice_array)

func set_active_dice(dice):
	active_dice = dice
	SignalManager.set_active_dice.emit(dice)
	
func unset_active_dice(dice):
	active_dice = null


func set_power_label_text(value):
	power_label.text = str(value)

func update_sprites(visibility):
	if visibility == "show":
		power_label.show()
		active_dice.get_node("Arrow").show()
		#print(current_dice.get_path())
	elif visibility == "hide":
		power_label.hide()
		active_dice.get_node("Arrow").hide()		
		#print(current_dice)


func mouse_entered_main(dice):
	hovered_dice = dice
	print(hovered_dice)
	
func mouse_exited_main():
	hovered_dice = null

func mouse_entered_upcoming(dice, sprite):	
	print("Mouse currently over ", dice, "with value ", dice.current_value)
	hovered_dice_ui = dice;	
	#hovered_dice_sprite = sprite;
	
func mouse_exited_upcoming(dice, sprite):	
	print("Mouse no longer over ", hovered_dice_ui, "with value ", hovered_dice_ui.current_value)
	hovered_dice_ui = null;
	#hovered_dice_sprite = null;
	
func mouse_entered_playable(dice, sprite):	
	print("Mouse currently over ", dice, "with value ", dice.current_value)
	hovered_dice_ui = dice;	
	hovered_dice_sprite = sprite;
	
func mouse_exited_playable(dice, sprite):	
	print("Mouse no longer over ", hovered_dice_ui, "with value ", hovered_dice_ui.current_value)
	hovered_dice_ui = null;
	#hovered_dice_sprite = null;

func update_upcoming_panel(dice_array):
	print("Upcoming Panel ", dice_array.size())
	
	for dice in dice_array:		
		print("Dice Contents ",  dice)
		#var is_odd = dice_array.size() % 2		
		#var sprite = Sprite2D.new()
		var sprite = TextureRect.new()		
		sprite.texture = load(dice.get_node("AnimatedSprite2D").sprite_frames.get_frame_texture("All", dice.available_values_index).get_path())
		hud.get_node("Bottom Bar/Upcoming Dice/VBoxContainer/HBoxContainer").add_child(sprite)
		sprite.mouse_entered.connect(mouse_entered_upcoming.bind(dice, sprite))
		sprite.mouse_exited.connect(mouse_exited_upcoming.bind(dice, sprite))
		#hud.get_node("Bottom Bar/Upcoming Dice").add_icon_item(sprite, true)
		
		#TODO (Remove) Removed as positioning dealt with using V&H Boxes 
		#sprite.position = Vector2(x, y)
		#x += spacing
		#TEST CHANGE


func update_playable_panel(dice_array):	
	#TODO: Currently this reads an array of dice, takes its size and distributes dice evenly in the panel.
	#What we'd like to take all current dice in the panel and add to it the passed dice, calculate size 
	#using the combined size.	
	#var panel_width = hud.get_node("Bottom Bar/Current Dice").size.x
	#var panel_height = hud.get_node("Bottom Bar/Current Dice").size.y
	#var panel_position = hud.get_node("Bottom Bar/Current Dice").position
	
	#var vertical_margin = 40
	#var number_of_entries = dice_array.size()
	#var spacing = (panel_width / (number_of_entries + 1))
	#var x = spacing	
	#var y = (panel_height / 2) + 10
	#var sprite = Sprite2D.new()
	#sprite.texture = load("res://Dice/2.png")
	#var sprite_width = sprite.get_rect().size.x	
	
	for dice in dice_array:		
		#var is_odd = dice_array.size() % 2		
		var sprite = TextureRect.new()
		sprite.texture = load(dice.get_node("AnimatedSprite2D").sprite_frames.get_frame_texture("All", dice.available_values_index).get_path())
		hud.get_node("Bottom Bar/Current Dice/VBoxContainer/HBoxContainer").add_child(sprite)
		sprite.mouse_entered.connect(mouse_entered_playable.bind(dice, sprite))
		sprite.mouse_exited.connect(mouse_exited_playable.bind(dice, sprite))
		
		print("Hud ", hud)
		
		#var sprite = Sprite2D.new()
		#sprite.texture = load(item.get_node("AnimatedSprite2D").sprite_frames.get_frame_texture("All", 0).get_path())
		#hud.get_node("Bottom Bar/Current Dice").add_child(item, false, Node.INTERNAL_MODE_BACK)
		#hud.get_node("Bottom Bar/Current Dice").add_icon_item(sprite, true)
		#print("ITEMLIST ", hud.get_node("Bottom Bar/Current Dice"))
		#item.position = panel_position + Vector2(x, y)		
		#TODO: Emit signal with reference to dice stating the dice is currently in playable area.
		#Receiver will set the dice properties appropriately (only selectable, can "drag and drop" dice into the playable area)
		#Releasing outside of this area will recall this function, placing back into the correct position
		#x += spacing
	print("Children ", hud.get_node("Bottom Bar/Current Dice").get_children())

func move_dice_offscreen(dice_to_move):	
	dice_to_move.position = Vector2(-100, current_dice_offscreen * 100)
	dice_to_move.isActive = false
	current_dice_offscreen += 1
	pass
	
func dice_follow_mouse(sprite):
	#TODO OPTIMISE: Cache sprite.size
	sprite.global_position = get_global_mouse_position() - (sprite.size * 0.5)
	
func mouse_enter_upcoming_panel():
	print("Mouse Entered Panel")

func mouse_exit_upcoming_panel():
	print("Mouse Exited Panel")
