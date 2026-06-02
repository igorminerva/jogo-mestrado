extends Button
class_name MapNode

signal node_selected(node_data)

var node_data: Dictionary = {}  # Changed from Variant to Dictionary

@onready var glow: Sprite2D = $Glow
@onready var tooltip: Panel = $Tooltip
@onready var tooltip_label: Label = $Tooltip/TooltipLabel
@onready var icon_rect: TextureRect = $Icon

func setup(data: Dictionary) -> void:
	# ✅ CRITICAL: Store the data first
	node_data = data
	
	# Disconnect old signals to avoid duplicates
	if mouse_entered.is_connected(_show_tooltip):
		mouse_entered.disconnect(_show_tooltip)
	if mouse_exited.is_connected(_hide_tooltip):
		mouse_exited.disconnect(_hide_tooltip)
	if pressed.is_connected(_on_pressed):
		pressed.disconnect(_on_pressed)
	
	# Connect fresh signals
	mouse_entered.connect(_show_tooltip)
	mouse_exited.connect(_hide_tooltip)
	pressed.connect(_on_pressed)
	
	# Update appearance AFTER data is set
	update_appearance()

func update_appearance() -> void:
	if not icon_rect:
		return
	
	var node_type = node_data.get("type", "battle")
	var is_accessible = node_data.get("is_accessible", false)
	var is_completed = node_data.get("is_completed", false)
	
	# Set color based on type (your placeholder system)
	match node_type:
		"battle":
			modulate = Color.YELLOW
			icon_rect.texture = preload("res://assets/icons/sword_icon.png")
		"elite":
			modulate = Color.ORANGE
			icon_rect.texture = preload("res://assets/icons/skull_icon.png")
		"shop":
			modulate = Color.GREEN
			icon_rect.texture = preload("res://assets/icons/shop_icon.png")
		"event":
			modulate = Color.CYAN
			icon_rect.texture = preload("res://assets/icons/question_icon.png")
		"boss":
			modulate = Color.RED
			icon_rect.texture = preload("res://assets/icons/boss_icon.png")
		"treasure":
			modulate = Color.PURPLE
			icon_rect.texture = preload("res://assets/icons/shop_icon.png")
		"rest":
			modulate = Color.BLUE
			icon_rect.texture = preload("res://assets/icons/question_icon.png")
		_:
			modulate = Color.GRAY
	
	# ✅ This is what makes buttons clickable
	disabled = not is_accessible
	
	if is_completed:
		modulate = modulate.darkened(0.5)
	
	# Start visual effects if accessible
	if is_accessible and not is_completed:
		if node_type == "elite":
			start_elite_glow()
		elif node_type == "event":
			start_event_pulse()

func start_elite_glow():
	if glow:
		glow.visible = true
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(glow, "modulate", Color(1, 0.2, 0.2, 0.8), 0.5)
		tween.tween_property(glow, "modulate", Color(1, 0.5, 0.5, 0.3), 0.5)

func start_event_pulse():
	if icon_rect:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(icon_rect, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(icon_rect, "scale", Vector2(1, 1), 0.5)

func _show_tooltip():
	if not node_data.get("is_accessible", false):
		return
	if tooltip and tooltip.has_method("show_tooltip"):
		var node_name = node_data.get("name", "")
		var node_type = node_data.get("type", "")
		var display_text = node_name if not node_name.is_empty() else node_type.capitalize()
		tooltip.show_tooltip(display_text, get_global_mouse_position() + Vector2(20, -40))

func _hide_tooltip():
	if tooltip and tooltip.has_method("hide_tooltip"):
		tooltip.hide_tooltip()

func _on_pressed():
	# Double-check accessibility (disabled button shouldn't send signal, but just in case)
	if node_data.get("is_accessible", false) and not node_data.get("is_completed", false):
		emit_signal("node_selected", node_data)
