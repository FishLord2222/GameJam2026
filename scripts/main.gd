extends Node2D

const Parts = preload("res://scripts/boat_parts.gd")
const Grid = preload("res://scripts/builder_grid.gd")
const Boat = preload("res://scripts/built_boat.gd")
@onready var water_simulator: Node2D = $WaterSimulator
@onready var water_visuals: Node2D = $WaterVisuals
var boat: Node2D
var grid: Control
var builder: Control
var hud: Control
var status: Label
var launch_button: Button
var palette_buttons: Array[Button] = []

func _ready() -> void:
 water_visuals.water_simulator = water_simulator
 _create_interface()

func _create_interface() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 builder = Control.new()
 builder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 canvas.add_child(builder)
 var shade := ColorRect.new()
 shade.color = Color(0.02, 0.09, 0.15, 0.93)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 builder.add_child(shade)
 _add_label(builder, "THE SHIPYARD", Vector2(56, 36), Vector2(550, 48), 34, Color("f5e6be"))
 _add_label(builder, "Build something that will hold together.", Vector2(58, 85), Vector2(550, 28), 17, Color("a8c9d0"))
 _add_label(builder, "PARTS", Vector2(60, 151), Vector2(200, 26), 15, Color("e6b968"))
 _add_palette("HULL", "Keeps your boat afloat", Parts.HULL, 190)
 _add_palette("DECK", "Structure with extra weight", Parts.DECK, 274)
 _add_palette("MOTOR", "Powers the boat forward", Parts.MOTOR, 358)
 _add_label(builder, "LEFT CLICK / DRAG  ·  PLACE\nRIGHT CLICK / DRAG  ·  REMOVE", Vector2(60, 470), Vector2(300, 64), 14, Color("b3cbd1"))
 var clear := _make_button("CLEAR GRID", Vector2(60, 565), Vector2(250, 48), false)
 clear.pressed.connect(_clear_grid)
 builder.add_child(clear)
 _add_label(builder, "YOUR BLUEPRINT", Vector2(390, 145), Vector2(500, 30), 17, Color("e6b968"))
 _add_label(builder, "Connected parts stay together", Vector2(390, 176), Vector2(500, 25), 14, Color("a8c9d0"))
 grid = Grid.new()
 grid.position = Vector2(390, 211)
 grid.size = Vector2(576, 384)
 grid.design_changed.connect(_update_status)
 builder.add_child(grid)
 status = _add_label(builder, "", Vector2(390, 610), Vector2(585, 46), 15, Color("c3d9d9"))
 launch_button = _make_button("SET SAIL  →", Vector2(1000, 615), Vector2(215, 58), true)
 launch_button.pressed.connect(_launch)
 builder.add_child(launch_button)
 _select_part(Parts.HULL)
 _update_status()
 hud = Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(hud)
 var top := ColorRect.new()
 top.color = Color(0.04, 0.15, 0.20, 0.88)
 top.position = Vector2(24, 20)
 top.size = Vector2(500, 76)
 top.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hud.add_child(top)
 _add_label(hud, "KEEP THE CAPTAIN SAFE", Vector2(42, 29), Vector2(300, 28), 20, Color("f5e6be"))
 _add_label(hud, "←  →  /  A  D   STEER      •      Reach the far right", Vector2(42, 59), Vector2(460, 24), 14, Color("c4dcdb"))
 var back := _make_button("←  SHIPYARD", Vector2(1040, 25), Vector2(190, 50), false)
 back.pressed.connect(_return_to_builder)
 hud.add_child(back)
 var win := _add_label(hud, "", Vector2(390, 120), Vector2(600, 40), 24, Color("fff1bf"))
 win.name = "WinMessage"
 hud.hide()

func _add_label(parent: Node, text: String, pos: Vector2, bounds: Vector2, font_size: int, color: Color) -> Label:
 var label := Label.new()
 label.text = text
 label.position = pos
 label.size = bounds
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 return label

func _make_button(text: String, pos: Vector2, bounds: Vector2, accent: bool) -> Button:
 var button := Button.new()
 button.text = text
 button.position = pos
 button.size = bounds
 button.add_theme_font_size_override("font_size", 16)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("d8a94f") if accent else Color("254657")
 style.set_corner_radius_all(7)
 style.set_content_margin_all(10)
 button.add_theme_stylebox_override("normal", style)
 var hover := style.duplicate()
 hover.bg_color = Color("efc570") if accent else Color("356074")
 button.add_theme_stylebox_override("hover", hover)
 button.add_theme_stylebox_override("pressed", hover)
 button.add_theme_color_override("font_color", Color("172f38") if accent else Color("e8f2ed"))
 button.add_theme_color_override("font_hover_color", Color("172f38") if accent else Color.WHITE)
 return button

func _add_palette(title: String, description: String, part: int, y: float) -> void:
 var button := _make_button(title, Vector2(60, y), Vector2(250, 48), false)
 button.alignment = HORIZONTAL_ALIGNMENT_LEFT
 button.pressed.connect(_select_part.bind(part))
 button.set_meta("part", part)
 palette_buttons.append(button)
 builder.add_child(button)
 _add_label(builder, description, Vector2(66, y + 50), Vector2(250, 22), 13, Color("9cbcc4"))

func _select_part(part: int) -> void:
 grid.selected_part = part
 for button in palette_buttons:
  var selected: bool = button.get_meta("part") == part
  button.text = ("●  " if selected else "    ") + ["", "HULL", "DECK", "MOTOR"][button.get_meta("part")]

func _clear_grid() -> void:
 grid.cells.clear()
 grid.queue_redraw()
 _update_status()

func _update_status() -> void:
 var hulls := 0
 var motors := 0
 for part in grid.cells.values():
  if part == Parts.HULL:
   hulls += 1
  elif part == Parts.MOTOR:
   motors += 1
 var problem := ""
 if grid.cells.is_empty():
  problem = "Place some parts to start building."
 elif not grid.design_is_connected():
  problem = "Connect every block edge-to-edge."
 elif hulls == 0:
  problem = "Add at least one hull block to float."
 elif motors == 0:
  problem = "Add at least one motor to sail."
 else:
  problem = "%d blocks   •   %d hull   •   %d motor" % [grid.cells.size(), hulls, motors]
 status.text = problem
 launch_button.disabled = hulls == 0 or motors == 0 or not grid.design_is_connected()

func _launch() -> void:
 if launch_button.disabled:
  return
 water_simulator.calm_water()
 boat = Boat.new()
 boat.configure(grid.cells, water_simulator)
 boat.position = Vector2(-490, -50)
 boat.reached_destination.connect(_on_arrival)
 add_child(boat)
 builder.hide()
 hud.get_node("WinMessage").text = ""
 hud.show()

func _on_arrival() -> void:
 hud.get_node("WinMessage").text = "THE CAPTAIN MADE IT ACROSS!"

func _return_to_builder() -> void:
 if is_instance_valid(boat):
  boat.queue_free()
  boat = null
 hud.hide()
 builder.show()
 _update_status()


