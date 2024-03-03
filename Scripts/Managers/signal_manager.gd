extends Node

#emitted by dice.gd to transmit itself to main (for HUD)
signal load_dice
signal set_active_dice
signal power_value
signal active_dice_in_motion
signal active_dice_stationary
signal mouse_enter
signal mouse_enter_upcoming
signal mouse_exit
signal set_arrow_visibility

#Display dice in HUD
signal add_dice_to_upcoming
signal add_dice_to_playable

signal initialise_dice_values
signal move_dice_offscreen
