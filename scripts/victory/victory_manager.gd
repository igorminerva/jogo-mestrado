extends Control

@onready var cards_container: GridContainer = $CardsContainer
@onready var fanfarra_player: AudioStreamPlayer = $FanfarraPlayer
@onready var card_manager: CardManager = $CardManager

func _ready():
	fanfarra_player.play()
	show_reward_cards()

func show_reward_cards():
	# Pegar 3 cartas aleatórias (com chance de raras)
	var reward_cards = card_manager.get_random_cards(3, true)
	
	# Limpar container
	for child in cards_container.get_children():
		child.queue_free()
	
	# Criar UI para cada carta
	for i in range(reward_cards.size()):
		var card = card_manager.create_card_ui(reward_cards[i])
		cards_container.add_child(card)
		
		# Conectar sinal de seleção
		card.card_selected.connect(_on_reward_card_selected.bind(i))
		
		# Se for rara, adicionar efeito especial
		if reward_cards[i].card_rarity != "common":
			card.set_rare(true)
			
			# Animação de entrada para cartas raras
			var tween = create_tween()
			tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(card, "scale", Vector2(1, 1), 0.2)

func _on_reward_card_selected(card_data: CardData, index: int):
	# Adicionar carta ao deck do jogador
	add_card_to_deck(card_data)
	
	# Feedback visual
	show_card_selected_feedback(index)
	
	# Aguardar e voltar ao mapa
	await get_tree().create_timer(1.0).timeout
	return_to_map()

func add_card_to_deck(card_data: CardData):
	var game_state = get_node("/root/GameState")
	game_state.player_deck.append(card_data)

func show_card_selected_feedback(index: int):
	# Desabilitar outras cartas
	for i in cards_container.get_children():
		i.disabled = true
	
	# Animar carta selecionada
	var selected_card = cards_container.get_child(index)
	var tween = create_tween()
	tween.tween_property(selected_card, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(selected_card, "scale", Vector2(0, 0), 0.3).set_delay(0.3)
