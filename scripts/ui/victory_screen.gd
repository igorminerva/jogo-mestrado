extends Control
class_name VictoryScreen
signal rewards_selected
signal game_completed

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var story_label: RichTextLabel = $VBoxContainer/StoryLabel
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var turn_label: Label = $VBoxContainer/StatsContainer/TurnLabel
@onready var damage_label: Label = $VBoxContainer/StatsContainer/DamageLabel
@onready var enemies_label: Label = $VBoxContainer/StatsContainer/EnemiesLabel
@onready var most_used_label: Label = $VBoxContainer/StatsContainer/MostUsedCardLabel
@onready var gold_label: Label = $VBoxContainer/StatsContainer/GoldLabel
@onready var share_button: Button = $VBoxContainer/ShareButton
@onready var unlock_label: Label = $VBoxContainer/UnlockLabel
@onready var menu_button: Button = $VBoxContainer/MenuButton

var run_stats: Dictionary = {}

func _ready():
	share_button.pressed.connect(_on_share_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	play_victory_sequence()

func setup(stats: Dictionary):
	run_stats = stats

func play_victory_sequence():
	play_victory_animation()
	await get_tree().create_timer(1.5).timeout
	show_story_text()
	await get_tree().create_timer(3.0).timeout
	show_run_stats()
	await get_tree().create_timer(0.5).timeout
	process_unlockables()

func play_victory_animation():
	if animation_player and animation_player.has_animation("victory"):
		animation_player.play("victory")
	else:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func show_story_text():
	var game_state = get_node_or_null("/root/GameState")
	var floors_cleared = game_state.current_run.get("current_floor", 0) if game_state else 0
	
	var story_texts = [
		"[center]Com o chefe derrotado, as trevas começam a recuar...[/center]",
		"[center]Os Relicários brilham novamente com luz pura.[/center]",
		"[center]Você salvou o mundo da destruição![/center]",
		"[center]Sua jornada chegou ao fim... mas novas aventuras aguardam.[/center]"
	]
	
	story_label.text = story_texts[0]
	story_label.visible = true
	
	for i in range(1, story_texts.size()):
		await get_tree().create_timer(2.0).timeout
		story_label.text = story_texts[i]

func show_run_stats():
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
	
	var total_turns = game_state.current_run.get("turns_survived", 0)
	var damage_dealt = game_state.current_run.get("damage_dealt", 0)
	var enemies_killed = game_state.current_run.get("total_enemies_killed", 0)
	var gold_earned = game_state.current_run.get("gold", 0)
	var card_usage = game_state.current_run.get("card_usage", {})
	var most_used_card = get_most_used_card_from_dict(card_usage)
	
	turn_label.text = "Turnos: " + str(total_turns)
	damage_label.text = "Dano Causado: " + str(damage_dealt)
	enemies_label.text = "Inimigos Derrotados: " + str(enemies_killed)
	most_used_label.text = "Carta Mais Usada: " + (most_used_card if most_used_card else "Nenhuma")
	gold_label.text = "Ouro Total: " + str(gold_earned)
	
	stats_container.visible = true

func get_most_used_card_from_dict(card_usage: Dictionary) -> String:
	var most_used = ""
	var max_count = 0
	
	for card_name in card_usage:
		if card_usage[card_name] > max_count:
			max_count = card_usage[card_name]
			most_used = card_name
	
	return most_used

func process_unlockables():
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
	
	game_state.total_victories += 1
	
	var unlocks = [
		"Novo Personagem: Mago",
		"Novo Deck Inicial",
		"Dificuldade: Pesado",
		"Carta Lendária"
	]
	var new_unlock = unlocks[randi() % unlocks.size()]
	
	game_state.unlock_item(new_unlock)
	unlock_label.text = "✨ NOVO DESBLOQUEADO: " + new_unlock + " ✨"
	unlock_label.visible = true
	
	game_state.save_game_data()

func _on_share_pressed():
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
	
	var total_turns = game_state.current_run.get("turns_survived", 0)
	var card_usage = game_state.current_run.get("card_usage", {})
	var most_used = get_most_used_card_from_dict(card_usage)
	
	var share_text = "Run vitoriosa em %d turnos! Carta mais usada: '%s'." % [total_turns, most_used]
	
	DisplayServer.clipboard_set(share_text)
	
	var original_text = share_button.text
	share_button.text = "Copiado!"
	await get_tree().create_timer(1.5).timeout
	share_button.text = original_text

func _on_menu_pressed():
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.end_run(true)
	
	game_completed.emit()
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
