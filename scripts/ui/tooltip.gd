extends Panel

@onready var tooltip_label: Label = $TooltipLabel

func show_tooltip(text: String, position: Vector2):
	tooltip_label.text = text
	visible = true
	global_position = position

func hide_tooltip():
	visible = false
