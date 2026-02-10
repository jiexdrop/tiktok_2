extends Node

func play_sfx(stream: AudioStream, position: Vector2):
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = position
	player.bus = "SFX" # Optional: route to a specific bus
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
