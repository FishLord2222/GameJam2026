## WaterVisuals
## Renders the animated water surface using a custom shader.
##
## This sits ON TOP of the WaterSimulator and draws a visually rich
## water surface with color gradients, specular-like highlights,
## and animated wave patterns.
##
## The shader reads from the WaterSimulator's wave state for
## synchronized visuals, but also has its own aesthetic animation.

extends Node2D

# Reference to the water simulation
@export var water_simulator: Node2D

# Water visual parameters
@export var water_color_deep: Color = Color(0.02, 0.08, 0.25)
@export var water_color_shallow: Color = Color(0.1, 0.3, 0.55)
@export var foam_color: Color = Color(0.6, 0.75, 0.9)

# Wave rendering
@export var wave_amplitude_visual: float = 5.0
@export var wave_speed_visual: float = 3.0
@export var wave_segments: int = 200

var _time: float = 0.0


func _ready() -> void:
	if not water_simulator:
		water_simulator = _find_water_simulator()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not water_simulator:
		return

	var sim_width = water_simulator.sim_width
	var water_y_base = water_simulator.water_y
	var resolution = water_simulator.resolution
	var heights = water_simulator.heights
	var velocities = water_simulator.velocities
	var point_spacing = sim_width / float(resolution)
	var start_x = -sim_width / 2.0

	# ── Draw water body (gradient fill below surface) ──
	var water_poly: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()

	for i in range(resolution):
		var x = start_x + i * point_spacing
		var y = water_y_base + heights[i]
		water_poly.append(Vector2(x, y))
		# Deeper color for each point (will blend)
		colors.append(water_color_deep)

	# Close polygon at bottom
	var bottom_y = water_y_base + 500
	water_poly.append(Vector2(start_x + (resolution - 1) * point_spacing, bottom_y))
	colors.append(water_color_deep)
	water_poly.append(Vector2(start_x, bottom_y))
	colors.append(water_color_deep)

	# Draw filled water body with per-vertex colors
	draw_polygon(water_poly, colors)

	# ── Draw animated foam line on surface ──
	for i in range(resolution - 1):
		var x1 = start_x + i * point_spacing
		var y1 = water_y_base + heights[i]
		var x2 = start_x + (i + 1) * point_spacing
		var y2 = water_y_base + heights[i + 1]

		# Add visual sparkle based on wave velocity
		var velocity = velocities[i] if i < velocities.size() else 0.0
		var foam_amount = clampf(absf(velocity) * 0.05, 0.0, 1.0)

		if foam_amount > 0.1:
			var foam_pos = Vector2((x1 + x2) / 2.0, (y1 + y2) / 2.0 - 2.0)
			var foam_size = 3.0 + foam_amount * 8.0
			draw_circle(foam_pos, foam_size * 0.5, foam_color * (0.3 + foam_amount * 0.7))

	# ── Draw secondary wave highlight (shimmering surface line) ──
	var highlight_poly: PackedVector2Array = PackedVector2Array()
	for i in range(0, resolution, 2):  # Every other point for perf
		var x = start_x + i * point_spacing
		var base_y = water_y_base + heights[i]
		# Add visual-only ripple on top of physics
		var visual_ripple = sin(i * 0.15 + _time * wave_speed_visual) * wave_amplitude_visual
		var y = base_y + visual_ripple * 0.3

		highlight_poly.append(Vector2(x, y))

	if highlight_poly.size() >= 2:
		draw_polyline(highlight_poly, water_color_shallow * 1.5, 1.5, true)

	# ── Draw deeper caustic patterns (animated) ──
	for i in range(8):
		var cx = start_x + (sim_width / 9.0) * (i + 0.5)
		var cx_offset = sin(_time * 0.7 + i * 1.3) * 30.0
		var cy = water_y_base + 60.0 + sin(_time * 0.5 + i) * 20.0
		var size = 40.0 + sin(_time + i * 2.0) * 15.0

		var caustic_color = water_color_shallow * 0.2
		draw_circle(Vector2(cx + cx_offset, cy), size, caustic_color)


func _find_water_simulator() -> Node2D:
	var parent = get_parent()
	while parent:
		for child in parent.get_children():
			if child.has_method("set_wave_at"):
				return child
		parent = parent.get_parent()
	return null
