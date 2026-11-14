## Main
## Entry point for the game. Sets up the water simulation,
## spawns the ship, and handles game state.

extends Node2D

# Use Node2D to avoid headless load-order issues with class_name
@onready var water_simulator: Node2D = $WaterSimulator
@onready var water_visuals: Node2D = $WaterVisuals

# Ship configuration
var ship_scene: PackedScene
var ship: Node2D
var ship_spawn_position: Vector2 = Vector2(0, 50)  # Start above water


func _ready() -> void:
	_setup_water()
	_spawn_ship()
	_connect_signals()
	print("[GameJam2026] Game started!")
	print("  Water simulation: %d points" % water_simulator.resolution)
	print("  Ship spawn: ", ship_spawn_position)


func _setup_water() -> void:
	# Link water visuals to simulator
	water_visuals.water_simulator = water_simulator


func _spawn_ship() -> void:
	# Load and instantiate the ship scene
	ship_scene = load("res://scenes/ship.tscn")
	ship = ship_scene.instantiate()
	
	# Link ship to water simulator
	ship.water_simulator = water_simulator
	ship.position = ship_spawn_position
	
	# Add to scene (under Main)
	add_child(ship)


func _connect_signals() -> void:
	if ship:
		ship.connect("ship_entered_water",Callable(self,"_on_ship_entered_water"))
		ship.connect("ship_exited_water",Callable(self,"_on_ship_exited_water"))


func _on_ship_entered_water() -> void:
	print("[Ship] Entered water!")
	# TODO: Play splash sound, enable foam particles


func _on_ship_exited_water() -> void:
	print("[Ship] Left water!")
	# TODO: Play exit sound, disable particles


# ─────────────────────────────────────────────
# DEBUG / TESTING
# ─────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Press R to reset ship position
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_reset_ship()
		
		# Press Space to create a big wave (testing)
		if event.keycode == KEY_SPACE:
			water_simulator.set_wave_at(ship.position.x, -50.0, 100.0)
		
		# Press C to calm the water (testing)
		if event.keycode == KEY_C:
			water_simulator.calm_water()


func _reset_ship() -> void:
	if ship:
		ship.reset_position(ship_spawn_position)
		print("[Game] Ship reset")
