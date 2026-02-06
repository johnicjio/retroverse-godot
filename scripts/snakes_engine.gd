extends Node
class_name SnakesEngine

const SNAKES_MAP = {
	17: 7, 54: 34, 62: 19, 64: 60,
	87: 24, 92: 73, 95: 75, 98: 79
}

const LADDERS_MAP = {
	1: 38, 4: 14, 9: 31, 21: 42,
	28: 84, 51: 67, 71: 91, 80: 100
}

var players: Array = []  # {id, position, color}
var current_turn_index: int = 0
var dice_value: int = 0
var winner_id: int = -1

signal dice_rolled(value)
signal player_moved(player_id, new_position)
signal snake_hit(from_pos, to_pos)
signal ladder_climbed(from_pos, to_pos)
signal player_won(player_id)
signal turn_changed(player_index)

func initialize(player_list: Array):
	players.clear()
	current_turn_index = 0
	dice_value = 0
	winner_id = -1
	
	# Only 2 players for Snakes & Ladders
	for i in range(min(player_list.size(), 2)):
		players.append({
			"id": player_list[i].id,
			"position": 0,
			"color": "cyan" if i == 0 else "magenta"
		})

func roll_dice() -> int:
	if winner_id != -1:
		return 0
	
	var roll = randi() % 6 + 1
	dice_value = roll
	dice_rolled.emit(roll)
	
	var current_player = players[current_turn_index]
	var new_pos = current_player.position + roll
	
	# Rule: Exact roll to reach 100
	if new_pos > 100:
		print("Overshoot! Stay at ", current_player.position)
		next_turn()
		return roll
	
	# Check snakes
	if new_pos in SNAKES_MAP:
		var snake_end = SNAKES_MAP[new_pos]
		print("Snake! ", new_pos, " -> ", snake_end)
		snake_hit.emit(new_pos, snake_end)
		new_pos = snake_end
	
	# Check ladders
	elif new_pos in LADDERS_MAP:
		var ladder_end = LADDERS_MAP[new_pos]
		print("Ladder! ", new_pos, " -> ", ladder_end)
		ladder_climbed.emit(new_pos, ladder_end)
		new_pos = ladder_end
	
	players[current_turn_index].position = new_pos
	player_moved.emit(current_player.id, new_pos)
	
	# Check win
	if new_pos == 100:
		winner_id = current_player.id
		player_won.emit(current_player.id)
		return roll
	
	next_turn()
	return roll

func next_turn():
	current_turn_index = 1 - current_turn_index
	turn_changed.emit(current_turn_index)
