extends Control
class_name SlayMapController

@export var room_button_scene: PackedScene
@export var background_color: Color = Color(0.05, 0.05, 0.1, 1)
@export var camera_follow_speed: float = 5.0

var map_generator: SlayMapGenerator
var rooms: Dictionary = {}
var room_buttons: Dictionary = {} # id -> button
var line_container: Node2D
var skip_room_auto_selection: bool = false

@onready var rooms_container: Control = $RoomsContainer
@onready var current_room_id: int = -1

func _ready():
	print("DEBUG: MapController _ready() called")
	map_generator = SlayMapGenerator.new()
	# create line container behind rooms
	line_container = Node2D.new()
	add_child(line_container)
	move_child(line_container, 0)
	var game_state = get_node_or_null("/root/GameState")
	var saved_map = game_state.current_run.get("saved_map_state") if game_state else null
	if saved_map != null:
		restore_map_state_from_game_state(saved_map)
	else:
		generate_new_map()
		save_map_state_to_game_state()
	# Handle room completion after returning from shop/rest
	check_pending_room_completion()
	print("DEBUG: MapController _ready() completed. current_room_id=", current_room_id)

func generate_new_map() -> void:
	# clear existing
	for child in rooms_container.get_children():
		child.queue_free()
	room_buttons.clear()
	if line_container and is_instance_valid(line_container):
		line_container.queue_free()
	line_container = Node2D.new()
	add_child(line_container)
	move_child(line_container, 0)

	rooms = map_generator.generate_map()
	layout_rooms()
	var start_id = find_start_room_id()
	if start_id != -1:
		update_reachable_from(start_id)
		rooms[start_id].is_current = true
		update_room_visuals()
	save_map_state_to_game_state()

func layout_rooms() -> void:
	var screen_size = get_viewport_rect().size
	var margin = Vector2(100, 80)
	var column_width = (screen_size.x - margin.x * 2) / (map_generator.num_columns + 1)
	var row_height = (screen_size.y - margin.y * 2) / 5

	# group by column
	var columns: Dictionary = {}
	for id in rooms:
		var r = rooms[id]
		if not columns.has(r.column):
			columns[r.column] = []
		columns[r.column].append(r)

	for col in range(map_generator.num_columns + 1):
		if not columns.has(col):
			continue
		var col_rooms = columns[col]
		var x_pos = margin.x + (col * column_width)
		var y_spacing = row_height
		var start_y = (screen_size.y - (col_rooms.size() - 1) * y_spacing) / 2
		for i in range(col_rooms.size()):
			var room = col_rooms[i]
			var y_pos = start_y + (i * y_spacing)
			var button: Button = null
			if room_button_scene:
				button = room_button_scene.instantiate()
				button.setup(room, self)
				button.position = Vector2(x_pos - 40, y_pos - 40)
				rooms_container.add_child(button)
				room_buttons[room.id] = button
		# draw connections
	draw_all_connections()

func draw_all_connections() -> void:
	# remove old children lines
	for child in line_container.get_children():
		child.queue_free()
	for id in rooms:
		var room = rooms[id]
		var start_pos = get_room_center(id)
		for conn_id in room.connections:
			var end_pos = get_room_center(conn_id)
			var line = Line2D.new()
			line.add_point(start_pos)
			# add simple mid curve
			var mid_x = (start_pos.x + end_pos.x) * 0.5
			line.add_point(Vector2(mid_x, start_pos.y))
			line.add_point(Vector2(mid_x, end_pos.y))
			line.add_point(end_pos)
			line.width = 3
			line.default_color = Color(0.5, 0.5, 0.5, 0.6)
			line_container.add_child(line)
			line_container.move_child(line, 0)

func save_map_state_to_game_state() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
	var room_entries: Array = []
	for id in rooms:
		var room = rooms[id]
		room_entries.append({
			"id": room.id,
			"room_type": int(room.room_type),
			"column": room.column,
			"row": room.row,
			"connections": room.connections.duplicate(),
			"is_visited": room.is_visited,
			"is_current": room.is_current,
			"is_reachable": room.is_reachable
		})
	game_state.current_run["saved_map_state"] = {
		"rooms": room_entries,
		"current_room_id": current_room_id,
		"skip_room_auto_selection": skip_room_auto_selection
	}

func restore_map_state_from_game_state(map_state: Dictionary) -> void:
	if map_state == null or not map_state.has("rooms"):
		generate_new_map()
		return
	rooms.clear()
	room_buttons.clear()
	for child in rooms_container.get_children():
		child.queue_free()
	if line_container and is_instance_valid(line_container):
		line_container.queue_free()
	line_container = Node2D.new()
	add_child(line_container)
	move_child(line_container, 0)

	for room_data in map_state["rooms"]:
		var room = RoomData.new()
		room.id = int(room_data.get("id", -1))
		room.room_type = int(room_data.get("room_type", RoomData.RoomType.BATTLE))
		room.column = int(room_data.get("column", 0))
		room.row = int(room_data.get("row", 0))
		room.connections = room_data.get("connections", [])
		room.is_visited = bool(room_data.get("is_visited", false))
		room.is_current = bool(room_data.get("is_current", false))
		room.is_reachable = bool(room_data.get("is_reachable", false))
		rooms[room.id] = room

	current_room_id = int(map_state.get("current_room_id", -1))
	skip_room_auto_selection = bool(map_state.get("skip_room_auto_selection", false))
	layout_rooms()
	update_room_visuals()

func get_room_center(room_id: int) -> Vector2:
	if not room_buttons.has(room_id):
		# approximate by column/row if button not placed yet
		var r = rooms[room_id]
		return Vector2((r.column + 1) * 100, (r.row + 1) * 100)
	var button = room_buttons[room_id]
	var global_pos = button.global_position
	var button_size = Vector2(80, 80)
	if button is Control:
		button_size = button.size
	return global_pos + button_size / 2

func update_reachable_from(start_id: int) -> void:
	for id in rooms:
		rooms[id].is_reachable = false
	var queue: Array = [start_id]
	rooms[start_id].is_reachable = true
	while not queue.is_empty():
		var cur = queue.pop_front()
		for nid in rooms[cur].connections:
			if not rooms[nid].is_reachable and not rooms[nid].is_visited:
				rooms[nid].is_reachable = true
				queue.append(nid)
	update_room_visuals()

func on_room_selected(room_id: int) -> void:
	print("DEBUG: on_room_selected(", room_id, ")")
	var selected_room = rooms[room_id]
	if not selected_room.is_reachable or selected_room.is_visited:
		print("DEBUG: Room ", room_id, " not reachable or already visited")
		return
	if current_room_id != -1:
		rooms[current_room_id].is_visited = true
		rooms[current_room_id].is_current = false
	current_room_id = room_id
	rooms[current_room_id].is_current = true
	rooms[current_room_id].is_visited = true
	rooms[current_room_id].is_reachable = false
	update_reachable_from(current_room_id)
	update_room_visuals()
	save_map_state_to_game_state()
	print("DEBUG: Transitioning to room ", room_id, " type=", selected_room.room_type)
	transition_to_room(selected_room)

func update_room_visuals() -> void:
	for id in room_buttons:
		var btn = room_buttons[id]
		btn.update_visual_state()

func set_skip_room_auto_selection(skip: bool) -> void:
	skip_room_auto_selection = skip

func load_progress_from_game_state() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return

	# Restore visited/reachable state if present
	var completed_nodes = game_state.current_run.get("completed_nodes", [])
	for entry in completed_nodes:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			var rid = int(entry["id"])
			if rooms.has(rid):
				rooms[rid].is_visited = true
				rooms[rid].is_current = false
				rooms[rid].is_reachable = false

	var accessible_nodes = game_state.current_run.get("accessible_nodes", [])
	for entry in accessible_nodes:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			var rid = int(entry["id"])
			if rooms.has(rid):
				rooms[rid].is_reachable = true
				if room_buttons.has(rid):
					room_buttons[rid].disabled = false

	# Fall back to floor-based restoration for older save shapes
	if completed_nodes.is_empty() and accessible_nodes.is_empty():
		var completed_floors = game_state.current_run.get("completed_floors", [])
		var accessible_floors = game_state.current_run.get("accessible_floors", [])
		for id in rooms:
			var room = rooms[id]
			if room.column in completed_floors:
				room.is_visited = true
				room.is_reachable = false
				if room_buttons.has(id):
					room_buttons[id].disabled = true
			elif room.column in accessible_floors:
				room.is_reachable = true
				if room_buttons.has(id):
					room_buttons[id].disabled = false

	update_room_visuals()
	visible = true
	
	# Only auto-select a room after battles, not after shop/rest
	if not skip_room_auto_selection and current_room_id == -1:
		# Find and select the first reachable room
		for id in rooms:
			if rooms[id].is_reachable and not rooms[id].is_visited:
				on_room_selected(id)
				break
	skip_room_auto_selection = false  # Reset for next time

func find_start_room_id() -> int:
	for id in rooms:
		if rooms[id].room_type == RoomData.RoomType.START:
			return id
	return -1

func transition_to_room(room: RoomData) -> void:
	match room.room_type:
		RoomData.RoomType.BATTLE, RoomData.RoomType.ELITE, RoomData.RoomType.BOSS:
			start_battle(room)
		RoomData.RoomType.SHOP:
			open_shop(room)
		RoomData.RoomType.TREASURE:
			open_treasure(room)
		RoomData.RoomType.REST:
			rest_at_site(room)
		_:
			print("Loading generic room...")

func start_battle(room: RoomData) -> void:
	var battle_scene_path = "res://scenes/battle/battle_scene.tscn"
	if not ResourceLoader.exists(battle_scene_path):
		print("Battle scene not found: ", battle_scene_path)
		return

	var battle_res = load(battle_scene_path)
	if not battle_res:
		print("Failed to load battle scene resource: ", battle_scene_path)
		return
	var battle_scene = battle_res.instantiate()
	battle_scene.z_index = 100
	get_tree().root.add_child(battle_scene)

	# Hide the map while the battle is active
	visible = false

	var enemies = get_enemies_for_room(room)
	# Ensure we pass a typed Array[EnemyData] (filter out nulls)
	var typed_enemies: Array[EnemyData] = []
	for e in enemies:
		if e and e is EnemyData:
			typed_enemies.append(e)
	if battle_scene.has_method("setup_battle"):
		battle_scene.setup_battle(typed_enemies, room.room_type == RoomData.RoomType.ELITE, room.room_type == RoomData.RoomType.BOSS)
	if battle_scene.has_signal("battle_finished"):
		battle_scene.connect("battle_finished", Callable(self, "_on_battle_finished").bind(room.id))

func get_enemies_for_room(room: RoomData) -> Array:
	var enemies: Array = []
	match room.room_type:
		RoomData.RoomType.BATTLE:
			var count = int(randi() % 2) + 1
			for i in range(count):
				enemies.append(load_random_enemy("common"))
		RoomData.RoomType.ELITE:
			enemies.append(load_random_enemy("elite"))
			for i in range(int(randi() % 2) + 1):
				enemies.append(load_random_enemy("common"))
		RoomData.RoomType.BOSS:
			enemies.append(load_random_enemy("boss"))
	return enemies

func load_random_enemy(difficulty: String):
	var enemies_pool = {
		"common": ["goblin", "skeleton"],
		"elite": ["orc", "ogre"],
		"boss": ["demon", "dragon"]
	}
	var pool = enemies_pool.get(difficulty, ["goblin"])
	var enemy_name = pool[randi() % pool.size()]
	var path = "res://resources/enemies/enemy_" + enemy_name + ".tres"
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _on_battle_finished(victory: bool, rewards: Dictionary, room_id: int) -> void:
	if victory:
		mark_node_completed_by_id(room_id)
		unlock_next_nodes_by_id(room_id)
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			if not game_state.current_run.has("completed_nodes"):
				game_state.current_run["completed_nodes"] = []
			game_state.current_run["completed_nodes"].append({"id": room_id})
			save_map_state_to_game_state()
			# Boss victory is handled by the battle manager's final victory screen.
	else:
		# Defeat is handled by the battle manager's defeat screen.
		pass

func mark_node_completed_by_id(room_id: int) -> void:
	if not rooms.has(room_id):
		return
	rooms[room_id].is_visited = true
	if room_buttons.has(room_id):
		var btn = room_buttons[room_id]
		btn.modulate = Color(0.5, 0.5, 0.5)
		btn.disabled = true

func unlock_next_nodes_by_id(room_id: int) -> void:
	if not rooms.has(room_id):
		return
	var game_state = get_node_or_null("/root/GameState")
	if game_state and not game_state.current_run.has("accessible_nodes"):
		game_state.current_run["accessible_nodes"] = []
	for nid in rooms[room_id].connections:
		if not rooms[nid].is_visited:
			rooms[nid].is_reachable = true
			if game_state:
				var entry = {"id": nid}
				if not entry in game_state.current_run["accessible_nodes"]:
					game_state.current_run["accessible_nodes"].append(entry)
			if room_buttons.has(nid):
				var btn = room_buttons[nid]
				btn.disabled = false

func open_shop(room: RoomData) -> void:
	print("DEBUG: open_shop called for room ", room.id)
	var game_state = get_node("/root/GameState")
	game_state.current_run["pending_room_completion"] = room.id
	skip_room_auto_selection = true  # Don't auto-select rooms when returning
	save_map_state_to_game_state()
	print("DEBUG: Changing to shop scene...")
	get_tree().change_scene_to_file("res://scenes/ui/shop_screen.tscn")

func check_pending_room_completion() -> void:
	var game_state = get_node("/root/GameState")
	print("DEBUG: check_pending_room_completion() called")
	if game_state.current_run.has("pending_room_completion"):
		var room_id = game_state.current_run["pending_room_completion"]
		print("DEBUG: Found pending room ", room_id, " - marking complete")
		game_state.current_run.erase("pending_room_completion")
		mark_node_completed_by_id(room_id)
		unlock_next_nodes_by_id(room_id)
		update_room_visuals()
		save_map_state_to_game_state()
		print("DEBUG: Pending room completion finished")
	else:
		print("DEBUG: No pending room completion")

func trigger_event(room: RoomData) -> void:
	var event_path = "res://scenes/ui/event_screen.tscn"
	if ResourceLoader.exists(event_path):
		var event_res = load(event_path)
		if not event_res:
			print("Failed to load event scene: ", event_path)
			return
		var event_scene = event_res.instantiate()
		if event_scene.has_signal("event_completed"):
			event_scene.event_completed.connect(Callable(self, "_on_event_completed").bind(room.id))
		add_child(event_scene)

func _on_event_completed(result: Dictionary, room_id: int) -> void:
	# result: Dictionary emitted by the event screen
	mark_node_completed_by_id(room_id)
	unlock_next_nodes_by_id(room_id)

func open_treasure(room: RoomData) -> void:
	var treasure_path = "res://scenes/ui/treasure_screen.tscn"
	if ResourceLoader.exists(treasure_path):
		var treasure_res = load(treasure_path)
		if not treasure_res:
			print("Failed to load treasure scene: ", treasure_path)
			return
		var treasure_scene = treasure_res.instantiate()
		if treasure_scene.has_signal("treasure_collected"):
			treasure_scene.treasure_collected.connect(Callable(self, "_on_treasure_collected").bind(room.id))
		add_child(treasure_scene)

func _on_treasure_collected(rewards: Dictionary, room_id: int) -> void:
	# rewards: Dictionary describing collected rewards
	mark_node_completed_by_id(room_id)
	unlock_next_nodes_by_id(room_id)

func rest_at_site(room: RoomData) -> void:
	var game_state = get_node("/root/GameState")
	game_state.current_run["pending_room_completion"] = room.id
	skip_room_auto_selection = true  # Don't auto-select rooms when returning
	save_map_state_to_game_state()
	get_tree().change_scene_to_file("res://scenes/ui/rest_screen.tscn")

func show_defeat_screen(killed_by: String = "Unknown") -> void:
	var defeat_res = load("res://scenes/ui/defeat_screen.tscn")
	if not defeat_res:
		print("Defeat scene not found")
		return
	var defeat_scene = defeat_res.instantiate()
	if defeat_scene.has_method("setup"):
		defeat_scene.setup({
			"damage_taken": 0,
			"turn_defeated": 0,
			"enemies_killed": 0,
			"killed_by": killed_by
		})
	get_tree().root.add_child(defeat_scene)
	queue_free()

func _process(delta: float) -> void:
	if current_room_id != -1 and room_buttons.has(current_room_id):
		var target_pos = get_room_center(current_room_id)
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.global_position = camera.global_position.lerp(target_pos, delta * camera_follow_speed)
