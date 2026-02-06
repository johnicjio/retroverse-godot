# Retroverse Arcade - Godot Edition

Multiplayer board games built with **Godot 4** for playing with friends online.

## Games

- **Ludo**: Classic 4-player race game with captures and safe zones
- **Snakes & Ladders**: Race to 100 with snakes and ladders
- **Tic-Tac-Toe**: Strategic 3x3 with smart AI

## Features

✅ **Real multiplayer** using Godot's high-level networking  
✅ **Smooth animations** with tweens and particles  
✅ **Game juice** - sounds, visual feedback, satisfying interactions  
✅ **AI bots** for solo play  
✅ **Web export** ready - play in browser  
✅ **Mobile friendly** touch controls

## Tech Stack

- **Godot 4.3** (game engine)
- **GDScript** (Python-like scripting)
- **High-level multiplayer API** (ENet under the hood)
- **Export targets**: Web (HTML5), Windows, Linux, macOS, Android, iOS

## Setup

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Clone this repo
3. Open `project.godot` in Godot
4. Press F5 to run

## Project Structure

```
scenes/
  MainMenu.tscn          # Start screen with host/join
  GameLobby.tscn         # Player list and game selection
  games/
    Ludo.tscn            # Ludo board
    Snakes.tscn          # Snakes & Ladders
    TicTacToe.tscn       # Tic-Tac-Toe

scripts/
  network/
    NetworkManager.gd    # Handles connections
  games/
    LudoController.gd    # Ludo game logic
    SnakesController.gd  # Snakes logic
    TTTController.gd     # TTT logic
  shared/
    Dice.gd              # Reusable dice

assets/
  sprites/               # Board textures, pieces
  sounds/                # SFX
  fonts/                 # Arcade fonts
```

## Multiplayer

**Host creates room:**
- Click "Host Game"
- Share your IP or use Godot relay
- Friends join automatically

**Client joins:**
- Click "Join Game"
- Enter host IP
- Synced instantly

## Export

**Web (HTML5):**
```bash
Project > Export > Web
```

**Windows/Mac/Linux:**
```bash
Project > Export > [Platform]
```

Deploy to itch.io, GitHub Pages, or any web host.

## License

MIT
