extends Area2D

signal hit(body)
signal scored(body)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die("pipe")
	hit.emit(body)



func _on_score_body_entered(body: Node2D) -> void:
	if body.get("has_died") == true:
		return

	scored.emit(body)
