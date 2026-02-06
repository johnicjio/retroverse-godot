extends Button

signal dice_rolled(value: int)

var current_value = 0
var is_rolling = false

func _ready():
	set_value(0)

func _on_pressed():
	if is_rolling:
		return
	
	is_rolling = true
	text = "..."
	
	# Animate rolling
	var tween = create_tween()
	for i in range(10):
		tween.tween_callback(_show_random)
		tween.tween_interval(0.05)
	
	tween.tween_callback(_finish_roll)

func _show_random():
	text = str(randi() % 6 + 1)

func _finish_roll():
	var value = randi() % 6 + 1
	set_value(value)
	is_rolling = false
	dice_rolled.emit(value)

func set_value(value: int):
	current_value = value
	if value == 0:
		text = "ROLL"
	else:
		text = str(value)
