extends Control

const BOARD_SIZE = 15
const CELL_SIZE = 32

var ludo_engine: LudoEngine
var piece_nodes: Dictionary = {}  # piece_id -> Node2D

@onready var board_grid = $CenterContainer/BoardGrid
@onready var dice_button = $VBoxContainer/Dice
@onready var dice_label = $VBoxContainer/DiceValue
@onready var turn_label = $VBoxContainer/TurnLabel

func _ready():
	ludo_engine = get_node("/root/GameState/LudoEngine")
	
	# Connect signals
	ludo_engine.dice_rolled.connect(_on_dice_rolled)
	ludo_engine.piece_moved.connect(_on_piece_moved)
	ludo_engine.piece_captured.connect(_on_piece_captured)
	ludo_engine.player_won.connect(_on_player_won)
	ludo_engine.turn_changed.connect(_on_turn_changed)
	ludo_engine.blockade_hit.connect(_on_blockade_hit)
	
	dice_button.pressed.connect(_on_dice_pressed)
	
	_create_board()
	_create_pieces()
	update_turn_label()

func _create_board():
	# Create 15x15 grid
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var cell = ColorRect.new()
			cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			
			# Color home zones
			if x < 6 and y < 6:
				cell.color = Color(0, 1, 1, 0.2)  # Cyan yard
			elif x >= 9 and y < 6:
				cell.color = Color(1, 0, 1, 0.2)  # Magenta yard
			elif x >= 9 and y >= 9:
				cell.color = Color(0.7, 1, 0.3, 0.2)  # Lime yard
			elif x < 6 and y >= 9:
				cell.color = Color(1, 1, 0, 0.2)  # Yellow yard
			elif x >= 6 and x <= 8 and y >= 6 and y <= 8:
				cell.color = Color(1, 0.8, 0, 0.3)  # Center home
			else:
				cell.color = Color(0.2, 0.2, 0.2, 0.5)
			
			board_grid.add_child(cell)

func _create_pieces():
	for piece in ludo_engine.pieces:
		var piece_node = _create_piece_visual(piece)
		piece_nodes[piece.id] = piece_node
		board_grid.get_parent().add_child(piece_node)
		_update_piece_position(piece)

func _create_piece_visual(piece: Dictionary) -> Node2D:
	var node = Node2D.new()
	
	var circle = Sprite2D.new()
	# Create simple colored circle (in real game use texture)
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(get_color_from_string(piece.color))
	var tex = ImageTexture.create_from_image(img)
	circle.texture = tex
	node.add_child(circle)
	
	# Make clickable
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	area.add_child(collision)
	node.add_child(area)
	
	area.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.pressed:
			_on_piece_clicked(piece.id)
	)
	
	return node

func _update_piece_position(piece: Dictionary):
	if piece.id not in piece_nodes:
		return
	
	var coords = get_position_coords(piece.position, piece.color)
	var piece_node = piece_nodes[piece.id]
	
	# Animate to position
	var tween = create_tween()
	var target_pos = Vector2(coords.x * CELL_SIZE + CELL_SIZE/2, coords.y * CELL_SIZE + CELL_SIZE/2)
	tween.tween_property(piece_node, "position", target_pos, 0.3).set_trans(Tween.TRANS_QUAD)

func get_position_coords(pos: int, color: String) -> Vector2i:
	# Yard positions
	if pos < 0:
		var yard_offsets = {
			"cyan": [Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 3), Vector2i(3, 3)],
			"magenta": [Vector2i(11, 1), Vector2i(13, 1), Vector2i(11, 3), Vector2i(13, 3)],
			"lime": [Vector2i(11, 11), Vector2i(13, 11), Vector2i(11, 13), Vector2i(13, 13)],
			"yellow": [Vector2i(1, 11), Vector2i(3, 11), Vector2i(1, 13), Vector2i(3, 13)]
		}
		var idx = -pos - 1
		return yard_offsets[color][idx]
	
	# Home stretch
	if pos >= 52:
		var home_pos = pos - 52
		match color:
			"cyan": return Vector2i(7, 6 - home_pos)
			"magenta": return Vector2i(8 + home_pos, 7)
			"lime": return Vector2i(7, 8 + home_pos)
			"yellow": return Vector2i(6 - home_pos, 7)
	
	# Main track (simplified - full track requires all 52 coords)
	return Vector2i(7, 7)

func get_color_from_string(color_name: String) -> Color:
	match color_name:
		"cyan": return Color(0, 1, 1)
		"magenta": return Color(1, 0, 1)
		"lime": return Color(0.7, 1, 0.3)
		"yellow": return Color(1, 1, 0)
		_: return Color.WHITE

func _on_dice_pressed():
	if not ludo_engine.can_roll:
		return
	
	if Global.is_host:
		ludo_engine.roll_dice()

func _on_dice_rolled(value: int):
	dice_label.text = "Dice: " + str(value)
	
	# Highlight valid moves
	var valid_moves = ludo_engine.get_valid_moves()
	print("Valid moves: ", valid_moves)

func _on_piece_clicked(piece_id: String):
	if Global.is_host:
		ludo_engine.move_piece(piece_id)

func _on_piece_moved(piece_id: String, new_position: int):
	for piece in ludo_engine.pieces:
		if piece.id == piece_id:
			_update_piece_position(piece)
			break

func _on_piece_captured(piece_id: String):
	print("Piece captured: ", piece_id)
	for piece in ludo_engine.pieces:
		if piece.id == piece_id:
			_update_piece_position(piece)
			break

func _on_player_won(player_id: int):
	print("Player won: ", player_id)
	# Show victory screen

func _on_turn_changed(player_index: int):
	update_turn_label()

func _on_blockade_hit():
	print("Blocked by blockade!")

func update_turn_label():
	if ludo_engine.current_turn_index < Global.players.size():
		var player = Global.players[ludo_engine.current_turn_index]
		turn_label.text = "Turn: " + player.name
