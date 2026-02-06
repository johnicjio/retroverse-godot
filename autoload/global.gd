extends Node

# Global game state
var player_id: int = 0
var player_name: String = ""
var is_host: bool = false
var room_code: String = ""
var current_game: String = "LUDO"  # LUDO, SNAKES, TTT

# Players in session
var players: Array = []  # {id, name, color, is_ready}

# Network status
var is_connected: bool = false
var with_bot: bool = false

# Colors
const PLAYER_COLORS = ["cyan", "magenta", "lime", "yellow"]

signal game_started
signal player_joined(player_data)
signal player_left(player_id)
signal game_switched(game_type)

func _ready():
	randomize()
	player_id = randi()
	player_name = "Player" + str(randi() % 9999)

func generate_room_code() -> String:
	var code = ""
	for i in range(6):
		code += str(randi() % 10)
	return code

func get_available_color() -> String:
	var used_colors = []
	for p in players:
		used_colors.append(p.color)
	
	for color in PLAYER_COLORS:
		if color not in used_colors:
			return color
	return "cyan"
