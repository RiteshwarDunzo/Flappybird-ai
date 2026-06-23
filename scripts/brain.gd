extends Node

class_name Brain

var genome : Genome

func _init(g : Genome):
	genome = g
	
func sigmoid(x):
	return 1.0 / (1.0 + exp(-x))

func predict(inputs):
	var hidden = []

	var index = 0

	for h in range(6):

		var sum = 0.0

		for i in range(4):
			sum += inputs[i] * genome.genes[index]
			index += 1

		hidden.append(sigmoid(sum))

	var output = 0.0

	for h in range(6):
		output += hidden[h] * genome.genes[index]
		index += 1

	return sigmoid(output)
