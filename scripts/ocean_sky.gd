extends Node2D

func _draw() -> void:
 # Soft bands, sun and distant islands keep the horizon readable behind the waves.
 var sky_top := Color("528db0")
 var sky_horizon := Color("b9dddb")
 for i in range(36):
  var y: float = -360.0 + i * 12.0
  draw_rect(Rect2(-1000.0, y, 2000.0, 13.0), sky_top.lerp(sky_horizon, float(i) / 35.0))
 draw_circle(Vector2(400, -230), 37.0, Color("f8edbc"))
 for i in range(3):
  var x: float = -470.0 + i * 410.0
  var y: float = -245.0 + (i % 2) * 45.0
  var cloud := Color(0.94, 0.98, 0.94, 0.45)
  draw_circle(Vector2(x, y), 24.0, cloud)
  draw_circle(Vector2(x + 27, y - 9), 31.0, cloud)
  draw_circle(Vector2(x + 57, y), 22.0, cloud)
 draw_colored_polygon(PackedVector2Array([Vector2(-1000, 40), Vector2(-850, -3), Vector2(-740, 13), Vector2(-660, -21), Vector2(-535, 20), Vector2(-420, 40)]), Color("669b9c"))
 # A small flag marks the destination at the far side of the crossing.
 draw_line(Vector2(510, 32), Vector2(510, -30), Color("6a4b35"), 4.0)
 draw_colored_polygon(PackedVector2Array([Vector2(512, -30), Vector2(549, -22), Vector2(512, -12)]), Color("e8ae5b"))
