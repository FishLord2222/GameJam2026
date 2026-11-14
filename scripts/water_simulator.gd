## WaterSimulator
## 1D wave simulation using the classic adjacent-spring algorithm.
##
## This simulates water as a horizontal line of "points" where each point
## influences its neighbors. When you displace one point (e.g. a ship landing),
## waves propagate outward and bounce back, creating realistic-looking water.
##
## ## How It Works
## Each frame we:
## 1. Apply "springs" that pull each point back toward its rest height
## 2. Propagate velocity between adjacent points (wave travel)
## 3. Apply damping so energy dissipates over time
##
## ## Collaboration Notes
## This class exposes `get_water_height_at(x)` and `set_wave_at(x, height)`
## so other scripts can read and disturb the water. It also emits
## `water_level_changed` if you need to react globally.

class_name WaterSimulator
extends Node2D

signal wave_impact(intensity)

# ─────────────────────────────────────────────
# TUNABLE PARAMETERS (exposed in Inspector)
# ─────────────────────────────────────────────

## Total number of simulation points along the water surface.
## Higher = more detail but more CPU. 200-500 is usually plenty.
@export var resolution: int = 300:
	set(value):
		if value != resolution:
			resolution = value
			_init_arrays()

## Water rest height relative to the node's origin.
## Negative = water sits below this node.
@export var water_y: float = 200.0

## Spring stiffness. Higher = snappier waves that return to rest faster.
@export_range(0.0, 0.3) var spring_strength: float = 0.025

## How much velocity transfers to adjacent points per frame.
## Higher = waves travel faster and farther.
@export_range(0.0, 0.5) var wave_propagation: float = 0.25

## Damping per frame. 0.0 = no damping (waves go forever), 1.0 = instant stop.
@export_range(0.0, 0.05) var damping: float = 0.015

## Ambient wave amplitude — makes the water gently bob even without interaction.
@export_range(0.0, 50.0) var ambient_wave_amplitude: float = 8.0

## Ambient wave speed.
@export_range(0.0, 5.0) var ambient_wave_speed: float = 2.0

## Ambient wave frequency (how many wave peaks across the width).
@export_range(0.5, 10.0) var ambient_wave_frequency: float = 3.0

## World width covered by the simulation (pixels).
@export var sim_width: float = 2000.0

# ─────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────

## Height displacement for each point (relative to rest height).
var heights: PackedFloat32Array = PackedFloat32Array()

## Velocity for each point (how fast it's moving up/down).
var velocities: PackedFloat32Array = PackedFloat32Array()

## Time accumulator for ambient waves.
var _time: float = 0.0

## Whether the simulation is active.
var _active: bool = false


# ─────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────

func _init_arrays() -> void:
	heights.resize(resolution)
	velocities.resize(resolution)
	for i in range(resolution):
		heights[i] = 0.0
		velocities[i] = 0.0


func _ready() -> void:
	_init_arrays()
	_active = true


# ─────────────────────────────────────────────
# SIMULATION STEP
# ─────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _active:
		return

	_time += delta

	# 1. Propagate waves between adjacent points
	_propagate_waves()

	# 2. Apply spring forces + damping
	_apply_springs_and_damping()

	# 3. Add ambient wave motion
	_apply_ambient_waves(delta)


## Main simulation step: propagate waves between neighbors.
## Uses a temporary array to prevent instantaneous infinite propagation.
func _propagate_waves() -> void:
	var velocity_deltas: PackedFloat32Array = PackedFloat32Array()
	velocity_deltas.resize(resolution)

	# Left-to-right pass
	for i in range(1, resolution):
		var delta = -velocities[i - 1] * wave_propagation
		velocity_deltas[i] += delta

	# Right-to-left pass
	for i in range(resolution - 2, -1, -1):
		var delta = -velocities[i + 1] * wave_propagation
		velocity_deltas[i] += delta

	# Apply accumulated deltas
	for i in range(resolution):
		velocities[i] += velocity_deltas[i]


## Apply spring force (pull back to rest) and damping (lose energy).
func _apply_springs_and_damping() -> float:
	var max_impact: float = 0.0

	for i in range(resolution):
		# Spring: accelerate toward rest height
		velocities[i] += -heights[i] * spring_strength

		# Damping: reduce velocity
		velocities[i] *= (1.0 - damping)

		# Update height
		heights[i] += velocities[i]

		# Track max impact for events
		if absf(velocities[i]) > max_impact:
			max_impact = absf(velocities[i])

	return max_impact


## Add gentle ambient sine-wave motion so water isn't perfectly still.
func _apply_ambient_waves(delta: float) -> void:
	for i in range(resolution):
		var x_ratio = float(i) / float(resolution)
		var wave = sin(x_ratio * TAU * ambient_wave_frequency + _time * ambient_wave_speed)
		heights[i] += wave * ambient_wave_amplitude * delta * 0.5


# ─────────────────────────────────────────────
# PUBLIC API — for other scripts to interact
# ─────────────────────────────────────────────

## Get the world Y position of the water surface at a given world X coordinate.
func get_water_height_at(world_x: float) -> float:
	var index = _world_x_to_index(world_x)
	if index < 0.0 or index >= float(resolution):
		return water_y  # Outside sim bounds → flat water

	# Interpolate between two neighboring points for smoothness
	var left_idx = int(clampf(index, 0.0, float(resolution) - 1.0))
	var right_idx = int(clampf(index + 1.0, 0.0, float(resolution) - 1.0))
	var frac = index - floor(index)

	var h_left = heights[left_idx]
	var h_right = heights[right_idx]
	var interpolated = lerp(h_left, h_right, frac)

	return water_y + interpolated


## Get the water angle (slope) at a world X position.
## Useful for tilting the ship to match the wave.
func get_water_angle_at(world_x: float) -> float:
	var delta_x: float = 10.0  # Sample 10px apart for slope
	var h1 = get_water_height_at(world_x - delta_x)
	var h2 = get_water_height_at(world_x + delta_x)
	return atan2(h2 - h1, delta_x * 2.0)


## Create a wave disturbance at a world X position.
## `height` = how far to push the water (positive = up, negative = down)
## `radius` = spread of the disturbance
func set_wave_at(world_x: float, height: float, radius: float = 50.0) -> void:
	var center_idx = _world_x_to_index(world_x)
	var radius_idx = int(radius / _get_point_spacing())

	for i in range(resolution):
		var dist = absf(float(i) - center_idx)
		if dist <= float(radius_idx):
			# Quadratic falloff
			var influence = 1.0 - dist / float(radius_idx)
			influence = influence * influence
			velocities[i] += height * influence


## Drop an object into the water (simulates impact).
func create_impact(world_x: float, velocity: float, mass: float = 1.0) -> void:
	var intensity = absf(velocity) * mass
	set_wave_at(world_x, -intensity * 5.0, 80.0)
	if intensity > 2.0:
		wave_impact.emit(intensity)


## Reset all waves (smooth out the water).
func calm_water() -> void:
	for i in range(resolution):
		heights[i] = 0.0
		velocities[i] = 0.0


# ─────────────────────────────────────────────
# DRAWING — visualize the water surface
# ─────────────────────────────────────────────

func _draw() -> void:
	if resolution < 2:
		return

	var point_spacing = _get_point_spacing()
	var start_x = -sim_width / 2.0

	# Draw water surface line
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(resolution):
		var x = start_x + i * point_spacing
		var y = water_y + heights[i]
		points.append(Vector2(x, y))

	if points.size() >= 2:
		draw_polyline(points, Color(0.1, 0.3, 0.6, 0.8), 2.0, true)

	# Draw water body below the surface (filled area)
	var fill: PackedVector2Array = PackedVector2Array()
	for i in range(resolution):
		var x = start_x + i * point_spacing
		var y = water_y + heights[i]
		fill.append(Vector2(x, y))

	# Close the polygon at the bottom
	fill.append(Vector2(start_x + (resolution - 1) * point_spacing, water_y + 400))
	fill.append(Vector2(start_x, water_y + 400))

	draw_colored_polygon(fill, Color(0.05, 0.15, 0.4, 0.4))


# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

func _get_point_spacing() -> float:
	return sim_width / float(resolution)


func _world_x_to_index(world_x: float) -> float:
	var start_x = -sim_width / 2.0
	return (world_x - start_x) / _get_point_spacing()
