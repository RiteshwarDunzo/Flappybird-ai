extends CharacterBody2D

signal died(bird)

var genome : Genome:
	set(value):
		genome = value
		brain = Brain.new(genome) if genome else null
var fitness := 0.0
var brain : Brain
const GRAVITY: int = 1000
const MAX_VEL: int = 680
const FLAP_SPEED: int = -580

var flying: bool = false
var falling: bool = false
var has_died: bool = false

const START_POS = Vector2(193, 303)
const PIPE_PASSED_MARGIN := 80.0

func _ready():
	reset()

func reset():
	falling = false
	flying = false
	has_died = false
	fitness = 0.0
	velocity = Vector2.ZERO
	position = START_POS
	set_rotation(0)
	$CollisionShape2D.set_deferred("disabled", false)

func get_inputs():
	var viewport_size = get_viewport_rect().size
	var pipe_distance := 1.0
	var gap_center_diff := 0.0

	var main = get_tree().current_scene
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
	if flying and not has_died:
		fitness += delta
		if brain and brain.predict(get_inputs()) > 0.5:
			flap()
	if flying or falling:
		if flying and global_position.y <= 0:
			die("top")
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
	if has_died:
		return

	velocity.y = FLAP_SPEED
	var flap_sound = get_tree().current_scene.get_node_or_null("Flap")
	if flap_sound:
		flap_sound.play()

func die(_reason := ""):
	if has_died:
		return

	has_died = true
	flying = false
	falling = true
	if genome:
		genome.fitness = fitness
	$CollisionShape2D.set_deferred("disabled", true)
	died.emit(self)
