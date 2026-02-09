extends Fighter
class_name MeleeFighter

@export var charge_force: float = 800.0
@export var charge_duration: float = 0.3
@export var dash_boost: float = 1.5

var is_charging: bool = false

func _ready():
	super._ready() # Calls the base Fighter _ready()
	body_entered.connect(_on_body_entered)

func move_towards_target():
	# Melee fighter is more aggressive - always direct chase
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	# Dash when close but not charging
	if distance < 150.0 and not is_charging:
		apply_central_force(direction * move_speed * dash_boost)
	else:
		apply_central_force(direction * move_speed)

func perform_attack():
	if is_charging:
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
	start_attack_cooldown()

func _on_body_entered(body):
	if body is Fighter and body != self and is_charging:
		body.take_damage(attack_damage, global_position)
		# Bounce back a bit
		var bounce_dir = (global_position - body.global_position).normalized()
		apply_central_impulse(bounce_dir * 200.0)
