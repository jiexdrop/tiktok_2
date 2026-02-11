extends Fighter
class_name MeleeFighter

@export var charge_force: float = 1200.0  # Increased for snappier charges
@export var charge_duration: float = 0.25  # Slightly faster
@export var dash_boost: float = 2.5
@export var retreat_speed: float = 1.2
@export var dodge_force: float = 400.0  # Stronger dodge
@export var detection_radius: float = 200.0  # Larger detection range
@export var pursuit_boost: float = 1.8
@export var close_range_threshold: float = 150.0
@export var far_range_threshold: float = 300.0
@export var linear_damp_override: float = 2.0
@export var dodge_cooldown_time: float = 0.5  # Faster dodge recovery
@export var projectile_prediction_time: float = 0.4  # How far ahead to predict
@export var attack_prediction_multiplier: float = 0.6  # Target velocity prediction for attacks

var is_charging: bool = false
var is_retreating: bool = false
var retreat_timer: float = 0.0
var retreat_duration: float = 0.5
var dodge_cooldown: bool = false
var dodge_cooldown_timer: float = 0.0
var pursuit_mode: bool = false
var last_dodge_time: float = 0.0

func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)
	linear_damp = linear_damp_override

func _physics_process(delta):
	super._physics_process(delta)
	
	# Handle retreat timer
	if is_retreating:
		retreat_timer -= delta
		if retreat_timer <= 0:
			is_retreating = false
	
	# Handle dodge cooldown
	if dodge_cooldown:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			dodge_cooldown = false
	
	# Reactive Dodging Logic - check every frame for threats
	if not dodge_cooldown and not is_charging:
		look_for_projectiles()

func look_for_projectiles():
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	var most_dangerous_projectile = null
	var shortest_time_to_impact = INF
	
	for p in projectiles:
		if p is Projectile and p.owner_fighter != self:
			var projectile_to_me = global_position - p.global_position
			var distance = projectile_to_me.length()
			
			# Check if projectile is actually heading towards us
			var projectile_velocity = p.linear_velocity
			if projectile_velocity.length() > 0:
				var projectile_direction = projectile_velocity.normalized()
				var direction_to_me = projectile_to_me.normalized()
				var dot = projectile_direction.dot(direction_to_me)
				
				# Only dodge if projectile is heading our way (dot > 0.5 means roughly aimed at us)
				if dot > 0.5 and distance < detection_radius:
					# Calculate time to impact
					var closing_speed = projectile_velocity.length()
					var time_to_impact = distance / closing_speed if closing_speed > 0 else INF
					
					# Track the most imminent threat
					if time_to_impact < shortest_time_to_impact:
						shortest_time_to_impact = time_to_impact
						most_dangerous_projectile = p
	
	# Dodge the most dangerous projectile if it's close enough
	if most_dangerous_projectile and shortest_time_to_impact < projectile_prediction_time:
		perform_dodge(most_dangerous_projectile)

func perform_dodge(projectile: Projectile):
	dodge_cooldown = true
	dodge_cooldown_timer = dodge_cooldown_time
	
	# Predict where the projectile will be
	var projectile_velocity = projectile.linear_velocity
	var predicted_projectile_pos = projectile.global_position + projectile_velocity * 0.2
	
	var to_threat = (predicted_projectile_pos - global_position).normalized()
	
	# Dodge perpendicular to the threat with some randomness
	var perpendicular = Vector2(-to_threat.y, to_threat.x)
	var dodge_dir = perpendicular * strafe_direction
	
	# Add slight backward component to increase distance
	dodge_dir = (dodge_dir * 0.8 - to_threat * 0.2).normalized()
	
	apply_central_impulse(dodge_dir * dodge_force)
	animation_player.play("hit")

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
		# FAR RANGE: Aggressive pursuit with prediction
		movement_force = move_speed * pursuit_boost
		
		# Predict target movement
		if target is Fighter:
			var target_velocity = target.linear_velocity
			var predicted_position = target.global_position + target_velocity * 0.3
			approach_direction = (predicted_position - global_position).normalized()
		else:
			approach_direction = direction
		
		# Cap velocity to prevent overshooting
		if linear_velocity.length() < move_speed * 2.0:
			apply_central_force(approach_direction * movement_force)
		
	elif distance < close_range_threshold:
		# CLOSE RANGE: Circle strafe while closing
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.6
		approach_direction = (direction + side_step).normalized()
		movement_force = move_speed * dash_boost
		apply_central_force(approach_direction * movement_force)
		
	else:
		# MID RANGE: Balanced approach with evasive movement
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.4
		approach_direction = (direction + side_step).normalized()
		movement_force = move_speed * 1.6
		apply_central_force(approach_direction * movement_force)

func perform_attack():
	if is_charging or is_retreating:
		return
	
	if not target or not is_instance_valid(target):
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# Only attack if in optimal range
	if distance > close_range_threshold * 1.3:
		return
	
	attack_sound.play()
	is_charging = true
	can_attack = false
	
	animation_player.play("charge")
	
	# Advanced prediction: account for both our charge time and target's velocity
	var target_velocity = Vector2.ZERO
	if target is Fighter:
		target_velocity = target.linear_velocity
	
	# Predict where target will be when we arrive
	var time_to_reach = charge_duration * attack_prediction_multiplier
	var predicted_pos = target.global_position + target_velocity * time_to_reach
	
	# Also account for target's current direction of movement
	var direction = (predicted_pos - global_position).normalized()
	
	# Apply a stronger, more accurate charge
	apply_central_impulse(direction * charge_force)
	
	# Reduce our angular velocity to charge straighter
	angular_velocity *= 0.3
	
	await get_tree().create_timer(charge_duration).timeout
	is_charging = false
	
	# Only retreat if we didn't hit anything
	is_retreating = true
	retreat_timer = retreat_duration
	start_attack_cooldown()

func _on_body_entered(body):
	if body is Fighter and body != self and is_charging:
		body.take_damage(attack_damage, global_position)
		
		# Bounce back with force
		var bounce_dir = (global_position - body.global_position).normalized()
		apply_central_impulse(bounce_dir * 400.0)
		
		# Successful hit - shorter retreat
		is_retreating = true
		retreat_timer = retreat_duration * 0.5
		is_charging = false
