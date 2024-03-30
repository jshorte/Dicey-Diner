extends Resource
class_name base_dice

var definitions = load("res://Scripts/global_definitions.gd")

@export var dice_min : int = 0
@export var dice_max : int = 0
@export var dice_interval : int = 0
@export var dice_sprite_animation_path : String = ""
@export var dice_type := Global.DiceType.BASIC
@export var dice_name = "Pizza"
