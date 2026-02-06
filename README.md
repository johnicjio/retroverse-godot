# Retroverse - Multiplayer Board Games (Godot)

**Play Ludo, Snakes & Ladders, and Tic-Tac-Toe with friends online!**

Built with Godot 4 and GDScript for smooth multiplayer gameplay.

## Features

✅ **3 Classic Games:**
- **Ludo** - Complete rules with blockades, captures, safe zones, exact home landing
- **Snakes & Ladders** - Real snakes/ladders, exact 100 rule
- **Tic-Tac-Toe** - Minimax AI (unbeatable bot)

✅ **Multiplayer:**
- Host/Join games via IP (ENet networking)
- Up to 4 players (Ludo) / 2 players (Snakes) / 2 players (TTT)
- Real-time synchronization

✅ **AI Bot:**
- Play solo against intelligent AI
- Bot plays all 3 games
- Adjustable difficulty (currently smart)

✅ **Game Feel:**
- Smooth animations with Tween
- Colorful visuals
- Turn-based gameplay
- Win detection and celebration

## How to Run

### Prerequisites
- Download [Godot 4.3+](https://godotengine.org/download)

### Steps
1. Clone this repo:
   ```bash
   git clone https://github.com/johnicjio/retroverse-godot.git
   cd retroverse-godot
   ```

2. Open Godot Engine
3. Click **Import** → Navigate to `project.godot` → **Import & Edit**
4. Press **F5** to run

### Playing

**Host a Game:**
1. Check "Play with AI Bot" (optional)
2. Click "Host Game"
3. Share your local IP with friends

**Join a Game:**
1. Enter host's IP address
2. Click "Join Game"

**Switch Games:**
- Use sidebar buttons in lobby to switch between Ludo/Snakes/TTT

## Game Rules

### Ludo
- Roll 6 to exit yard
- Capture opponents on non-safe tiles
- 2+ pieces of same color = blockade (blocks opponents)
- Roll 6 or capture = bonus turn
- Three 6s in a row = forfeit turn
- Get all 4 pieces home to win

### Snakes & Ladders
- Roll dice to move
- Land on snake = slide down
- Land on ladder = climb up
- Exact roll needed to reach 100

### Tic-Tac-Toe
- X goes first (Host)
- O is second player or Bot
- Get 3 in a row to win
- Bot uses minimax (perfect play)

## Architecture

```
scripts/
├── network_manager.gd   # ENet P2P networking
├── game_state.gd        # Orchestrates all engines
├── ludo_engine.gd       # Ludo rules + logic
├── snakes_engine.gd     # Snakes rules + logic
├── ttt_engine.gd        # TTT rules + minimax AI
└── ai_bot.gd            # Bot player for all games

scenes/
├── main_menu.tscn       # Host/Join screen
├── game_lobby.tscn      # Game selection + player list
├── ludo_board.tscn      # Ludo visual board
├── snakes_board.tscn    # Snakes visual board
└── ttt_board.tscn       # TTT visual board

autoload/
└── global.gd            # Global state (players, room, game type)
```

## Export for Web/Desktop

**Web (HTML5):**
1. Project → Export
2. Add "Web" preset
3. Export Project
4. Upload to itch.io or serve locally

**Desktop:**
1. Project → Export
2. Add Windows/Linux/Mac preset
3. Export executable

## TODO / Future Features

- [ ] Sound effects (dice roll, piece move, win)
- [ ] Particle effects (captures, snakes, ladders)
- [ ] Room codes instead of IP addresses
- [ ] Lobby chat
- [ ] Save/resume games
- [ ] More board game variants
- [ ] Leaderboards

## Credits

Built by **johnicjio**  
Engine: Godot 4.3  
Language: GDScript

## License

MIT License - Feel free to use and modify!
