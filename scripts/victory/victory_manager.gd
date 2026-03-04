extends Control

@onready var fanfarra_player: AudioStreamPlayer = $FanfarraPlayer
@onready var cards_container: GridContainer = $CardsContainer
@onready var card_scene = preload("res://scenes/battle/card.tscn")

var available_cards: Array = []
var selected_card_index: int = -1

func _ready():
	fanfarra_player.play()
	setup_reward_cards()

func setup_reward_cards():
	# Gerar 3 cartas aleatórias
	for i in range(3):
		var card = card_scene.instantiate()
		cards_container.add_child(card)
		
		# Configurar carta
		card.card_data = generate_random_card()
		
		# Chance de raridade (30%)
		if randf() < 0.3:
			card.set_rare(true)
		
		card.connect("pressed", _on_card_selected.bind(i))

func generate_random_card() -> Dictionary:
	var card_types = ["attack", "defense", "special"]
	var card_powers = [10, 15, 20, 25, 30]
	
	return {
		"type": card_types[randi() % card_types.size()],
		"power": card_powers[randi() % card_powers.size()],
		"cost": randi() % 3 + 1
	}

func _on_card_selected(index: int):
	if selected_card_index != -1:
		# Desselecionar carta anterior
		cards_container.get_child(selected_card_index).deselect()
	
	selected_card_index = index
	var selected_card = cards_container.get_child(index)
	selected_card.select()
	
	# Adicionar carta ao deck do jogador
	add_card_to_deck(selected_card.card_data)
	
	# Retornar ao mapa
	await get_tree().create_timer(1.0).timeout
	return_to_map()

func add_card_to_deck(card_data: Dictionary):
	var game_state = get_node("/root/GameState")
	game_state.player_deck.append(card_data)

func return_to_map():
	var map_scene = preload("res://scenes/map/map_scene.tscn").instantiate()
	get_tree().root.add_child(map_scene)
	queue_free()
