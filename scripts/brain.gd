extends Node

class_name Brain

var genes = []

func _init():
	for i in range(30):
		genes.append(randf_range(-1.0, 1.0))

func sigmoid(x):
	return 1.0 / (1.0 + exp(-x))

func predict(inputs):
	print(inputs)
	var hidden = []

	var index = 0

	for h in range(6):

		var sum = 0.0

		for i in range(4):
			sum += inputs[i] * genes[index]
			index += 1

		hidden.append(sigmoid(sum))

	var output = 0.0

	for h in range(6):
		output += hidden[h] * genes[index]
		index += 1

	return sigmoid(output)
