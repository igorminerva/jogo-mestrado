extends Button
class_name RoomButton

@onready var icon_texture: TextureRect = $IconTexture
@onready var type_label: Label = $TypeLabel
@onready var selection_outline: Panel = $SelectionOutline
@onready var background: ColorRect = $Background

var room_data: RoomData
var map_controller: Node

func setup(room: RoomData, controller: Node) -> void:
	room_data = room
	map_controller = controller
	# Ensure child nodes exist (flexible to scene changes)
	if not icon_texture or icon_texture == null:
		icon_texture = get_node_or_null("IconTexture")
		if not icon_texture:
			icon_texture = get_node_or_null("Icon")
	if not type_label or type_label == null:
		type_label = get_node_or_null("TypeLabel")
	if not selection_outline or selection_outline == null:
		selection_outline = get_node_or_null("SelectionOutline")
	if not background or background == null:
		background = get_node_or_null("Background")

	# visuals
	if icon_texture and room.get_icon_path() != "" and ResourceLoader.exists(room.get_icon_path()):
		var tex = load(room.get_icon_path())
		if tex:
			icon_texture.texture = tex
		else:
			icon_texture.texture = null
	elif icon_texture:
		icon_texture.texture = null

	if type_label:
		type_label.text = room.get_room_type_string()
	update_visual_state()
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func update_visual_state() -> void:
	if not room_data:
		return
	if room_data.is_current:
		background.color = Color(0.3, 0.5, 0.8, 0.3)
		selection_outline.visible = true
	elif room_data.is_visited:
		background.color = Color(0.3, 0.3, 0.3, 0.2)
		selection_outline.visible = false
	elif room_data.is_reachable:
		background.color = Color(0.1, 0.8, 0.1, 0.2)
		selection_outline.visible = false
	else:
		background.color = Color(0.2, 0.2, 0.2, 0.3)
		selection_outline.visible = false
		disabled = not room_data.is_reachable

func _on_pressed() -> void:
	if room_data and room_data.is_reachable and not room_data.is_visited:
		if map_controller and map_controller.has_method("on_room_selected"):
			map_controller.on_room_selected(room_data.id)
