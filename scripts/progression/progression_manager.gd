extends Node
class_name ProgressionManager

var unlocked_items: Array = []
var global_buffs: Dictionary = {
	"max_hp_bonus": 0,
	"starting_gold_bonus": 0,
	"card_draw_bonus": 0
}

func _ready():
	load_unlocked_items()

func load_unlocked_items():
	var game_state = get_node("/root/GameState")
	for item_id in game_state.unlocked_items:
		var item = load_unlockable_item(item_id)
		if item:
			unlocked_items.append(item)
			apply_global_buff(item)

func load_unlockable_item(item_id: String) -> UnlockableItem:
	match item_id:
		"Espada Afiada":
			return UnlockableItem.new("Espada Afiada", "attack", 5, "+5 de Ataque inicial")
		"Escudo Reforçado":
			return UnlockableItem.new("Escudo Reforçado", "defense", 10, "+10 de Defesa inicial")
		"Amuleto de Regeneração":
			return UnlockableItem.new("Amuleto de Regeneração", "regen", 2, "Regenera 2 HP por turno")
		_:
			return null

func apply_global_buff(item: UnlockableItem):
	match item.buff_type:
		"attack":
			global_buffs["starting_gold_bonus"] += item.buff_value
		"defense":
			global_buffs["max_hp_bonus"] += item.buff_value
		"regen":
			global_buffs["card_draw_bonus"] += 1

func unlock_random_item() -> String:
	var available_items = [
		"Espada Afiada", "Escudo Reforçado", "Amuleto de Regeneração",
		"Poção de Vida", "Cristal de Poder", "Manuscrito Antigo",
		"Bota Veloz", "Capa da Sorte", "Anel da Sabedoria"
	]
	var item_id = available_items[randi() % available_items.size()]
	get_node("/root/GameState").unlock_item(item_id)
	return item_id

func register_bestiary_entry(enemy_name: String):
	var game_state = get_node("/root/GameState")
	game_state.register_enemy_encounter(enemy_name, true)

class UnlockableItem:
	var id: String
	var buff_type: String
	var buff_value: int
	var description: String
	
	func _init(p_id: String, p_type: String, p_value: int, p_desc: String):
		id = p_id
		buff_type = p_type
		buff_value = p_value
		description = p_desc
