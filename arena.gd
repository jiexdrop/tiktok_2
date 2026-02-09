extends StaticBody2D
class_name Arena

@export var arena_size: Vector2 = Vector2(400, 600)
@export var wall_thickness: float = 20.0

func _ready():
	create_arena_walls()

func create_arena_walls():
	# Clear existing collision shapes
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	var half_size = arena_size / 2
	
	# Top wall
	create_wall(Vector2(0, -half_size.y), Vector2(arena_size.x, wall_thickness))
	
	# Bottom wall
	create_wall(Vector2(0, half_size.y), Vector2(arena_size.x, wall_thickness))
	
	# Left wall
	create_wall(Vector2(-half_size.x, 0), Vector2(wall_thickness, arena_size.y))
	
	# Right wall
	create_wall(Vector2(half_size.x, 0), Vector2(wall_thickness, arena_size.y))

func create_wall(pos: Vector2, size: Vector2):
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	add_child(collision)
