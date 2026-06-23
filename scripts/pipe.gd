extends Area2D

signal hit(body)
signal scored(body, counts_for_score)

var has_counted_score := false


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die("pipe")
	hit.emit(body)



func _on_score_body_entered(body: Node2D) -> void:
	if body.get("has_died") == true:
		return

	var counts_for_score := not has_counted_score
	has_counted_score = true
	scored.emit(body, counts_for_score)
