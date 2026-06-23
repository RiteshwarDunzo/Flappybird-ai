extends Node

@export var bird_scene : PackedScene
@export var bird_container_path : NodePath = NodePath("../BirdContainer")

const POPULATION_SIZE := 100
const GENOME_SIZE := 30

var generation := 0
var population : Array[Genome] = []
var alive_birds := 0
var best_fitness := 0.0

func _process(_delta: float) -> void:
	refresh_best_fitness()

func create_population():
	population.clear()

	for i in range(POPULATION_SIZE):
		population.append(Genome.new(GENOME_SIZE))
		
func start_generation():
	if population.is_empty():
		create_population()

	generation += 1
	spawn_generation()

func spawn_generation():
	var bird_container = get_node(bird_container_path)
	for child in bird_container.get_children():
		bird_container.remove_child(child)
		child.queue_free()

	alive_birds = population.size()
	best_fitness = 0.0
	for genome in population:
		var bird = bird_scene.instantiate()
		bird.genome = genome
		bird.died.connect(_on_bird_died)
		bird_container.add_child(bird)

	print_generation_status()
		
func _on_bird_died(bird):
	if alive_birds <= 0:
		return

	best_fitness = max(best_fitness, bird.fitness)
	alive_birds -= 1
	print_generation_status()

	if alive_birds <= 0:
		print("Generation Complete")
		var main = get_parent()
		if main and main.has_method("stop_game"):
			main.stop_game()

func print_generation_status():
	print("Generation:", generation, " Alive birds:", alive_birds)

func refresh_best_fitness() -> void:
	for genome in population:
		best_fitness = max(best_fitness, genome.fitness)

	var bird_container = get_node_or_null(bird_container_path)
	if not bird_container:
		return

	for bird in bird_container.get_children():
		if bird.get("fitness") != null:
			best_fitness = max(best_fitness, bird.fitness)
