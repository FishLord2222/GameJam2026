# Pirate characters

Each character has a Godot scene containing an AnimatedSprite2D and two looping animations, `idle` and `walk`. Drag a `.tscn` into a scene, then call `$Pirate.play("walk")` or `$Pirate.play("idle")`. Use `flip_h` to face left. Adjust the node scale to fit the game.

The sheets are generated artwork. Their frames are divided into a 4-by-2 grid; inspect animation and positioning in-game and adjust if needed. These are visual sprites, with no movement or collision logic.
