extends Area2D

signal clicked

var player_index: int = 0
var piece_color: Color = Color.WHITE

func _ready():
	$Visual.color = piece_color
	
	# Add collision shape
	var shape = CircleShape2D.new()
	shape.radius = 15
	$CollisionShape2D.shape = shape

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
			# Visual feedback
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
