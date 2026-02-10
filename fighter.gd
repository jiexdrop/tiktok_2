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

var current_health: float
var can_attack: bool = true
var target: Fighter = null
var movement_timer: float = 0.0
var strafe_direction: float = 1.0
var movement_style: int = 0  # 0 = direct, 1 = orbit, 2 = strafe

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
	#sprite.color = fighter_color
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Randomize movement style for variety
	movement_style = randi() % 3
	strafe_direction = 1.0 if randf() > 0.5 else -1.0
	
	# Connect area entered signal
	attack_area.body_entered.connect(_on_body_entered_attack_area)
	
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
	
	# Play hit animation
	animation_player.play("hit")
	hit_sound.play()
	
	# Apply knockback
	var knockback_dir = (global_position - attacker_position).normalized()
	apply_central_impulse(knockback_dir * knockback_force)
	
	if current_health <= 0:
		die()

func die():
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
