extends Camera2D

# SUPER SIMPLE SHAKE - No noise, no fancy math, just SHAKE!

var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _process(delta):
	if shake_strength > 0:
		# Simple random shake
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		rotation = randf_range(-shake_strength * 0.01, shake_strength * 0.01)
		
		# Decay
		shake_strength -= shake_decay * delta
		
		#print("SHAKING! Strength: ", shake_strength, " Offset: ", offset)
	else:
		offset = Vector2.ZERO
		rotation = 0
		shake_strength = 0

func add_trauma(amount: float):
	shake_strength += amount * 50.0  # Convert to pixel amount
	print("=== SHAKE ADDED ===")
	print("New strength: ", shake_strength)

func small_shake():
	print("SMALL SHAKE!")
	shake_strength = 1.5

func medium_shake():
	print("MEDIUM SHAKE!")
	shake_strength = 3.0

func large_shake():
	print("LARGE SHAKE!")
	shake_strength = 5.0

func huge_shake():
	print("HUGE SHAKE!")
	shake_strength = 10.0

func test_shake():
	print("TEST SHAKE - MAXIMUM!")
	shake_strength = 10.0
