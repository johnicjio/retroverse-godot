extends Control

const CELL_SIZE = 100

var ttt_engine: TTTEngine
var cell_buttons: Array = []

@onready var grid_container = $CenterContainer/VBoxContainer/GridContainer
@onready var turn_label = $CenterContainer/VBoxContainer/TurnLabel

func _ready():
	ttt_engine = get_node("/root/GameState/TTTEngine")
	
	ttt_engine.mark_placed.connect(_on_mark_placed)
	ttt_engine.game_over.connect(_on_game_over)
	
	_create_board()
	update_turn_label()

func _create_board():
	for i in range(9):
		var button = Button.new()
		button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		button.text = ""
		button.add_theme_font_size_override("font_size", 48)
		
		var cell_index = i
		button.pressed.connect(func(): _on_cell_pressed(cell_index))
		
		cell_buttons.append(button)
		grid_container.add_child(button)

func _on_cell_pressed(index: int):
	if Global.is_host:
		if ttt_engine.current_turn == "X":
			ttt_engine.place_mark(index)

func _on_mark_placed(index: int, mark: String):
	cell_buttons[index].text = mark
	cell_buttons[index].disabled = true
	
	update_turn_label()

func _on_game_over(winner_mark: String):
	if winner_mark == "DRAW":
		turn_label.text = "DRAW!"
	else:
		turn_label.text = winner_mark + " WINS!"
	
	# Disable all cells
	for button in cell_buttons:
		button.disabled = true
	
	# Highlight winning line
	if ttt_engine.winning_line.size() > 0:
		for idx in ttt_engine.winning_line:
			cell_buttons[idx].modulate = Color(0.5, 1, 0.5)

func update_turn_label():
	if ttt_engine.winner == "":
		turn_label.text = "Turn: " + ttt_engine.current_turn
