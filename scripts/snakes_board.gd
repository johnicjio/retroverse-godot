extends Control

const BOARD_SIZE = 10
const CELL_SIZE = 48

var snakes_engine: SnakesEngine
var player_tokens: Dictionary = {}  # player_id -> Node2D

@onready var board_grid = $CenterContainer/BoardGrid
@onready var roll_button = $VBoxContainer/RollButton
@onready var dice_label = $VBoxContainer/DiceLabel
@onready var turn_label = $VBoxContainer/TurnLabel

func _ready():
	snakes_engine = get_node("/root/GameState/SnakesEngine")
	
	snakes_engine.dice_rolled.connect(_on_dice_rolled)
	snakes_engine.player_moved.connect(_on_player_moved)
	snakes_engine.snake_hit.connect(_on_snake_hit)
	snakes_engine.ladder_climbed.connect(_on_ladder_climbed)
	snakes_engine.player_won.connect(_on_player_won)
	snakes_engine.turn_changed.connect(_on_turn_changed)
	
	roll_button.pressed.connect(_on_roll_pressed)
	
	_create_board()
	_create_tokens()
	update_turn_label()

func _create_board():
	# Create 10x10 grid (numbered 1-100)
	for i in range(100):
		var num = 100 - i
		var cell = PanelContainer.new()
		cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		
		var label = Label.new()
		label.text = str(num)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_child(label)
		
		# Color snakes and ladders
		if num in snakes_engine.SNAKES_MAP:
			cell.modulate = Color(1, 0.3, 0.3, 0.7)  # Red for snakes
		elif num in snakes_engine.LADDERS_MAP:
			cell.modulate = Color(0.3, 1, 0.3, 0.7)  # Green for ladders
		else:
			var row = i / 10
			if row % 2 == 0:
				cell.modulate = Color(0.9, 0.9, 0.9)
			else:
				cell.modulate = Color(0.8, 0.8, 0.8)
		
		board_grid.add_child(cell)

func _create_tokens():
	for player in snakes_engine.players:
		var token = _create_token_visual(player.color)
		player_tokens[player.id] = token
		board_grid.get_parent().add_child(token)
		_update_token_position(player)

func _create_token_visual(color: String) -> Node2D:
	var node = Node2D.new()
	
	var circle = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var col = Color(0, 1, 1) if color == "cyan" else Color(1, 0, 1)
	img.fill(col)
	var tex = ImageTexture.create_from_image(img)
	circle.texture = tex
	node.add_child(circle)
	
	return node

func _update_token_position(player: Dictionary):
	if player.id not in player_tokens:
		return
	
	var coords = get_cell_coords(player.position)
	var token = player_tokens[player.id]
	
	var tween = create_tween()
	var target_pos = Vector2(coords.x * CELL_SIZE + CELL_SIZE/2, coords.y * CELL_SIZE + CELL_SIZE/2)
	tween.tween_property(token, "position", target_pos, 1.0).set_trans(Tween.TRANS_QUAD)

func get_cell_coords(pos: int) -> Vector2i:
	if pos == 0:
		return Vector2i(0, BOARD_SIZE - 1)
	
	var adjusted = pos - 1
	var row = adjusted / BOARD_SIZE
	var col = adjusted % BOARD_SIZE
	
	if row % 2 == 1:
		col = BOARD_SIZE - 1 - col
	
	return Vector2i(col, BOARD_SIZE - 1 - row)

func _on_roll_pressed():
	if Global.is_host:
		snakes_engine.roll_dice()

func _on_dice_rolled(value: int):
	dice_label.text = "Rolled: " + str(value)

func _on_player_moved(player_id: int, new_position: int):
	for player in snakes_engine.players:
		if player.id == player_id:
			_update_token_position(player)
			break

func _on_snake_hit(from_pos: int, to_pos: int):
	print("Snake! ", from_pos, " -> ", to_pos)

func _on_ladder_climbed(from_pos: int, to_pos: int):
	print("Ladder! ", from_pos, " -> ", to_pos)

func _on_player_won(player_id: int):
	print("Winner: ", player_id)

func _on_turn_changed(player_index: int):
	update_turn_label()

func update_turn_label():
	turn_label.text = "Turn: Player " + str(snakes_engine.current_turn_index + 1)
