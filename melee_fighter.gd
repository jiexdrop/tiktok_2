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

func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)
	linear_damp = linear_damp_override
	
	# Create charge trail particles
	setup_charge_trail()

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
	
	# Update charge trail
	if charge_trail:
		charge_trail.emitting = is_charging
	
	# Reactive Dodging Logic
	if not dodge_cooldown and not is_charging:
		look_for_projectiles()

func setup_charge_trail():
	if charge_particles_scene:
		charge_trail = charge_particles_scene.instantiate()
		add_child(charge_trail)
	else:
		# Create default charge trail
		charge_trail = CPUParticles2D.new()
		add_child(charge_trail)
		
		charge_trail.emitting = false
		charge_trail.amount = 30
		charge_trail.lifetime = 0.3
		charge_trail.explosiveness = 0.0
		charge_trail.randomness = 0.3
		
		charge_trail.direction = Vector2.LEFT  # Trails behind
		charge_trail.spread = 30.0
		charge_trail.initial_velocity_min = 50.0
		charge_trail.initial_velocity_max = 100.0
		
		charge_trail.scale_amount_min = 2.0
		charge_trail.scale_amount_max = 4.0
		
		# Color fade
		var gradient = Gradient.new()
		gradient.set_color(0, fighter_color)
		gradient.set_color(1, Color(fighter_color.r, fighter_color.g, fighter_color.b, 0))
		charge_trail.color_ramp = gradient

func look_for_projectiles():
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	var most_dangerous_projectile = null
	var shortest_time_to_impact = INF
	
	for p in projectiles:
		if p is Projectile and p.owner_fighter != self:
			var projectile_to_me = global_position - p.global_position
			var distance = projectile_to_me.length()
			
			var projectile_velocity = p.linear_velocity
			if projectile_velocity.length() > 0:
				var projectile_direction = projectile_velocity.normalized()
				var direction_to_me = projectile_to_me.normalized()
				var dot = projectile_direction.dot(direction_to_me)
				
				if dot > 0.5 and distance < detection_radius:
					var closing_speed = projectile_velocity.length()
					var time_to_impact = distance / closing_speed if closing_speed > 0 else INF
					
					if time_to_impact < shortest_time_to_impact:
						shortest_time_to_impact = time_to_impact
						most_dangerous_projectile = p
	
	if most_dangerous_projectile and shortest_time_to_impact < projectile_prediction_time:
		perform_dodge(most_dangerous_projectile)

func perform_dodge(projectile: Projectile):
	dodge_cooldown = true
	dodge_cooldown_timer = dodge_cooldown_time
	
	# Dodge juice effects
	spawn_dodge_effect()
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

func spawn_dodge_effect():
	# Quick burst of particles at dodge location
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	
	particles.color = Color(fighter_color.r * 1.5, fighter_color.g * 1.5, fighter_color.b * 1.5)
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

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
		
		if linear_velocity.length() < move_speed * 2.0:
			apply_central_force(approach_direction * movement_force)
		
	elif distance < close_range_threshold:
		var side_step = Vector2(-direction.y, direction.x) * strafe_direction * 0.6
		approach_direction = (direction + side_step).normalized()
		movement_force = move_speed * dash_boost
		apply_central_force(approach_direction * movement_force)
		
	else:
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
	
	if distance > close_range_threshold * 1.3:
		return
	
	# Charge windup effects
	spawn_charge_windup()
	
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
	is_charging = false
	
	is_retreating = true
	retreat_timer = retreat_duration
	start_attack_cooldown()

func spawn_charge_windup():
	# Ring expanding from fighter before charge
	var particles = CPUParticles2D.new()
	add_child(particles)
	
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.2
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.0
	
	particles.color = Color.WHITE
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

func _on_body_entered(body):
	if body is Fighter and body != self and is_charging:
		body.take_damage(attack_damage, global_position)
		
		# Impact effects!
		spawn_impact_effect(body)
		if camera and camera.has_method("medium_shake"):
			camera.medium_shake()
		
		var bounce_dir = (global_position - body.global_position).normalized()
		apply_central_impulse(bounce_dir * 400.0)
		
		is_retreating = true
		retreat_timer = retreat_duration * 0.5
		is_charging = false

func spawn_impact_effect(target_body: Fighter):
	# Impact particles at hit location
	var hit_point = (global_position + target_body.global_position) / 2.0
	
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = hit_point
	
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 400.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	
	# Mix both fighter colors
	particles.color = Color(
		(fighter_color.r + target_body.fighter_color.r) / 2.0,
		(fighter_color.g + target_body.fighter_color.g) / 2.0,
		(fighter_color.b + target_body.fighter_color.b) / 2.0
	)
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()
