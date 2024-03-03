extends Control

var panel_previous_position = Vector2.ZERO

func _on_score_show_hide_toggled(toggled_on: bool) -> void:
	var tween = create_tween().bind_node(self)
	var panel_width = $Score.size.x
	var panel_position = $Score.position	

	if(toggled_on):		
		panel_previous_position = panel_position
		tween.tween_property(
		$Score,
		"position",
		 Vector2($Score.position.x + panel_width, panel_position.y),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$Score/Score_Show_Hide.release_focus()
	else: 
		tween.tween_property(
		$Score,
		"position",
		 Vector2(panel_previous_position.x, panel_position.y),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$Score/Score_Show_Hide.release_focus()
