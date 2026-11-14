extends RefCounted

const HULL := 1
const DECK := 2
const MOTOR := 3

static func draw_part(canvas: CanvasItem, rect: Rect2, part: int) -> void:
	var r := rect.grow(-2.0)
	match part:
		HULL:
			canvas.draw_rect(r, Color("98603b"))
			canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color("d3a16b"))
			canvas.draw_line(r.position + Vector2(3, r.size.y * 0.62), r.position + Vector2(r.size.x - 3, r.size.y * 0.62), Color("70432d"), 2)
			canvas.draw_circle(r.position + Vector2(5, 9), 1.5, Color("eac088"))
			canvas.draw_circle(r.position + Vector2(r.size.x - 5, 9), 1.5, Color("eac088"))
		DECK:
			canvas.draw_rect(r, Color("bd9666"))
			canvas.draw_rect(r.grow(-3), Color("d8b384"), false, 2)
			canvas.draw_line(r.position + Vector2(5, 5), r.end - Vector2(5, 5), Color("99714b"), 2)
			canvas.draw_line(Vector2(r.end.x - 5, r.position.y + 5), Vector2(r.position.x + 5, r.end.y - 5), Color("99714b"), 2)
		MOTOR:
			canvas.draw_rect(r, Color("445b66"))
			canvas.draw_rect(r.grow(-4), Color("829aa1"))
			canvas.draw_circle(r.get_center(), r.size.x * 0.27, Color("263f4d"))
			canvas.draw_line(r.get_center() - Vector2(0, r.size.y * 0.2), r.get_center() + Vector2(0, r.size.y * 0.2), Color("e3c77f"), 3)
			canvas.draw_line(r.get_center() - Vector2(r.size.x * 0.2, 0), r.get_center() + Vector2(r.size.x * 0.2, 0), Color("e3c77f"), 3)
