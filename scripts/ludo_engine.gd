extends Node
class_name LudoEngine

const SAFE_ZONES = [0, 8, 13, 21, 26, 34, 39, 47]
const START_POSITIONS = {"cyan": 0, "magenta": 13, "lime": 26, "yellow": 39}

var pieces: Array = []  # {id, player_id, color, position, is_home}
var current_turn_index: int = 0
var dice_value: int = 0
var consecutive_sixes: int = 0
var can_roll: bool = true
var winners: Array = []

signal dice_rolled(value)
signal piece_moved(piece_id, new_position)
signal piece_captured(piece_id)
signal player_won(player_id)
signal turn_changed(player_index)
signal blockade_hit

func initialize(player_list: Array):
	pieces.clear()
	winners.clear()
	current_turn_index = 0
	dice_value = 0
	consecutive_sixes = 0
	can_roll = true
	
	# Create 4 pieces per player
	for i in range(min(player_list.size(), 4)):
		var player = player_list[i]
		for j in range(4):
			pieces.append({
				"id": str(player.id) + "_piece_" + str(j),
				"player_id": player.id,
				"color": player.color,
				"position": -1 - j,  # In yard
				"is_home": false
			})

func roll_dice() -> int:
	if not can_roll:
		return 0
	
	var roll = randi() % 6 + 1
	dice_value = roll
	
	if roll == 6:
		consecutive_sixes += 1
	else:
		consecutive_sixes = 0
	
	# Three 6s in a row = forfeit turn
	if consecutive_sixes >= 3:
		print("Three 6s! Turn forfeited.")
		dice_value = 0
		consecutive_sixes = 0
		next_turn()
		return 0
	
	can_roll = false
	dice_rolled.emit(roll)
	return roll

func can_piece_move(piece: Dictionary) -> bool:
	if piece.is_home:
		return false
	
	# Must roll 6 to exit yard
	if piece.position < 0:
		return dice_value == 6
	
	# Cannot overshoot home
	return piece.position + dice_value <= 57

func get_valid_moves() -> Array:
	if dice_value == 0:
		return []
	
	var current_player = Global.players[current_turn_index]
	var valid = []
	
	for piece in pieces:
		if piece.player_id == current_player.id and can_piece_move(piece):
			# Check blockades
			var new_pos = piece.position
			if new_pos < 0:
				new_pos = 0
			else:
				new_pos += dice_value
			
			if new_pos >= 0 and new_pos < 52:
				if not is_blocked_by_blockade(piece.color, new_pos, current_player.id):
					valid.append(piece.id)
			else:
				valid.append(piece.id)
	
	return valid

func is_blocked_by_blockade(color: String, target_pos: int, player_id: int) -> bool:
	var global_pos = get_global_position(color, target_pos)
	var color_counts = {}
	
	for piece in pieces:
		if piece.player_id == player_id:
			continue
		if piece.position < 0 or piece.position >= 52:
			continue
		
		var piece_global = get_global_position(piece.color, piece.position)
		if piece_global == global_pos:
			var piece_color = piece.color
			if piece_color not in color_counts:
				color_counts[piece_color] = 0
			color_counts[piece_color] += 1
	
	# Blockade = 2+ pieces of same color
	for count in color_counts.values():
		if count >= 2:
			return true
	return false

func move_piece(piece_id: String) -> bool:
	if dice_value == 0:
		return false
	
	var piece_index = -1
	for i in range(pieces.size()):
		if pieces[i].id == piece_id:
			piece_index = i
			break
	
	if piece_index == -1:
		return false
	
	var piece = pieces[piece_index]
	
	if not can_piece_move(piece):
		return false
	
	var new_pos = piece.position
	
	# Exit yard
	if new_pos < 0:
		new_pos = 0
	else:
		new_pos += dice_value
	
	if new_pos > 57:
		return false
	
	# Check blockade
	if new_pos >= 0 and new_pos < 52:
		if is_blocked_by_blockade(piece.color, new_pos, piece.player_id):
			print("Blocked by blockade!")
			blockade_hit.emit()
			return false
	
	# Check for captures (on main track, not safe zones)
	var bonus_turn = false
	if new_pos >= 0 and new_pos < 52:
		var global_pos = get_global_position(piece.color, new_pos)
		var is_safe = global_pos in SAFE_ZONES
		
		if not is_safe:
			for i in range(pieces.size()):
				var other = pieces[i]
				if other.player_id != piece.player_id and other.position >= 0 and other.position < 52:
					if get_global_position(other.color, other.position) == global_pos:
						# Capture!
						print("Captured piece: ", other.id)
						pieces[i].position = -1
						pieces[i].is_home = false
						piece_captured.emit(other.id)
						bonus_turn = true
	
	# Update piece
	pieces[piece_index].position = new_pos
	pieces[piece_index].is_home = (new_pos == 57)
	piece_moved.emit(piece_id, new_pos)
	
	# Check for win
	var player_pieces = pieces.filter(func(p): return p.player_id == piece.player_id)
	var all_home = player_pieces.all(func(p): return p.is_home)
	
	if all_home and piece.player_id not in winners:
		winners.append(piece.player_id)
		player_won.emit(piece.player_id)
	
	# Bonus turn on 6 or capture
	if dice_value == 6 or bonus_turn:
		can_roll = true
	else:
		next_turn()
	
	dice_value = 0
	return true

func next_turn():
	current_turn_index = (current_turn_index + 1) % Global.players.size()
	can_roll = true
	consecutive_sixes = 0
	turn_changed.emit(current_turn_index)

func get_global_position(color: String, rel_pos: int) -> int:
	if rel_pos < 0 or rel_pos >= 52:
		return -1
	
	var start = START_POSITIONS.get(color, 0)
	return (start + rel_pos) % 52
