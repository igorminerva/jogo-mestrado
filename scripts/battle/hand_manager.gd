extends Control
class_name HandManager

@onready var hand_container: Control = $HandContainer
@onready var deck_manager: DeckManager = get_parent().get_parent().get_node("DeckManager")

var cards_in_hand: Array[CardUI] = []
var card_spacing: float = 140.0
var hand_curve: float = 0.15

func _ready():
	deck_manager.hand_updated.connect(_update_hand_layout)
	deck_manager.card_drawn.connect(_add_card_to_hand)

	# Ensure the hand area has a usable size so cards are visible and layout works
	# If the scene set a custom_minimum_size in the editor, respect it; otherwise fall back
	if custom_minimum_size == Vector2():
		custom_minimum_size = Vector2(1152, 220)
	hand_container.custom_minimum_size = Vector2(1152, 220)

func _add_card_to_hand(card_ui: CardUI):
	await get_tree().process_frame
	if is_instance_valid(card_ui) and card_ui.get_parent() == null:
		hand_container.add_child(card_ui)
	cards_in_hand = deck_manager.hand
	_update_hand_layout()

func _update_hand_layout(hand_size: int = -1):
	hand_size = cards_in_hand.size()
	if hand_size == 0:
		return

	var center_x = hand_container.size.x / 2

	for i in range(hand_size):
		var card = cards_in_hand[i]
		if not is_instance_valid(card):
			continue
		var offset = (i - (hand_size - 1) / 2.0) * card_spacing
		var target_x = center_x + offset
		var target_y = hand_container.size.y - 80
		var angle = (i - (hand_size - 1) / 2.0) * hand_curve

		var tween = card.create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "position", Vector2(target_x, target_y), 0.2)
		tween.tween_property(card, "rotation", angle, 0.2)

		card.z_index = int(hand_size - abs(i - hand_size / 2))

func clear_hand():
	for card in cards_in_hand:
		card.queue_free()
	cards_in_hand.clear()
