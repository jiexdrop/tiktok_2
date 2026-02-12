extends Node2D

@onready var fighter1: Fighter = $Fighter1
@onready var fighter2: Fighter = $Fighter2
@onready var arena: Arena = $Arena
@onready var victory_label: Label = $UI/VictoryLabel
@onready var round_label: Label = $UI/RoundLabel
@onready var victory_sound: AudioStreamPlayer = $VictorySound
@onready var camera = $Camera2D

var round_number: int = 1

func _ready():
	# Connect fighter death signals
	fighter1.fighter_died.connect(_on_fighter_died)
	fighter2.fighter_died.connect(_on_fighter_died)
	
	# Set targets
	fighter1.target = fighter2
	fighter2.target = fighter1
	
	victory_label.hide()
	round_label.text = "ROUND " + str(round_number)
	
	# Start round after brief delay
	await get_tree().create_timer(1.0).timeout
	round_label.hide()

func _on_fighter_died(fighter: Fighter):
	# Determine winner
	var winner_name = ""
	if fighter == fighter1:
		winner_name = "BLUE WINS!"
	else:
		winner_name = "RED WINS!"
	
	victory_label.text = winner_name
	victory_label.show()
	victory_sound.play()
	
	# Victory effects!
	if camera and camera.has_method("huge_shake"):
		camera.huge_shake()
	spawn_victory_particles(fighter)
	flash_screen()
	
	# Restart after delay
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()

func spawn_victory_particles(defeated_fighter: Fighter):
	# Big celebration burst
	var particles = CPUParticles2D.new()
	add_child(particles)
	particles.global_position = defeated_fighter.global_position
	
	particles.emitting = true
	particles.amount = 100
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.9
	
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 300.0
	particles.initial_velocity_max = 600.0
	particles.gravity = Vector2(0, 400)
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 10.0
	
	# Rainbow colors for victory!
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.RED)
	gradient.add_point(0.25, Color.YELLOW)
	gradient.add_point(0.5, Color.GREEN)
	gradient.add_point(0.75, Color.CYAN)
	gradient.add_point(1.0, Color.MAGENTA)
	particles.color_ramp = gradient
	
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

func flash_screen():
	# Create a full screen white flash overlay
	var flash = ColorRect.new()
	add_child(flash)
	
	# Make it cover the whole viewport
	flash.color = Color(1, 1, 1, 0.7)
	flash.size = get_viewport_rect().size
	
	# FIX: Set position to top-left (0,0)
	flash.position = Vector2(0, 0) 
	
	flash.z_index = 100
	
	# Fade out quickly
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	await tween.finished
	flash.queue_free()
