extends Fighter
class_name RangedFighter

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var min_attack_distance: float = 150.0
@export var optimal_distance: float = 180.0
@export var retreat_multiplier: float = 1.8

func move_towards_target():
	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()
	
	if distance < min_attack_distance:
		# Retreat! Move away from target
		var retreat_dir = -direction
		# Add some strafing while retreating
		var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
		var combined = (retreat_dir * 0.7 + perpendicular * 0.3).normalized()
		apply_central_force(combined * move_speed * retreat_multiplier)
		
	elif distance > optimal_distance:
		# Too far, move closer but with strafing
		var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
		var combined = (direction * 0.5 + perpendicular * 0.5).normalized()
		apply_central_force(combined * move_speed * 0.8)
	else:
		# At optimal distance, just strafe
		var perpendicular = Vector2(-direction.y, direction.x) * strafe_direction
		apply_central_force(perpendicular * move_speed * 0.6)

func perform_attack():
	if not target:
		return
	
	# Always shoot when attack is ready
	shoot_projectile()

func shoot_projectile():
	attack_sound.play()
	animation_player.play("shoot")
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	
	var direction = (target.global_position - global_position).normalized()
	projectile.set_velocity(direction * projectile_speed)
	projectile.set_damage(attack_damage)
	projectile.set_owner_fighter(self)
	
	start_attack_cooldown()
