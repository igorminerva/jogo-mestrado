extends Node
class_name MapGenerator

const FLOORS: int = 7
const ROWS: int = 3
const START_NODES: int = 3
const NODE_SPACING_X: float = 160.0
const NODE_SPACING_Y: float = 140.0

const SCREEN_WIDTH: float = 1152.0
const SCREEN_HEIGHT: float = 648.0
const MARGIN: float = 100.0

var nodes: Dictionary = {}
var start_nodes: Array = []
var _sort_reference_y: float = 0.0

func generate_map() -> Dictionary:
	nodes.clear()
	start_nodes.clear()
	generate_grid()
	generate_paths()
	remove_disconnected_nodes()
	assign_locations()
	return nodes

func generate_grid():
	var grid_height = (ROWS - 1) * NODE_SPACING_Y
	var start_y = (SCREEN_HEIGHT - grid_height) / 2

	for floor in range(FLOORS):
		var floor_nodes: Array = []
		var x = MARGIN + floor * NODE_SPACING_X
		var nodes_this_row = ROWS
		if floor == FLOORS - 1:
			nodes_this_row = 1
		
		for row in range(nodes_this_row):
			var y = start_y + row * NODE_SPACING_Y
			floor_nodes.append(_create_node(floor, Vector2(x, y)))
		
		nodes[floor] = floor_nodes

func _create_node(floor: int, position: Vector2) -> Dictionary:
	var node_type: String
	if floor == FLOORS - 1:
		node_type = "boss"
	else:
		node_type = "unassigned"
	var node_name: String
	if node_type == "boss":
		node_name = "CHEFE: " + get_random_boss_name()
	else:
		node_name = ""
	return {
		"type": node_type,
		"name": node_name,
		"floor": floor,
		"position": position,
		"is_accessible": false,
		"is_completed": false,
		"connections": [],
		"incoming": [],
		"connections_out": 0,
		"connections_in": 0
	}

func generate_paths():
	for node in nodes[0]:
		node["is_accessible"] = true
	start_nodes = nodes[0].duplicate()

	for floor_idx in range(FLOORS - 1):
		var current_floor = nodes[floor_idx]
		var next_floor = nodes[floor_idx + 1]
		var max_incoming: int
		if floor_idx + 1 == FLOORS - 1:
			max_incoming = 3
		else:
			max_incoming = 2

		var targets_needing_incoming: Array = []
		for target in next_floor:
			if target["connections_in"] == 0:
				targets_needing_incoming.append(target)

		for source in current_floor:
			if source["connections_out"] >= 2:
				continue

			var possible_targets = next_floor.duplicate()
			_sort_reference_y = source["position"].y
			possible_targets.sort_custom(Callable(self, "_sort_by_vertical_distance"))

			var connected_count = 0

			for target in possible_targets:
				if source["connections_out"] >= 2:
					break
				if target["connections_in"] >= max_incoming:
					continue
				if _connect_nodes(source, target):
					connected_count += 1
					if target in targets_needing_incoming:
						targets_needing_incoming.erase(target)

			if connected_count == 0 and not targets_needing_incoming.is_empty():
				_connect_nodes(source, targets_needing_incoming[0])
				targets_needing_incoming.erase(targets_needing_incoming[0])

		for target in targets_needing_incoming:
			var sources_with_room: Array = []
			for source in current_floor:
				if source["connections_out"] < 2:
					sources_with_room.append(source)

			if sources_with_room.is_empty():
				continue

			_sort_reference_y = target["position"].y
			sources_with_room.sort_custom(Callable(self, "_sort_by_vertical_distance"))
			_connect_nodes(sources_with_room[0], target)

		if floor_idx == FLOORS - 2:
			var boss_node = next_floor[0]
			while boss_node["connections_in"] < 2:
				var candidates = []
				for source in current_floor:
					if source["connections_out"] < 2 and boss_node not in source["connections"]:
						candidates.append(source)
				if candidates.is_empty():
					break
				_sort_reference_y = boss_node["position"].y
				candidates.sort_custom(Callable(self, "_sort_by_vertical_distance"))
				_connect_nodes(candidates[0], boss_node)

func _connect_nodes(source: Dictionary, target: Dictionary) -> bool:
	if target in source["connections"]:
		return false
	if source["connections_out"] >= 2:
		return false
	var max_incoming: int
	if target["floor"] == FLOORS - 1:
		max_incoming = 3
	else:
		max_incoming = 2
	if target["connections_in"] >= max_incoming:
		return false

	source["connections"].append(target)
	target["incoming"].append(source)
	source["connections_out"] += 1
	target["connections_in"] += 1
	return true

func _sort_by_vertical_distance(a: Dictionary, b: Dictionary) -> int:
	var dist_a = abs(a["position"].y - _sort_reference_y)
	var dist_b = abs(b["position"].y - _sort_reference_y)
	if dist_a == dist_b:
		return int(a["position"].y - b["position"].y)
	if dist_a < dist_b:
		return -1
	return 1

func remove_disconnected_nodes():
	var changed = true
	while changed:
		changed = false
		var to_remove: Array = []
		
		for floor in nodes.keys():
			if floor == 0:
				continue
			for node in nodes[floor]:
				if node["connections"].is_empty() and node["incoming"].is_empty():
					to_remove.append(node)
					changed = true
		
		for node in to_remove:
			var floor = node["floor"]
			nodes[floor].erase(node)
			
			for conn in node["connections"]:
				if node in conn["incoming"]:
					conn["incoming"].erase(node)
				conn["connections_in"] = max(0, conn["connections_in"] - 1)
			
			for inc in node["incoming"]:
				if node in inc["connections"]:
					inc["connections"].erase(node)
				inc["connections_out"] = max(0, inc["connections_out"] - 1)

func assign_locations():
	for floor in nodes.keys():
		for node in nodes[floor]:
			if node["floor"] != FLOORS - 1:
				node["type"] = "unassigned"

	for node in nodes[0]:
		node["type"] = "battle"
		node["name"] = get_random_battle_name()

	var treasure_floor = 4
	if nodes.has(treasure_floor):
		for node in nodes[treasure_floor]:
			if node["type"] != "boss":
				node["type"] = "treasure"
				node["name"] = "Tesouro"

	var rest_floor = FLOORS - 2
	if nodes.has(rest_floor):
		for node in nodes[rest_floor]:
			if node["type"] != "boss":
				node["type"] = "rest"
				node["name"] = "Descanso"
	
	var unassigned: Array = []
	for floor in nodes.keys():
		for node in nodes[floor]:
			if node["type"] == "unassigned":
				unassigned.append(node)
	
	unassigned.shuffle()
	for node in unassigned:
		var new_type = roll_location_type(node["floor"])
		node["type"] = new_type
		node["name"] = get_name_for_type(new_type)
		
		if not validate_location_rules():
			node["type"] = "battle"
			node["name"] = get_random_battle_name()
	
	fix_location_violations()

func roll_location_type(floor: int) -> String:
	var roll = randf()
	if floor < 4:
		if roll < 0.5:
			return "battle"
		elif roll < 0.75:
			return "shop"
		else:
			return "event"
	else:
		if roll < 0.4:
			return "battle"
		elif roll < 0.55:
			return "elite"
		elif roll < 0.7:
			return "shop"
		elif roll < 0.85:
			return "rest"
		else:
			return "event"

func validate_location_rules() -> bool:
	for floor in nodes.keys():
		for node in nodes[floor]:
			if node["floor"] < 4:
				if node["type"] == "elite" or node["type"] == "rest":
					return false
			
			if node["floor"] == FLOORS - 2:
				if node["type"] == "rest":
					return false
			
			if node["connections"].size() >= 2:
				var types = []
				for conn in node["connections"]:
					types.append(conn["type"])
				var unique = []
				for t in types:
					if t not in unique:
						unique.append(t)
				if unique.size() < types.size():
					return false
	
	return true

func fix_location_violations():
	for iteration in range(500):
		if validate_location_rules():
			break
		
		for floor in nodes.keys():
			for node in nodes[floor]:
				if node["floor"] < 4:
					if node["type"] == "elite" or node["type"] == "rest":
						node["type"] = "battle"
						node["name"] = get_random_battle_name()
				
				if node["floor"] == FLOORS - 2:
					if node["type"] == "rest":
						node["type"] = "battle"
						node["name"] = get_random_battle_name()
				
				if node["connections"].size() >= 2:
					var types = []
					for conn in node["connections"]:
						types.append(conn["type"])
					var unique = []
					for t in types:
						if t not in unique:
							unique.append(t)
					if unique.size() < types.size():
						node["type"] = "battle"
						node["name"] = get_random_battle_name()

func get_name_for_type(type: String) -> String:
	match type:
		"battle": return get_random_battle_name()
		"elite": return "ELITE: " + get_random_elite_name()
		"shop": return "Loja do Viajante"
		"rest": return "Descanso"
		"treasure": return "Tesouro"
		"event": return get_random_event_name()
		"boss": return "CHEFE: " + get_random_boss_name()
	return ""


func get_random_battle_name() -> String:
	var names = ["Goblins", "Esqueletos", "Lobos", "Bandidos", "Cultistas"]
	return names[randi() % names.size()]

func get_random_elite_name() -> String:
	var names = ["Capitão Ogro", "Mago Sombrio", "Golem de Pedra", "Assassino"]
	return names[randi() % names.size()]

func get_random_boss_name() -> String:
	var names = ["Rei Demônio", "Dragão Ancestral", "Lich Imortal"]
	return names[randi() % names.size()]

func get_random_event_name() -> String:
	var names = ["Fonte Misteriosa", "Templo Abandonado", "Viajante Perdido"]
	return names[randi() % names.size()]

func get_node_at(floor: int, index: int) -> Dictionary:
	if nodes.has(floor) and index < nodes[floor].size():
		return nodes[floor][index]
	return {}
