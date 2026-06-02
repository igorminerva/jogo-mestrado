extends Control
signal event_completed(result: Dictionary)

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var description_label: Label = $Panel/VBoxContainer/Description
@onready var choice_a_button: Button = $Panel/VBoxContainer/Choices/ChoiceA
@onready var choice_b_button: Button = $Panel/VBoxContainer/Choices/ChoiceB
@onready var result_label: Label = $Panel/VBoxContainer/ResultLabel
@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton

var event_data: Dictionary = {}

func _ready():
	choice_a_button.pressed.connect(_on_choice_a)
	choice_b_button.pressed.connect(_on_choice_b)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.disabled = true
	create_random_event()

func create_random_event():
	var events = [
		{
			"title": "Fonte Misteriosa",
			"description": "Uma fonte cintilante pulsa entre ruínas antigas. Você sente algo mágico no ar.",
			"choices": [
				{"label": "Beber a água", "result": {"type": "heal", "value": 15, "text": "Você recupera 15 HP e sente uma energia leve."}},
				{"label": "Ignorar e seguir", "result": {"type": "gold", "value": 10, "text": "Você sai da fonte e encontra moedas antigas pelo caminho."}}
			]
		},
		{
			"title": "Viajante Perdido",
			"description": "Um andarilho machucado pede ajuda e fala sobre um caminho secreto.",
			"choices": [
				{"label": "Ajudar", "result": {"type": "card", "rarity": "common", "text": "Ele te dá uma carta adicional como agradecimento."}},
				{"label": "Seguir sozinho", "result": {"type": "gold", "value": 20, "text": "Você encontra um pequeno tesouro escondido."}}
			]
		},
		{
			"title": "Armadilha Antiga",
			"description": "Um mecanismo estala sob seus pés. Há algo valioso à frente, mas o risco é real.",
			"choices": [
				{"label": "Desarmar", "result": {"type": "card", "rarity": "rare", "text": "Você desarma a armadilha e encontra uma carta rara."}},
				{"label": "Voltar atrás", "result": {"type": "hp", "value": -10, "text": "A armadilha dispara e você perde 10 HP."}}
			]
		}
	]

	event_data = events[randi() % events.size()]
	title_label.text = event_data["title"]
	description_label.text = event_data["description"]
	choice_a_button.text = event_data["choices"][0]["label"]
	choice_b_button.text = event_data["choices"][1]["label"]

func _apply_choice(choice: Dictionary):
	var result_data = choice["result"]	
	var game_state = get_node("/root/GameState")
	match result_data["type"]:
		"heal":
			var max_hp = game_state.current_run.get("max_hp", 50)
			game_state.current_run["hp"] = min(max_hp, game_state.current_run.get("hp", 50) + result_data["value"])
		"gold":
			game_state.current_run["gold"] = game_state.current_run.get("gold", 0) + result_data["value"]
		"hp":
			game_state.current_run["hp"] = max(0, game_state.current_run.get("hp", 50) + result_data["value"])
		"card":
			var card_manager = preload("res://scripts/battle/card_manager.gd").new()
			card_manager.load_all_cards()
			var rarity = result_data.get("rarity", "common")
			var card_data = card_manager.get_random_card(rarity)
			game_state.current_run["deck"].append(card_data)

	result_label.text = result_data["text"]
	choice_a_button.disabled = true
	choice_b_button.disabled = true
	continue_button.disabled = false

func _on_choice_a():
	_apply_choice(event_data["choices"][0])

func _on_choice_b():
	_apply_choice(event_data["choices"][1])

func _on_continue_pressed():
	emit_signal("event_completed", {"success": true})
	queue_free()
