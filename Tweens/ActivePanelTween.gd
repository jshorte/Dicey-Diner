extends Control

func _init() -> void:
	SignalManager.connect("close_all_panels", _on_active_show_hide_toggled)

func _on_active_show_hide_toggled(toggled_on: bool) -> void:
	var tween = create_tween().bind_node(self)
	var panel_width = $Active.size.x
	var panel_position = $Active.position

	if(toggled_on):		
		tween.tween_property(
		$Active,
		"position",
		 Vector2(panel_position.x - panel_width, panel_position.y),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$Active/Active_Show_Hide.release_focus()
	else: 
		tween.tween_property(
		$Active,
		"position",
		 Vector2(panel_position.x + panel_width, panel_position.y),
		 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		$Active/Active_Show_Hide.release_focus()
