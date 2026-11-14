# GameJam2026 — Floating Ship

A Godot 4.3 2D game featuring realistic water physics and a buoyant ship.

## 🚀 Quick Start

1. Open Godot 4.3+
2. Import `project.godot` from this directory
3. Press **F5** to run

## 🎮 Controls

| Key | Action |
|-----|--------|
| ← → | Rotate ship |
| ↑ | Thrust forward |
| ↓ | Reverse thrust |
| R | Reset ship position |
| Space | Create test wave |
| C | Calm water |

## 📁 Project Structure

```
GameJam2026/
├── project.godot          # Godot project file
├── scenes/
│   ├── main_scene.tscn    # Main game scene
│   └── ship.tscn          # Ship prefab
├── scripts/
│   ├── main.gd            # Scene setup & game state
│   ├── water_simulator.gd # 1D wave physics simulation
│   ├── ship_controller.gd # Buoyancy, movement, input
│   └── water_visuals.gd   # Water surface rendering
├── shaders/               # Custom shaders (coming soon)
└── assets/                # Art, audio, fonts
```

## 🔧 Core Systems

### Water Simulator (`water_simulator.gd`)
- **Algorithm**: 1D adjacent-spring wave simulation
- **Tunable**: Resolution, spring strength, propagation, damping
- **API**: `get_water_height_at(x)`, `get_water_angle_at(x)`, `set_wave_at(x, height)`
- **Ambient waves**: Configurable sine-wave background motion

### Ship Controller (`ship_controller.gd`)
- **Buoyancy**: Depth-based upward force with water drag
- **Wave alignment**: Ship tilts to match wave slope
- **Wakes**: Moving ship creates wave disturbances
- **Signals**: `ship_entered_water`, `ship_exited_water`

### Water Visuals (`water_visuals.gd`)
- Filled water body with gradient coloring
- Foam particles at wave peaks
- Surface shimmer line
- Caustic light patterns underwater

## 🤝 Collaboration Guide

### Working with ChatGPT alongside this agent

**Division of labor suggestion:**

| This Agent (Terminal) | ChatGPT |
|----------------------|---------|
| Write/modify code files | Review code, suggest improvements |
| Run & test in Godot | Brainstorm game design |
| Git commits & pushes | Write design docs & tutorials |
| Debug runtime errors | Refactor suggestions |
| Create new scenes/scripts | Balance tuning advice |

**Sync workflow:**
1. This agent writes code → commits to repo
2. You review with ChatGPT → discuss improvements
3. This agent implements changes → commits
4. Repeat!

### Key Parameters to Tune

**In `water_simulator.gd`:**
- `spring_strength` (0.0-0.3) — Wave snappiness
- `wave_propagation` (0.0-0.5) — Wave speed
- `damping` (0.0-0.05) — Energy loss
- `ambient_wave_amplitude` — Background wave size

**In `ship_controller.gd`:**
- `buoyancy_strength` — Float responsiveness
- `water_drag` — Dampening in water
- `wave_align_strength` — How much waves tilt the ship
- `max_thrust_speed` — Ship speed cap

### Adding New Features

1. **New scripts** → Add to `scripts/` with `class_name`
2. **New scenes** → Add to `scenes/`
3. **Assets** → Add to `assets/` (art, audio, etc.)
4. **Shaders** → Add to `shaders/` as `.gdshader` files

## 🎯 Next Steps (TODO)

- [ ] Add ship sprite/art
- [ ] Add splash particle effects
- [ ] Add sound effects (wave crash, engine)
- [ ] Add camera follow
- [ ] Add UI (health, speed)
- [ ] Add obstacles/collectibles
- [ ] Add day/night cycle
- [ ] Add rain effects on water

## ⚙️ Technical Details

- **Engine**: Godot 4.3 (GDScript 2.0)
- **Renderer**: OpenGL Compatibility (mobile-friendly)
- **Resolution**: 1280×720
- **Physics**: Custom 1D wave sim + Godot 2D physics
- **Target**: 60 FPS

---
*Built for Game Jam 2026*
