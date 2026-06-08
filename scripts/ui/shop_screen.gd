extends Control
signal shop_closed(result: Dictionary)

@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/ItemsContainer
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var leave_button: Button = $Panel/VBoxContainer/Buttons/LeaveButton

var offers: Array = []

func _ready():
	print("DEBUG: ShopScreen loaded")
	leave_button.pressed.connect(_on_leave_pressed)
	create_offers()
	update_gold_display()

func create_offers():
	var card_manager = preload("res://scripts/battle/card_manager.gd").new()
	card_manager.load_all_cards()
	offers = [
		{
			"title": "Cofre de Cartas",
			"description": "Adicione uma carta comum aleatória ao seu deck.",
			"cost": 30,
			"type": "card",
			"card_data": card_manager.get_random_card("common")
		},
		{
			"title": "Poção de Cura",
			"description": "Recupera 15 HP agora.",
			"cost": 20,
			"type": "item",
			"item_id": "Poção de Cura"
		},
		{
			"title": "Escudo Tático",
			"description": "Ganha +5 de defesa no próximo combate.",
			"cost": 25,
			"type": "item",
			"item_id": "Escudo Tático"
		}
	]

	for i in range(offers.size()):
		var offer = offers[i]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 40)

		var info = VBoxContainer.new()
		var title = Label.new()
		title.text = offer["title"]
		title.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
		var desc = Label.new()
		desc.text = offer["description"]
		desc.custom_minimum_size = Vector2(200, 0)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(title)
		info.add_child(desc)

		var buy_button = Button.new()
		buy_button.text = "Comprar - " + str(offer["cost"]) + " Ouro"
		buy_button.pressed.connect(_on_buy_pressed.bind(i))

		row.add_child(info)
		row.add_child(buy_button)
		items_container.add_child(row)

func update_gold_display():
	var game_state = get_node("/root/GameState")
	gold_label.text = "Ouro: " + str(game_state.current_run.get("gold", 0))

func _on_buy_pressed(index: int):
	var offer = offers[index]
	var game_state = get_node("/root/GameState")
	var current_gold = game_state.current_run.get("gold", 0)
	if current_gold < offer["cost"]:
		status_label.text = "Ouro insuficiente para comprar " + offer["title"]
		return

	game_state.current_run["gold"] = current_gold - offer["cost"]
	if offer["type"] == "card":
		game_state.current_run["deck"].append(offer["card_data"])
		status_label.text = "Comprou carta: " + offer["title"]
	elif offer["type"] == "item":
		var items = game_state.current_run.get("items", [])
		items.append(offer["item_id"])
		game_state.current_run["items"] = items
		if offer["item_id"] == "Poção de Cura":
			var max_hp = game_state.current_run.get("max_hp", 50)
			var current_hp = game_state.current_run.get("hp", 50)
			game_state.current_run["hp"] = min(max_hp, current_hp + 15)
		elif offer["item_id"] == "Escudo Tático":
			game_state.current_run["defense_buff"] = game_state.current_run.get("defense_buff", 0) + 5
		status_label.text = "Comprou item: " + offer["title"]

	update_gold_display()

func _on_leave_pressed():
	get_tree().change_scene_to_file("res://scenes/map/map_scene_slay.tscn")
