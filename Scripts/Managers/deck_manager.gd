extends Node

var basic = Global.DiceType.BASIC
var dice_scene = preload("res://Scenes/dice_new.tscn") #Dice framework
var basic_dice_template_path = "res://Resources/basic_dice.tres" #Dice definition

#Various dice states
var draw_pile := [] #Dice in deck 
var discard_pile := [] #Dice in discard pile
var upcoming_pile := [] #Dice drawn from deck ready to move to playable
var playable_pile := [] #Dice moved from upcoming ready to be selected and played

#The amount of dice to be drawn to populate upcoming
var player_draw_amount := 10
var player_transfer_amount := 2

func _ready():		
	#TODO: This will come from the player
	#var player_dice = [basic, basic, basic, basic, basic, basic]
	var player_dice = [basic]
	load_player_dice(player_dice)
	
	#Populate decks with data
	populate_upcoming(player_draw_amount)
	populate_playable_with_upcoming(player_transfer_amount)
	
	#Add visual representations to UI (Sprites)
	call_deferred("call_deferred_add_dice_to_upcoming", upcoming_pile) 	
	call_deferred("call_deferred_add_dice_to_playable", playable_pile)


func populate_upcoming(draw_amount):
	draw_pile.shuffle()
	
	for i in draw_amount:
		#If the deck has cards to draw from
		if draw_pile.size() > 0:	
			var card_to_add = draw_pile.pop_back()
			print("Adding card (", card_to_add, ") To upcoming pile" )
			upcoming_pile.append(card_to_add)
			print("Upcoming Pile: ", upcoming_pile)
		#Draw is empty, check if discard pile has cards
		elif discard_pile.size() > 0:
			#Add discard pile back into draw and continute drawing
			populate_deck_with_discard()
			var remaining_items_to_draw = draw_amount - i
			print("Shuffled in discard. Continuing to draw ", remaining_items_to_draw, " cards" )
			populate_upcoming(remaining_items_to_draw)
		#No cards left to draw
		else:
			print("No cards left to draw! Draw Pile (", draw_pile.size(), ") Discard Pile ()", discard_pile.size(), ")")
			break


func populate_playable_with_upcoming(transfer_amount):
	for i in transfer_amount:
		if(upcoming_pile.size() > 0):
			var card_to_add = upcoming_pile.pop_back()
			print("Transfering card (", card_to_add, ") To upcoming pile" )
			playable_pile.append(card_to_add)
			print("Playable pile: ", playable_pile)
		else:
			print("No cards to transfer from upcoming to playable. Upcoming Pile", upcoming_pile.size(), "Playable Pile", playable_pile.size())
			break


func populate_deck_with_discard():
	print("Draw pile empty (", draw_pile.size(), "): Shuffling in discard pile")
	discard_pile.shuffle()
	draw_pile.append_array(discard_pile)
	discard_pile = []


func call_deferred_add_dice_to_upcoming(pile):
	SignalManager.add_dice_to_upcoming.emit(pile)


func call_deferred_add_dice_to_playable(pile):
	SignalManager.add_dice_to_playable.emit(pile)


#Base versions of each dice type TODO: Apply modifications to particular dice seperately
func load_player_dice(dice_type_array):	
	for type in dice_type_array:		
		match type:
			Global.DiceType.BASIC:				
				var blank_dice = dice_scene.instantiate()			
				print("Pre Template: ", blank_dice.dice_template)
				blank_dice.dice_template = load(basic_dice_template_path)			
				print("Post Template ", blank_dice.dice_template)
				SignalManager.initialise_dice_values.emit(blank_dice)
				#TODO: Add dice as child to offscreen "Waiting area" which will move to playable area when icon is selected
				get_tree().root.add_child.call_deferred(blank_dice)				
				draw_pile.append(blank_dice)
				SignalManager.move_dice_offscreen.emit(blank_dice)
