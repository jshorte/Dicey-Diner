extends Control

@onready var panel_previous_position = $"Score".position
#@onready var score_vbox = $"Score/Score Container/VBoxContainer/Score Space"
@onready var score_vbox = $"Score/Score Container/VBoxContainer/DiceVBox"
@onready var total_score_text = $"Score/Score Container/VBoxContainer/HBoxContainer3/Total Score"
var total_score_value = 0
var dice_score_scene = preload("res://Scenes/dice_score.tscn")
var dice_label_default = preload("res://Art/default_label.tres")
var dice_label_hovered = preload("res://Art/hovered_label.tres")
var dice_array = []
var i = 0

func _init() -> void:
	#SignalManager.connect("close_all_panels", _on_score_show_hide_toggled)
	SignalManager.connect("add_dice_to_score", add_new_dice)
	SignalManager.connect("update_dice_score", update_dice_score)
	SignalManager.connect("update_total_score", update_total_score)
	SignalManager.connect("update_dice_score_label_to_default", update_dice_score_label_to_default)
	SignalManager.connect("update_dice_score_label_to_hovered", update_dice_score_label_to_hovered)

"""
func _on_score_show_hide_toggled(toggled_on: bool) -> void: 
	
	var tween = create_tween().bind_node($Score/Score_Show_Hide)
	var panel_width = $"Score".size.x
	var panel_position = $"Score".position	

	if(toggled_on):	
		#panel_previous_position = panel_position
		tween.tween_property(
		$"Score",
		"position",
		 Vector2($"Score".position.x + panel_width, panel_position.y),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$Score/Score_Show_Hide.release_focus()
	else: 
		tween.tween_property(
		$"Score",
		"position",
		 #Vector2(panel_previous_position.x, panel_position.y),
		 Vector2($"Score".position.x - panel_width, panel_position.y),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$Score/Score_Show_Hide.release_focus()
"""

func add_new_dice(dice):
	print(dice)	
	var dice_score = dice_score_scene.instantiate()
		
	#print("Dice Label: ", dice_label)
	#print("Dice Label Colour: ", dice_label.font_color)	
	
	#Enable this to display dice on board entry
	#dice_score.get_node("Score Body Food Text").text = dice.dice_name
	#dice_score.get_node("Score Body Score Text").text = str(dice.current_value)
	
	#print("Pre Label Colour: ", dice_score.get_node("Score Body Score Text").font_color)
	dice_score.get_node("Score Body Food Text").set_label_settings(dice_label_default)
	dice_score.get_node("Score Body Score Text").set_label_settings(dice_label_hovered)
	print("Label Settings ", dice_score.get_node("Score Body Food Text").get_label_settings())
	#print("Post Label Colour: ", dice_score.get_node("Score Body Score Text").font_color)
	
	
	score_vbox.add_child(dice_score)	
	
	#Add the newly added dice to an array to be locally accessed
	var dice_dict_key = dice
	var dice_dict_value = dice_score
	var dice_dict = {dice_dict_key : dice_dict_value}
	dice_array.push_back(dice_dict)
	print ("Size: ", dice_array.size())
	print ("Font Colour: ", dice_score.get_node("Score Body Food Text"))

#Highlight a dices score when the dices rigidbody is moused over 
func update_dice_score_label_to_default(dice):
	for dict in dice_array:
		if dict.has(dice):
			dict[dice].get_node("Score Body Food Text").set_label_settings(dice_label_default)
			dict[dice].get_node("Score Body Score Text").set_label_settings(dice_label_default)

#Set default label values when a dice is no longer moused over 
func update_dice_score_label_to_hovered(dice):		
	for dict in dice_array:
		if dict.has(dice):
			dict[dice].get_node("Score Body Food Text").set_label_settings(dice_label_hovered)
			dict[dice].get_node("Score Body Score Text").set_label_settings(dice_label_hovered)

func update_dice_score(dice, score):
	var total_score_value = 0
	
	for dict in dice_array:
		if dict.has(dice):
			dict[dice].get_node("Score Body Food Text").text = dice.dice_name
			dict[dice].get_node("Score Body Score Text").text = str(score)
			#total_score_value += dice.total_score
			#total_score_text.text = str(total_score_value)		
			#total_score_value += int(dict[dice].get_node("Score Body Score Text").text)
			#total_score_text.text = str(total_score_value)	
	update_total_score()
	
	#if (i == dice_array.size()):
	#	total_score_text.text = str(total_score_value)
		
#TODO: This runs on every dice currently. Setup scoring phase which calls this functions once
func update_total_score():
	var score_ui_array = score_vbox.get_children()
	var total_score_value = 0
	
	for object in score_ui_array:
		total_score_value += int(object.get_node("Score Body Score Text").text)
		print(object.get_node("Score Body Score Text").text)
	
	total_score_text.text = str(total_score_value)
	print(total_score_value)
