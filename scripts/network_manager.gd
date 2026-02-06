extends Node

const DEFAULT_PORT = 7777
const MAX_PLAYERS = 4

var peer = ENetMultiplayerPeer.new()

signal connected_to_server
signal connection_failed
signal player_connected_signal(id)
signal player_disconnected_signal(id)

func create_server(port: int = DEFAULT_PORT):
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	Global.is_host = true
	Global.is_connected = true
	print("Server created on port ", port)

func join_server(ip: String, port: int = DEFAULT_PORT):
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	Global.is_host = false

func _on_player_connected(id: int):
	print("Player connected: ", id)
	player_connected_signal.emit(id)
	
	# Host sends current game state to new player
	if Global.is_host:
		rpc_id(id, "receive_game_state", Global.current_game, Global.players)

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	player_disconnected_signal.emit(id)
	
	# Remove from players list
	for i in range(Global.players.size()):
		if Global.players[i].id == id:
			Global.players.remove_at(i)
			Global.player_left.emit(id)
			break

func _on_connected_to_server():
	print("Connected to server")
	Global.is_connected = true
	connected_to_server.emit()
	
	# Send player info to host
	rpc_id(1, "register_player", Global.player_id, Global.player_name)

func _on_connection_failed():
	print("Connection failed")
	connection_failed.emit()

@rpc("any_peer", "call_remote")
func register_player(id: int, pname: String):
	if not Global.is_host:
		return
	
	var player_data = {
		"id": id,
		"name": pname,
		"color": Global.get_available_color(),
		"is_ready": true
	}
	
	Global.players.append(player_data)
	Global.player_joined.emit(player_data)
	
	# Broadcast to all clients
	rpc("receive_player_list", Global.players)

@rpc("authority", "call_remote")
func receive_game_state(game_type: String, player_list: Array):
	Global.current_game = game_type
	Global.players = player_list

@rpc("authority", "call_remote")
func receive_player_list(player_list: Array):
	Global.players = player_list

@rpc("any_peer", "call_remote")
func switch_game(game_type: String):
	if Global.is_host:
		Global.current_game = game_type
		rpc("receive_game_switch", game_type)

@rpc("authority", "call_remote")
func receive_game_switch(game_type: String):
	Global.current_game = game_type
	Global.game_switched.emit(game_type)
