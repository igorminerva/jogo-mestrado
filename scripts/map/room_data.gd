extends Resource
class_name RoomData

enum RoomType {
	START,
	BATTLE,
	ELITE,
	SHOP,
	REST,
	TREASURE,
	BOSS
}

@export var id: int = -1
@export var room_type: RoomType = RoomType.BATTLE
@export var column: int = 0
@export var row: int = 0
@export var connections: Array = []
@export var is_visited: bool = false
@export var is_current: bool = false
@export var is_reachable: bool = false

func get_room_type_string() -> String:
	match room_type:
		RoomType.START:
			return "Start"
		RoomType.BATTLE:
			return "Battle"
		RoomType.ELITE:
			return "Elite"
		RoomType.SHOP:
			return "Shop"
		RoomType.REST:
			return "Rest"
		RoomType.TREASURE:
			return "Treasure"
		RoomType.BOSS:
			return "Boss"
	return "Unknown"

func get_icon_path() -> String:
	# Map to existing project icons where possible
	match room_type:
		RoomType.START, RoomType.BATTLE:
			return "res://icons/sword_icon.png"
		RoomType.ELITE:
			return "res://icons/skull_icon.png"
		RoomType.SHOP:
			return "res://icons/shop_icon.png"
		RoomType.REST, RoomType.TREASURE:
			return "res://icons/question_icon.png"
		RoomType.BOSS:
			return "res://icons/boss_icon.png"
	return ""