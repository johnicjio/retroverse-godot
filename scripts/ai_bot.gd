extends Node
class_name AIBot

var bot_player_id: int = -1
var is_active: bool = false
var think_timer: float = 0.0
const THINK_TIME = 1.5  # seconds

func set_bot_player(player_id: int):
	bot_player_id = player_id
	is_active = true

func _process(delta):
	if not is_active or not Global.is_host:
		return
	
	think_timer += delta
	
	if think_timer < THINK_TIME:
		return
	
	think_timer = 0.0
	
	# Check if it's bot's turn
	if Global.current_game == "LUDO":
		var ludo = get_node_or_null("/root/GameState/LudoEngine")
		if ludo:
			var current_player = Global.players[ludo.current_turn_index]
			if current_player.id == bot_player_id:
				if ludo.can_roll:
					ludo.roll_dice()
				elif ludo.dice_value > 0:
					var valid_moves = ludo.get_valid_moves()
					if valid_moves.size() > 0:
						# Pick piece closest to home
						var best_piece = valid_moves[0]
						var best_pos = -999
						
						for piece_id in valid_moves:
							for piece in ludo.pieces:
								if piece.id == piece_id and piece.position > best_pos:
									best_piece = piece_id
									best_pos = piece.position
						
						ludo.move_piece(best_piece)
	
	elif Global.current_game == "SNAKES":
		var snakes = get_node_or_null("/root/GameState/SnakesEngine")
		if snakes and snakes.winner_id == -1:
			var current_player = snakes.players[snakes.current_turn_index]
			if current_player.id == bot_player_id:
				snakes.roll_dice()
	
	elif Global.current_game == "TTT":
		var ttt = get_node_or_null("/root/GameState/TTTEngine")
		if ttt and ttt.winner == "" and ttt.current_turn == "O":
			var best_move = ttt.get_best_move_minimax()
			if best_move != -1:
				ttt.place_mark(best_move)
