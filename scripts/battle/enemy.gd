extends Area2D
class_name Enemy
signal enemy_died(enemy)
signal enemy_action_executed(action_type, value)

# Dados
@export var enemy_data: EnemyData :
	set(value):
		enemy_data = value
		if is_node_ready():
			update_stats()

# Estatísticas atuais (podem ser buffadas)
var current_hp: int
var current_attack: int
var current_defense: int

# Estado do turno
var current_intention: String = ""   # "attack", "defend", "buff"
var intention_value: int = 0
var is_defending: bool = false
var defense_block: int = 0

# Nós
@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var intention_icon: Sprite2D = $IntentionIcon
@onready var intention_label: Label = $IntentionLabel
@onready var defense_icon: Sprite2D = $DefenseIcon
@onready var buff_icon: Sprite2D = $BuffIcon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer

func _ready():
	update_stats()
	setup_signals()

func setup_signals():
	add_to_group("enemies")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func update_stats():
	if not enemy_data:
		return
	
	current_hp = enemy_data.max_hp
	current_attack = enemy_data.base_attack
	current_defense = enemy_data.base_defense
	
	update_hp_display()
	update_sprite()

func update_hp_display():
	if not is_node_ready():
		return
	
	# Ensure HP bar is properly sized
	hp_bar.custom_minimum_size = Vector2(80, 10)
	hp_bar.min_value = 0
	hp_bar.max_value = max(enemy_data.max_hp, 1)
	hp_bar.value = clamp(float(current_hp), 0.0, float(hp_bar.max_value))
	hp_label.text = str(current_hp) + "/" + str(enemy_data.max_hp)
	
	# Mudar cor da barra baseado na vida
	var health_percentage = float(hp_bar.value) / float(hp_bar.max_value)
	var bar_color = Color.GREEN
	
	if health_percentage < 0.3:
		bar_color = Color.RED
	elif health_percentage < 0.6:
		bar_color = Color.YELLOW
	
	# Apply color - using self_modulate for the bar
	hp_bar.self_modulate = bar_color
func update_sprite():
	# Aqui você usaria o sprite sheet
	# Por enquanto, usa um placeholder
	pass

# ============ INTENÇÕES (Mostradas no turno do jogador) ============

func choose_intention():
	"""Escolhe o que o inimigo vai fazer no próximo turno"""
	var roll = randf()
	
	if roll < enemy_data.attack_chance:
		set_intention_attack()
	elif roll < enemy_data.attack_chance + enemy_data.defend_chance:
		set_intention_defend()
	else:
		set_intention_buff()

func set_intention_attack():
	current_intention = "attack"
	intention_value = current_attack
	
	# Usar placeholder com "A" em vez de icone
	var placeholder = ColorRect.new()
	placeholder.color = Color.YELLOW
	intention_icon.modulate = Color.YELLOW
	
	intention_label.text = str(intention_value)
	intention_label.add_theme_color_override("font_color", Color.RED)
	show_intention()

func set_intention_defend():
	current_intention = "defend"
	intention_value = current_defense
	
	# Usar placeholder com "D"
	intention_label.text = "DEF: " + str(intention_value)
	intention_label.add_theme_color_override("font_color", Color.BLUE)
	show_intention()

func set_intention_buff():
	current_intention = "buff"
	intention_value = enemy_data.buff_attack_increase
	
	# Usar placeholder com "B"
	intention_label.text = "BUFF: +" + str(intention_value)
	intention_label.add_theme_color_override("font_color", Color.YELLOW_GREEN)
	show_intention()

func show_intention():
	intention_icon.visible = true
	intention_label.visible = true
	
	# Animação de aparecer
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(intention_icon, "modulate:a", 1.0, 0.2)
	tween.tween_property(intention_label, "modulate:a", 1.0, 0.2)

func hide_intention():
	intention_icon.visible = false
	intention_label.visible = false

# ============ AÇÕES DO TURNO (Executadas no turno do inimigo) ============

func execute_intention():
	"""Executa a ação escolhida"""
	match current_intention:
		"attack":
			execute_attack()
		"defend":
			execute_defend()
		"buff":
			execute_buff()
	
	# Limpar após executar
	hide_intention()
	current_intention = ""

func execute_attack():
	print(enemy_data.enemy_name + " ataca causando " + str(intention_value) + " de dano!")
	
	# Animação de ataque
	play_attack_animation()
	
	# Emitir sinal para o battle_manager processar dano
	enemy_action_executed.emit("attack", intention_value)

func execute_defend():
	print(enemy_data.enemy_name + " se defende com " + str(intention_value) + " de bloqueio!")
	
	# Adicionar bloqueio
	defense_block = intention_value
	is_defending = true
	
	# Mostrar efeito visual de escudo
	show_defense_effect()
	
	# Animação de defesa
	play_defend_animation()
	
	enemy_action_executed.emit("defend", intention_value)

func execute_buff():
	print(enemy_data.enemy_name + " buffa seu ataque em +" + str(intention_value) + "!")
	
	# Aumentar ataque permanentemente
	current_attack += intention_value
	
	# Mostrar efeito visual de buff
	show_buff_effect()
	
	# Animação de buff
	play_buff_animation()
	
	enemy_action_executed.emit("buff", intention_value)

# ============ RECEBER DANO ============

func take_damage(damage: int):
	var actual_damage = damage
	print("DEBUG: Enemy.take_damage called. damage=", damage, " current_hp=", current_hp, " defense_block=", defense_block)
	
	# Aplicar bloqueio se estiver defendendo
	if is_defending and defense_block > 0:
		var blocked = min(defense_block, damage)
		actual_damage = damage - blocked
		defense_block -= blocked
		
		# Mostrar número de bloqueio
		show_block_number(blocked)
		
		if defense_block <= 0:
			is_defending = false
			hide_defense_effect()
	
	current_hp -= actual_damage
	update_hp_display()
	print("DEBUG: Enemy current_hp after damage=", current_hp)
	
	# Efeito de dano
	play_hurt_animation()
	show_damage_number(actual_damage)
	
	if current_hp <= 0:
		die()

func show_damage_number(damage: int):
	var label = Label.new()
	label.text = str(damage)
	label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
	label.position = position - Vector2(0, 30)
	get_parent().add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position", position - Vector2(0, 60), 0.5)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(label.queue_free)

func show_block_number(block: int):
	var label = Label.new()
	label.text = "BLOCK " + str(block)
	label.add_theme_color_override("font_color", Color(0.3, 0.6, 1))
	label.position = position - Vector2(0, 20)
	get_parent().add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(label.queue_free)

func die():
	print(enemy_data.enemy_name + " morreu!")
	enemy_died.emit(self)
	
	# Animação de morte
	play_death_animation()
	await animation_player.animation_finished
	queue_free()

# ============ ANIMAÇÕES ============

func play_attack_animation():
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout

func play_defend_animation():
	if animation_player.has_animation("defend"):
		animation_player.play("defend")
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout

func play_buff_animation():
	if animation_player.has_animation("buff"):
		animation_player.play("buff")
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout

func play_hurt_animation():
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	# Mudar cor para vermelho temporariamente
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func play_death_animation():
	if animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		modulate.a = 0.0

func show_defense_effect():
	defense_icon.visible = true
	var tween = create_tween()
	tween.tween_property(defense_icon, "modulate:a", 1.0, 0.2)

func hide_defense_effect():
	defense_icon.visible = false

func show_buff_effect():
	buff_icon.visible = true
	var tween = create_tween()
	tween.tween_property(buff_icon, "modulate:a", 1.0, 0.2)
	tween.tween_property(buff_icon, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): buff_icon.visible = false)

# ============ INTERAÇÃO COM MOUSE ============

func _on_mouse_entered():
	# Destacar inimigo quando mouse passa por cima
	modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited():
	modulate = Color.WHITE

# ============ RESET ============

func reset_for_new_turn():
	"""Chamado no início do turno do inimigo"""
	is_defending = false
	defense_block = 0
	hide_defense_effect()
