extends RigidBody2D
class_name Projectile

var damage: float = 10.0
var owner_fighter: Fighter = null

@onready var sprite: ColorRect = $ColorRect
@onready var impact_sound: AudioStreamPlayer = $ImpactSound

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func set_velocity(vel: Vector2):
	linear_velocity = vel

func set_damage(dmg: float):
	damage = dmg

func set_owner_fighter(fighter: Fighter):
	owner_fighter = fighter

func _on_body_entered(body):
	if body is Fighter and body != owner_fighter:
		body.take_damage(damage, global_position)
		SoundManager.play_sfx(impact_sound.stream, global_position)
		# Visual impact effect
		modulate = Color(2, 2, 2, 1)
		await get_tree().create_timer(0.1).timeout
		queue_free()
	elif body is StaticBody2D:
		# Hit wall
		SoundManager.play_sfx(impact_sound.stream, global_position)
		await get_tree().create_timer(0.1).timeout
		queue_free()
