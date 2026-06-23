extends Node2D

@export var pipe_scene : PackedScene
var scroll : float = 0.0
var score := 0
var high_score := 0
var game_running : bool 
var game_over : bool

const SCROLL_SPEED : int = 360
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

var screen_size : Vector2i
var ground_height : int
var pipes : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	new_game()

func new_game():
	reset_round()
	if $PopulationManager.setup_population():
		$PopulationManager.spawn_generation()
	else:
		$PopulationManager.start_generation()

func reset_round():
	$Timer.stop()
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	update_high_score_label()
	$GameOver.hide()

	for pipe in pipes:
		if is_instance_valid(pipe):
			pipe.queue_free()

	pipes.clear()

func _input(event):
	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()

func start_game():
	game_running = true
	for bird in $BirdContainer.get_children():
		if bird.get("has_died") == true:
			continue
		bird.flying = true
		bird.get_node("CollisionShape2D").set_deferred("disabled", false)
		bird.flap()
	$Timer.start()
	
func _process(delta: float) -> void:
	update_stats_ui()

	if game_running:
		scroll += SCROLL_SPEED*delta

		if scroll >= screen_size.x:
			scroll = 0

		$Ground.position.x = -scroll

		for pipe in pipes:
			if is_instance_valid(pipe):
				pipe.position.x -= SCROLL_SPEED*delta
			
func _on_timer_timeout() -> void:
	generate_pipes()


func generate_pipes():
	if not game_running:
		return

	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)

func bird_hit(_bird):
	$Hit.play()

func scored(bird):
	score += 1
	high_score = max(high_score, score)
	if bird.get("fitness") != null:
		bird.fitness += 100
	update_high_score_label()
	$Point.play()

func stop_game():
	$Timer.stop()
	$GameOver.show()
	for bird in $BirdContainer.get_children():
		bird.flying = false
	game_running = false
	game_over = true


func _on_ground_hit(_bird) -> void:
	$Die.play()


func _on_game_over_restart() -> void:
	new_game()

func update_stats_ui() -> void:
	var population_manager = $PopulationManager
	$UI/Stats/GenerationLabel.text = "GENERATION: " + str(population_manager.generation)
	$UI/Stats/BestFitnessLabel.text = "BEST FITNESS: " + str(snappedf(population_manager.best_fitness, 0.01))
	$UI/Stats/BirdsAliveLabel.text = "BIRDS ALIVE: " + str(population_manager.alive_birds)
	$UI/Stats/SaveBestGenomeRow/SaveBestGenomeToggle.set_pressed_no_signal(population_manager.save_best_genome)
	$UI/Stats/SaveBestGenomeRow/SaveBestGenomeValue.text = "YES" if population_manager.save_best_genome else "NO"

func update_high_score_label() -> void:
	$Label.text = "HIGH SCORE: " + str(high_score)

func _on_save_best_genome_toggle_toggled(button_pressed: bool) -> void:
	$PopulationManager.set_save_best_genome(button_pressed)
