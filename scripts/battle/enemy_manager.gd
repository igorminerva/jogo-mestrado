extends Node
class_name EnemyManager
signal all_enemies_defeated
signal enemy_action_processed(action_type, value, enemy)
signal enemy_turn_finished

var enemies: Array[Enemy] = []
var current_enemy_index: int = 0
var current_enemy: Enemy = null

func _ready():
	pass

func add_enemy(enemy: Enemy):
	enemies.append(enemy)
	enemy.enemy_died.connect(_on_enemy_died)
	add_child(enemy)

func add_enemies_from_data(enemies_data: Array[EnemyData]):
	for data in enemies_data:
		var enemy_scene = preload("res://scenes/battle/enemy.tscn")
		var enemy = enemy_scene.instantiate()
		enemy.enemy_data = data
		add_enemy(enemy)

func remove_enemy(enemy: Enemy):
	var index = enemies.find(enemy)
	if index != -1:
		enemies.remove_at(index)

func _on_enemy_died(enemy: Enemy):
	remove_enemy(enemy)
	
	if enemies.is_empty():
		all_enemies_defeated.emit()

func setup_enemy_intentions():
	"""Chamado no início do turno do jogador - mostra o que cada inimigo vai fazer"""
	for enemy in enemies:
		enemy.choose_intention()

func execute_enemy_turn():
	"""Chamado no turno do inimigo - executa ações de todos"""
	current_enemy_index = 0
	execute_next_enemy_action()

func execute_next_enemy_action():
	if current_enemy_index >= enemies.size():
		# Todos inimigos agiram
		print("DEBUG: EnemyManager: all enemies acted, emitting enemy_turn_finished")
		enemy_turn_finished.emit()
		return

	var enemy = enemies[current_enemy_index]
	current_enemy = enemy
	enemy.enemy_action_executed.connect(Callable(self, "_on_enemy_action_executed"))
	enemy.execute_intention()

func _on_enemy_action_executed(action_type: String, value: int):
	if current_enemy:
		current_enemy.enemy_action_executed.disconnect(Callable(self, "_on_enemy_action_executed"))
		if action_type != "":
			print("DEBUG: EnemyManager: emitting enemy_action_processed: ", action_type, value, " for ", current_enemy)
			enemy_action_processed.emit(action_type, value, current_enemy)
	current_enemy_index += 1
	execute_next_enemy_action()

func get_enemies() -> Array[Enemy]:
	return enemies

func clear_all_enemies():
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
