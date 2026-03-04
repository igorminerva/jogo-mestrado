extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var battle_ui: CanvasLayer = $BattleUI
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var player_sprite: Sprite2D = $PlayerSprite

var player_defending: bool = false
var enemy_attacks_this_turn: bool = false

func play_finishing_blow(enemy: Node):
	# Congelar frame
	get_tree().paused = true
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = false
	
	# Zoom in e shake forte
	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "zoom", Vector2(1.3, 1.3), 0.1)
	tween.tween_callback(func(): camera.start_shake(15.0, 0.3))
	
	# Som de impacto
	audio_player.stream = preload("res://assets/sounds/heavy_impact.wav")
	audio_player.play()
	
	await get_tree().create_timer(0.2).timeout
	
	# Resetar zoom
	tween = create_tween()
	tween.tween_property(camera, "zoom", Vector2.ONE, 0.2)
	
	# Remover inimigo
	enemy.die()

func play_powerful_defense():
	# Efeito visual do escudo
	var tween = create_tween().set_parallel(true)
	tween.tween_property(player_sprite, "modulate", Color(0.5, 0.5, 1.0, 1.0), 0.1)
	tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.2).set_delay(0.2)
	
	# Som abafado
	audio_player.stream = preload("res://assets/sounds/block.wav")
	audio_player.play()
	
	# Efeito de partícula (opcional)
	if has_node("ShieldParticles"):
		$ShieldParticles.emitting = true

func check_defense_interaction(card_type: String):
	if card_type == "defense" and enemy_attacks_this_turn:
		play_powerful_defense()
		player_defending = true
