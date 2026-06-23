extends Node2D

const LAYER_COUNTS := [4, 6, 1]
const NODE_RADIUS := 13.0
const PANEL_PADDING := 18.0
const PANEL_COLOR := Color(0.02, 0.025, 0.035, 0.72)
const PANEL_BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.18)
const POSITIVE_WEIGHT_COLOR := Color(0.1, 0.95, 0.45, 0.78)
const NEGATIVE_WEIGHT_COLOR := Color(1.0, 0.18, 0.1, 0.78)
const IDLE_WEIGHT_COLOR := Color(0.55, 0.62, 0.72, 0.14)
const INPUT_COLOR := Color(0.0, 0.78, 1.0, 0.96)
const HIDDEN_COLOR := Color(1.0, 0.73, 0.12, 0.96)
const OUTPUT_COLOR := Color(1.0, 0.18, 0.66, 0.98)
const NODE_RING_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const NODE_INACTIVE_COLOR := Color(0.08, 0.1, 0.14, 0.92)
const TEXT_COLOR := Color(0.92, 0.96, 1.0, 0.95)
const MUTED_TEXT_COLOR := Color(0.74, 0.8, 0.88, 0.82)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.30)
const ACTIVATION_BAR_BG := Color(1.0, 1.0, 1.0, 0.12)
const FONT_SIZE := 13
const SMALL_FONT_SIZE := 10

const INPUT_LABELS := ["Y", "VEL", "PIPE", "GAP"]
const INPUT_DESCRIPTIONS := ["height", "velocity", "pipe dist", "gap offset"]
const LAYER_LABELS := ["INPUTS", "HIDDEN", "OUTPUT"]

func _ready() -> void:
	z_index = 0
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var layers := get_layer_positions()
	var panel_rect := get_panel_rect(layers)
	var bird := get_display_bird()
	var weights := []
	var activations := get_default_activations()
	var raw_inputs := []

	if bird and bird.get("genome"):
		weights = bird.genome.genes
		raw_inputs = bird.get_inputs()
		activations = calculate_activations_from_inputs(raw_inputs, weights)

	draw_panel(panel_rect, bird)
	draw_connections(layers, weights, activations)
	draw_nodes(layers, activations)
	draw_layer_labels(layers)
	draw_input_labels(layers[0], activations[0], raw_inputs)
	draw_hidden_labels(layers[1], activations[1])
	draw_output_label(layers[2][0], activations[2][0])
	draw_legend(panel_rect)

func draw_panel(rect: Rect2, bird: Node) -> void:
	draw_rect(rect, PANEL_COLOR, true)
	draw_rect(rect, PANEL_BORDER_COLOR, false, 2.0)

	var font := ThemeDB.fallback_font
	var title := "Best Living Bird Neural Network"
	if not bird:
		title = "Neural Network - waiting for birds"

	draw_string(font, rect.position + Vector2(PANEL_PADDING, 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE + 2, TEXT_COLOR)
	if bird and bird.get("fitness") != null:
		draw_string(font, rect.position + Vector2(PANEL_PADDING, 43), "fitness " + format_number(bird.fitness), HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)

func draw_connections(layers: Array, weights: Array, activations: Array) -> void:
	var weight_index := 0

	for from_index in range(LAYER_COUNTS[0]):
		for to_index in range(LAYER_COUNTS[1]):
			var weight := get_weight(weights, weight_index)
			weight_index += 1
			draw_weight_line(layers[0][from_index], layers[1][to_index], weight, activations[0][from_index])

	for from_index in range(LAYER_COUNTS[1]):
		var weight := get_weight(weights, weight_index)
		weight_index += 1
		draw_weight_line(layers[1][from_index], layers[2][0], weight, activations[1][from_index])

func draw_weight_line(from_pos: Vector2, to_pos: Vector2, weight: float, from_activation: float) -> void:
	var weight_strength: float = clampf(abs(weight), 0.0, 1.0)
	var signal_strength: float = clampf(weight_strength * clampf(from_activation, 0.0, 1.0), 0.0, 1.0)
	var color: Color = IDLE_WEIGHT_COLOR

	if weight > 0.02:
		color = POSITIVE_WEIGHT_COLOR
	elif weight < -0.02:
		color = NEGATIVE_WEIGHT_COLOR

	color.a = lerpf(0.08, 0.68, signal_strength)
	var width: float = lerpf(0.75, 3.4, signal_strength)

	# Draw weak connections very faintly, but make active/important paths stand out.
	if signal_strength > 0.62:
		var glow_color: Color = color
		glow_color.a *= 0.28
		draw_line(from_pos, to_pos, glow_color, width + 3.0)

	draw_line(from_pos, to_pos, color, width)

func draw_nodes(layers: Array, activations: Array) -> void:
	var layer_colors := [INPUT_COLOR, HIDDEN_COLOR, OUTPUT_COLOR]

	for layer_index in range(layers.size()):
		for node_index in range(layers[layer_index].size()):
			var pos: Vector2 = layers[layer_index][node_index]
			var activation: float = clampf(activations[layer_index][node_index], 0.0, 1.0)
			var color: Color = layer_colors[layer_index]
			color = color.lerp(Color.WHITE, activation * 0.22)

			draw_circle(pos + Vector2(2, 3), NODE_RADIUS + 4.0, SHADOW_COLOR)
			draw_circle(pos, NODE_RADIUS + 3.0, NODE_INACTIVE_COLOR)
			draw_circle(pos, NODE_RADIUS * activation, color)
			draw_arc(pos, NODE_RADIUS + 4.0, 0.0, TAU, 32, NODE_RING_COLOR, 1.8)
			draw_activation_bar(pos, activation)

func draw_activation_bar(pos: Vector2, activation: float) -> void:
	var bar_size: Vector2 = Vector2(38, 4)
	var bar_pos: Vector2 = pos + Vector2(-bar_size.x * 0.5, NODE_RADIUS + 10.0)
	draw_rect(Rect2(bar_pos, bar_size), ACTIVATION_BAR_BG, true)
	draw_rect(Rect2(bar_pos, Vector2(bar_size.x * activation, bar_size.y)), Color(1.0, 1.0, 1.0, 0.68), true)

func draw_layer_labels(layers: Array) -> void:
	var font := ThemeDB.fallback_font
	for layer_index in range(layers.size()):
		var top_y: float = layers[layer_index][0].y - 34.0
		var label_pos: Vector2 = Vector2(layers[layer_index][0].x - 34.0, top_y)
		draw_string(font, label_pos, LAYER_LABELS[layer_index], HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)

func draw_input_labels(input_layer: Array, activations: Array, raw_inputs: Array) -> void:
	var font := ThemeDB.fallback_font
	for i in range(input_layer.size()):
		var pos: Vector2 = input_layer[i]
		draw_string(font, pos + Vector2(-9, 4), INPUT_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, TEXT_COLOR)
		draw_string(font, pos + Vector2(-86, 4), INPUT_DESCRIPTIONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)

		var value_text := format_number(activations[i])
		if raw_inputs.size() > i:
			value_text = format_number(raw_inputs[i])
		draw_string(font, pos + Vector2(-83, 18), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, TEXT_COLOR)

func draw_hidden_labels(hidden_layer: Array, activations: Array) -> void:
	var font := ThemeDB.fallback_font
	for i in range(hidden_layer.size()):
		var pos: Vector2 = hidden_layer[i]
		draw_string(font, pos + Vector2(-7, 4), "H" + str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, TEXT_COLOR)
		draw_string(font, pos + Vector2(24, 4), format_number(activations[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)

func draw_output_label(output_pos: Vector2, activation: float) -> void:
	var font := ThemeDB.fallback_font
	var decision := "FLAP" if activation > 0.5 else "WAIT"
	var decision_color := OUTPUT_COLOR if activation > 0.5 else MUTED_TEXT_COLOR

	draw_string(font, output_pos + Vector2(-11, 4), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, TEXT_COLOR)
	draw_string(font, output_pos + Vector2(25, -2), format_number(activation), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
	draw_string(font, output_pos + Vector2(25, 15), decision, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, decision_color)
	draw_string(font, output_pos + Vector2(25, 31), "threshold 0.50", HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)

func draw_legend(panel_rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var base := panel_rect.position + Vector2(panel_rect.size.x - 164.0, 24.0)
	draw_string(font, base, "weights", HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)
	draw_line(base + Vector2(0, 15), base + Vector2(28, 15), POSITIVE_WEIGHT_COLOR, 3.0)
	draw_string(font, base + Vector2(36, 19), "+ helps", HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, TEXT_COLOR)
	draw_line(base + Vector2(0, 33), base + Vector2(28, 33), NEGATIVE_WEIGHT_COLOR, 3.0)
	draw_string(font, base + Vector2(36, 37), "- blocks", HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, TEXT_COLOR)
	draw_string(font, base + Vector2(0, 55), "thicker = stronger active signal", HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, MUTED_TEXT_COLOR)

func get_layer_positions() -> Array:
	var viewport_size: Vector2 = get_viewport_rect().size
	var layer_gap: float = minf(viewport_size.x * 0.19, 178.0)
	var node_gap: float = 43.0
	var total_width: float = float(LAYER_COUNTS.size() - 1) * layer_gap
	var origin: Vector2 = Vector2(
		viewport_size.x * 0.5 - total_width * 0.5,
		viewport_size.y * 0.63
	)
	var layers := []

	for layer_index in range(LAYER_COUNTS.size()):
		var count: int = LAYER_COUNTS[layer_index]
		var layer := []
		var height: float = float(count - 1) * node_gap
		var x: float = origin.x + float(layer_index) * layer_gap

		for node_index in range(count):
			var y: float = origin.y - height * 0.5 + float(node_index) * node_gap
			layer.append(Vector2(x, y))

		layers.append(layer)

	return layers

func get_panel_rect(layers: Array) -> Rect2:
	var min_pos: Vector2 = Vector2(INF, INF)
	var max_pos: Vector2 = Vector2(-INF, -INF)

	for layer: Array in layers:
		for pos: Vector2 in layer:
			min_pos.x = minf(min_pos.x, pos.x)
			min_pos.y = minf(min_pos.y, pos.y)
			max_pos.x = maxf(max_pos.x, pos.x)
			max_pos.y = maxf(max_pos.y, pos.y)

	min_pos += Vector2(-112.0, -70.0)
	max_pos += Vector2(148.0, 76.0)

	return Rect2(min_pos, max_pos - min_pos)

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

func calculate_activations_from_inputs(inputs: Array, weights: Array) -> Array:
	var hidden := []
	var index := 0

	for h in range(LAYER_COUNTS[1]):
		var sum := 0.0
		for i in range(LAYER_COUNTS[0]):
			sum += inputs[i] * get_weight(weights, index)
			index += 1
		hidden.append(sigmoid(sum))

	var output_sum := 0.0
	for h in range(LAYER_COUNTS[1]):
		output_sum += hidden[h] * get_weight(weights, index)
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

func format_number(value: float) -> String:
	return str(snappedf(value, 0.01))

func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))
