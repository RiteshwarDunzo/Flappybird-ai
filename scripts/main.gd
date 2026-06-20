extends Node2D

var scroll
var score
var game_running : bool 
var game_over : bool

const SCROLL_SPEED : int = 4
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

var screen_size : Vector2i
var ground_height : int
var pipes : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

func new_game():
	# reset variables
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	$Bird.reset()

func _input(event):
	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				else:
					if $Bird.flying:
						$Bird.flap()

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
