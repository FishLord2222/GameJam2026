extends Node2D

signal reached_destination

const Parts = preload("res://scripts/boat_parts.gd")
const CaptainScene = preload("res://assets/characters/pirates/captain.tscn")
const BLOCK_SIZE := 30.0
var cells: Dictionary = {}
var water: Node2D
var velocity := Vector2.ZERO
var engine_count := 0
var hull_count := 0
var _lowest: float = 0.0
var _last_wake: float = 0.0
var _arrived := false

func configure(design: Dictionary, simulator: Node2D) -> void:
	cells = design.duplicate()
	water = simulator
	var min_x := 100
	var max_x := -100
	var min_y := 100
	var max_y := -100
	for cell: Vector2i in cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
		if cells[cell] == Parts.MOTOR:
			engine_count += 1
		elif cells[cell] == Parts.HULL:
			hull_count += 1
	var center := Vector2((min_x + max_x + 1) * BLOCK_SIZE / 2.0, (min_y + max_y + 1) * BLOCK_SIZE / 2.0)
	set_meta("design_center", center)
	_lowest = (max_y + 1) * BLOCK_SIZE - center.y
	# Attach the captain to a topmost block so the passenger follows the boat's
	# motion and rotation. The art is intentionally scaled to fit the blocks.
	var anchor := Vector2i(min_x, min_y)
	var best_distance := INF
	for cell: Vector2i in cells:
		if cell.y == min_y:
			var distance: float = absf(float(cell.x) - (min_x + max_x) * 0.5)
			if distance < best_distance:
				best_distance = distance
				anchor = cell
	var captain := CaptainScene.instantiate() as AnimatedSprite2D
	captain.name = "Captain"
	captain.scale = Vector2.ONE * 0.13
	captain.position = Vector2((anchor.x + 0.5) * BLOCK_SIZE, anchor.y * BLOCK_SIZE) - center + Vector2(0, -23)
	add_child(captain)
	captain.play("idle")
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = get_meta("design_center", Vector2.ZERO)
	for cell: Vector2i in cells:
		var pos := Vector2(cell.x, cell.y) * BLOCK_SIZE - center
		Parts.draw_part(self, Rect2(pos, Vector2.ONE * BLOCK_SIZE), cells[cell])

func _physics_process(delta: float) -> void:
	if not is_instance_valid(water):
		return
	var direction := Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	direction = clampf(direction, -1.0, 1.0)
	var target_speed: float = direction * minf(180.0, 95.0 + 20.0 * engine_count)
	velocity.x = move_toward(velocity.x, target_speed, 100.0 * delta)
	position.x = clampf(position.x + velocity.x * delta, -540.0, 540.0)
	# Hulls support the other blocks; extra weight makes the boat sit lower.
	var draft: float = clampf(8.0 + float(cells.size() - hull_count) * 3.0 / maxf(float(hull_count), 1.0), 8.0, 26.0)
	var target_y: float = water.get_water_height_at(global_position.x) - _lowest + draft
	velocity.y += (target_y - global_position.y) * 18.0 * delta
	velocity.y *= exp(-5.5 * delta)
	position.y += velocity.y * delta
	rotation = lerp_angle(rotation, clampf(water.get_water_angle_at(global_position.x), -0.18, 0.18), minf(1.0, delta * 3.0))
	_last_wake -= delta
	if absf(velocity.x) > 35.0 and _last_wake <= 0.0:
		water.set_wave_at(global_position.x - signf(velocity.x) * 45.0, 0.8, 45.0)
		_last_wake = 0.3
	if not _arrived and position.x >= 500.0:
		_arrived = true
		reached_destination.emit()


