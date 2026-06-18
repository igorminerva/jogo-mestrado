extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var battle_ui: CanvasLayer = $BattleUI
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var enemy_container: Node2D = $Battlefield/EnemyPosition
@onready var player_sprite: Sprite2D = $Battlefield/PlayerPosition/PlayerSprite
@onready var deck_manager: DeckManager = $DeckManager
@onready var hand_manager: HandManager = $BattleUI/HandManager
@onready var card_effect: CardEffect = $CardEffect
@onready var energy_label: Label = $BattleUI/EnergyLabel
@onready var end_turn_button: Button = $BattleUI/EndTurnButton
@onready var enemy_manager: EnemyManager = $EnemyManager
@onready var stats_label: Label = $BattleUI/StatsBar/StatsLabel

signal battle_finished(victory: bool, rewards: Dictionary)

var player_defending: bool = false
var enemy_attacks_this_turn: bool = false
var game_over_called: bool = false

var current_energy: int = 3
var max_energy: int = 3
var player_block: int = 0
var player_hp: int = 50
var player_atk_buff: int = 0
var player_def_buff: int = 0
var repeat_next_card: int = 0
var repeat_type: String = ""
var is_player_turn: bool = true
var current_turn: int = 1
var cards_played_this_turn: int = 0
var current_battle_rewards: Dictionary = {
	"gold": 0,
	"exp": 0,
	"cards": []
}
var battle_enemy_names: Array = []
var card_usage_count: Dictionary = {}
var current_node: Dictionary = {}

func _ready():
	current_node = get_node("/root/GameState").current_run.get("current_battle_node", {})
	card_effect.battle_manager = self
	deck_manager.card_played.connect(_on_card_played)
	enemy_manager.enemy_action_processed.connect(_on_enemy_action)
	enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	enemy_manager.enemy_turn_finished.connect(_on_enemy_turn_finished)
	end_turn_button.pressed.connect(end_turn)
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_setup_responsive_layout()

	print("DEBUG: BattleManager ready. EndTurnButton found=", is_instance_valid(end_turn_button), " path=", end_turn_button.get_path())

func _setup_responsive_layout():
	if not is_inside_tree():
		return
	var screen_size = get_viewport_rect().size
	
	var player_pos = $Battlefield/PlayerPosition
	var enemy_pos = $Battlefield/EnemyPosition
	
	player_pos.position = Vector2(screen_size.x * 0.2, screen_size.y * 0.4)
	enemy_pos.position = Vector2(screen_size.x * 0.75, screen_size.y * 0.4)
	
	if camera:
		camera.position = screen_size / 2

func _on_viewport_size_changed():
	_setup_responsive_layout()

func _on_end_turn_pressed():
	print("DEBUG: End turn button was pressed!")
	end_turn()

var is_boss_battle: bool = false

func setup_battle(enemies_data: Array[EnemyData] = [], is_elite: bool = false, is_boss: bool = false):
	is_boss_battle = is_boss
	hand_manager.clear_hand()
	var game_state = get_node("/root/GameState")
	print("DEBUG setup_battle: deck from game_state =", game_state.current_run.get("deck", []))
	player_hp = game_state.current_run.get("hp", player_hp)
	max_energy = 3
	current_energy = max_energy
	
	if enemies_data.is_empty():
		enemies_data = get_current_battle_enemies()
	
	battle_enemy_names.clear()
	for enemy_data in enemies_data:
		if enemy_data and enemy_data.enemy_name:
			battle_enemy_names.append(enemy_data.enemy_name)
	
	enemy_manager.add_enemies_from_data(enemies_data)
	current_battle_rewards["gold"] = calculate_gold_reward(is_elite, is_boss)
	current_battle_rewards["exp"] = calculate_exp_reward(is_elite, is_boss)

	var player_deck = get_player_deck()
	deck_manager.initialize_deck(player_deck)
	deck_manager.draw_starting_hand()
	update_energy_display()
	start_player_turn()

func calculate_gold_reward(is_elite: bool, is_boss: bool) -> int:
	if is_boss:
		return 100
	elif is_elite:
		return 50
	return 25

func calculate_exp_reward(is_elite: bool, is_boss: bool) -> int:
	if is_boss:
		return 50
	elif is_elite:
		return 25
	return 10

func get_current_battle_enemies() -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	var goblin = load("res://resources/enemies/enemy_goblin.tres")
	var orc = load("res://resources/enemies/enemy_orc.tres")
	enemies.append(goblin)
	enemies.append(orc)
	return enemies

func get_player_deck() -> Array[CardData]:
	var game_state = get_node("/root/GameState")
	print("DEBUG get_player_deck: current_run keys=", game_state.current_run.keys())
	print("DEBUG get_player_deck: deck in current_run=", game_state.current_run.has("deck"))
	if game_state.current_run.has("deck"):
		print("DEBUG get_player_deck: deck size=", game_state.current_run["deck"].size())
		for i in range(game_state.current_run["deck"].size()):
			var card = game_state.current_run["deck"][i]
			print("DEBUG get_player_deck: card[", i, "] type=", typeof(card), " is CardData=", card is CardData)
		print("DEBUG get_player_deck: deck contents=", game_state.current_run["deck"])
	if game_state.current_run.has("deck") and game_state.current_run["deck"].size() > 0:
		var deck: Array[CardData] = []
		for card in game_state.current_run["deck"]:
			if card is CardData:
				deck.append(card)
		print("DEBUG get_player_deck: returning deck with ", deck.size(), " cards")
		return deck

	var deck: Array[CardData] = []
	var card_files = ["attack", "defesa", "attack", "defesa", "attack"]
	for card_name in card_files:
		var card = load("res://resources/cards/" + card_name + ".tres")
		if card and card is CardData:
			deck.append(card)
	return deck

func _on_card_played(card: CardUI):
	if not is_player_turn:
		return
	try_play_card(card)

func try_play_card(card: CardUI):
	var cost = card.card_data.card_cost
	var repetitions = 1

	if repeat_next_card > 0:
		repetitions = repeat_next_card
		repeat_next_card = 0

	if current_energy < cost:
		show_not_enough_energy()
		return

	var target = get_target_enemy()
	if not target:
		return

	var card_type = card.card_data.normalize_card_type(card.card_data.card_type) if card.card_data.has_method("normalize_card_type") else card.card_data.card_type
	
	if card_type == "repetition_for":
		card_effect.apply_card_effect(card.card_data, target)
		current_energy -= cost
		deck_manager.discard_card(card)
		card.play_card_animation()
		await card.tree_exited
		update_energy_display()
		return

	for i in range(repetitions):
		var success = card_effect.apply_card_effect(card.card_data, target)
		if not success:
			show_not_enough_energy()
			return

	current_energy -= cost
	cards_played_this_turn += 1
	track_card_usage(card.card_data)
	deck_manager.discard_card(card)
	card.play_card_animation()
	await card.tree_exited

	update_energy_display()
	check_victory()

func get_target_enemy():
	"""Retorna o inimigo selecionado ou o primeiro da lista"""
	for enemy in enemy_manager.get_enemies():
		if enemy.modulate != Color.WHITE:
			return enemy
	
	var enemies = enemy_manager.get_enemies()
	if enemies.size() > 0:
		return enemies[0]
	return null

func end_turn():
	if not is_player_turn:
		return
	is_player_turn = false
	end_turn_button.disabled = true
	end_turn_button.text = "TURNO INIMIGO..."
	
	var btn = end_turn_button
	var tween = create_tween()
	tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)
	
	show_turn_message("Turno do Inimigo!")
	
	print("DEBUG: BattleManager: end_turn called, starting enemy turn")
	enemy_manager.execute_enemy_turn()

func show_turn_message(msg: String):
	var label = Label.new()
	label.text = msg
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	label.position = Vector2(500, 100)
	label.z_index = 100
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.5)
	tween.tween_callback(label.queue_free)

func start_player_turn():
	is_player_turn = true
	current_energy = max_energy
	cards_played_this_turn = 0
	player_block = 0
	player_atk_buff = 0
	player_def_buff = 0
	repeat_next_card = 0
	repeat_type = ""
	get_node("/root/GameState").current_run["turns_survived"] += 1

	# Discard unplayed cards from previous turn
	deck_manager.discard_hand()
	
	# Mostrar intenções dos inimigos
	enemy_manager.setup_enemy_intentions()
	
	# Draw 5 cards for this turn
	for i in range(5):
		deck_manager.draw_card()
	
	# Enable end turn button
	end_turn_button.disabled = false
	end_turn_button.text = "FIM DO TURNO"
	end_turn_button.modulate = Color.WHITE
	
	update_energy_display()

	for card in deck_manager.hand:
		card.set_playable(true)

	# Debug: print hand and playability
	var hand_debug = []
	for c in deck_manager.hand:
		hand_debug.append({"name": c.card_data.card_name, "cost": c.card_data.card_cost, "playable": c.is_playable})
	print("DEBUG: start_player_turn: is_player_turn=", is_player_turn, " current_energy=", current_energy, " hand_size=", deck_manager.hand.size(), " hand=", hand_debug)

func _on_all_enemies_defeated():
	if enemy_manager.get_enemies().is_empty():
		victory(is_boss_battle)
		return
	
	if player_hp <= 0 and not game_over_called:
		game_over_called = true
		game_over()
	else:
		current_turn += 1
		start_player_turn()

func _on_enemy_turn_finished():
	print("DEBUG: BattleManager: enemy turn finished signal received")
	if enemy_manager.get_enemies().is_empty():
		return
	if player_hp <= 0 and not game_over_called:
		game_over()
	elif player_hp > 0:
		current_turn += 1
		print("DEBUG: Enemy turn finished. Preparing player turn. player_hp=", player_hp, " enemies=", enemy_manager.get_enemies().size())
		# Add a small delay before starting player turn for visual clarity
		await get_tree().create_timer(0.5).timeout
		start_player_turn()

func _on_enemy_action(action_type: String, value: int, enemy: Enemy):
	match action_type:
		"attack":
			var damage = value
			print("DEBUG: Enemy action attack received: damage=", damage, " player_block=", player_block, " player_hp=", player_hp)
			var actual_damage = max(0, damage - player_block)
			player_block = max(0, player_block - damage)
			player_hp -= actual_damage
			print("DEBUG: After applying block: actual_damage=", actual_damage, " new_player_block=", player_block, " new_player_hp=", player_hp)
			var game_state = get_node("/root/GameState")
			game_state.current_run.damage_taken += actual_damage
			game_state.current_run["hp"] = player_hp
			# Refresh top stats UI
			update_energy_display()
			create_damage_flash()
			show_damage_to_player(actual_damage)
			if player_hp <= 0 and not game_over_called:
				game_over_called = true
				game_over()
		"defend":
			# Defesa aplicada internamente pelo inimigo
			pass
		"buff":
			# Buff aplicado internamente pelo inimigo
			pass

func update_energy_display():
	energy_label.text = str(current_energy) + "/" + str(max_energy)

	# Update top stats bar
	if stats_label:
		var stats = get_battle_stats()
		stats_label.text = "HP: %d   Turn: %d   Enemies: %d" % [player_hp, stats["turns"], enemy_manager.get_enemies().size()]

	update_hand_playability()

	# If the player has no mana and no playable cards, end their turn.
	if is_player_turn and current_energy <= 0 and not has_playable_cards():
		show_auto_pass_message()
		end_turn()

func update_hand_playability():
	for card in deck_manager.hand:
		var cost = card.card_data.card_cost
		card.set_playable(is_player_turn and current_energy >= cost)

func has_playable_cards() -> bool:
	for card in deck_manager.hand:
		if current_energy >= card.card_data.card_cost:
			return true
	return false

func show_not_enough_energy():
	var label = Label.new()
	label.text = "Energia Insuficiente!"
	label.position = Vector2(400, 300)
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(label.queue_free)

func show_auto_pass_message():
	var label = Label.new()
	label.text = "Turno passato: nessuna carta giocabile"
	label.position = Vector2(400, 300)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(label.queue_free)

func show_damage_to_player(damage: int):
	var label = Label.new()
	label.text = str(damage)
	label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
	label.position = player_sprite.global_position - Vector2(0, 30)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position", player_sprite.global_position - Vector2(0, 60), 0.5)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(label.queue_free)

func create_damage_flash():
	var flash = ColorRect.new()
	flash.color = Color(1, 0.2, 0.2, 0.4)
	flash.size = get_viewport().get_visible_rect().size
	add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "color", Color(1, 0.2, 0.2, 0), 0.3)
	tween.tween_callback(flash.queue_free)

func player_heal(amount: int):
	player_hp = min(player_hp + amount, 50)
	print("Curado ", amount)

func track_card_usage(card_data: CardData):
	var game_state = get_node("/root/GameState")
	var card_name = card_data.card_name
	
	if not game_state.current_run.has("card_usage"):
		game_state.current_run["card_usage"] = {}
	
	game_state.current_run["card_usage"][card_name] = game_state.current_run["card_usage"].get(card_name, 0) + 1
	
	card_usage_count[card_name] = card_usage_count.get(card_name, 0) + 1

func get_most_used_card() -> String:
	var most_used = ""
	var max_count = 0
	
	for card_name in card_usage_count:
		if card_usage_count[card_name] > max_count:
			max_count = card_usage_count[card_name]
			most_used = card_name
	
	return most_used

func get_battle_stats() -> Dictionary:
	return {
		"turns": current_turn,
		"damage_dealt": 0,
		"damage_taken": 0,
		"cards_played": cards_played_this_turn,
		"enemies_killed": battle_enemy_names.size(),
		"most_used_card": get_most_used_card()
	}

func play_finishing_blow(enemy: Enemy):
	get_tree().paused = true
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = false

	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "zoom", Vector2(1.3, 1.3), 0.1)
	tween.tween_callback(func(): camera.start_shake(15.0, 0.3))

	if audio_player.has_stream_playback():
		audio_player.stream = preload("res://assets/sounds/combat/card_draw.wav")
		audio_player.play()

	await get_tree().create_timer(0.2).timeout

	tween = create_tween()
	tween.tween_property(camera, "zoom", Vector2.ONE, 0.2)

	enemy.die()

func play_powerful_defense():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(player_sprite, "modulate", Color(0.5, 0.5, 1.0, 1.0), 0.1)
	tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.2).set_delay(0.2)

	if audio_player.has_stream_playback():
		audio_player.stream = preload("res://assets/sounds/ui/click.wav")
		audio_player.play()

	if has_node("ShieldParticles"):
		$ShieldParticles.emitting = true

func check_defense_interaction(card_type: String):
	if card_type == "defense" and enemy_attacks_this_turn:
		play_powerful_defense()
		player_defending = true

func check_victory():
	var enemies = enemy_manager.get_enemies()
	if enemies.is_empty():
		victory(is_boss_battle)

func victory(is_boss_victory: bool = false):
	print("Vitória!" + (" (BOSS)" if is_boss_victory else ""))
	var game_state = get_node("/root/GameState")
	game_state.current_run.gold += current_battle_rewards["gold"]
	game_state.current_run.enemies_defeated.append_array(battle_enemy_names)
	game_state.current_run["total_enemies_killed"] = game_state.current_run.get("total_enemies_killed", 0) + battle_enemy_names.size()
	emit_signal("battle_finished", true, current_battle_rewards)
	
	if is_boss_victory:
		show_final_victory()
	else:
		show_battle_rewards()

func show_battle_rewards():
	var rewards_scene = preload("res://scenes/victory/victory_rewards.tscn").instantiate()
	battle_ui.add_child(rewards_scene)
	rewards_scene.setup({"gold_reward": current_battle_rewards["gold"], "exp_reward": current_battle_rewards["exp"]})
	rewards_scene.rewards_selected.connect(_on_rewards_selected)

func show_final_victory():
	var game_state = get_node("/root/GameState")
	var victory_scene = preload("res://scenes/ui/victory_screen.tscn").instantiate()
	victory_scene.z_index = 1000
	battle_ui.add_child(victory_scene)
	victory_scene.setup({
		"gold_reward": current_battle_rewards["gold"],
		"exp_reward": current_battle_rewards["exp"],
		"is_final": true
	})
	victory_scene.game_completed.connect(_on_game_completed)

func _on_rewards_selected():
	var game_state = get_node("/root/GameState")
	save_battle_deck_to_game_state()
	print("DEBUG _on_rewards_selected: deck AFTER saving battle deck =", game_state.current_run.get("deck", []))
	print("DEBUG _on_rewards_selected: deck size =", game_state.current_run["deck"].size() if game_state.current_run.has("deck") else 0)
	var completed_floor = current_node.get("floor", 0)
	var next_floor = completed_floor + 1
	
	# Save completed floor to GameState
	if not game_state.current_run.has("completed_floors"):
		game_state.current_run["completed_floors"] = []
	if completed_floor not in game_state.current_run["completed_floors"]:
		game_state.current_run["completed_floors"].append(completed_floor)
	
	# Save accessible floor to GameState
	if not game_state.current_run.has("accessible_floors"):
		game_state.current_run["accessible_floors"] = []
	if next_floor not in game_state.current_run["accessible_floors"]:
		game_state.current_run["accessible_floors"].append(next_floor)
	
	print("DEBUG: Saved completed floor=", completed_floor, " next floor accessible=", next_floor)
	
	# Find the hidden map and make it visible again
	for node in get_tree().root.get_children():
		if node.name == "MapScene":
			node.visible = true
			node.set_skip_room_auto_selection(false)  # Re-enable after battle
			node.load_progress_from_game_state()
			print("DEBUG: Made map visible and reloaded nodes")
			break
	
	await get_tree().process_frame
	queue_free()

func _on_game_completed():
	get_node("/root/GameState").end_run(true)
	if get_parent():
		get_parent().queue_free()
	else:
		queue_free()

func game_over():
	print("Derrota!")
	var game_state = get_node("/root/GameState")
	var killed_by = "Unknown"
	if battle_enemy_names.size() > 0:
		killed_by = battle_enemy_names[0]
	game_state.end_run(false)
	show_defeat_screen(killed_by)
	emit_signal("battle_finished", false, current_battle_rewards)

func show_defeat_screen(killed_by: String = "Unknown"):
	var game_state = get_node("/root/GameState")
	var defeat_scene = preload("res://scenes/ui/defeat_screen.tscn").instantiate()
	defeat_scene.z_index = 1000
	defeat_scene.setup({
		"damage_taken": game_state.current_run.damage_taken,
		"turn_defeated": current_turn,
		"enemies_killed": game_state.current_run.enemies_defeated.size(),
		"killed_by": killed_by
	})
	battle_ui.add_child(defeat_scene)

func save_battle_deck_to_game_state():
	var game_state = get_node("/root/GameState")
	var complete_deck: Array[CardData] = []
	complete_deck.append_array(deck_manager.draw_pile)
	complete_deck.append_array(deck_manager.discard_pile)
	for card_ui in deck_manager.hand:
		if card_ui.card_data:
			complete_deck.append(card_ui.card_data)
	print("DEBUG save_battle_deck: draw_pile=", deck_manager.draw_pile.size(), " discard=", deck_manager.discard_pile.size(), " hand=", deck_manager.hand.size())
	print("DEBUG save_battle_deck: complete deck to save=", complete_deck.size(), " cards")
	game_state.current_run["deck"] = complete_deck
