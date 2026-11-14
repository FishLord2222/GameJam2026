# GameJam2026 — Shipyard prototype

Build a boat from blocks and carry the captain safely across the sea. Open `project.godot` in Godot 4.3 or newer and press F5.

## How to play

- Select Hull, Deck, or Motor in the shipyard. Left-click or drag to place blocks; right-click or drag to remove them.
- Your design must be connected edge-to-edge and contain at least one hull and one motor. A starter design is ready to sail.
- Select **Set Sail**. Use Left/Right or A/D to steer toward the flag on the right. Choose **Shipyard** to edit the same design again.

The boat uses a lightweight, game-oriented floating model. Hulls support the design, other parts increase draft, and additional motors increase speed. Obstacles and a full construction physics simulation are not implemented yet.

## Project files

- `scripts/main.gd`: shipyard UI and test-mode flow.
- `scripts/builder_grid.gd`, `scripts/boat_parts.gd`: grid editing and block drawing.
- `scripts/built_boat.gd`: launches and moves the assembled boat.
- `scripts/water_simulator.gd`, `scripts/water_visuals.gd`, `scripts/ocean_sky.gd`: waves and ocean presentation.
- `assets/characters/pirates/`: character scenes; five currently have swimming animations. The captain rides on the constructed boat; hazards and independent character movement are not implemented yet.
