extends Fighter
class_name RangedFighter

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var min_attack_distance: float = 150.0
@export var optimal_distance: float = 180.0
@export var retreat_multiplier: float = 1.8
@export var gun_orbit_radius: float = 20.0  # Distance from body center
@onready var gun: Sprite2D = $Gun

func _process(delta):
	if target:
		update_gun_position_and_rotation()

func update_gun_position_and_rotation():
	var to_target = target.global_position - global_position
	var angle_to_target = to_target.angle()
	
	# Position gun on orbit around body
	var orbit_offset = Vector2.RIGHT.rotated(angle_to_target) * gun_orbit_radius
	gun.position = orbit_offset
	
	# Rotate gun to face target
	gun.rotation = angle_to_target

func move_towards_target():
	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()
	
	if distance < min_attack_distance:
		var retreat_dir = -direction
		var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
		var combined = (retreat_dir * 0.7 + perpendicular * 0.3).normalized()
		apply_central_force(combined * move_speed * retreat_multiplier)
		
	elif distance > optimal_distance:
		var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
		var combined = (direction * 0.5 + perpendicular * 0.5).normalized()
		apply_central_force(combined * move_speed * 0.8)
	else:
		var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
		apply_central_force(perpendicular * move_speed * 0.6)

func perform_attack():
	if not target:
		return
	shoot_projectile()

func shoot_projectile():
	attack_sound.play()
	animation_player.play("shoot")
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# Spawn at gun's global position (orbiting position)
	projectile.global_position = gun.global_position
	projectile.global_rotation = gun.global_rotation
	
	# Fire in direction gun is pointing
	var direction = Vector2.RIGHT.rotated(gun.rotation)
	projectile.set_velocity(direction * projectile_speed)
	projectile.set_damage(attack_damage)
	projectile.set_owner_fighter(self)
	
	start_attack_cooldown()
