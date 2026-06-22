extends CharacterBody2D

signal hit_top

var fitness := 0.0
var brain : Brain
const GRAVITY: int = 1000
const MAX_VEL: int = 680
const FLAP_SPEED: int = -580

var flying: bool = false
var falling: bool = false

const START_POS = Vector2(193, 303)
const PIPE_PASSED_MARGIN := 80.0

func _ready():
	reset()
	brain = Brain.new()

func reset():
	falling = false
	flying = false
	fitness = 0.0
	position = START_POS
	set_rotation(0)

func get_inputs():
	var viewport_size = get_viewport_rect().size
	var pipe_distance := 1.0
	var gap_center_diff := 0.0

	var main = get_parent()
	if main and "pipes" in main and main.pipes.size() > 0:
		var next_pipe: Node2D = null
		var closest_dx := INF

		for pipe in main.pipes:
			var gap_center: Vector2 = pipe.get_node("Score").global_position
			var dx = gap_center.x - global_position.x
			if dx < -PIPE_PASSED_MARGIN:
				continue
			if dx < closest_dx:
				closest_dx = dx
				next_pipe = pipe

		if next_pipe:
			var gap_center: Vector2 = next_pipe.get_node("Score").global_position
			var dx = gap_center.x - global_position.x
			# 0.0 = at the pipe, 1.0 = far away
			pipe_distance = clampf(dx / viewport_size.x, 0.0, 1.0)
			# positive = bird above gap, negative = bird below gap
			gap_center_diff = (gap_center.y - global_position.y) / viewport_size.y

	return [
		global_position.y / viewport_size.y,
		velocity.y / 1000.0,
		pipe_distance,
		gap_center_diff
	]

func _physics_process(delta: float) -> void:
	if flying:
		fitness += delta
		var output = brain.predict(get_inputs())
		print(output)
		if output > 0.6:
			flap()
	if flying or falling:
		if flying and global_position.y <= 0:
			hit_top.emit()
		velocity.y += GRAVITY * delta

		if velocity.y > MAX_VEL:
			velocity.y = MAX_VEL

		if flying:
			set_rotation(deg_to_rad(velocity.y * 0.05))
			$AnimatedSprite2D.play()

		elif falling:
			set_rotation(PI / 2)
			$AnimatedSprite2D.stop()

		else:
			$AnimatedSprite2D.stop()
			
		move_and_slide()

func flap():
	velocity.y = FLAP_SPEED
	$"../Flap".play()
