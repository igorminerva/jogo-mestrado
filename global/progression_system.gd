extends Node

var bestiary: Dictionary = {}
var unlocked_items: Array = []

const ITEMS_POOL = [
	"Espada Afiada +5 Ataque",
	"Escudo Reforçado +8 Defesa",
	"Amuleto de Regeneração",
	"Cristal de Poder +15 Poder",
    "Poção de Vida +30 HP Máximo"
]

func unlock_random_item() -> String:
	var available_items = ITEMS_POOL.filter(func(item): return item not in unlocked_items)
	
	if available_items.size() > 0:
		var new_item = available_items[randi() % available_items.size()]
		unlocked_items.append(new_item)
		return new_item
	
	return "Fragmento de Poder" # Item padrão

func register_bestiary_entry(enemy_name: String):
	if bestiary.has(enemy_name):
		bestiary[enemy_name]["defeats"] += 1
	else:
		bestiary[enemy_name] = {
			"defeats": 1,
			"info": get_enemy_info(enemy_name)
		}

func get_enemy_info(enemy_name: String) -> Dictionary:
	var enemy_data = {
		"Goblin": {
			"hp": 50,
			"attack": 8,
			"defense": 3,
			"weakness": "Poder",
			"loot": "Moedas"
		},
		"Orc": {
			"hp": 80,
			"attack": 12,
			"defense": 5,
			"weakness": "Ataques Rápidos",
			"loot": "Pele Grossa"
		}
	}
	
	return enemy_data.get(enemy_name, {})
