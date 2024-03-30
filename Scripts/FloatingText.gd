extends Marker2D

@onready var label = get_node("Floating Text Label")
@onready var tween = create_tween().bind_node($".")
var value = 0

func _ready() -> void:
	label.set_text("+ " + str(value))
	
	tween.tween_property(
		self,
		"scale",
		Vector2(2,2),
		1
	)
	
	tween.parallel().tween_property(
		self,
		"position",
		Vector2(0,-64),
		1
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_interval(0.5)
	
	tween.tween_property(
		self,
		"scale",
		Vector2(0.3,0.3),
		0.5
	)
	
	await tween.finished
	queue_free()
