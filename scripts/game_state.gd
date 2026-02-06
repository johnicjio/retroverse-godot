extends Node

var ludo_engine: LudoEngine
var snakes_engine: SnakesEngine
var ttt_engine: TTTEngine
var ai_bot: AIBot
var network_manager: Node

func _ready():
	ludo_engine = LudoEngine.new()
	snakes_engine = SnakesEngine.new()
	ttt_engine = TTTEngine.new()
	ai_bot = AIBot.new()
	network_manager = preload("res://scripts/network_manager.gd").new()
	
	add_child(ludo_engine)
	add_child(snakes_engine)
	add_child(ttt_engine)
	add_child(ai_bot)
	add_child(network_manager)
	
	# Connect signals
	Global.game_started.connect(_on_game_started)
	Global.game_switched.connect(_on_game_switched)

func _on_game_started():
	print("Game started with ", Global.players.size(), " players")
	
	# Initialize all engines
	ludo_engine.initialize(Global.players)
	snakes_engine.initialize(Global.players)
	ttt_engine.initialize()
	
	# Setup bot if enabled
	if Global.with_bot:
		var bot_player = null
		for p in Global.players:
			if p.name == "BOT":
				bot_player = p
				break
		
		if bot_player:
			ai_bot.set_bot_player(bot_player.id)

func _on_game_switched(game_type: String):
	print("Switched to: ", game_type)
	Global.current_game = game_type
