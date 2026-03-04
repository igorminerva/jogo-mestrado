extends CanvasLayer

@onready var player_hp_bar: ProgressBar = $TopLeft/PlayerInfo/HPBar
@onready var player_hp_label: Label = $TopLeft/PlayerInfo/HPLabel
@onready var attack_value: Label = $TopLeft/PlayerInfo/Stats/AttackValue
@onready var defense_value: Label = $TopLeft/PlayerInfo/Stats/DefenseValue
@onready var regen_value: Label = $TopLeft/PlayerInfo/Stats/RegenValue
@onready var power_value: Label = $TopLeft/PlayerInfo/Stats/PowerValue

@onready var turn_counter: Label = $TopRight/TurnCounter
@onready var hand_container: Control = $Bottom/HandContainer
@onready var menu_button: Button = $BottomRight/MenuButton

@onready var card_scene = preload("res://scenes/battle/card.tscn")

var player_stats: Dictionary = {
	"hp": 100,
	"max_hp": 100,
	"attack": 15,
	"defense": 10,
	"regen": 5,
	"power": 20
}

var current_turn: int = 1

func _ready():
	update_player_stats()
	setup_hand()

func update_player_stats():
	player_hp_bar.max_value = player_stats["max_hp"]
	player_hp_bar.value = player_stats["hp"]
	player_hp_label.text = str(player_stats["hp"]) + "/" + str(player_stats["max_hp"])
	
	attack_value.text = str(player_stats["attack"])
	defense_value.text = str(player_stats["defense"])
	regen_value.text = str(player_stats["regen"])
	power_value.text = str(player_stats["power"])
	
	turn_counter.text = "Turno " + str(current_turn)

func setup_hand():
	# Criar 5 cartas em leque
	var cards = 5
	for i in range(cards):
		var card = card_scene.instantiate()
		hand_container.add_child(card)
		
		# Posicionar em leque
		var angle = (i - (cards - 1) / 2.0) * 0.15
		card.rotation = angle
		card.position = Vector2(i * 120 - 240, 0)

func update_enemy_intentions(enemies: Array):
	for enemy in enemies:
		if enemy.has_method("get_intention"):
			var intention = enemy.get_intention()
			var icon = enemy.get_node("IntentionIcon")
			
			match intention:
				"attack":
					icon.texture = preload("res://assets/icons/sword.png")
				"defend":
					icon.texture = preload("res://assets/icons/shield.png")
				"special":
					icon.texture = preload("res://assets/icons/star.png")
