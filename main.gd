extends Node2D

@onready var fighter1: Fighter = $Fighter1
@onready var fighter2: Fighter = $Fighter2
@onready var arena: Arena = $Arena
@onready var victory_label: Label = $UI/VictoryLabel
@onready var round_label: Label = $UI/RoundLabel
@onready var victory_sound: AudioStreamPlayer = $VictorySound

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
	
	# Add screen shake
	shake_camera()
	
	# Restart after delay
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()

func shake_camera():
	var camera = $Camera2D
	var shake_amount = 10.0
	var shake_duration = 0.5
	var shake_frequency = 30.0
	
	for i in range(int(shake_duration * shake_frequency)):
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		await get_tree().create_timer(1.0 / shake_frequency).timeout
	
	camera.offset = Vector2.ZERO
