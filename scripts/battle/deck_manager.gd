extends Node
class_name DeckManager

signal hand_updated(hand_size)
signal deck_updated(deck_size)
signal card_drawn(card_ui)
signal card_played(card_ui)

var draw_pile: Array[CardData] = []
var hand: Array[CardUI] = []
var discard_pile: Array[CardData] = []
var exhausted_pile: Array[CardData] = []

@export var hand_size_limit: int = 5
@export var starting_hand_size: int = 3
@export var cards_per_turn: int = 1
@export var card_scene: PackedScene = preload("res://scenes/battle/card.tscn")

func _ready():
    pass

func initialize_deck(deck_cards: Array[CardData]):
    print("DEBUG initialize_deck: received ", deck_cards.size(), " cards")
    draw_pile = deck_cards.duplicate()
    print("DEBUG initialize_deck: draw_pile now has ", draw_pile.size(), " cards")
    shuffle_deck()
    deck_updated.emit(draw_pile.size())

func shuffle_deck():
    draw_pile.shuffle()

func draw_card() -> CardUI:
    if draw_pile.is_empty():
        reshuffle_from_discard()
        if draw_pile.is_empty():
            return null

    if hand.size() >= hand_size_limit:
        return null

    var card_data = draw_pile.pop_back()
    var card_ui = create_card_ui(card_data)
    hand.append(card_ui)
    card_drawn.emit(card_ui)
    hand_updated.emit(hand.size())
    deck_updated.emit(draw_pile.size())
    return card_ui

func draw_starting_hand():
    for i in range(starting_hand_size):
        draw_card()

func draw_end_of_turn():
    for i in range(cards_per_turn):
        draw_card()

func create_card_ui(card_data: CardData) -> CardUI:
    var card = card_scene.instantiate() as CardUI
    card.card_data = card_data
    card.card_played.connect(func(card_ui):
        emit_signal("card_played", card_ui)
    )
    return card

func discard_card(card_ui: CardUI):
    for i in range(hand.size() - 1, -1, -1):
        if hand[i] == card_ui:
            hand.remove_at(i)
            break

    if card_ui.card_data:
        discard_pile.append(card_ui.card_data)

    hand_updated.emit(hand.size())
    deck_updated.emit(draw_pile.size())

func reshuffle_from_discard():
    if discard_pile.is_empty():
        return

    draw_pile = discard_pile.duplicate()
    discard_pile.clear()
    shuffle_deck()
    deck_updated.emit(draw_pile.size())

func discard_hand():
    for card in hand:
        if card.card_data:
            discard_pile.append(card.card_data)
        card.queue_free()
    hand.clear()
    hand_updated.emit(0)

func get_hand_size() -> int:
    return hand.size()

func get_deck_size() -> int:
    return draw_pile.size()
