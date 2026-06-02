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
	return false

func normalize_card_type(card_type: String) -> String:
	match card_type:
		"attack", "function_attack":
			return "attack"
		"defend", "defesa", "function_defend":
			return "defend"
		"skill", "heal":
			return "skill"
	return card_type

func apply_attack(card_data: CardData, enemy) -> bool:
	if not enemy or not enemy.has_method("take_damage"):
		return false

	var damage = card_data.card_value
	enemy.take_damage(damage)
	create_floating_text(str(damage), enemy.global_position, Color(1, 0.5, 0.3))
	track_damage_dealt(damage)
	return true

func apply_defense(card_data: CardData) -> bool:
	if battle_manager:
		battle_manager.player_block += card_data.card_value
	create_floating_text("+" + str(card_data.card_value), Vector2(120, 160), Color(0.3, 0.6, 1), false)
	return true

func apply_skill(card_data: CardData, target = null) -> bool:
	if card_data.card_name == "Heal" and battle_manager and battle_manager.has_method("player_heal"):
		battle_manager.player_heal(card_data.card_value)
		return true
	return false

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
