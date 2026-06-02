extends Button
class_name CardUI

# Sinais
signal card_played(card_ui)
signal card_selected(card_ui)
signal card_hovered(card_ui)

# Dados da carta
var _card_data: CardData
var card_data: CardData:
	get:
		return _card_data
	set(value):
		_card_data = value
		if is_node_ready():
			update_display()

# Nós
@onready var card_name_label: Label = $CardName
@onready var card_desc_label: Label = $CardDescription
@onready var card_value_label: Label = $CardValue
@onready var cost_label: Label = $CardCost/CostLabel
@onready var card_type_icon: TextureRect = $CardTypeIcon
@onready var card_background: TextureRect = $CardBackground

# Estado
var is_playable: bool = true
var is_selected: bool = false

func _ready():
	update_display()
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func update_display():
	if not card_data:
		return
	
	card_name_label.text = card_data.card_name
	card_desc_label.text = card_data.card_description.replace("{value}", str(card_data.card_value))
	card_value_label.text = str(card_data.card_value)
	cost_label.text = str(card_data.card_cost)
	
	# Atualizar cor baseada no tipo
	match card_data.card_type:
		"attack", "function_attack":
			card_value_label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
		"defend", "defesa", "function_defend":
			card_value_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1))
		"skill", "heal":
			card_value_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		_:
			card_value_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))

func set_playable(playable: bool):
	is_playable = playable
	disabled = not playable
	modulate = Color(1, 1, 1, 0.7 if not playable else 1)

func _on_pressed():
	if is_playable:
		card_played.emit(self)

func _on_mouse_entered():
	if is_playable:
		scale = Vector2(1.1, 1.1)
		z_index = 10
		card_hovered.emit(self)

func _on_mouse_exited():
	scale = Vector2(1, 1)
	z_index = 0

func select_card():
	is_selected = true
	modulate = Color(1, 1, 0.8)

func deselect_card():
	is_selected = false
	modulate = Color(1, 1, 1)

func play_card_animation():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(0, 0), 0.2)
	tween.tween_callback(queue_free)
