extends Area2D

@export var enemy_name: String = "Goblin"
@export var max_hp: int = 50
@export var current_hp: int = 50
@export var attack_damage: int = 8
@export var defense_value: int = 3

@onready var hp_bar: TextureProgressBar = $HPBar
@onready var intention_icon: Sprite2D = $IntentionIcon
@onready var hp_label: Label = $HPLabel

var current_intention: String = "attack"
var is_defending: bool = false

func _ready():
	update_hp_bar()
	randomize_intention()

func update_hp_bar():
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = str(current_hp) + "/" + str(max_hp)
	
	# Mudar cor da barra baseado na vida
	if current_hp < max_hp * 0.3:
		hp_bar.modulate = Color.RED
	elif current_hp < max_hp * 0.6:
		hp_bar.modulate = Color.YELLOW
	else:
		hp_bar.modulate = Color.GREEN

func randomize_intention():
	var intentions = ["attack", "defend", "special"]
	current_intention = intentions[randi() % intentions.size()]

func get_intention() -> String:
	return current_intention

func take_damage(damage: int) -> bool:
	var actual_damage = damage
	if is_defending:
		actual_damage = max(1, damage - defense_value)
	
	current_hp = max(0, current_hp - actual_damage)
	update_hp_bar()
	
	return current_hp <= 0

func die():
	queue_free()
