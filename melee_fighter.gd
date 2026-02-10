extends Fighter
class_name MeleeFighter

@export var charge_force: float = 800.0
@export var charge_duration: float = 0.3
@export var dash_boost: float = 1.5
@export var retreat_speed: float = 1.2
@export var dodge_force: float = 600.0 # Force applied when dodging
@export var detection_radius: float = 100.0 # How close a projectile must be to trigger a dodge

var is_charging: bool = false
var is_retreating: bool = false
var retreat_timer: float = 0.0
var retreat_duration: float = 0.5
var dodge_cooldown: bool = false

func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	super._physics_process(delta)
	
	# Handle retreat timer
	if is_retreating:
		retreat_timer -= delta
		if retreat_timer <= 0:
			is_retreating = false
			
	# Reactive Dodging Logic
	if not dodge_cooldown and not is_charging:
		look_for_projectiles()

func look_for_projectiles():
	# Simple scan for nearby projectiles
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if p is Projectile and p.owner_fighter != self:
			var dist = global_position.distance_to(p.global_position)
			if dist < detection_radius:
				perform_dodge(p.global_position)
				break

func perform_dodge(incoming_pos: Vector2):
	dodge_cooldown = true
	
	# Calculate perpendicular direction to the incoming threat
	var to_threat = (incoming_pos - global_position).normalized()
	var dodge_dir = Vector2(-to_threat.y, to_threat.x) * strafe_direction
	
	# Apply a sudden burst of movement
	apply_central_impulse(dodge_dir * dodge_force)
	
	# Brief invulnerability or visual feedback could go here
	animation_player.play("hit") # Reusing hit anim for a "twitch" effect
	
	await get_tree().create_timer(0.8).timeout # Dodge cooldown
	dodge_cooldown = false

func move_towards_target():
	if not target or not is_instance_valid(target):
		return
		
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	if is_retreating:
		# Faster, more erratic retreat
		var jitter = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		apply_central_force((-direction + jitter).normalized() * move_speed * retreat_speed)
		return
	
	if is_charging: return
	
	# Improved closing behavior: spiral in instead of walking straight
	var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.5
	var approach_vec = (direction + side_step).normalized()
	
	if distance < 150.0:
		apply_central_force(approach_vec * move_speed * dash_boost)
	else:
		apply_central_force(approach_vec * move_speed)

func perform_attack():
	if is_charging or is_retreating:
		return
		
	attack_sound.play()
	is_charging = true
	can_attack = false
	
	animation_player.play("charge")
	
	var direction = (target.global_position - global_position).normalized()
	apply_central_impulse(direction * charge_force)
	
	await get_tree().create_timer(charge_duration).timeout
	is_charging = false
	is_retreating = true
	retreat_timer = retreat_duration
	start_attack_cooldown()

func _on_body_entered(body):
	if body is Fighter and body != self and is_charging:
		body.take_damage(attack_damage, global_position)
		var bounce_dir = (global_position - body.global_position).normalized()
		apply_central_impulse(bounce_dir * 300.0) # Increased bounce for "impact" feel
		is_retreating = true
		retreat_timer = retreat_duration
