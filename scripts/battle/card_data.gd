extends Resource
class_name CardData

# Propriedades básicas
@export var card_name: String = "Nova Carta"
@export var card_type: String = "attack"  # attack, defend, skill, power
@export var card_description: String = ""
@export var card_value: int = 0
@export var card_cost: int = 1
@export var card_rarity: String = "common"  # common, rare, epic, legendary

# Coordenadas no atlas (x, y, width, height)
@export var icon_type: String = "attack"  # Qual ícone principal usar
@export var icon_effects: Array[String] = []  # Ícones de efeito adicionais (ex: ["fire", "poison"])
@export var show_energy_icon: bool = true
@export var energy_icon_size: String = "small"  # small, medium, large

# 🎨 NOVO: Cores personalizadas por tipo
@export var type_colors: Dictionary = {
	"value": Color(1, 0.8, 0.2),      # Cor do valor numérico
	"name": Color(1, 1, 1),            # Cor do nome
	"background_tint": Color(1, 1, 1)  # Tinta do fundo
}

@export var atlas_config: Dictionary = {
	# Frames por raridade
	"frames": {
		"common": Rect2(54, 33, 68, 109),
		"rare": Rect2(54, 290, 68, 109),
		"epic": Rect2(54, 162, 68, 109),
		"legendary": Rect2(166, 33, 68, 109)
	},
	# Ícones por tipo
	"icons": {
		"function_attack": Rect2(561, 433, 14, 14),
		"function_defend": Rect2(593, 449, 14, 14),
		"condiction_skill": Rect2(577, 465, 14, 14),
		"repetion_skill": Rect2(577, 465, 14, 14),
		"variavel_buff": Rect2(577, 465, 14, 14),
		"variavel_debuff": Rect2(577, 465, 14, 14),
		"heal": Rect2(593, 434, 14, 14),
	},
}


@export var special_effects: Dictionary = {
	"particle_effect": "",
	"sound_effect": "card_play"
}

# Função para obter o frame correto baseado na raridade
func get_frame_rect() -> Rect2:
	return atlas_config.frames.get(card_rarity, atlas_config.frames.common)

# Função para obter o ícone principal
func get_icon_rect() -> Rect2:
	return atlas_config.icons.get(icon_type, atlas_config.icons.attack)
