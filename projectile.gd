extends RigidBody2D
class_name Projectile

var damage: float = 10.0
var owner_fighter: Fighter = null

@onready var sprite: TextureRect = $ColorRect
@onready var impact_sound: AudioStreamPlayer = $ImpactSound
@onready var trail: CPUParticles2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("projectiles")
	
	# Setup trail effect
	setup_trail()
	
	# Auto-destroy after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func setup_trail():
	trail = CPUParticles2D.new()
	add_child(trail)
	
	trail.emitting = true
	trail.amount = 20
	trail.lifetime = 0.3
	trail.explosiveness = 0.0
	trail.randomness = 0.2
	
	trail.direction = Vector2.LEFT  # Trail behind projectile
	trail.spread = 20.0
	trail.initial_velocity_min = 30.0
	trail.initial_velocity_max = 60.0
	trail.scale_amount_min = 1.5
	trail.scale_amount_max = 3.0
	
	# Use sprite color for trail
	if sprite:
		var sprite_color = sprite.modulate if sprite.modulate != Color.WHITE else Color.YELLOW
		var gradient = Gradient.new()
		gradient.set_color(0, sprite_color)
		gradient.set_color(1, Color(sprite_color.r, sprite_color.g, sprite_color.b, 0))
		trail.color_ramp = gradient

func set_velocity(vel: Vector2):
	linear_velocity = vel

func set_damage(dmg: float):
	damage = dmg

func set_owner_fighter(fighter: Fighter):
	owner_fighter = fighter

func _on_body_entered(body):
	if body is Fighter and body != owner_fighter:
		body.take_damage(damage, global_position)
		if impact_sound and impact_sound.stream:
			impact_sound.play()
		
		# Impact effects
		spawn_impact_particles()
		flash_on_impact()
		
		await get_tree().create_timer(0.1).timeout
		queue_free()
		
	elif body is StaticBody2D:
		# Hit wall
		if impact_sound and impact_sound.stream:
			impact_sound.play()
		
		spawn_wall_impact_particles()
		await get_tree().create_timer(0.1).timeout
		queue_free()

func flash_on_impact():
	# Quick bright flash
	sprite.modulate = Color(3, 3, 3, 1)

func spawn_impact_particles():
	# Burst of particles on hit
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.emitting = true
	particles.amount = 25
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.5
	
	# Explode outward from impact point
	var impact_direction = -linear_velocity.normalized()
	particles.direction = impact_direction
	particles.spread = 120.0
	
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 300.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Match projectile color
	if sprite:
		var sprite_color = sprite.modulate if sprite.modulate != Color.WHITE else Color.YELLOW
		particles.color = sprite_color
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

func spawn_wall_impact_particles():
	# Particles bounce off wall
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Reflect off wall
	particles.direction = -linear_velocity.normalized()
	particles.spread = 90.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	
	# Greyish spark particles
	particles.color = Color(0.8, 0.8, 0.8)
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()
