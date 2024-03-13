extends Control

#var panel_previous_position = Vector2.ZERO

func _init() -> void:
	SignalManager.connect("close_all_panels", _on_info_show_hide_toggled)

func _on_info_show_hide_toggled(toggled_on: bool) -> void:
	var tween = create_tween().bind_node(self)
	var panel_height = $"Information Bar".size.y
	var panel_position = $"Information Bar".position	

	if(toggled_on):		
		#panel_previous_position = panel_position
		tween.tween_property(
		$"Information Bar",
		"position",
		 Vector2(panel_position.x, panel_position.y - panel_height),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$"Information Bar/Info_Show_Hide".release_focus()
	else: 
		tween.tween_property(
		$"Information Bar",
		"position",
		 Vector2(panel_position.x, panel_position.y + panel_height),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$"Information Bar/Info_Show_Hide".release_focus()		
