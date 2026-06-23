extends Node2D

const LAYER_COUNTS := [4, 6, 1]
const NODE_RADIUS := 10.0
const POSITIVE_WEIGHT_COLOR := Color(0.1, 0.9, 0.45, 0.58)
const NEGATIVE_WEIGHT_COLOR := Color(1.0, 0.15, 0.08, 0.58)
const IDLE_WEIGHT_COLOR := Color(0.12, 0.16, 0.2, 0.18)
const INPUT_COLOR := Color(0.0, 0.75, 1.0, 0.9)
const HIDDEN_COLOR := Color(1.0, 0.72, 0.12, 0.9)
const OUTPUT_COLOR := Color(1.0, 0.15, 0.65, 0.95)
const NODE_RING_COLOR := Color(1.0, 1.0, 1.0, 0.42)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.22)

func _ready() -> void:
	z_index = 0
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var layers := get_layer_positions()
	var bird := get_display_bird()
	var weights := []
	var activations := get_default_activations()

	if bird and bird.get("genome"):
		weights = bird.genome.genes
		activations = calculate_activations(bird)

	draw_connections(layers, weights)
	draw_nodes(layers, activations)

func draw_connections(layers: Array, weights: Array) -> void:
	var weight_index := 0

	for from_index in range(LAYER_COUNTS[0]):
		for to_index in range(LAYER_COUNTS[1]):
			var weight := get_weight(weights, weight_index)
			weight_index += 1
			draw_weight_line(layers[0][from_index], layers[1][to_index], weight)

	for from_index in range(LAYER_COUNTS[1]):
		var weight := get_weight(weights, weight_index)
		weight_index += 1
		draw_weight_line(layers[1][from_index], layers[2][0], weight)

func draw_weight_line(from_pos: Vector2, to_pos: Vector2, weight: float) -> void:
	var strength := clampf(abs(weight), 0.0, 1.0)
	var color := IDLE_WEIGHT_COLOR
	if weight > 0.0:
		color = POSITIVE_WEIGHT_COLOR
	elif weight < 0.0:
		color = NEGATIVE_WEIGHT_COLOR

	color.a = lerpf(0.16, 0.72, strength)
	draw_line(from_pos, to_pos, color, lerpf(1.0, 3.0, strength))

func draw_nodes(layers: Array, activations: Array) -> void:
	var layer_colors := [INPUT_COLOR, HIDDEN_COLOR, OUTPUT_COLOR]

	for layer_index in range(layers.size()):
		for node_index in range(layers[layer_index].size()):
			var activation := clampf(activations[layer_index][node_index], 0.0, 1.0)
			var color: Color = layer_colors[layer_index]
			color = color.lerp(Color.WHITE, activation * 0.28)
			color.a = lerpf(0.38, 0.95, activation)

			draw_circle(layers[layer_index][node_index] + Vector2(2, 3), NODE_RADIUS + 2.0, SHADOW_COLOR)
			draw_circle(layers[layer_index][node_index], NODE_RADIUS + activation * 5.0, color)
			draw_arc(layers[layer_index][node_index], NODE_RADIUS + 5.0, 0.0, TAU, 24, NODE_RING_COLOR, 1.7)

func get_layer_positions() -> Array:
	var viewport_size := get_viewport_rect().size
	var layer_gap := viewport_size.x * 0.17
	var node_gap := 44.0
	var total_width := float(LAYER_COUNTS.size() - 1) * layer_gap
	var origin := Vector2(
		viewport_size.x * 0.5 - total_width * 0.5,
		viewport_size.y * 0.64
	)
	var layers := []

	for layer_index in range(LAYER_COUNTS.size()):
		var count: int = LAYER_COUNTS[layer_index]
		var layer := []
		var height := float(count - 1) * node_gap
		var x := origin.x + float(layer_index) * layer_gap

		for node_index in range(count):
			var y := origin.y - height * 0.5 + float(node_index) * node_gap
			layer.append(Vector2(x, y))

		layers.append(layer)

	return layers

func get_display_bird() -> Node:
	var main = get_tree().current_scene
	if not main:
		return null

	var bird_container = main.get_node_or_null("BirdContainer")
	if not bird_container:
		return null

	var best_bird = null
	var best_fitness := -INF
	for bird in bird_container.get_children():
		if bird.get("has_died") == true:
			continue
		if bird.get("fitness") != null and bird.fitness > best_fitness:
			best_fitness = bird.fitness
			best_bird = bird

	return best_bird

func calculate_activations(bird: Node) -> Array:
	var inputs: Array = bird.get_inputs()
	var hidden := []
	var index := 0

	for h in range(LAYER_COUNTS[1]):
		var sum := 0.0
		for i in range(LAYER_COUNTS[0]):
			sum += inputs[i] * bird.genome.genes[index]
			index += 1
		hidden.append(sigmoid(sum))

	var output_sum := 0.0
	for h in range(LAYER_COUNTS[1]):
		output_sum += hidden[h] * bird.genome.genes[index]
		index += 1

	return [
		normalize_inputs(inputs),
		hidden,
		[sigmoid(output_sum)]
	]

func normalize_inputs(inputs: Array) -> Array:
	return [
		clampf(inputs[0], 0.0, 1.0),
		clampf((inputs[1] + 1.0) * 0.5, 0.0, 1.0),
		clampf(inputs[2], 0.0, 1.0),
		clampf((inputs[3] + 1.0) * 0.5, 0.0, 1.0)
	]

func get_default_activations() -> Array:
	return [
		[0.2, 0.2, 0.2, 0.2],
		[0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
		[0.2]
	]

func get_weight(weights: Array, index: int) -> float:
	if index >= weights.size():
		return 0.0

	return weights[index]

func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))
