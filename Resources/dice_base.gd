extends Resource
class_name base_dice

var definitions = load("res://Scripts/global_definitions.gd")

@export var dice_min : int
@export var dice_max : int
@export var dice_interval : int 
@export var dice_sprite_animation_path : String
@export var dice_type: Global.DiceType
@export var dice_name : String
