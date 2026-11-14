extends Node2D

@export var water_simulator: Node2D
@export var deep_color: Color = Color("103c64")
@export var mid_color: Color = Color("17678a")
@export var surface_color: Color = Color("2997a5")
var _time: float = 0.0

func _process(delta: float) -> void:
 _time += delta
 queue_redraw()

func _draw() -> void:
 if not is_instance_valid(water_simulator) or water_simulator.heights.size() < 2:
  return
 var count: int = water_simulator.resolution
 var width: float = water_simulator.sim_width
 var spacing: float = width / float(count - 1)
 var start: float = -width * 0.5 + water_simulator.position.x
 var bottom: float = 500.0
 var surface := PackedVector2Array()
 for i in range(count):
  var x: float = start + i * spacing
  surface.append(Vector2(x, water_simulator.get_water_height_at(to_global(Vector2(x, 0)).x) - global_position.y))
 # Individual convex strips cannot self-intersect when the surface moves.
 for i in range(count - 1):
  var a: Vector2 = surface[i]
  var b: Vector2 = surface[i + 1]
  var shallow_a: Vector2 = Vector2(a.x, minf(a.y + 85.0, bottom))
  var shallow_b: Vector2 = Vector2(b.x, minf(b.y + 85.0, bottom))
  draw_polygon(PackedVector2Array([a, b, shallow_b, shallow_a]), PackedColorArray([surface_color, surface_color, mid_color, mid_color]))
  draw_polygon(PackedVector2Array([shallow_a, shallow_b, Vector2(b.x, bottom), Vector2(a.x, bottom)]), PackedColorArray([mid_color, mid_color, deep_color, deep_color]))
 draw_polyline(surface, Color("75d5d3"), 3.0, true)
 # Short, subdued moving glints bring the surface to life without obscuring the ship.
 for i in range(18):
  var x: float = -width * 0.5 + fposmod(float(i) * 127.0 + _time * (8.0 + (i % 3) * 3.0), width)
  var y: float = water_simulator.get_water_height_at(to_global(Vector2(x, 0)).x) - global_position.y + 14.0 + (i % 4) * 17.0
  var length: float = 16.0 + (i % 3) * 8.0
  draw_line(Vector2(x, y), Vector2(x + length, y), Color(0.65, 0.91, 0.89, 0.22), 2.0)
