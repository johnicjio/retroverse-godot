extends Control

@onready var player_list = $VBox/PlayerList
@onready var ludo_button = $VBox/GameButtons/LudoButton
@onready var snakes_button = $VBox/GameButtons/SnakesButton
@onready var ttt_button = $VBox/GameButtons/TTTButton

var players = {}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Add self
	var my_id = multiplayer.get_unique_id()
	players[my_id] = {"name": "Player %d" % my_id, "ready": false}
	
	# Only host can start games
	if not multiplayer.is_server():
		ludo_button.disabled = true
		snakes_button.disabled = true
		ttt_button.disabled = true
	
	_update_player_list()

func _on_peer_connected(id: int):
	players[id] = {"name": "Player %d" % id, "ready": false}
	_update_player_list()

func _on_peer_disconnected(id: int):
	players.erase(id)
	_update_player_list()

func _update_player_list():
	player_list.clear()
	for id in players:
		var player = players[id]
		var text = "%s %s" % [player.name, "(Host)" if id == 1 else ""]
		player_list.add_item(text)

func _on_ludo_pressed():
	if multiplayer.is_server():
		_start_game.rpc("res://scenes/games/Ludo.tscn")

func _on_snakes_pressed():
	if multiplayer.is_server():
		_start_game.rpc("res://scenes/games/Snakes.tscn")

func _on_ttt_pressed():
	if multiplayer.is_server():
		_start_game.rpc("res://scenes/games/TicTacToe.tscn")

@rpc("authority", "call_local")
func _start_game(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

func _on_back_pressed():
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
