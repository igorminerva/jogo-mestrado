extends Node2D

@onready var map_container: Node2D = $ScrollContainer/MapContent/MapNodes
@onready var path_drawer: Line2D = $ScrollContainer/MapContent/Line2D
@onready var map_generator: Node = $MapGenerator
@onready var map_content: Control = $ScrollContainer/MapContent
@onready var scroll_container: ScrollContainer = $ScrollContainer

var nodes_data: Dictionary = {}
var node_buttons: Dictionary = {}
var current_node: Dictionary = {}
var current_floor: int = 0

func _ready():
	var game_state = get_node_or_null("/root/GameState")
	current_floor = game_state.current_run.get("current_floor", 0) if game_state else 0
	nodes_data = map_generator.generate_map()
	draw_map_nodes()
	draw_paths()
	load_completed_nodes()
	load_accessible_nodes()

func load_completed_nodes():
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.current_run.has("completed_floors"):
		return
	var completed = game_state.current_run["completed_floors"]
	for floor in completed:
		for node in nodes_data.get(floor, []):
			node["is_completed"] = true
			for btn in node_buttons.values():
				if btn.node_data == node:
					btn.modulate = Color(0.5, 0.5, 0.5)
					btn.disabled = true

func load_accessible_nodes():
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.current_run.has("accessible_floors"):
		return
	var accessible = game_state.current_run["accessible_floors"]
	for floor in accessible:
		for node in nodes_data.get(floor, []):
			node["is_accessible"] = true
			for btn in node_buttons.values():
				if btn.node_data == node and not node.get("is_completed", false):
					btn.disabled = false

func load_progress_from_game_state():
	load_completed_nodes()
	load_accessible_nodes()

func mark_node_by_position(floor: int, pos: Vector2):
	for floor_key in nodes_data.keys():
		for node in nodes_data[floor_key]:
			if node.get("floor") == floor and node.get("position") == pos:
				node["is_completed"] = true
				for key in node_buttons.keys():
					var btn = node_buttons[key]
					if btn.node_data == node:
						btn.modulate = Color(0.5, 0.5, 0.5)
						btn.disabled = true
				return

func draw_map_nodes():
	var min_x: float = 0
	var max_x: float = 0
	var max_y: float = 0
	
	for floor in nodes_data.keys():
		for node_data in nodes_data[floor]:
			var node_button = preload("res://scenes/ui/map_node_icon.tscn").instantiate()
			node_button.position = node_data["position"]
			node_button.node_selected.connect(_on_node_selected)
			map_container.add_child(node_button)
			node_button.setup(node_data)
			var key = str(floor) + "_" + str(node_data["position"].x)
			node_buttons[key] = node_button
			
			min_x = min(min_x, node_data["position"].x)
			max_x = max(max_x, node_data["position"].x)
			max_y = max(max_y, node_data["position"].y)
	
	map_content.custom_minimum_size = Vector2(max_x + 150, max_y + 150)
	map_content.size = map_content.custom_minimum_size

func draw_paths():
	path_drawer.clear_points()
	for floor in nodes_data.keys():
		for node_data in nodes_data[floor]:
			for connection in node_data["connections"]:
				draw_connection(node_data["position"], connection["position"])

func draw_connection(start: Vector2, end: Vector2):
	var line = Line2D.new()
	var mid_x = (start.x + end.x) * 0.5
	line.add_point(start)
	line.add_point(Vector2(mid_x, start.y))
	line.add_point(Vector2(mid_x, end.y))
	line.add_point(end)
	line.width = 3
	line.default_color = Color(0.4, 0.3, 0.2)
	line.modulate = Color(0.6, 0.5, 0.4, 0.5)
	map_container.add_child(line)
	map_container.move_child(line, 0)

func _on_node_selected(node_data: Dictionary):
	print("DEBUG: Node selected - ", node_data["name"], " (type: ", node_data["type"], ", floor: ", node_data["floor"], ")")
	if node_data["is_completed"]:
		return
	current_node = node_data
	current_floor = node_data["floor"]
	match node_data["type"]:
		"battle", "elite", "boss":
			print("DEBUG: Need scene -> res://scenes/battle/battle_scene.tscn")
			start_battle(node_data)
		"shop":
			print("DEBUG: Need scene -> res://scenes/ui/shop_screen.tscn")
		"event":
			print("DEBUG: Need scene -> res://scenes/ui/event_screen.tscn")
			trigger_event(node_data)
		"treasure":
			print("DEBUG: Need scene -> res://scenes/ui/treasure_screen.tscn")
			open_treasure(node_data)
		"rest":
			print("DEBUG: Need scene -> res://scenes/ui/rest_screen.tscn")
			rest_at_site(node_data)

func start_battle(node_data: Dictionary):
	var tween = create_tween()
	tween.tween_property($CanvasLayer/TransitionRect, "color", Color(0, 0, 0, 1), 0.3)
	tween.tween_callback(func(): load_battle_scene(node_data))

func load_battle_scene(node_data: Dictionary):
	current_node = node_data
	get_node("/root/GameState").current_run["current_battle_node"] = node_data
	get_tree().current_scene = null
	var battle_scene = preload("res://scenes/battle/battle_scene.tscn").instantiate()
	battle_scene.z_index = 100
	get_tree().root.add_child(battle_scene)
	get_tree().current_scene = battle_scene
	var enemies = get_enemies_for_node(node_data)
	if battle_scene.has_method("setup_battle"):
		battle_scene.setup_battle(enemies, node_data["type"] == "elite", node_data["type"] == "boss")
	if battle_scene.has_signal("battle_finished"):
		battle_scene.connect("battle_finished", Callable(self, "_on_battle_finished").bind(node_data))
	visible = false

func get_enemies_for_node(node_data: Dictionary) -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	match node_data["type"]:
		"battle":
			var count = randi() % 2 + 1
			for i in range(count):
				enemies.append(load_random_enemy("common"))
		"elite":
			enemies.append(load_random_enemy("elite"))
			for i in range(randi() % 2 + 1):
				enemies.append(load_random_enemy("common"))
		"boss":
			enemies.append(load_random_enemy("boss"))
	return enemies

func load_random_enemy(difficulty: String) -> EnemyData:
	var enemies_pool = {
		"common": ["goblin", "skeleton"],
		"elite": ["orc", "ogre"],
		"boss": ["demon", "dragon"]
	}
	var pool = enemies_pool.get(difficulty, ["goblin"])
	var enemy_name = pool[randi() % pool.size()]
	return load("res://resources/enemies/enemy_" + enemy_name + ".tres") as EnemyData

func _on_battle_finished(victory: bool, rewards: Dictionary, node_data: Dictionary):
	print("DEBUG: _on_battle_finished called, victory=", victory)
	if victory:
		mark_node_completed(node_data)
		unlock_next_nodes(node_data)
		
		var game_state = get_node("/root/GameState")
		if not game_state.current_run.has("completed_nodes"):
			game_state.current_run["completed_nodes"] = []
		game_state.current_run["completed_nodes"].append({
			"floor": node_data["floor"],
			"position": node_data["position"]
		})
		
		if node_data.get("type") == "boss":
			queue_free()
			return
		
		# Battle scene will be freed by battle_manager
	else:
		var game_state = get_node_or_null("/root/GameState")
		var killed_by = "Unknown"
		if game_state and game_state.current_run.has("enemies_defeated"):
			var enemies = game_state.current_run["enemies_defeated"]
			if enemies.size() > 0:
				killed_by = enemies[-1]
		show_defeat_screen(killed_by)

func mark_node_completed(node_data: Dictionary):
	node_data["is_completed"] = true
	for button in node_buttons.values():
		if button.node_data == node_data:
			button.modulate = Color(0.5, 0.5, 0.5)
			button.disabled = true
			break

func unlock_next_nodes(completed_node: Dictionary):
	var next_floor = completed_node["floor"] + 1
	if not nodes_data.has(next_floor):
		return
	var game_state = get_node("/root/GameState")
	if not game_state.current_run.has("accessible_nodes"):
		game_state.current_run["accessible_nodes"] = []
	for node_data in nodes_data[next_floor]:
		if completed_node in node_data.get("connections", []):
			node_data["is_accessible"] = true
			if not {"floor": node_data["floor"], "position": node_data["position"]} in game_state.current_run["accessible_nodes"]:
				game_state.current_run["accessible_nodes"].append({
					"floor": node_data["floor"],
					"position": node_data["position"]
				})
			for button in node_buttons.values():
				if button.node_data == node_data:
					button.disabled = false
					if node_data["type"] == "elite":
						button.start_elite_glow()
					elif node_data["type"] == "event":
						button.start_event_pulse()
					break

func open_shop(node_data: Dictionary):
	var shop_scene = preload("res://scenes/ui/shop_screen.tscn").instantiate()
	shop_scene.shop_closed.connect(_on_shop_closed.bind(node_data))
	add_child(shop_scene)

func _on_shop_closed(node_data: Dictionary):
	mark_node_completed(node_data)
	unlock_next_nodes(node_data)

func trigger_event(node_data: Dictionary):
	var event_scene = preload("res://scenes/ui/event_screen.tscn").instantiate()
	event_scene.event_completed.connect(_on_event_completed.bind(node_data))
	add_child(event_scene)

func collect_treasure(node_data: Dictionary):
	mark_node_completed(node_data)
	unlock_next_nodes(node_data)
	get_tree().change_scene_to_packed(load("res://scenes/map/map_scene.tscn"))

func open_treasure(node_data: Dictionary):
	var treasure_scene = preload("res://scenes/ui/treasure_screen.tscn").instantiate()
	treasure_scene.treasure_collected.connect(_on_treasure_collected.bind(node_data))
	add_child(treasure_scene)

func _on_treasure_collected(rewards: Dictionary, node_data: Dictionary):
	mark_node_completed(node_data)
	unlock_next_nodes(node_data)

func rest_at_site(node_data: Dictionary):
	var rest_scene = preload("res://scenes/ui/rest_screen.tscn").instantiate()
	rest_scene.rest_completed.connect(_on_rest_completed.bind(node_data))
	add_child(rest_scene)

func _on_rest_completed(result: Dictionary, node_data: Dictionary):
	mark_node_completed(node_data)
	unlock_next_nodes(node_data)

func _on_event_completed(node_data: Dictionary):
	mark_node_completed(node_data)
	unlock_next_nodes(node_data)

func show_defeat_screen(killed_by: String = "Unknown"):
	var defeat_scene = preload("res://scenes/ui/defeat_screen.tscn").instantiate()
	defeat_scene.setup({
		"damage_taken": 0,
		"turn_defeated": 0,
		"enemies_killed": 0,
		"killed_by": killed_by
	})
	get_tree().root.add_child(defeat_scene)
	queue_free()
