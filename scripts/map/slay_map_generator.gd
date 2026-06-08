extends Node
class_name SlayMapGenerator

@export var num_columns: int = 7
@export var min_rooms_per_column: int = 1
@export var max_rooms_per_column: int = 3
@export var elite_chance: float = 0.25
@export var shop_chance: float = 0.2
@export var rest_chance: float = 0.15

var _sort_rooms_ref: Dictionary = {}

func _init():
	randomize()

func generate_map() -> Dictionary:
	var rooms: Dictionary = {}
	var next_id: int = 0

	# Generate columns (0 = start, num_columns = boss column)
	for col in range(num_columns + 1):
		var num_rooms = get_rooms_for_column(col)
		var rows_in_column: Array = []
		for room_index in range(num_rooms):
			var room = RoomData.new()
			room.id = next_id
			room.column = col
			room.row = room_index
			room.room_type = determine_room_type(col, room_index, num_rooms)
			room.connections = []
			rooms[next_id] = room
			rows_in_column.append(next_id)
			next_id += 1

		# Connect to previous column
		if col > 0:
			connect_columns(rooms, col - 1, rows_in_column, col)

	# Ensure reachability
	ensure_all_reachable(rooms)
	return rooms

func get_rooms_for_column(col: int) -> int:
	if col == 0:
		return 1
	elif col == num_columns:
		return 1
	var span = max_rooms_per_column - min_rooms_per_column + 1
	return int(randi() % span) + min_rooms_per_column

func determine_room_type(col: int, room_index: int, total_in_column: int) -> RoomData.RoomType:
	if col == 0:
		return RoomData.RoomType.START
	elif col == num_columns:
		return RoomData.RoomType.BOSS

	var r = randf()
	# early columns are mostly battles
	if col < 2:
		return RoomData.RoomType.BATTLE

	# elite chance after column 2
	if col >= 2 and r < elite_chance:
		return RoomData.RoomType.ELITE
	# shop
	if r < elite_chance + shop_chance:
		return RoomData.RoomType.SHOP
	# rest
	if r < elite_chance + shop_chance + rest_chance:
		return RoomData.RoomType.REST
	# otherwise battle
	return RoomData.RoomType.BATTLE

func connect_columns(rooms: Dictionary, prev_col: int, cur_col_room_ids: Array, cur_col: int) -> void:
	# Build list of previous column room ids
	var prev_ids: Array = []
	for id in rooms:
		if rooms[id].column == prev_col:
			prev_ids.append(id)

	# Simple greedy connect: each prev connects to 1-2 closest rows in current
	for pid in prev_ids:
		var p = rooms[pid]
		# sort current column by row
		_sort_rooms_ref = rooms
		cur_col_room_ids.sort_custom(Callable(self, "_sort_ids_by_row"))
		_sort_rooms_ref = {}
		var connections = int(randi() % 2) + 1
		for i in range(connections):
			if i >= cur_col_room_ids.size():
				break
			var cid = cur_col_room_ids[i]
			# add bidirectional reference (store by id)
			if not cid in p.connections:
				p.connections.append(cid)

func ensure_all_reachable(rooms: Dictionary) -> void:
	# mark reachable from start
	var start_id = -1
	for id in rooms:
		if rooms[id].room_type == RoomData.RoomType.START:
			start_id = id
			break
	if start_id == -1:
		return

	for id in rooms:
		rooms[id].is_reachable = false

	var queue: Array = [start_id]
	rooms[start_id].is_reachable = true
	while not queue.is_empty():
		var cur = queue.pop_front()
		for nid in rooms[cur].connections:
			if not rooms[nid].is_reachable:
				rooms[nid].is_reachable = true
				queue.append(nid)

	# If some nodes are unreachable, connect them to nearest reachable in previous column
	for id in rooms:
		if not rooms[id].is_reachable:
			# find candidate in previous column
			var candidate = find_nearest_reachable_before(rooms, rooms[id])
			if candidate != -1:
				rooms[candidate].connections.append(id)
				rooms[id].is_reachable = true

func find_nearest_reachable_before(rooms: Dictionary, target: RoomData) -> int:
	# search previous columns for reachable room closest by row
	for col in range(target.column - 1, -1, -1):
		var best_id = -1
		var best_dist = 1e9
		for id in rooms:
			var r = rooms[id]
			if r.column != col:
				continue
			if not r.is_reachable:
				continue
			var d = abs(r.row - target.row)
			if d < best_dist:
				best_dist = d
				best_id = id
		if best_id != -1:
			return best_id
	return -1

func _sort_ids_by_row(a, b) -> int:
	# compare by row value for room ids
	var ra = _sort_rooms_ref[a].row
	var rb = _sort_rooms_ref[b].row
	if ra == rb:
		return 0
	return -1 if ra < rb else 1
