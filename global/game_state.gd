extends Node

var player_stats: Dictionary = {
	"hp": 100,
	"max_hp": 100,
	"attack": 15,
	"defense": 10,
	"regen": 5,
	"power": 20
}

var player_deck: Array = []
var bestiary: Dictionary = {}
var unlocked_items: Array = []

func _ready():
	# Inicializar deck padrão
	if player_deck.is_empty():
		initialize_default_deck()

func initialize_default_deck():
	player_deck = [
		{"type": "attack", "power": 15, "cost": 1},
		{"type": "attack", "power": 20, "cost": 2},
		{"type": "defense", "power": 10, "cost": 1},
		{"type": "defense", "power": 15, "cost": 2},
		{"type": "special", "power": 25, "cost": 3}
	]

func reset_for_new_run():
	player_stats = {
		"hp": 100,
		"max_hp": 100,
		"attack": 15,
		"defense": 10,
		"regen": 5,
		"power": 20
	}
	# Itens desbloqueados permanecem
