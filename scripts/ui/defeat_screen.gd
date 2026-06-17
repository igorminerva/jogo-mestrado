extends Control
class_name DefeatScreen
signal new_run_requested
signal bestiary_requested
signal return_to_menu_requested

@onready var damage_taken_label: Label = $Panel/VBoxContainer/DamageTaken
@onready var turn_defeated_label: Label = $Panel/VBoxContainer/TurnDefeated
@onready var enemies_killed_label: Label = $Panel/VBoxContainer/EnemiesKilled
@onready var reflection_text: RichTextLabel = $Panel/VBoxContainer/ReflectionText
@onready var new_run_button: Button = $Panel/VBoxContainer/NewRunButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton
@onready var bestiary_button: Button = $Panel/VBoxContainer/BestiaryButton
@onready var unlocked_item_label: Label = $Panel/VBoxContainer/UnlockedItem

var battle_stats: Dictionary = {}
var killed_by: String = ""

func _ready():
	z_index = 1000
	new_run_button.pressed.connect(_on_new_run_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	bestiary_button.pressed.connect(_on_bestiary_pressed)
	display_stats()
	process_progression()

func setup(stats: Dictionary):
	battle_stats = stats
	killed_by = stats.get("killed_by", "Unknown")

func display_stats():
	damage_taken_label.text = "Dano Sofrido: " + str(battle_stats.get("damage_taken", 0))
	turn_defeated_label.text = "Derrotado no Turno: " + str(battle_stats.get("turn_defeated", 1))
	enemies_killed_label.text = "Inimigos Derrotados: " + str(battle_stats.get("enemies_killed", 0))

func process_progression():
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
	
	game_state.register_enemy_encounter(killed_by, false)
	show_reflection()
	attempt_unlock_item(game_state)

func show_reflection():
	var reflections = [
		"[center]💭 O que podia ter feito diferente?[/center]",
		"[center]💭 Talvez guardar defesa para o próximo turno?[/center]",
		"[center]💭 Ataques muito agressivos te deixaram vulnerável.[/center]",
		"[center]💭 Faltou gerenciar melhor seus recursos.[/center]",
		"[center]💭 Tente focar em um inimigo por vez.[/center]",
		"[center]💭 Use cartas de defesa antes dos ataques pesados.[/center]"
	]
	reflection_text.text = reflections[randi() % reflections.size()]

func attempt_unlock_item(game_state):
	if randf() < 0.7:
		var new_item = get_random_unlockable_item()
		game_state.unlock_item(new_item)
		unlocked_item_label.text = "✨ Desbloqueado: " + new_item + " ✨"
		unlocked_item_label.visible = true
	else:
		unlocked_item_label.text = "Continue jogando para desbloquear novos itens!"
		unlocked_item_label.visible = true

func get_random_unlockable_item() -> String:
	var unlockable_items = [
		"Espada Afiada", "Escudo Reforçado", "Amuleto de Regeneração",
		"Poção de Vida", "Cristal de Poder", "Manuscrito Antigo",
		"Bota Veloz", "Capa da Sorte", "Anel da Sabedade"
	]
	return unlockable_items[randi() % unlockable_items.size()]

func _on_new_run_pressed():
	print("DEBUG: New run button pressed")
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.end_run(false)
		game_state.start_new_run()
	
	cleanup_old_scenes()
	
	get_tree().call_deferred("change_scene_to_packed", load("res://scenes/map/map_scene_slay.tscn"))
	queue_free()

func cleanup_old_scenes():
	var current_parent = get_parent()
	while current_parent:
		var parent_to_free = current_parent
		current_parent = current_parent.get_parent()
		if parent_to_free and parent_to_free.name.begins_with("Battle"):
			parent_to_free.queue_free()
			break
	
	# Also clean any other leftover scenes
	var root = get_tree().root
	var scenes_to_clean = ["Battle", "Victory", "Defeat", "VictoryRewards"]
	for child in root.get_children():
		for scene_name in scenes_to_clean:
			if child.name.begins_with(scene_name) or child.name == scene_name:
				child.queue_free()
				break

func _on_menu_pressed():
	print("DEBUG: Defeat screen menu button pressed")
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.end_run(false)
	
	cleanup_old_scenes()
	
	get_tree().call_deferred("change_scene_to_packed", load("res://scenes/menu/main_menu.tscn"))
	queue_free()

func _on_bestiary_pressed():
	bestiary_requested.emit()
	var bestiary_scene = preload("res://scenes/ui/bestiary_screen.tscn").instantiate()
	bestiary_scene.z_index = 2000
	add_child(bestiary_scene)
