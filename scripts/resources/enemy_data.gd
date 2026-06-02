extends Resource
class_name EnemyData

# Informações básicas
@export var enemy_name: String = "Goblin"
@export var enemy_description: String = "Um goblin comum"
@export var enemy_icon: String = "goblin"  # Referência no sprite sheet

# Estatísticas
@export var max_hp: int = 30
@export var base_attack: int = 6
@export var base_defense: int = 2

# IA - Probabilidades (valores de 0 a 1)
@export var attack_chance: float = 0.6      # 60% chance de atacar
@export var defend_chance: float = 0.3      # 30% chance de defender
@export var buff_chance: float = 0.1        # 10% chance de buffar

# Efeitos de buff
@export var buff_attack_increase: int = 2   # +2 de ataque permanente
@export var buff_defense_increase: int = 1  # +1 de defesa permanente

# Recompensa
@export var exp_reward: int = 10
@export var gold_reward: int = 15

# Coordenadas no sprite sheet
@export var sprite_coords: Rect2 = Rect2(0, 0, 64, 64)
