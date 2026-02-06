extends Control

@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton
@onready var ip_input = $VBoxContainer/IPInput
@onready var check_bot = $VBoxContainer/CheckBot

var game_state: Node

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	# Load or create game state
	if not has_node("/root/GameState"):
		game_state = preload("res://scripts/game_state.gd").new()
		game_state.name = "GameState"
		get_tree().root.add_child(game_state)
	else:
		game_state = get_node("/root/GameState")

func _on_host_pressed():
	Global.with_bot = check_bot.button_pressed
	Global.is_host = true
	Global.room_code = Global.generate_room_code()
	
	# Create host player
	var host_player = {
		"id": Global.player_id,
		"name": Global.player_name,
		"color": "cyan",
		"is_ready": true
	}
	Global.players = [host_player]
	
	# Add bot if requested
	if Global.with_bot:
		var bot_player = {
			"id": randi(),
			"name": "BOT",
			"color": "magenta",
			"is_ready": true
		}
		Global.players.append(bot_player)
	
	# Start server
	game_state.network_manager.create_server()
	
	Global.game_started.emit()
	
	# Switch to game lobby
	get_tree().change_scene_to_file("res://scenes/game_lobby.tscn")

func _on_join_pressed():
	var ip = ip_input.text
	if ip.is_empty():
		ip = "127.0.0.1"
	
	Global.is_host = false
	
	# Join server
	game_state.network_manager.join_server(ip)
	
	# Wait for connection
	await game_state.network_manager.connected_to_server
	
	get_tree().change_scene_to_file("res://scenes/game_lobby.tscn")
