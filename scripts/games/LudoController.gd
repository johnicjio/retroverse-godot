extends Node2D

const TILE_SIZE = 50
const BOARD_SIZE = 15
const PIECE_SCENE = preload("res://scenes/shared/Piece.tscn")

@onready var board = $Board
@onready var tiles = $Board/Tiles
@onready var pieces_container = $Board/Pieces
@onready var turn_label = $UI/Panel/VBox/TurnLabel
@onready var dice = $UI/Panel/VBox/Dice

enum PlayerColor { CYAN, MAGENTA, LIME, YELLOW }

var game_state = {
	"pieces": [],
	"current_turn": 0,
	"dice_value": 0,
	"consecutive_sixes": 0,
	"can_roll": true,
	"winners": []
}

var player_colors = [
	Color(0.13, 0.83, 0.93),  # Cyan
	Color(0.85, 0.27, 0.94),  # Magenta
	Color(0.75, 0.95, 0.39),  # Lime
	Color(0.99, 0.88, 0.28)   # Yellow
]

var players = []
var pieces = []

# Ludo board layout
var safe_zones = [0, 8, 13, 21, 26, 34, 39, 47]
var start_positions = {0: 0, 1: 13, 2: 26, 3: 39}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Get players from multiplayer
	var my_id = multiplayer.get_unique_id()
	players = [my_id]
	
	if multiplayer.is_server():
		_initialize_game()
	
	dice.dice_rolled.connect(_on_dice_rolled)
	_draw_board()

func _initialize_game():
	# Create 4 pieces for each player
	for player_idx in range(min(players.size(), 4)):
		for piece_idx in range(4):
			var piece_data = {
				"id": "p%d_%d" % [player_idx, piece_idx],
				"player": player_idx,
				"position": -1 - piece_idx,  # In yard
				"is_home": false
			}
			game_state.pieces.append(piece_data)
			_spawn_piece(piece_data)
	
	_sync_state.rpc(game_state)

func _spawn_piece(piece_data: Dictionary):
	var piece = PIECE_SCENE.instantiate()
	piece.name = piece_data.id
	piece.player_index = piece_data.player
	piece.piece_color = player_colors[piece_data.player]
	piece.clicked.connect(_on_piece_clicked.bind(piece_data.id))
	pieces_container.add_child(piece)
	pieces.append(piece)
	_update_piece_position(piece, piece_data.position)

func _update_piece_position(piece: Node2D, pos: int):
	var coords = _get_tile_coords(pos, piece.player_index)
	var tween = create_tween()
	tween.tween_property(piece, "position", coords, 0.3).set_trans(Tween.TRANS_CUBIC)

func _get_tile_coords(pos: int, player_idx: int) -> Vector2:
	# Yard positions (negative)
	if pos < 0:
		var yard_offsets = [
			[Vector2(-300, -300), Vector2(-200, -300), Vector2(-300, -200), Vector2(-200, -200)],  # Cyan
			[Vector2(200, -300), Vector2(300, -300), Vector2(200, -200), Vector2(300, -200)],      # Magenta
			[Vector2(200, 200), Vector2(300, 200), Vector2(200, 300), Vector2(300, 300)],          # Lime
			[Vector2(-300, 200), Vector2(-200, 200), Vector2(-300, 300), Vector2(-200, 300)]       # Yellow
		]
		return yard_offsets[player_idx][-pos - 1]
	
	# Home stretch (52-57)
	if pos >= 52:
		var home_pos = pos - 52
		var home_offsets = [
			Vector2(0, -50 - home_pos * 40),   # Cyan
			Vector2(50 + home_pos * 40, 0),    # Magenta
			Vector2(0, 50 + home_pos * 40),    # Lime
			Vector2(-50 - home_pos * 40, 0)    # Yellow
		]
		return home_offsets[player_idx]
	
	# Main track (0-51) - simplified circular layout
	var angle = (pos + start_positions[player_idx]) * (2.0 * PI / 52.0)
	var radius = 250.0
	return Vector2(cos(angle), sin(angle)) * radius

func _draw_board():
	# Draw main track tiles
	for i in range(52):
		var tile = ColorRect.new()
		tile.size = Vector2(40, 40)
		var coords = _get_tile_coords(i, 0)
		tile.position = coords - tile.size / 2
		tile.color = Color(0.2, 0.2, 0.3, 0.5) if not i in safe_zones else Color(0.3, 0.5, 0.3, 0.7)
		tiles.add_child(tile)

func _on_dice_rolled(value: int):
	if not multiplayer.is_server():
		return
	
	if not game_state.can_roll:
		return
	
	game_state.dice_value = value
	game_state.consecutive_sixes = value if value == 6 else 0
	
	# Three 6s forfeit turn
	if game_state.consecutive_sixes >= 3:
		game_state.current_turn = (game_state.current_turn + 1) % players.size()
		game_state.consecutive_sixes = 0
		game_state.can_roll = true
		_sync_state.rpc(game_state)
		return
	
	game_state.can_roll = false
	_sync_state.rpc(game_state)

func _on_piece_clicked(piece_id: String):
	if not multiplayer.is_server():
		return
	
	if game_state.dice_value == 0:
		return
	
	var piece_data = null
	for p in game_state.pieces:
		if p.id == piece_id:
			piece_data = p
			break
	
	if piece_data == null or piece_data.player != game_state.current_turn:
		return
	
	if not _can_piece_move(piece_data):
		return
	
	_move_piece(piece_data)
	_sync_state.rpc(game_state)

func _can_piece_move(piece_data: Dictionary) -> bool:
	if piece_data.is_home:
		return false
	if piece_data.position < 0:
		return game_state.dice_value == 6
	return piece_data.position + game_state.dice_value <= 57

func _move_piece(piece_data: Dictionary):
	var new_pos = piece_data.position
	
	if new_pos < 0:
		new_pos = 0
	else:
		new_pos += game_state.dice_value
	
	piece_data.position = new_pos
	piece_data.is_home = (new_pos == 57)
	
	# Check for captures on main track
	if new_pos < 52 and new_pos >= 0:
		var global_pos = (new_pos + start_positions[piece_data.player]) % 52
		if not global_pos in safe_zones:
			# Capture other pieces at this position
			for other in game_state.pieces:
				if other.player != piece_data.player and other.position >= 0 and other.position < 52:
					var other_global = (other.position + start_positions[other.player]) % 52
					if other_global == global_pos:
						other.position = -1
						other.is_home = false
	
	# Update piece visually
	for piece in pieces:
		if piece.name == piece_data.id:
			_update_piece_position(piece, piece_data.position)
			break
	
	# Check win condition
	var player_pieces = game_state.pieces.filter(func(p): return p.player == piece_data.player)
	var all_home = player_pieces.all(func(p): return p.is_home)
	if all_home and not piece_data.player in game_state.winners:
		game_state.winners.append(piece_data.player)
	
	# Next turn
	var bonus = (game_state.dice_value == 6)
	if not bonus:
		game_state.current_turn = (game_state.current_turn + 1) % players.size()
	
	game_state.dice_value = 0
	game_state.can_roll = true

func _on_peer_connected(id: int):
	if not id in players:
		players.append(id)

func _on_peer_disconnected(id: int):
	players.erase(id)

@rpc("authority", "call_local", "reliable")
func _sync_state(state: Dictionary):
	game_state = state
	turn_label.text = "Player %d's Turn" % (game_state.current_turn + 1)
	dice.set_value(game_state.dice_value)
	
	# Update all pieces
	for piece_data in game_state.pieces:
		for piece in pieces:
			if piece.name == piece_data.id:
				_update_piece_position(piece, piece_data.position)
				break

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/GameLobby.tscn")
