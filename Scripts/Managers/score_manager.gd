extends Node

var dice_collisions : Array = []

func _init() -> void:
	SignalManager.connect("process_dice_collision", process_dice_collision)

#Get the resulting score from the collision of two dice
func process_dice_collision(dice1, dice2, dice1_face_value, dice2_face_value):
	#Bind unique id to each dice
	#var dice1_dict = {dice1.unique_id : dice1}
	#var dice2_dict = {dice2.unique_id : dice2}
	var grace_period : int = 0.1
	
	print("D1 FV ", dice1_face_value)
	print("D2 FV ", dice2_face_value)
	
	print("Processing collision between ", dice1, " and ", dice2)
	
	#Array of unique IDs to be compared against currently processed collisions
	var dice_to_process = [dice1.unique_id, dice2.unique_id]
	print("Created Array: ", dice_to_process)
	dice_to_process.sort()
	print("Sorted Array: ", dice_to_process)
	
	print("Current dice_collisions: ", dice_collisions)
	print("Current dice_to_process: ", dice_to_process)
	
	#Dice pairing has not yet had the score calculated
	if not dice_collisions.has(dice_to_process):
		print("Pairing not processed. Processing...")
		dice_collisions.push_back(dice_to_process)
		
		print("Dice To process: ", dice1)
		print("Dice To process: ", dice2)
		
		var dice1_dicetype = dice1.dice_template.dice_type
		var dice1_total_score = dice1.total_score
		var dice1_bonus_score = dice1.bonus_score		
		
		var dice2_dicetype = dice2.dice_template.dice_type
		var dice2_total_score = dice2.total_score
		var dice2_bonus_score = dice2.bonus_score
		
		print("Dice 1 Score B4: ",  dice1_total_score)
		print("Dice 2 Score: B4: ",  dice2_total_score)
		
		if dice1_dicetype == Global.DiceType.BASIC:
			#Increase collision count
			if dice2_dicetype == Global.DiceType.BASIC:
				dice1_total_score += dice1_face_value + dice1_bonus_score
				dice2_total_score += dice2_face_value + dice2_bonus_score
			#Increase dice 1 score by dice 2 face
			elif dice2_dicetype == Global.DiceType.GARLIC:
				dice1_total_score += dice1_face_value + dice1_bonus_score
				dice1_total_score *= dice2_face_value
		elif dice1_dicetype == Global.DiceType.GARLIC:
			#Increase dice 2 score by dice 1 face
			if dice2_dicetype == Global.DiceType.BASIC:
				dice2_total_score += dice2_face_value + dice2_bonus_score
				dice2_total_score *= dice1_face_value
			#Dips don't affect eachother
			#elif dice2_dicetype == Global.DiceType.GARLIC:
			#	return
			
		print("Dice 1 Score: ",  dice1_total_score)
		print("Dice 2 Score: ",  dice2_total_score)
		
		#Update dices objects local score
		dice1.total_score = dice1_total_score
		dice2.total_score = dice2_total_score		
		
		SignalManager.update_dice_score.emit(dice1, dice1_total_score)
		SignalManager.update_dice_score.emit(dice2, dice2_total_score)
		
		#TODO: Determine the order which scoring should happen depending on
		# Dice Type
		# Which combination results in the largest score
		
		var timer := Timer.new()
		add_child(timer)
		timer.wait_time = grace_period
		timer.one_shot = true
		timer.start()
		timer.connect("timeout", remove_pair_from_dict.bind(dice_to_process))
	else:
		print("Pairing already exists")
		
func remove_pair_from_dict(processed_dice):
	print("Removing ", processed_dice, "from", dice_collisions)
	dice_collisions.erase(processed_dice)
	print("Removed ", processed_dice, "from", dice_collisions)
	
