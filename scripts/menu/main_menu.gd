extends Control

@onready var play_button: Button = $ButtonContainer/PlayButton
@onready var options_button: Button = $ButtonContainer/OptionsButton
@onready var quit_button: Button = $ButtonContainer/QuitButton
@onready var tip_label: Label = $TipPanel/TipLabel
@onready var tip_timer: Timer = $TipTimer
@onready var particles: GPUParticles2D = $Particles

var tips: Array[String] = [
	"✨ Dica: Use cartas de defesa antes de ataques pesados!",
	"📊 A run anterior durou 47 turnos!",
	"🆕 Nova build disponível para testar!",
	"💀 Monstros elites dão recompensas melhores!",
	"🛒 Visite a loja para melhorar seu deck!",
	"🎯 Foque em um inimigo por vez!",
	"⭐ Cartas raras têm borda dourada!",
	"🔄 O baralho é reembaralhado quando acaba!",
	"💪 Quanto mais HP você tiver, mais agressivo pode ser!",
	"🏆 Derrote o chefe para desbloquear novos conteúdos!"
]

var current_tip_index: int = 0

func _ready():
	setup_button_animations()
	setup_particles()
	load_game_stats_for_tips()

	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	tip_timer.timeout.connect(_next_tip)
	
	update_tip_display()

func setup_button_animations():
	for button in [play_button, options_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_exit.bind(button))

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "modulate", Color(1.2, 1.1, 0.9), 0.1)

func _on_button_exit(button: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1)
	tween.tween_property(button, "modulate", Color(1, 1, 1), 0.1)

func setup_particles():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(particles, "position", Vector2(640, 380), 10.0)
	tween.tween_property(particles, "position", Vector2(640, 360), 10.0)

func load_game_stats_for_tips():
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		var last_run_turns = game_state.current_run.get("turns_survived", 0)
		if last_run_turns > 0:
			tips.append("📜 Sua última run durou " + str(last_run_turns) + " turnos!")

func _next_tip():
	current_tip_index = (current_tip_index + 1) % tips.size()
	update_tip_display()

func update_tip_display():
	var tween = create_tween()
	tween.tween_property(tip_label, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): tip_label.text = tips[current_tip_index])
	tween.tween_property(tip_label, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_play_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/menu/cutscene.tscn"))

func _on_options_pressed():
	print("Opções - Será implementado depois")

func _on_quit_pressed():
	get_tree().quit()
