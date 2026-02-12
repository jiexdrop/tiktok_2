extends Fighter
class_name MeleeFighter

@export var charge_force: float = 1200.0
@export var charge_duration: float = 0.25
@export var dash_boost: float = 2.5
@export var retreat_speed: float = 1.2
@export var dodge_force: float = 400.0
@export var detection_radius: float = 200.0
@export var pursuit_boost: float = 1.8
@export var close_range_threshold: float = 150.0
@export var far_range_threshold: float = 300.0
@export var linear_damp_override: float = 2.0
@export var dodge_cooldown_time: float = 0.5
@export var projectile_prediction_time: float = 0.4
@export var attack_prediction_multiplier: float = 0.6
@export var attack_cooldown_duration: float = 0.7  # Reduced from 1.0 for more attacks
@export var threat_assessment_radius: float = 180.0  # Reduced - less cautious
@export var safe_attack_window: float = 0.3  # Reduced - more willing to take risks

# Charge trail particles
@export var charge_particles_scene: PackedScene

var is_charging: bool = false
var is_retreating: bool = false
var retreat_timer: float = 0.0
var retreat_duration: float = 0.5
var dodge_cooldown: bool = false
var dodge_cooldown_timer: float = 0.0
var pursuit_mode: bool = false
var last_dodge_time: float = 0.0
var charge_trail: CPUParticles2D = null

# AI logic variables
var attack_cooldown_timer: float = 0.0
var last_projectile_time: float = 0.0
var projectile_fire_interval: float = 0.0 # Learned interval between shots

func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)
	linear_damp = linear_damp_override
	
	# Initialize timers - start ready to attack
	attack_cooldown_timer = 0.0

func _physics_process(delta):
	super._physics_process(delta)
	
	# 1. Handle Timers
	update_timers(delta)
	
	# 2. Learn enemy fire patterns
	detect_projectile_patterns()
	
	# 3. Handle Projectile Dodging (High Priority but doesn't block attacks)
	if check_for_dodge():
		return

	# 4. AI State Machine - PRIORITIZE ATTACKING
	if not is_charging and not is_retreating:
		if target and is_instance_valid(target):
			var distance = global_position.distance_to(target.global_position)
			
			# SIMPLIFIED: Attack if in range and cooldown is done
			if distance < close_range_threshold and attack_cooldown_timer <= 0:
				# Attack unless there's an IMMEDIATE threat
				if not get_immediate_projectile_threat():
					perform_attack()
				else:
					# Strafe while waiting for threat to pass
					move_towards_target()
			elif distance < close_range_threshold * 1.3 and attack_cooldown_timer <= 0:
				# Still attack from slightly further range - be aggressive
				perform_attack()
			else:
				move_towards_target()
		else:
			pass
			
	# 5. Update Particles
	if charge_trail:
		charge_trail.emitting = is_charging

func update_timers(delta: float):
	if is_retreating:
		retreat_timer -= delta
		if retreat_timer <= 0:
			is_retreating = false
	
	if dodge_cooldown:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			dodge_cooldown = false
			
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

func detect_projectile_patterns():
	"""Learn when the enemy typically fires to predict safe attack windows"""
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if not is_instance_valid(p):
			continue
		if p is Projectile and is_instance_valid(p.owner_fighter) and p.owner_fighter != self:
			# Detect newly spawned projectiles
			if p.global_position.distance_to(p.owner_fighter.global_position) < 50:
				var current_time = Time.get_ticks_msec() / 1000.0
				if last_projectile_time > 0:
					var interval = current_time - last_projectile_time
					# Use exponential moving average to smooth out the interval
					if projectile_fire_interval == 0:
						projectile_fire_interval = interval
					else:
						projectile_fire_interval = projectile_fire_interval * 0.7 + interval * 0.3
				last_projectile_time = current_time
				break

func get_immediate_projectile_threat() -> Projectile:
	"""Returns projectile that poses IMMEDIATE danger (very close), or null"""
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if not is_instance_valid(p):
			continue
		if p is Projectile and is_instance_valid(p.owner_fighter) and p.owner_fighter != self:
			var projectile_to_me = global_position - p.global_position
			var distance_to_bullet = projectile_to_me.length()
			
			# Only consider VERY close projectiles as threats to attacking
			if distance_to_bullet < detection_radius * 0.7:  # Reduced radius
				var dot = p.linear_velocity.normalized().dot(projectile_to_me.normalized())
				
				if dot > 0.7:  # Must be aimed quite directly at us
					var closing_speed = p.linear_velocity.length()
					var time_to_impact = distance_to_bullet / closing_speed if closing_speed > 0 else INF
					
					# Only block attack if impact is VERY imminent
					if time_to_impact < 0.3:  # Reduced from charge_duration
						return p
	
	return null

func check_for_dodge() -> bool:
	if dodge_cooldown:
		return false
		
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if not is_instance_valid(p):
			continue
		if p is Projectile and is_instance_valid(p.owner_fighter) and p.owner_fighter != self:
			var projectile_to_me = global_position - p.global_position
			var distance_to_bullet = projectile_to_me.length()
			
			if distance_to_bullet < detection_radius:
				var dot = p.linear_velocity.normalized().dot(projectile_to_me.normalized())
				
				if dot > 0.7: 
					var closing_speed = p.linear_velocity.length()
					var time_to_impact = distance_to_bullet / closing_speed if closing_speed > 0 else INF
					
					if time_to_impact < projectile_prediction_time:
						# ALWAYS interrupt charge if projectile is incoming
						if is_charging:
							is_charging = false
							# Shorter cooldown penalty for interrupted attacks
							attack_cooldown_timer = attack_cooldown_duration * 0.3
						
						perform_dodge(p)
						return true
	
	return false

func perform_dodge(projectile: Projectile):
	dodge_cooldown = true
	dodge_cooldown_timer = dodge_cooldown_time
	
	is_charging = false
	is_retreating = false
	
	if camera and camera.has_method("small_shake"):
		camera.small_shake()
	
	var projectile_velocity = projectile.linear_velocity
	var predicted_projectile_pos = projectile.global_position + projectile_velocity * 0.2
	
	var to_threat = (predicted_projectile_pos - global_position).normalized()
	var perpendicular = Vector2(-to_threat.y, to_threat.x)
	
	var dodge_dir = perpendicular * strafe_direction
	dodge_dir = (dodge_dir * 0.8 - to_threat * 0.2).normalized()
	
	apply_central_impulse(dodge_dir * dodge_force)
	animation_player.play("hit")

func move_towards_target():
	if not target or not is_instance_valid(target):
		return
		
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	pursuit_mode = distance > far_range_threshold
	
	var movement_force: float
	var approach_direction: Vector2
	
	if distance > far_range_threshold:
		movement_force = move_speed * pursuit_boost
		
		if target is Fighter:
			var target_velocity = target.linear_velocity
			var predicted_position = target.global_position + target_velocity * 0.3
			approach_direction = (predicted_position - global_position).normalized()
		else:
			approach_direction = direction
		
		if linear_velocity.length() < move_speed * 2.5:
			apply_central_force(approach_direction * movement_force)
		
	elif distance < close_range_threshold:
		# Enhanced strafing while waiting for attack cooldown
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.7
		approach_direction = (direction * 0.15 + side_step).normalized()
		movement_force = move_speed * dash_boost
		apply_central_force(approach_direction * movement_force)
		
	else:
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.2
		approach_direction = (direction + side_step).normalized()
		movement_force = move_speed * 1.6
		apply_central_force(approach_direction * movement_force)

func perform_attack():
	if is_charging or is_retreating:
		return
	
	if not target or not is_instance_valid(target):
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance > close_range_threshold * 1.5:
		move_towards_target() 
		return
	
	attack_sound.play()
	is_charging = true
	can_attack = false
	
	animation_player.play("charge")
	
	var target_velocity = Vector2.ZERO
	if target is Fighter:
		target_velocity = target.linear_velocity
	
	var time_to_reach = charge_duration * attack_prediction_multiplier
	var predicted_pos = target.global_position + target_velocity * time_to_reach
	var direction = (predicted_pos - global_position).normalized()
	
	apply_central_impulse(direction * charge_force)
	angular_velocity *= 0.3
	
	await get_tree().create_timer(charge_duration).timeout
	
	if is_charging:
		finish_charge()

func finish_charge():
	is_charging = false
	is_retreating = true
	retreat_timer = retreat_duration
	
	start_attack_cooldown()

func start_attack_cooldown():
	attack_cooldown_timer = attack_cooldown_duration

func _on_body_entered(body):
	if not is_charging:
		return

	if body is Fighter and body != self:
		body.take_damage(attack_damage, global_position)
		
		if camera and camera.has_method("medium_shake"):
			camera.medium_shake()
		
		var bounce_dir = (global_position - body.global_position).normalized()
		apply_central_impulse(bounce_dir * 400.0)
		
		is_charging = false
		is_retreating = true
		retreat_timer = retreat_duration * 0.5
		
		start_attack_cooldown()
