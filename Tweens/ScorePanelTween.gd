extends Control

@onready var panel_previous_position = $"Score".position
#@onready var score_vbox = $"Score/Score Container/VBoxContainer/Score Space"
@onready var score_vbox = $"Score/Score Container/VBoxContainer/DiceVBox"
@onready var base_score = $"Score/Score Container/VBoxContainer/Dice Score"
var dice_score_scene = preload("res://Scenes/dice_score.tscn")

func _init() -> void:
	#SignalManager.connect("close_all_panels", _on_score_show_hide_toggled)
	SignalManager.connect("add_dice_to_score", add_new_dice)

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

func add_new_dice(dice):
	print(dice)
	var dice_score = dice_score_scene.instantiate()
	dice_score.get_node("Score Body Food Text").text = dice.dice_name
	dice_score.get_node("Score Body Score Text").text = str(dice.current_value)
	score_vbox.add_child(dice_score)
