extends Fighter
class_name MeleeFighter

@export var charge_force: float = 800.0
@export var charge_duration: float = 0.3
@export var dash_boost: float = 2.5  # Increased from 1.5
@export var retreat_speed: float = 1.2
@export var dodge_force: float = 600.0
@export var detection_radius: float = 100.0
@export var pursuit_boost: float = 1.8  # New: boost when far from target
@export var close_range_threshold: float = 150.0
@export var far_range_threshold: float = 300.0
@export var linear_damp_override: float = 2.0  # Reduce drift

var is_charging: bool = false
var is_retreating: bool = false
var retreat_timer: float = 0.0
var retreat_duration: float = 0.5
var dodge_cooldown: bool = false
var pursuit_mode: bool = false

func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)
	# Reduce linear damping so melee fighter maintains momentum better
	linear_damp = linear_damp_override

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
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if p is Projectile and p.owner_fighter != self:
			var dist = global_position.distance_to(p.global_position)
			if dist < detection_radius:
				perform_dodge(p.global_position)
				break

func perform_dodge(incoming_pos: Vector2):
	dodge_cooldown = true
	
	var to_threat = (incoming_pos - global_position).normalized()
	var dodge_dir = Vector2(-to_threat.y, to_threat.x) * strafe_direction
	
	apply_central_impulse(dodge_dir * dodge_force)
	animation_player.play("hit")
	
	await get_tree().create_timer(0.8).timeout
	dodge_cooldown = false

func move_towards_target():
	if not target or not is_instance_valid(target):
		return
		
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	if is_retreating:
		var jitter = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		apply_central_force((-direction + jitter).normalized() * move_speed * retreat_speed)
		return
	
	if is_charging: 
		return
	
	# Determine pursuit mode based on distance
	pursuit_mode = distance > far_range_threshold
	
	# Calculate movement strategy based on distance
	var movement_force: float
	var approach_direction: Vector2
	
	if distance > far_range_threshold:
		# FAR RANGE: Aggressive pursuit, straight line with high speed
		movement_force = move_speed * pursuit_boost
		approach_direction = direction
		
		# Also cap maximum velocity when far to prevent overshooting
		if linear_velocity.length() < move_speed * 2.0:
			apply_central_force(approach_direction * movement_force)
		
	elif distance < close_range_threshold:
		# CLOSE RANGE: Dash boost with spiral
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.5
		approach_direction = (direction + side_step).normalized()
		movement_force = move_speed * dash_boost
		apply_central_force(approach_direction * movement_force)
		
	else:
		# MID RANGE: Balanced approach with slight strafe
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.3
		approach_direction = (direction + side_step).normalized()
		movement_force = move_speed * 1.5
		apply_central_force(approach_direction * movement_force)
	
	# Predictive movement: aim where target will be
	if distance > close_range_threshold and target is Fighter:
		var target_velocity = target.linear_velocity
		var predicted_position = target.global_position + target_velocity * 0.3
		var predicted_direction = (predicted_position - global_position).normalized()
		# Blend current direction with predicted direction
		approach_direction = (direction * 0.6 + predicted_direction * 0.4).normalized()
		apply_central_force(approach_direction * movement_force * 0.5)

func perform_attack():
	if is_charging or is_retreating:
		return
	
	# Only attack if close enough
	var distance = global_position.distance_to(target.global_position)
	if distance > close_range_threshold * 1.2:
		return
		
	attack_sound.play()
	is_charging = true
	can_attack = false
	
	animation_player.play("charge")
	
	# Predict where target will be and charge there
	var target_velocity = target.linear_velocity if target else Vector2.ZERO
	var predicted_pos = target.global_position + target_velocity * charge_duration * 0.5
	var direction = (predicted_pos - global_position).normalized()
	
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
		apply_central_impulse(bounce_dir * 300.0)
		is_retreating = true
		retreat_timer = retreat_duration
