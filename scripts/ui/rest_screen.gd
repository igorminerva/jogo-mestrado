extends Control
signal rest_completed(result: Dictionary)

@onready var hp_label: Label = $Panel/VBoxContainer/HPContainer/HPLabel
@onready var rest_button: Button = $Panel/VBoxContainer/ButtonsContainer/RestButton
@onready var skip_button: Button = $Panel/VBoxContainer/ButtonsContainer/SkipButton

const HEAL_AMOUNT: int = 30

func _ready():
	rest_button.pressed.connect(_on_rest_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	update_display()

func update_display():
	var game_state = get_node("/root/GameState")
	var current_hp = game_state.current_run.get("hp", 50)
	var max_hp = game_state.current_run.get("max_hp", 50)
	hp_label.text = "HP: %d/%d - Recupera %d HP" % [current_hp, max_hp, HEAL_AMOUNT]

func _on_rest_pressed():
	var game_state = get_node("/root/GameState")
	var current_hp = game_state.current_run.get("hp", 50)
	var max_hp = game_state.current_run.get("max_hp", 50)
	game_state.current_run["hp"] = min(max_hp, current_hp + HEAL_AMOUNT)
	emit_signal("rest_completed", {"healed": HEAL_AMOUNT})
	queue_free()

func _on_skip_pressed():
	emit_signal("rest_completed", {"healed": 0})
	queue_free()