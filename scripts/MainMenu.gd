extends Control

const PORT = 7777
const MAX_PEERS = 4

@onready var host_button = $VBox/HostButton
@onready var join_button = $VBox/JoinButton
@onready var ip_input = $VBox/IPInput
@onready var status_label = $VBox/Status

var peer: ENetMultiplayerPeer

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PEERS)
	
	if error != OK:
		status_label.text = "Failed to create server"
		return
	
	multiplayer.multiplayer_peer = peer
	status_label.text = "Hosting on port %d" % PORT
	host_button.disabled = true
	join_button.disabled = true
	
	# Wait a moment then go to lobby
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/GameLobby.tscn")

func _on_join_pressed():
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		status_label.text = "Failed to connect"
		return
	
	multiplayer.multiplayer_peer = peer
	status_label.text = "Connecting to %s:%d..." % [ip, PORT]
	host_button.disabled = true
	join_button.disabled = true

func _on_peer_connected(id: int):
	print("Peer %d connected" % id)

func _on_peer_disconnected(id: int):
	print("Peer %d disconnected" % id)

func _on_connected_to_server():
	status_label.text = "Connected!"
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/GameLobby.tscn")

func _on_connection_failed():
	status_label.text = "Connection failed"
	host_button.disabled = false
	join_button.disabled = false
