extends Node
class_name TTTEngine

var board: Array = []  # 9 elements: null, "X", "O"
var current_turn: String = "X"
var winner: String = ""  # "", "X", "O", "DRAW"
var winning_line: Array = []

signal mark_placed(index, mark)
signal game_over(winner_mark)

const WIN_LINES = [
	[0, 1, 2], [3, 4, 5], [6, 7, 8],  # Rows
	[0, 3, 6], [1, 4, 7], [2, 5, 8],  # Columns
	[0, 4, 8], [2, 4, 6]               # Diagonals
]

func initialize():
	board.clear()
	for i in range(9):
		board.append(null)
	current_turn = "X"
	winner = ""
	winning_line.clear()

func place_mark(index: int) -> bool:
	if winner != "":
		return false
	
	if board[index] != null:
		return false
	
	board[index] = current_turn
	mark_placed.emit(index, current_turn)
	
	check_win()
	
	if winner == "":
		current_turn = "O" if current_turn == "X" else "X"
	
	return true

func check_win():
	# Check all win lines
	for line in WIN_LINES:
		var a = board[line[0]]
		var b = board[line[1]]
		var c = board[line[2]]
		
		if a != null and a == b and a == c:
			winner = a
			winning_line = line
			game_over.emit(winner)
			return
	
	# Check draw
	var all_filled = true
	for cell in board:
		if cell == null:
			all_filled = false
			break
	
	if all_filled:
		winner = "DRAW"
		game_over.emit("DRAW")

func get_best_move_minimax() -> int:
	var best_score = -INF
	var best_move = -1
	
	for i in range(9):
		if board[i] == null:
			board[i] = "O"
			var score = minimax(board, 0, false)
			board[i] = null
			
			if score > best_score:
				best_score = score
				best_move = i
	
	return best_move

func minimax(test_board: Array, depth: int, is_maximizing: bool) -> float:
	var result = check_win_for_minimax(test_board)
	
	if result == "O":
		return 10.0 - depth
	elif result == "X":
		return depth - 10.0
	elif result == "DRAW":
		return 0.0
	
	if is_maximizing:
		var best_score = -INF
		for i in range(9):
			if test_board[i] == null:
				test_board[i] = "O"
				var score = minimax(test_board, depth + 1, false)
				test_board[i] = null
				best_score = max(best_score, score)
		return best_score
	else:
		var best_score = INF
		for i in range(9):
			if test_board[i] == null:
				test_board[i] = "X"
				var score = minimax(test_board, depth + 1, true)
				test_board[i] = null
				best_score = min(best_score, score)
		return best_score

func check_win_for_minimax(test_board: Array) -> String:
	for line in WIN_LINES:
		var a = test_board[line[0]]
		var b = test_board[line[1]]
		var c = test_board[line[2]]
		
		if a != null and a == b and a == c:
			return a
	
	var all_filled = true
	for cell in test_board:
		if cell == null:
			all_filled = false
			break
	
	if all_filled:
		return "DRAW"
	
	return ""
