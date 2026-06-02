extends Node2D

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var narration_label: Label = $NarrationLabel
@onready var skip_button: Button = $SkipButton
@onready var world_sprite: Sprite2D = $WorldSprite

var cutscene_complete: bool = false
var narration_index: int = 0

var narrations: Array[String] = [
	"O mundo está morrendo...",
	"As trevas consomem tudo...",
	"Restam apenas os Relicários...",
	"Heróis capazes de usar Relíquias ancestrais.",
	"Você é o último...",
	"Sua jornada começa agora!"
]

func _ready():
	skip_button.pressed.connect(_skip_cutscene)
	narration_label.modulate = Color(1, 1, 1, 0)
	show_narration()

func show_narration():
	if cutscene_complete:
		return

	if narration_index < narrations.size():
		narration_label.text = narrations[narration_index]
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(narration_label, "modulate", Color(1, 1, 1, 1), 0.5)
		
		await get_tree().create_timer(3.0).timeout
		
		var fade_tween = create_tween()
		fade_tween.tween_property(narration_label, "modulate", Color(1, 1, 1, 0), 0.5)
		
		narration_index += 1
		await get_tree().create_timer(0.5).timeout
		show_narration()
	else:
		finish_cutscene()

func _skip_cutscene():
	if cutscene_complete:
		return

	cutscene_complete = true
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color", Color(0, 0, 0, 1), 0.3)
	tween.tween_callback(func(): go_to_map())

func finish_cutscene():
	if cutscene_complete:
		return

	cutscene_complete = true
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color", Color(0, 0, 0, 1), 1.0)
	tween.tween_callback(func(): go_to_map())

func go_to_map():
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("start_new_run"):
		game_state.start_new_run()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
