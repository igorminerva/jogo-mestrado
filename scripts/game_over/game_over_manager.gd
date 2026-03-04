extends Control

@onready var damage_taken_label: Label = $VBoxContainer/Stats/DamageTaken
@onready var turn_defeated_label: Label = $VBoxContainer/Stats/TurnDefeated
@onready var reflection_text: Label = $VBoxContainer/ReflectionText
@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var bestiary_button: Button = $VBoxContainer/BestiaryButton

var battle_stats: Dictionary = {
	"damage_taken": 0,
	"turn_defeated": 1,
	"killed_by": "Goblin"
}

func _ready():
	display_stats()
	unlock_progression_reward()
	
	reflection_text.text = get_reflection_text()
	new_run_button.grab_focus()

func display_stats():
	damage_taken_label.text = "Dano Sofrido: " + str(battle_stats["damage_taken"])
	turn_defeated_label.text = "Derrotado no Turno: " + str(battle_stats["turn_defeated"])

func get_reflection_text() -> String:
	var texts = [
		"O que podia ter feito diferente?",
		"Talvez guardar defesa para o próximo turno?",
		"Ataques muito agressivos te deixaram vulnerável.",
        "Faltou gerenciar melhor seus recursos."
	]
	return texts[randi() % texts.size()]

func unlock_progression_reward():
	var progression = ProgressionSystem.new()
	
	# 50% de chance de desbloquear item
	if randf() > 0.5:
		var new_item = progression.unlock_random_item()
		reflection_text.text += "\n\n[color=green]Novo item desbloqueado: " + new_item + "[/color]"
	
	# Sempre registrar no bestiário
	progression.register_bestiary_entry(battle_stats["killed_by"])
	bestiary_button.disabled = false

func _on_new_run_button_pressed():
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_bestiary_button_pressed():
	# Abrir bestiário (seria implementado separadamente)
	print("Abrir bestiário")
