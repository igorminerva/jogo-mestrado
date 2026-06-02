extends Button
class_name RewardCard

@onready var card_name_label: Label = $CardName
@onready var card_value_label: Label = $CardValue
@onready var card_icon: TextureRect = $CardTypeIcon

var card_data_resource: CardData

func setup(card_data: CardData) -> void:
	card_data_resource = card_data
	if not card_name_label:
		card_name_label = get_node("CardName") as Label
	if not card_value_label:
		card_value_label = get_node("CardValue") as Label
	if not card_icon:
		card_icon = get_node("CardTypeIcon") as TextureRect
	card_name_label.text = card_data.card_name
	card_value_label.text = str(card_data.card_value)
	card_icon.texture = null
