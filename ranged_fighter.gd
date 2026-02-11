extends Fighter
class_name RangedFighter

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var min_attack_distance: float = 150.0
@export var optimal_distance: float = 180.0
@export var retreat_multiplier: float = 1.8
@export var gun_orbit_radius: float = 20.0

@onready var gun: Sprite2D = $Gun
@onready var muzzle_flash: CPUParticles2D = null

func _ready():
	super._ready()
	setup_muzzle_flash()

func _process(delta):
	if target:
		update_gun_position_and_rotation()

func setup_muzzle_flash():
	# Create muzzle flash particles at gun tip
	muzzle_flash = CPUParticles2D.new()
	gun.add_child(muzzle_flash)
	
	# Position at gun tip (adjust as needed for your sprite)
	muzzle_flash.position = Vector2(20, 0)
	
	muzzle_flash.emitting = false
	muzzle_flash.amount = 15
	muzzle_flash.lifetime = 0.1
	muzzle_flash.one_shot = true
	muzzle_flash.explosiveness = 1.0
	
	muzzle_flash.direction = Vector2.RIGHT
	muzzle_flash.spread = 30.0
	muzzle_flash.initial_velocity_min = 200.0
	muzzle_flash.initial_velocity_max = 400.0
	muzzle_flash.scale_amount_min = 2.0
	muzzle_flash.scale_amount_max = 4.0
	
	# Bright yellow-white flash
	var gradient = Gradient.new()
	gradient.set_color(0, Color(2, 2, 1))
	gradient.set_color(1, Color(1, 0.5, 0, 0))
	muzzle_flash.color_ramp = gradient

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
	
	# Juice effects!
	gun_recoil()
	muzzle_flash.emitting = true
	if camera and camera.has_method("small_shake"):
		camera.small_shake()
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# Spawn at gun's global position
	projectile.global_position = gun.global_position
	projectile.global_rotation = gun.global_rotation
	
	# Fire in direction gun is pointing
	var direction = Vector2.RIGHT.rotated(gun.rotation)
	projectile.set_velocity(direction * projectile_speed)
	projectile.set_damage(attack_damage)
	projectile.set_owner_fighter(self)
	
	start_attack_cooldown()

func gun_recoil():
	# Quick recoil animation on gun
	var original_pos = gun.position
	var recoil_offset = Vector2(-5, 0).rotated(gun.rotation)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(gun, "position", original_pos + recoil_offset, 0.05)
	tween.tween_property(gun, "position", original_pos, 0.2)
