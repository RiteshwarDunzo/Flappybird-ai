extends RefCounted

class_name Genome

var genes = []
var fitness := 0.0

func _init(size):

	for i in range(size):
		genes.append(
			randf_range(-1.0, 1.0)
		)
