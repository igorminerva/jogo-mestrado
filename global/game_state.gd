extends Node

# Dados persistentes entre runs
var unlocked_items: Array[String] = []
var bestiary: Dictionary = {}  # { "enemy_name": { "defeats": 0, "kills": 0, "first_encounter": "" } }
var total_runs: int = 0
var total_victories: int = 0
var total_defeats: int = 0

# Dados da run atual
var 	current_run: Dictionary = {
	"deck": [],
	"hp": 50,
	"max_hp": 50,
	"gold": 0,
	"current_floor": 0,
	"enemies_defeated": [],
	"damage_taken": 0,
	"cards_played": 0,
	"turns_survived": 0,
	"card_usage": {},
	"damage_dealt": 0
}

# Sinal para salvar
signal data_saved
signal data_loaded

func _ready():
	load_game_data()

func save_game_data():
	var save_data = {
		"unlocked_items": unlocked_items,
		"bestiary": bestiary,
		"total_runs": total_runs,
		"total_victories": total_victories,
		"total_defeats": total_defeats
	}
	
	var file = FileAccess.open("user://player_data.save", FileAccess.WRITE)
	file.store_var(save_data)
	data_saved.emit()

func load_game_data():
	if not FileAccess.file_exists("user://player_data.save"):
		initialize_default_data()
		return
	
	var file = FileAccess.open("user://player_data.save", FileAccess.READ)
	var save_data = file.get_var()
	
	unlocked_items = save_data.get("unlocked_items", [])
	bestiary = save_data.get("bestiary", {})
	total_runs = save_data.get("total_runs", 0)
	total_victories = save_data.get("total_victories", 0)
	total_defeats = save_data.get("total_defeats", 0)
	
	data_loaded.emit()

func initialize_default_data():
	unlocked_items = ["Strike", "Defend"]
	bestiary = {}
	total_runs = 0
	total_victories = 0
	total_defeats = 0

func start_new_run():
	total_runs += 1
	var starting_deck = get_starting_deck()
	current_run = {
		"deck": starting_deck,
		"hp": 50,
		"max_hp": 50,
		"gold": 100,
		"current_floor": 0,
		"enemies_defeated": [],
		"damage_taken": 0,
		"cards_played": 0,
		"turns_survived": 0,
		"items": [],
		"events_visited": [],
		"card_usage": {},
		"damage_dealt": 0,
		"total_enemies_killed": 0
	}
	print("DEBUG start_new_run: initialized deck with ", starting_deck.size(), " cards")
	save_game_data()

func get_starting_deck() -> Array:
	var deck: Array = []
	var starting_cards = ["attack", "attack", "defesa", "defesa", "attack"]
	
	for card_name in starting_cards:
		var card = load("res://resources/cards/" + card_name + ".tres")
		if card:
			deck.append(card)
	
	return deck

func end_run(victory: bool):
	if victory:
		total_victories += 1
	else:
		total_defeats += 1
	save_game_data()

func unlock_item(item_id: String):
	if item_id not in unlocked_items:
		unlocked_items.append(item_id)
		save_game_data()

func register_enemy_encounter(enemy_name: String, defeated: bool):
	if not bestiary.has(enemy_name):
		bestiary[enemy_name] = {
			"defeats": 0,
			"kills": 0,
			"first_encounter": Time.get_datetime_string_from_system()
		}
	
	if defeated:
		bestiary[enemy_name]["defeats"] += 1
	else:
		bestiary[enemy_name]["kills"] += 1
	
	save_game_data()
