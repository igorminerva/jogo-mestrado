extends Control
class_name RewardSelector
signal reward_chosen(card_data)

func select_reward(card_data: CardData):
	emit_signal("reward_chosen", card_data)
	queue_free()
