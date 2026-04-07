# Player Scaffolder

A Godot 4 editor plugin that generates a genre-based player scene with all the essentials — so you can skip the boilerplate and get straight to building your game.

## What it does

Instead of manually creating a `CharacterBody3D`, setting up cameras, writing movement code, and wiring up systems every time you start a new project, Player Scaffolder lets you pick a genre, tweak the settings, and generate a fully functional starting point in seconds.

The generated player is not a finished product — it's a clean, readable foundation you can extend however you like.

## Installation

1. Copy the `addons/player_scaffolder/` folder into your project's `addons/` directory.
2. Open **Project → Project Settings → Plugins** and enable **Player Scaffolder**.
3. The tool is now available under **Project → Tools → Player Scuffolder/Create Player...**.

## Usage

1. Open **Editor → Create Player...**
2. Select a **Genre** — this fills in sensible defaults for all options.
3. Adjust **Movement** features (Sprint, Crouch, Jump, Prone) as needed.
4. Toggle **Systems** (Health, Inventory, Stamina).
5. Set your **Player Name**, **Scene Path**, and **Script Path**.
6. Click **Generate**.

The plugin will:
- Create a `CharacterBody3D` scene at your specified scene path
- Write a config-specific `player_controller.gd` to your script path
- Copy system scripts (`health_system.gd`, `inventory.gd`, `stamina_system.gd`) as needed
- Register all required **Input Actions** in your `project.godot`
- Add a **HUD** with a crosshair and interaction label
- Open the generated scene automatically in the editor

> **Note:** It is recommended to restart the editor after generating a player so that the new Input Actions appear in the Input Map Editor. They are functional immediately without a restart.

## Genre Presets

| Genre | Sprint | Crouch | Jump | Prone | Inventory |
|---|---|---|---|---|---|
| Horror | ✓ | ✓ | — | — | ✓ |
| Survival | ✓ | ✓ | ✓ | — | ✓ |
| Simulator | ✓ | ✓ | — | — | ✓ |
| Shooter – Classic | ✓ | ✓ | ✓ | — | — |
| Shooter – BR/Extraction | ✓ | ✓ | ✓ | ✓ | ✓ |

All presets are fully adjustable before generating.

## Generated Structure

```
scenes/player/
└── player.tscn
    ├── CollisionShape3D
    ├── CameraTarget
    ├── Camera3D              (FPS / FPS+TP)
    ├── SpringArm3D           (TP / FPS+TP)
    │   └── ThirdPersonCamera
    ├── InteractRay
    ├── HealthSystem          (if enabled)
    ├── Inventory             (if enabled)
    ├── StaminaSystem         (if enabled)
    └── HUD (CanvasLayer)
        └── Control
            └── VBoxContainer
                ├── Crosshair
                └── InteractionLbl

scripts/player/
├── player_controller.gd
├── interact.gd
├── health_system.gd          (if enabled)
├── inventory.gd              (if enabled)
└── stamina_system.gd         (if enabled)
```

## Default Input Actions

| Action | Default Key |
|---|---|
| move_forward | W |
| move_back | S |
| move_left | A |
| move_right | D |
| interact | F |
| sprint | Shift *(if enabled)* |
| crouch | C *(if enabled)* |
| jump | Space *(if enabled)* |
| prone | Z *(if enabled)* |
| toggle_view | V *(FPS+TP only)* |
| zoom_in | Mouse Wheel Up *(non-shooter FPS+TP only)* |
| zoom_out | Mouse Wheel Down *(non-shooter FPS+TP only)* |

## Requirements

- Godot 4.2 or later
- Jolt Physics is recommended but not required

## License

MIT License — free to use in personal and commercial projects.
