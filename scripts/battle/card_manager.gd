extends Node
class_name CardManager

# Pool de cartas disponíveis por raridade
var common_cards: Array[CardData] = []
var rare_cards: Array[CardData] = []
var epic_cards: Array[CardData] = []
var legendary_cards: Array[CardData] = []

func _ready():
	load_all_cards()

func load_all_cards():
	# Carregar todas as cartas da pasta resources/cards/
	var card_files = DirAccess.get_files_at("res://resources/cards/")
	
	for file in card_files:
		if file.ends_with(".tres"):
			var card = load("res://resources/cards/" + file)
			if card is CardData:
				add_card_to_pool(card)

func add_card_to_pool(card: CardData):
	match card.card_rarity:
		"common":
			common_cards.append(card)
		"rare":
			rare_cards.append(card)
		"epic":
			epic_cards.append(card)
		"legendary":
			legendary_cards.append(card)

func get_random_card(rarity: String = "common") -> CardData:
	match rarity:
		"common":
			return common_cards[randi() % common_cards.size()]
		"rare":
			return rare_cards[randi() % rare_cards.size()]
		"epic":
			return epic_cards[randi() % epic_cards.size()]
		"legendary":
			return legendary_cards[randi() % legendary_cards.size()]
		_:
			return common_cards[randi() % common_cards.size()]

func get_random_cards(count: int, allow_rare: bool = true) -> Array[CardData]:
	var result: Array[CardData] = []
	
	for i in range(count):
		var rarity = "common"
		
		# Chance de carta rara
		if allow_rare and randf() < 0.3:  # 30% de chance
			var roll = randf()
			if roll < 0.7:  # 70% das raras são raras
				rarity = "rare"
			elif roll < 0.9:  # 20% são épicas
				rarity = "epic"
			else:  # 10% são lendárias
				rarity = "legendary"
		
		result.append(get_random_card(rarity))
	
	return result

# Função para criar uma carta visualmente
func create_card_ui(card_data: CardData) -> Button:
	var card_scene = preload("res://scenes/battle/card.tscn")
	var card_instance = card_scene.instantiate()
	card_instance.card_data_resource = card_data
	return card_instance
