extends Button

# Sinais
signal card_played(card_data)
signal card_selected(card_data)
signal card_deselected(card_data)

# Dados da carta
@export var card_data: CardData :
	set(value):
		card_data = value
		if is_node_ready():
			update_from_data()

# Referências aos nós
@onready var card_background: TextureRect = $CardBackground
@onready var card_art: TextureRect = $CardArt  # (se tiver arte no futuro)
@onready var card_type_icon: TextureRect = $CardTypeIcon
@onready var card_name_label: Label = $CardName
@onready var card_description: Label = $CardDescription
@onready var card_value_label: Label = $CardValue
@onready var card_cost_panel: Panel = $CardCost
@onready var energy_icon: TextureRect = $CardCost/EnergyIcon
@onready var cost_label: Label = $CardCost/CostLabel
@onready var effect_icons_container: HBoxContainer = $EffectIconsContainer
@onready var rare_glow: Sprite2D = $RareGlow
@onready var hover_animation: AnimationPlayer = $HoverAnimation
@onready var play_animation: AnimationPlayer = $PlayAnimation
@onready var audio: Node = $Audio

# Atlas principal
@onready var card_atlas = preload("res://assets/cards/sprite_sheet.png")

# Cache de AtlasTextures
var atlas_cache: Dictionary = {}

func _ready():
	if card_data:
		update_from_data()
	connect_signals()

func connect_signals():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)

func update_from_data():
	if not card_data:
		return
	
	# 1️⃣ ATUALIZAR FRAME (baseado na raridade)
	var frame_rect = card_data.get_frame_rect()
	card_background.texture = get_atlas_texture(frame_rect)
	
	# 2️⃣ ATUALIZAR ÍCONE PRINCIPAL (baseado no tipo)
	var icon_rect = card_data.get_icon_rect()
	card_type_icon.texture = get_atlas_texture(icon_rect)
	
	# 4️⃣ ATUALIZAR ÍCONE DE ENERGIA
	if card_data.show_energy_icon:
		var energy_rect = card_data.get_energy_icon_rect()
		energy_icon.texture = get_atlas_texture(energy_rect)
		energy_icon.show()
	else:
		energy_icon.hide()
	
	# 6️⃣ ATUALIZAR TEXTOS
	card_name_label.text = card_data.card_name
	card_name_label.label_settings.font_color = card_data.type_colors.name
	
	card_description.text = card_data.card_description.replace("{value}", str(card_data.card_value))
	
	card_value_label.text = str(card_data.card_value)
	card_value_label.label_settings.font_color = card_data.type_colors.value
	
	cost_label.text = str(card_data.card_cost)
	
	# 7️⃣ APLICAR TINT DE FUNDO
	card_background.modulate = card_data.type_colors.background_tint

# Função que cria e cacheia AtlasTextures
func get_atlas_texture(region: Rect2) -> AtlasTexture:
	var cache_key = str(region)
	
	if not atlas_cache.has(cache_key):
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = card_atlas
		atlas_tex.region = region
		atlas_cache[cache_key] = atlas_tex
	
	return atlas_cache[cache_key]


func _on_mouse_entered():
	if not disabled:
		hover_animation.play("hover")
		audio.get_node("HoverSound").play()
		z_index = 5

func _on_mouse_exited():
	if not disabled:
		hover_animation.play("unhover")
		z_index = 0

func _on_pressed():
	if not disabled:
		audio.get_node("ClickSound").play()
		play_animation.play("play")
		card_played.emit(card_data)

func _on_toggled(button_pressed: bool):
	if button_pressed:
		card_selected.emit(card_data)
		scale = Vector2(1.15, 1.15)
		z_index = 10
	else:
		card_deselected.emit(card_data)
		scale = Vector2(1, 1)
		z_index = 0
