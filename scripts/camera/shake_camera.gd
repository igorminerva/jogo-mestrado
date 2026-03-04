extends Camera2D

@export var shake_intensity: float = 10.0
@export var shake_duration: float = 0.3
@export var noise_speed: float = 100.0

var noise: FastNoiseLite
var noise_y: float = 0.0
var shaking: bool = false
var shake_timer: float = 0.0

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()

func _process(delta):
	if shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			stop_shake()
		else:
			apply_shake(delta)

func apply_shake(delta):
	noise_y += delta * noise_speed
	var x = noise.get_noise_1d(noise_y) * shake_intensity
	var y = noise.get_noise_1d(noise_y + 1000) * shake_intensity
	offset = Vector2(x, y)

func start_shake(intensity: float = 10.0, duration: float = 0.3):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shaking = true

func stop_shake():
	shaking = false
	offset = Vector2.ZERO
