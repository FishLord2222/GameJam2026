extends Control

signal design_changed

const Parts = preload("res://scripts/boat_parts.gd")
const COLS := 12
const ROWS := 8
const CELL := 48.0
var cells: Dictionary = {}
var selected_part: int = Parts.HULL
var _drag_button: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(COLS * CELL, ROWS * CELL)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# A compact starting boat that can be tested immediately.
	for x in range(3, 9):
		cells[Vector2i(x, 5)] = Parts.HULL
	for x in range(4, 8):
		cells[Vector2i(x, 4)] = Parts.DECK
	cells[Vector2i(2, 5)] = Parts.MOTOR

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("112e43"))
	for y in range(ROWS):
		for x in range(COLS):
			var rect := Rect2(x * CELL, y * CELL, CELL, CELL)
			var shade := Color("1d4255") if (x + y) % 2 == 0 else Color("20485a")
			draw_rect(rect.grow(-1), shade)
			var cell := Vector2i(x, y)
			if cells.has(cell):
				Parts.draw_part(self, rect, cells[cell])
			draw_rect(rect, Color(0.63, 0.84, 0.84, 0.14), false, 1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_drag_button = event.button_index if event.pressed else 0
			if event.pressed:
				_paint(event.position, _drag_button)
	elif event is InputEventMouseMotion and _drag_button != 0:
		_paint(event.position, _drag_button)

func _paint(pos: Vector2, button: int) -> void:
	var p := Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))
	if p.x < 0 or p.x >= COLS or p.y < 0 or p.y >= ROWS:
		return
	if button == MOUSE_BUTTON_RIGHT:
		cells.erase(p)
	else:
		cells[p] = selected_part
	queue_redraw()
	design_changed.emit()

func design_is_connected() -> bool:
	if cells.is_empty():
		return false
	var visited := {}
	var pending: Array = [cells.keys()[0]]
	while not pending.is_empty():
		var current: Vector2i = pending.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + d
			if cells.has(next) and not visited.has(next):
				pending.append(next)
	return visited.size() == cells.size()

