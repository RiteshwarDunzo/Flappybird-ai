extends Node2D

const INPUT_LINE_COLOR := Color(1.0, 0.05, 0.02, 0.65)
const INPUT_LINE_WIDTH := 1.5
const PIPE_PASSED_MARGIN := 80.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var main = get_tree().current_scene
	if not main or not "pipes" in main:
		return

	for bird in get_children():
		if not bird is Node2D:
			continue
		if bird.get("has_died") == true:
			continue

		var next_gap := get_next_pipe_gap(bird, main.pipes)
		if next_gap == Vector2.INF:
			continue

		var bird_pos := to_local(bird.global_position)
		var gap_pos := to_local(next_gap)
		draw_line(bird_pos, gap_pos, INPUT_LINE_COLOR, INPUT_LINE_WIDTH)

func get_next_pipe_gap(bird: Node2D, pipes: Array) -> Vector2:
	var next_gap := Vector2.INF
	var closest_dx := INF

	for pipe in pipes:
		if not is_instance_valid(pipe):
			continue

		var gap_center: Vector2 = pipe.get_node("Score").global_position
		var dx := gap_center.x - bird.global_position.x
		if dx < -PIPE_PASSED_MARGIN:
			continue
		if dx < closest_dx:
			closest_dx = dx
			next_gap = gap_center

	return next_gap
