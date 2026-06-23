# Flappybird AI

A Flappy Bird clone built in **Godot 4.7** where a population of AI-controlled birds learns to survive by evolving simple neural-network genomes over generations.

This project is built from scratch as a learning experiment. It does not use external machine-learning libraries; the genome, brain, population manager, fitness scoring, and neural-network visualizer are implemented directly in GDScript.



https://github.com/user-attachments/assets/a969a26c-2e6f-4da0-9883-4f6626a63f46



## Features

- Flappy Bird-style gameplay made in Godot.
- Population-based AI training.
- Simple feed-forward neural network per bird.
- Genome-based evolution with mutation and crossover.
- Fitness tracking across generations.
- Best-fitness and average-fitness console output.
- Save/load support for learning progress.
- Toggle for saving the best genome.
- Neural-network visualizer showing:
  - Inputs
  - Hidden nodes
  - Output decision
  - Positive and negative weights
  - Activation strength

## Intentional Randomized Training

Training is **randomized and intentionally not deterministic**.

This is a deliberate design choice. Random initialization, random selection, mutation, and pipe placement help keep each training run unique and allow the AI to explore different strategies instead of following the same fixed path every time.

Because of this, results can vary between runs. The same generation number may not always produce the exact same behavior or fitness score, and that is considered a positive part of the experiment.

The project is intended to keep this randomized behavior while improving how consistently fitness increases over generations.

## How the AI Works

Each bird has a small neural network with:

- **4 inputs**
  - Bird height
  - Bird vertical velocity
  - Distance to the next pipe
  - Difference from the pipe gap center
- **6 hidden nodes**
- **1 output**
  - Output above `0.5` means flap
  - Output below or equal to `0.5` means wait

Each bird is assigned a genome containing the network weights. Birds gain fitness by surviving and crossing pipes. When all birds die, the best genomes are selected, crossed over, mutated, and used to create the next generation.

## Current Status

The AI is functional and can learn over generations, but it is still experimental. Fitness improvement is not guaranteed to be smooth every generation because of randomness and the simple evolution strategy.

## Planned Improvements

Future improvements will focus on increasing fitness more consistently per generation, including:

- Better selection strategy.
- Improved mutation tuning.
- More stable fitness rewards.
- Keep randomized training while improving learning stability.
- Better preservation of elite genomes.
- More detailed training statistics.
- Improved neural-network visualization.
- Possible balancing of pipe spacing/speed for smoother learning.

## Running the Project

1. Install **Godot 4.7** or newer compatible Godot 4 version.
2. Clone this repository.
3. Open the project folder in Godot.
4. Run the main scene.
5. Click/tap to start the simulation.

## Project Structure

```text
scenes/      Godot scenes
scripts/     Game, AI, genome, population, and visualizer scripts
sprites/     Game sprites
sfx/         Sound effects
fonts/       Pixel font assets
demo/        Demo video
```

## Disclaimer

This is an ongoing AI/game-development experiment. More improvements will be made over time to make training more stable, increase generation-to-generation fitness gains, and improve the overall learning behavior.
