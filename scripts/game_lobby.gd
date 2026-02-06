extends Control

@onready var ludo_button = $HBoxContainer/Sidebar/LudoButton
@onready var snakes_button = $HBoxContainer/Sidebar/SnakesButton
@onready var ttt_button = $HBoxContainer/Sidebar/TTTButton
@onready var players_list = $HBoxContainer/Sidebar/PlayersList
@onready var game_container = $HBoxContainer/GameContainer

var current_game_scene: Node = null
var game_state: Node

func _ready():
	game_state = get_node("/root/GameState")
	
	ludo_button.pressed.connect(func(): switch_game("LUDO"))
	snakes_button.pressed.connect(func(): switch_game("SNAKES"))
	ttt_button.pressed.connect(func(): switch_game("TTT"))
	
	Global.player_joined.connect(_on_player_joined)
	Global.player_left.connect(_on_player_left)
	Global.game_switched.connect(_on_game_switched)
	
	update_players_list()
	switch_game(Global.current_game)

func switch_game(game_type: String):
	if Global.is_host:
		game_state.network_manager.switch_game(game_type)
	Global.current_game = game_type
	_load_game_scene(game_type)

func _on_game_switched(game_type: String):
	_load_game_scene(game_type)

func _load_game_scene(game_type: String):
	if current_game_scene:
		current_game_scene.queue_free()
	
	var scene_path = ""
	match game_type:
		"LUDO":
			scene_path = "res://scenes/ludo_board.tscn"
		"SNAKES":
			scene_path = "res://scenes/snakes_board.tscn"
		"TTT":
			scene_path = "res://scenes/ttt_board.tscn"
	
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path).instantiate()
		game_container.add_child(scene)
		current_game_scene = scene

func update_players_list():
	# Clear existing
	for child in players_list.get_children():
		child.queue_free()
	
	for player in Global.players:
		var label = Label.new()
		label.text = player.name + " (" + player.color + ")"
		players_list.add_child(label)

func _on_player_joined(player_data):
	update_players_list()

func _on_player_left(player_id):
	update_players_list()
