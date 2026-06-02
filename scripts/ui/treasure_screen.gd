extends Control
signal treasure_collected(rewards: Dictionary)

@onready var gold_label: Label = $Panel/VBoxContainer/RewardContainer/GoldContainer/GoldLabel
@onready var card_name_label: Label = $Panel/VBoxContainer/RewardContainer/CardContainer/CardName
@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton

var rewards: Dictionary = {
	"gold": 50,
	"card": null
}

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	generate_rewards()
	update_display()

func generate_rewards():
	var game_state = get_node("/root/GameState")
	game_state.current_run["gold"] = game_state.current_run.get("gold", 0) + rewards["gold"]
	
	var card_manager = preload("res://scripts/battle/card_manager.gd").new()
	card_manager.load_all_cards()
	var random_card = card_manager.get_random_card("common")
	if random_card:
		rewards["card"] = random_card
		game_state.current_run["deck"].append(random_card)

func update_display():
	gold_label.text = "+" + str(rewards["gold"]) + " Ouro"
	if rewards["card"]:
		card_name_label.text = rewards["card"].card_name

func _on_continue_pressed():
	emit_signal("treasure_collected", rewards)
	queue_free()