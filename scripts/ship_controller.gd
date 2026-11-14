## ShipController
## Handles the ship's buoyancy, movement, and interaction with water.
##
## ## How Buoyancy Works
## The ship samples the water height at its position and calculates:
## - How much of the ship is submerged (depth relative to waterline)
## - An upward buoyant force proportional to submerged area
## - A drag force that resists vertical motion in water
## - Rotation torque that aligns the ship with wave slope
##
## ## Controls (default input map)
## - `ui_right` / `ui_left` — Rotate ship
## - `ui_up` — Thrust forward
## - `ui_down` — Reverse thrust
##
## ## Collaboration Notes
## This script connects to a WaterSimulator node (set via @export).
## It emits `ship_entered_water` and `ship_exited_water` signals
## so other systems (UI, particles, sounds) can react.

class_name ShipController
extends CharacterBody2D

signal ship_entered_water
signal ship_exited_water

# ─────────────────────────────────────────────
# EXPOSED PARAMETERS
# ─────────────────────────────────────────────

## Reference to the WaterSimulator node in the scene.
@export var water_simulator: Node2D

## Ship mass (affects buoyancy response).
@export var mass: float = 5.0

## Maximum forward thrust speed.
@export var max_thrust_speed: float = 300.0

## Acceleration when thrusting.
@export var thrust_acceleration: float = 200.0

## Deceleration when not thrusting.
@export var drag_coefficient: float = 0.95

## How fast the ship rotates (degrees per second).
@export var rotation_speed: float = 1.5

## Buoyancy force multiplier. Higher = bouncier float.
@export var buoyancy_strength: float = 300.0

## The Y offset from the ship's origin to its waterline.
## Everything below this offset gets buoyant force when in water.
@export var waterline_offset: float = 20.0

## Water drag (dampens vertical motion while in water).
@export var water_drag: float = 0.85

## Ship tilt influence from wave angle.
@export var wave_align_strength: float = 2.0

# ─────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────

var _in_water: bool = false
var _gravity: float = 600.0  # Downward gravity
var _splash_timer: float = 0.0


# ─────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────

func _ready() -> void:
	if not water_simulator:
		# Try to find it automatically
		water_simulator = _find_water_simulator()
		if not water_simulator:
			printerr("[ShipController] No WaterSimulator found! Assign one in the inspector.")


func _find_water_simulator() -> Node2D:
	# Search parent tree for a WaterSimulator
	var parent = get_parent()
	while parent:
		for child in parent.get_children():
			if child.has_method("set_wave_at"):
				return child
		parent = parent.get_parent()
	return null


# ─────────────────────────────────────────────
# MAIN UPDATE LOOP
# ─────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# 1. Handle input (rotation + thrust)
	_handle_input(delta)

	# 2. Apply gravity
	velocity.y += _gravity * delta

	# 3. Check water interaction
	_handle_water_physics(delta)

	# 4. Apply movement
	move_and_slide()

	# 5. Create waves when moving through water
	if _in_water and velocity.length() > 30.0:
		_create_ship_wakes(delta)


# ─────────────────────────────────────────────
# INPUT HANDLING
# ─────────────────────────────────────────────

func _handle_input(delta: float) -> void:
	# Rotation
	var rotate_left = Input.is_action_pressed("ui_left")
	var rotate_right = Input.is_action_pressed("ui_right")

	if rotate_left:
		rotation -= rotation_speed * delta
	elif rotate_right:
		rotation += rotation_speed * delta

	# Thrust
	var thrust = 0.0
	if Input.is_action_pressed("ui_up"):
		thrust = 1.0
	elif Input.is_action_pressed("ui_down"):
		thrust = -0.5  # Reverse is weaker

	# Apply thrust in ship's forward direction
	if thrust != 0.0:
		var forward = Vector2.UP.rotated(rotation)
		velocity += forward * thrust_acceleration * thrust * delta

	# Clamp speed
	velocity = velocity.limit_length(max_thrust_speed)

	# Apply drag (air resistance)
	if not _in_water:
		velocity *= drag_coefficient


# ─────────────────────────────────────────────
# WATER PHYSICS — BUOYANCY, DRAG, WAVES
# ─────────────────────────────────────────────

func _handle_water_physics(delta: float) -> void:
	if not water_simulator:
		return

	# Get water height at ship's position
	var water_height = water_simulator.get_water_height_at(position.x)

	# Ship's waterline Y in world space
	var ship_waterline_y = position.y + waterline_offset

	# Calculate submersion depth (positive = underwater)
	var submersion = ship_waterline_y - water_height

	# Check if we entered/exited water
	var was_in_water = _in_water
	_in_water = submersion > -5.0  # Slight threshold

	if _in_water and not was_in_water:
		ship_entered_water.emit()
	elif not _in_water and was_in_water:
		ship_exited_water.emit()

	if _in_water:
		_apply_buoyancy(submersion, delta)
		_align_to_wave(delta)
		_impact_water(submersion)


## Apply upward buoyant force based on how deep the ship is.
func _apply_buoyancy(submersion: float, delta: float) -> void:
	if submersion <= 0:
		return

	# Buoyancy force scales with submersion depth
	var buoyancy_force = submersion * buoyancy_strength / mass
	velocity.y -= buoyancy_force * delta

	# Water drag — resist vertical motion
	velocity.y *= water_drag

	# Slight horizontal dampening in water
	velocity.x *= 0.99


## Gently rotate the ship to match the wave angle.
func _align_to_wave(delta: float) -> void:
	if not water_simulator:
		return

	var wave_angle = water_simulator.get_water_angle_at(position.x)
	var angle_diff = wave_angle - rotation

	# Smoothly rotate toward wave angle
	rotation += angle_diff * wave_align_strength * delta


## When the ship hits water hard, create a splash wave.
func _impact_water(submersion: float) -> void:
	if submersion > 10 and velocity.y > 100:
		var impact = velocity.y * 0.1
		water_simulator.create_impact(position.x, impact, mass)

		# Reduce splash frequency
		_splash_timer = 0.3


# ─────────────────────────────────────────────
# WAKE EFFECTS — waves behind the moving ship
# ─────────────────────────────────────────────

func _create_ship_wakes(delta: float) -> void:
	_splash_timer -= delta
	if _splash_timer > 0:
		return

	# Create a wave disturbance at the ship's position
	var wake_strength = velocity.length() * 0.02
	water_simulator.set_wave_at(position.x, wake_strength, 40.0)

	# If moving sideways, create wake at bow and stern
	if absf(velocity.x) > 20:
		var bow_offset = Vector2.RIGHT.rotated(rotation) * 40
		water_simulator.set_wave_at(
			position.x + bow_offset.x,
			wake_strength * 0.5,
			25.0
		)

	_splash_timer = 0.15


# ─────────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────────

## Check if the ship is currently floating.
func is_floating() -> bool:
	return _in_water


## Reset the ship to initial state.
func reset_position(new_position: Vector2) -> void:
	position = new_position
	velocity = Vector2.ZERO
	rotation = 0.0

