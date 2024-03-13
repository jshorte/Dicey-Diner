extends Button

func _init() -> void:
	SignalManager.connect("close_all_panels", set_state)

func set_state(state):
	set_pressed(state)
