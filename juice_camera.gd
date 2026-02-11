extends Camera2D
class_name JuiceCamera

# Trauma-based screen shake
var trauma: float = 0.0
var trauma_power: int = 2  # Exponential falloff
var decay: float = 1.5  # How fast trauma decays per second
var max_offset: float = 100.0
var max_roll: float = 0.15
var noise: FastNoiseLite
var noise_y: int = 0

# Chromatic aberration (via offset)
var chromatic_aberration: float = 0.0
var chromatic_decay: float = 3.0

func _ready():
	# Setup noise for smooth random shake
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 4.0

func _process(delta):
	# Decay trauma and chromatic aberration
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		shake()
	
	if chromatic_aberration > 0:
		chromatic_aberration = max(chromatic_aberration - chromatic_decay * delta, 0)
	
	# Advance noise "time"
	noise_y += 1

func shake():
	# Get trauma amount with exponential falloff
	var amount = pow(trauma, trauma_power)
	
	# Sample noise for smooth random values
	noise_y += 1
	var offset_x = max_offset * amount * noise.get_noise_2d(noise.seed, noise_y)
	var offset_y = max_offset * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
	var roll = max_roll * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
	
	offset = Vector2(offset_x, offset_y)
	rotation = roll

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func add_chromatic_aberration(amount: float):
	chromatic_aberration = min(chromatic_aberration + amount, 1.0)

# Convenience functions for different shake intensities
func small_shake():
	add_trauma(0.2)

func medium_shake():
	add_trauma(0.4)

func large_shake():
	add_trauma(0.6)

func huge_shake():
	add_trauma(0.9)
