extends Node

@export var bird_scene : PackedScene
@export var bird_container_path : NodePath = NodePath("../BirdContainer")

const POPULATION_SIZE := 100
const GENOME_SIZE := 30
const ELITE_COUNT := 10
const MUTATION_RATE := 0.10
const MUTATION_STRENGTH := 0.3
const SAVE_PATH := "user://flappy_ai_learning.json"

var generation := 0
var population : Array[Genome] = []
var alive_birds := 0
var best_fitness := 0.0
var saved_best_fitness := 0.0
var saved_best_genes := []
var generation_complete_pending := false
var save_best_genome := true

func _process(_delta: float) -> void:
	refresh_best_fitness()

func create_population():
	population.clear()

	for i in range(POPULATION_SIZE):
		population.append(Genome.new(GENOME_SIZE))

func setup_population() -> bool:
	if load_learning_state():
		return true

	generation = 0
	best_fitness = 0.0
	saved_best_fitness = 0.0
	saved_best_genes.clear()
	create_population()
	return false

func start_generation():
	if population.is_empty():
		create_population()

	generation += 1
	spawn_generation()
	save_learning_state()

func spawn_generation():
	var bird_container = get_node(bird_container_path)
	for child in bird_container.get_children():
		bird_container.remove_child(child)
		child.queue_free()

	alive_birds = population.size()
	best_fitness = 0.0
	generation_complete_pending = false
	for genome in population:
		var bird = bird_scene.instantiate()
		bird.genome = genome
		bird.died.connect(_on_bird_died)
		bird_container.add_child(bird)


func _on_bird_died(bird):
	if alive_birds <= 0:
		return

	best_fitness = max(best_fitness, bird.fitness)
	alive_birds -= 1

	if alive_birds <= 0:
		complete_generation()

func complete_generation():
	if generation_complete_pending:
		return

	generation_complete_pending = true
	call_deferred("_complete_generation_deferred")

func _complete_generation_deferred():
	var main = get_parent()
	if main and main.has_method("reset_round"):
		main.reset_round()
	evolve()
	save_learning_state()
	if main and main.has_method("start_game"):
		main.start_game()



func refresh_best_fitness() -> void:
	for genome in population:
		best_fitness = max(best_fitness, genome.fitness)

	var bird_container = get_node_or_null(bird_container_path)
	if not bird_container:
		return

	for bird in bird_container.get_children():
		if bird.get("fitness") != null:
			best_fitness = max(best_fitness, bird.fitness)

func evolve():
	if population.is_empty():
		create_population()
		start_generation()
		return

	population.sort_custom(func(a: Genome, b: Genome): return a.fitness > b.fitness)

	var ended_best_fitness := population[0].fitness
	var average_fitness := get_average_fitness()
	saved_best_fitness = max(saved_best_fitness, ended_best_fitness)
	saved_best_genes = population[0].genes.duplicate()

	print("Best fitness:", ended_best_fitness)
	print("Average fitness:", average_fitness)

	var elite_count = min(ELITE_COUNT, population.size())
	var elites : Array[Genome] = []
	for i in range(elite_count):
		elites.append(clone_genome(population[i]))

	var next_population : Array[Genome] = []
	for elite in elites:
		next_population.append(elite)

	while next_population.size() < POPULATION_SIZE:
		var parent_a := elites[randi_range(0, elites.size() - 1)]
		var parent_b := elites[randi_range(0, elites.size() - 1)]
		var child := crossover(parent_a, parent_b)
		mutate(child)
		next_population.append(child)

	population = next_population
	generation += 1
	spawn_generation()

func crossover(parent_a: Genome, parent_b: Genome) -> Genome:
	var child := Genome.new(0)

	for i in range(GENOME_SIZE):
		if randf() < 0.5:
			child.genes.append(parent_a.genes[i])
		else:
			child.genes.append(parent_b.genes[i])

	return child

func mutate(genome: Genome):
	for i in range(genome.genes.size()):
		if randf() < MUTATION_RATE:
			genome.genes[i] += randf_range(-MUTATION_STRENGTH, MUTATION_STRENGTH)

func clone_genome(source: Genome) -> Genome:
	var clone := Genome.new(0)
	clone.genes = source.genes.duplicate()
	clone.fitness = 0.0
	return clone

func get_average_fitness() -> float:
	if population.is_empty():
		return 0.0

	var total := 0.0
	for genome in population:
		total += genome.fitness

	return total / float(population.size())

func save_learning_state() -> void:
	var save_data := {
		"generation": generation,
		"best_fitness": saved_best_fitness,
		"save_best_genome": save_best_genome,
		"population": serialize_population()
	}

	if save_best_genome and not saved_best_genes.is_empty():
		save_data["best_genome"] = saved_best_genes

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Could not save learning state to " + SAVE_PATH)
		return

	file.store_string(JSON.stringify(save_data))

func load_learning_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false

	var loaded_population := deserialize_population(parsed.get("population", []))
	if loaded_population.size() != POPULATION_SIZE:
		return false

	save_best_genome = bool(parsed.get("save_best_genome", save_best_genome))
	generation = int(parsed.get("generation", 0))
	saved_best_fitness = float(parsed.get("best_fitness", 0.0))
	best_fitness = saved_best_fitness
	saved_best_genes = parsed.get("best_genome", [])
	population = loaded_population
	return true

func serialize_population() -> Array:
	var serialized := []
	for genome in population:
		serialized.append({
			"genes": genome.genes,
			"fitness": genome.fitness
		})

	return serialized

func deserialize_population(serialized: Array) -> Array[Genome]:
	var loaded : Array[Genome] = []

	for item in serialized:
		if not item is Dictionary:
			continue

		var genes: Array = item.get("genes", [])
		if genes.size() != GENOME_SIZE:
			continue

		var genome := Genome.new(0)
		for gene in genes:
			genome.genes.append(float(gene))
		genome.fitness = float(item.get("fitness", 0.0))
		loaded.append(genome)

	return loaded

func get_best_genome() -> Genome:
	if population.is_empty():
		return null

	var best_genome := population[0]
	for genome in population:
		if genome.fitness > best_genome.fitness:
			best_genome = genome

	return best_genome

func set_save_best_genome(enabled: bool) -> void:
	save_best_genome = enabled
	save_learning_state()
