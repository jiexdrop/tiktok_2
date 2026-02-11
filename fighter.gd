extends RigidBody2D
class_name Fighter

@export var fighter_color: Color = Color.RED
@export var max_health: float = 100.0
@export var move_speed: float = 200.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var knockback_force: float = 300.0
@export var strafe_speed: float = 150.0
@export var orbit_distance: float = 100.0

# Particle effects
@export var hit_particles_scene: PackedScene
@export var death_particles_scene: PackedScene

var current_health: float
var can_attack: bool = true
var target: Fighter = null
var movement_timer: float = 0.0
var strafe_direction: float = 1.0
var movement_style: int = 0  # 0 = direct, 1 = orbit, 2 = strafe
var camera = null

@onready var sprite: TextureRect = $ColorRect
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var death_sound: AudioStreamPlayer = $DeathSound
@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal fighter_died(fighter: Fighter)

func _ready():
	# Explicitly disable gravity
	gravity_scale = 0.0
	
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Randomize movement style for variety
	movement_style = randi() % 3
	strafe_direction = 1.0 if randf() > 0.5 else -1.0
	
	# Connect area entered signal
	attack_area.body_entered.connect(_on_body_entered_attack_area)
	
	# Find camera (works with any camera that has shake methods)
	camera = get_viewport().get_camera_2d()

func _physics_process(delta):
	movement_timer += delta
	
	# Change strafe direction periodically
	if movement_timer > 2.0:
		movement_timer = 0.0
		strafe_direction *= -1.0
	
	# Add subtle rotation based on velocity for visual feedback
	if linear_velocity.length() > 10.0:
		sprite.rotation = lerp(sprite.rotation, linear_velocity.angle() + PI/2, delta * 3.0)
	
	if target and is_instance_valid(target):
		move_towards_target()
		
		if can_attack:
			perform_attack()

func move_towards_target():
	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()
	
	match movement_style:
		0:  # Direct chase - straight at target
			apply_central_force(direction * move_speed)
			
		1:  # Orbit - circle around target
			var orbit_point = target.global_position + direction * orbit_distance
			var to_orbit = orbit_point - global_position
			var orbit_dir = to_orbit.normalized()
			
			# Add perpendicular force for orbiting
			var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
			var combined = (orbit_dir + perpendicular).normalized()
			apply_central_force(combined * move_speed)
			
		2:  # Strafe - move side to side while approaching
			var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
			var combined = (direction * 0.6 + perpendicular * 0.4).normalized()
			apply_central_force(combined * move_speed)

func perform_attack():
	# Override in child classes
	pass

func take_damage(amount: float, attacker_position: Vector2):
	current_health -= amount
	health_bar.value = current_health
	
	# Juice effects!
	hit_freeze()
	screen_shake_on_hit()
	flash_sprite()
	spawn_hit_particles(attacker_position)
	
	# Play hit animation and sound
	animation_player.play("hit")
	hit_sound.play()
	
	# Apply knockback
	var knockback_dir = (global_position - attacker_position).normalized()
	apply_central_impulse(knockback_dir * knockback_force)
	
	if current_health <= 0:
		die()

func die():
	# Death juice effects
	if camera and camera.has_method("huge_shake"):
		camera.huge_shake()
	spawn_death_particles()
	
	death_sound.play()
	animation_player.play("death")
	await animation_player.animation_finished
	fighter_died.emit(self)
	queue_free()

func _on_body_entered_attack_area(body):
	if body is Fighter and body != self and not target:
		target = body

func start_attack_cooldown():
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func hit_freeze(duration: float = 0.1):
	# Enhanced hit pause with longer duration for more impact
	Engine.time_scale = 0.05 
	await get_tree().create_timer(duration * Engine.time_scale, true, false, true).timeout 
	Engine.time_scale = 1.0

func screen_shake_on_hit():
	if camera and camera.has_method("small_shake"):
		camera.small_shake()

func flash_sprite():
	# Flash white on hit
	var original_modulate = sprite.modulate
	sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	
	# Create tween for smooth flash
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.15)

func spawn_hit_particles(attacker_position: Vector2):
	if not hit_particles_scene:
		# Create default particles if no scene provided
		create_default_hit_particles(attacker_position)
		return
	
	var particles = hit_particles_scene.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Orient particles away from attacker
	var direction = (global_position - attacker_position).normalized()
	particles.rotation = direction.angle()

func create_default_hit_particles(attacker_position: Vector2):
	# Create simple CPU particles as fallback
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Configure particles
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.5
	
	# Direction away from attacker
	var direction = (global_position - attacker_position).normalized()
	particles.direction = direction
	particles.spread = 45.0
	
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 300.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Color based on fighter color
	particles.color = fighter_color
	
	# Cleanup
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

func spawn_death_particles():
	if not death_particles_scene:
		create_default_death_particles()
		return
	
	var particles = death_particles_scene.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position

func create_default_death_particles():
	# Large explosion of particles on death
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.8
	
	particles.direction = Vector2.UP
	particles.spread = 180.0
	
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 500.0
	particles.gravity = Vector2(0, 500)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 8.0
	
	# Start with fighter color, fade to transparent
	particles.color = fighter_color
	var gradient = Gradient.new()
	gradient.set_color(0, fighter_color)
	gradient.set_color(1, Color(fighter_color.r, fighter_color.g, fighter_color.b, 0))
	particles.color_ramp = gradient
	
	# Cleanup
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()
