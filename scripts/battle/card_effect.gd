extends Node
class_name CardEffect

var battle_manager: Node = null

func apply_card_effect(card_data: CardData, target = null) -> bool:
	var card_type = normalize_card_type(card_data.card_type)
	match card_type:
		"attack":
			return apply_attack(card_data, target)
		"defend":
			return apply_defense(card_data)
		"skill":
			return apply_skill(card_data, target)
		"buff_atk":
			return apply_buff_atk(card_data)
		"buff_def":
			return apply_buff_def(card_data)
		"condition_if":
			return apply_condition_if(card_data)
		"condition_ifelse":
			return apply_condition_ifelse(card_data)
		"repetition_for":
			return apply_repetition_for(card_data)
	return false

func normalize_card_type(card_type: String) -> String:
	match card_type:
		"attack", "function_attack":
			return "attack"
		"defend", "defesa", "function_defend":
			return "defend"
		"skill", "heal":
			return "skill"
		"buff_atk", "power", "strength":
			return "buff_atk"
		"buff_def", "defense_up":
			return "buff_def"
		"condition_if", "condiction_skill":
			return "condition_if"
		"condition_ifelse":
			return "condition_ifelse"
		"repetition_for", "repetition_skill":
			return "repetition_for"
	return card_type

func apply_attack(card_data: CardData, enemy) -> bool:
	if not enemy or not enemy.has_method("take_damage"):
		return false

	var damage = card_data.card_value
	if battle_manager:
		damage += battle_manager.player_atk_buff
	enemy.take_damage(damage)
	create_floating_text(str(damage), enemy.global_position, Color(1, 0.5, 0.3))
	track_damage_dealt(damage)
	return true

func apply_defense(card_data: CardData) -> bool:
	var defense_value = card_data.card_value
	if battle_manager:
		defense_value += battle_manager.player_def_buff
		battle_manager.player_block += defense_value
	create_floating_text("+" + str(defense_value), Vector2(120, 160), Color(0.3, 0.6, 1), false)
	return true

func apply_skill(card_data: CardData, target = null) -> bool:
	if card_data.card_name == "Heal" and battle_manager and battle_manager.has_method("player_heal"):
		battle_manager.player_heal(card_data.card_value)
		return true
	return false

func apply_buff_atk(card_data: CardData) -> bool:
	if battle_manager:
		battle_manager.player_atk_buff += card_data.card_value
		create_floating_text("ATK +" + str(card_data.card_value), Vector2(120, 200), Color(1, 0.8, 0.3))
	return true

func apply_buff_def(card_data: CardData) -> bool:
	if battle_manager:
		battle_manager.player_def_buff += card_data.card_value
		create_floating_text("DEF +" + str(card_data.card_value), Vector2(120, 200), Color(0.3, 0.8, 1))
	return true

func track_damage_dealt(damage: int):
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.current_run["damage_dealt"] = game_state.current_run.get("damage_dealt", 0) + damage

func create_floating_text(text: String, position: Vector2, color: Color, float_up: bool = true):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.position = position
	add_child(label)

	var tween = create_tween()
	if float_up:
		tween.tween_property(label, "position", position - Vector2(0, 50), 0.5)
		tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.5)
	else:
		tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(label.queue_free)

func apply_condition_if(card_data: CardData) -> bool:
	if not battle_manager:
		return false
	var enemy = get_enemy_with_intention()
	if enemy and enemy.current_intention == "attack":
		battle_manager.player_atk_buff += card_data.card_value
		create_floating_text("ATK +" + str(card_data.card_value), Vector2(120, 200), Color(1, 0.8, 0.3))
		return true
	else:
		create_floating_text("Condition not met", Vector2(120, 200), Color(0.5, 0.5, 0.5))
		return true

func apply_condition_ifelse(card_data: CardData) -> bool:
	if not battle_manager:
		return false
	var enemy = get_enemy_with_intention()
	if enemy:
		if enemy.current_intention == "defend":
			battle_manager.player_atk_buff += card_data.card_value
			create_floating_text("ATK +" + str(card_data.card_value), Vector2(120, 200), Color(1, 0.8, 0.3))
			return true
		else:
			battle_manager.player_def_buff += card_data.card_value
			create_floating_text("DEF +" + str(card_data.card_value), Vector2(120, 200), Color(0.3, 0.8, 1))
			return true
	return true

func apply_repetition_for(card_data: CardData) -> bool:
	if not battle_manager:
		return false
	battle_manager.repeat_next_card = card_data.card_value
	battle_manager.repeat_type = "attack"
	create_floating_text("Repeat " + str(card_data.card_value) + "x", Vector2(120, 200), Color(0.8, 0.3, 1))
	return true

func get_enemy_with_intention():
	if battle_manager and battle_manager.enemy_manager:
		var enemies = battle_manager.enemy_manager.get_enemies()
		if enemies.size() > 0:
			return enemies[0]
	return null
