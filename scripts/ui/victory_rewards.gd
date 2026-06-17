extends Control
class_name VictoryRewards
signal rewards_selected

@onready var cards_container: GridContainer = $Panel/VBoxContainer/CardsContainer
@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var exp_label: Label = $Panel/VBoxContainer/ExpLabel
@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton
@onready var fanfare_player: AudioStreamPlayer = $FanfarePlayer

var reward_cards: Array = []
var selected_card_index: int = -1
var battle_stats: Dictionary = {}

func _ready():
	z_index = 1000
	if fanfare_player:
		fanfare_player.play()
	generate_rewards()
	continue_button.disabled = true
	continue_button.pressed.connect(_on_continue_pressed)

func setup(stats: Dictionary):
	battle_stats = stats
	gold_label.text = "+" + str(stats.get("gold_reward", 0))
	exp_label.text = "+" + str(stats.get("exp_reward", 0))

func generate_rewards():
	var card_manager = CardManager.new()
	card_manager.load_all_cards()
	
	for i in range(3):
		var rarity = determine_rarity()
		var card_data = card_manager.get_random_card(rarity)
		if card_data == null:
			continue
		reward_cards.append(card_data)
		var reward_card = create_reward_card(card_data, i)
		cards_container.add_child(reward_card)

func determine_rarity() -> String:
	var roll = randf()
	if roll < 0.6:
		return "common"
	elif roll < 0.85:
		return "rare"
	elif roll < 0.95:
		return "epic"
	else:
		return "legendary"

func create_reward_card(card_data: CardData, index: int) -> Button:
	var card_scene = preload("res://scenes/rewards/reward_card.tscn")
	var card = card_scene.instantiate() as RewardCard
	card.setup(card_data)
	card.pressed.connect(_on_card_selected.bind(index))
	
	if card_data.card_rarity != "common":
		add_rarity_glow(card, card_data.card_rarity)
	
	return card

func add_rarity_glow(card: Control, rarity: String):
	var color = get_rarity_color(rarity)
	var style = StyleBoxFlat.new()
	style.set_border_width_all(3)
	style.set_border_color(color)
	style.set_bg_color(Color(0.1, 0.1, 0.1, 0.9))
	card.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.set_border_color(color.lightened(0.3))
	card.add_theme_stylebox_override("hover", hover_style)

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.3, 0.8, 1)
		"epic":
			return Color(0.8, 0.3, 1)
		"legendary":
			return Color(1, 0.8, 0.2)
		_:
			return Color.WHITE

func _on_card_selected(index: int):
	if selected_card_index != -1:
		var prev_card = cards_container.get_child(selected_card_index)
		if prev_card:
			prev_card.modulate = Color.WHITE
	
	selected_card_index = index
	var selected_card = cards_container.get_child(index)
	if selected_card:
		selected_card.modulate = Color(1, 1, 0.5)
	
	add_card_to_deck(reward_cards[index])
	continue_button.disabled = false

func add_card_to_deck(card_data: CardData):
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.current_run.has("deck"):
		game_state.current_run["deck"].append(card_data)

func _on_continue_pressed():
	rewards_selected.emit()
	queue_free()
