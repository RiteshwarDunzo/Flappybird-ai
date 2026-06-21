extends CharacterBody2D

const GRAVITY: int = 1000
const MAX_VEL: int = 680
const FLAP_SPEED: int = -580

var flying: bool = false
var falling: bool = false

const START_POS = Vector2(193, 303)

func _ready():
	reset()

func reset():
	falling = false
	flying = false
	position = START_POS
	set_rotation(0)

func _physics_process(delta: float) -> void:
	if flying or falling:
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
