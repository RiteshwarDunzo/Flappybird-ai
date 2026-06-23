extends Area2D

signal hit(body)



func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die("ground")
	hit.emit(body)
