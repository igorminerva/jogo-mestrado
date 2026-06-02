extends Control
class_name BestiaryScreen

@onready var enemy_list: ItemList = $Panel/EnemyList
@onready var detail_panel: Panel = $Panel/DetailPanel
@onready var enemy_name_label: Label = $Panel/DetailPanel/EnemyName
@onready var enemy_sprite: TextureRect = $Panel/DetailPanel/EnemySprite
@onready var stats_label: Label = $Panel/DetailPanel/StatsLabel
@onready var description_label: Label = $Panel/DetailPanel/DescriptionLabel
@onready var close_button: Button = $Panel/CloseButton

var bestiary_data: Dictionary = {}

func _ready():
	close_button.pressed.connect(queue_free)
	load_bestiary_data()
	populate_enemy_list()
	enemy_list.item_selected.connect(_on_enemy_selected)

func load_bestiary_data():
	var game_state = get_node("/root/GameState")
	bestiary_data = game_state.bestiary

func populate_enemy_list():
	for enemy_name in bestiary_data.keys():
		enemy_list.add_item(enemy_name)

func _on_enemy_selected(index: int):
	var enemy_name = enemy_list.get_item_text(index)
	var data = bestiary_data.get(enemy_name, {})
	
	enemy_name_label.text = enemy_name
	stats_label.text = "Encontros: " + str(data.get("defeats", 0)) + " | Derrotas: " + str(data.get("kills", 0))
	
	var enemy_resource = load("res://resources/enemies/enemy_" + enemy_name.to_lower() + ".tres")
	if enemy_resource:
		description_label.text = enemy_resource.enemy_description
		if ResourceLoader.exists("res://assets/shaders/placeholder.png"):
			enemy_sprite.texture = load("res://assets/shaders/placeholder.png")
		else:
			enemy_sprite.texture = null
	else:
		description_label.text = "Informações do inimigo indisponíveis."

	detail_panel.visible = true
