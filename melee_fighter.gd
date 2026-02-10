extends Fighter
class_name MeleeFighter

@export var charge_force: float = 800.0
@export var charge_duration: float = 0.3
@export var dash_boost: float = 1.5
@export var retreat_distance: float = 120.0  # Distance to maintain after charge
@export var retreat_speed: float = 1.2  # Multiplier for retreat speed

var is_charging: bool = false
var is_retreating: bool = false
var retreat_timer: float = 0.0
var retreat_duration: float = 0.5  # How long to retreat for

func _ready():
	super._ready() # Calls the base Fighter _ready()
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	super._physics_process(delta)
	
	# Handle retreat timer
	if is_retreating:
		retreat_timer -= delta
		if retreat_timer <= 0:
			is_retreating = false

func move_towards_target():
	if not target or not is_instance_valid(target):
		return
		
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	# Retreat after charge
	if is_retreating:
		# Move away from target
		apply_central_force(-direction * move_speed * retreat_speed)
		return
	
	# Don't move while charging
	if is_charging:
		return
	
	# Dash when close but not charging
	if distance < 150.0:
		apply_central_force(direction * move_speed * dash_boost)
	else:
		apply_central_force(direction * move_speed)

func perform_attack():
	if is_charging or is_retreating:
		return
		
	attack_sound.play()
	is_charging = true
	can_attack = false
	
	# Charge animation
	animation_player.play("charge")
	
	# Apply massive force towards target
	var direction = (target.global_position - global_position).normalized()
	apply_central_impulse(direction * charge_force)
	
	await get_tree().create_timer(charge_duration).timeout
	is_charging = false
	
	# Start retreating after charge
	is_retreating = true
	retreat_timer = retreat_duration
	
	start_attack_cooldown()

func _on_body_entered(body):
	if body is Fighter and body != self and is_charging:
		body.take_damage(attack_damage, global_position)
		# Bounce back a bit
		var bounce_dir = (global_position - body.global_position).normalized()
		apply_central_impulse(bounce_dir * 200.0)
		
		# Immediately start retreating on hit
		is_retreating = true
		retreat_timer = retreat_duration
