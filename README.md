# Minion Missions Demo (Godot 2D, Mostly Text-Based)

A lightweight Godot prototype that showcases a text-first gameplay loop:

1. Dispatch minions on missions to nearby towns.
2. Advance the day.
3. Read story-driven reports when minions return.

## Run

1. Open Godot.
2. Import project at `minion-missions-demo/`.
3. Run the main scene (`res://scenes/Main.tscn`).

## Gameplay Loop

- Use **Dispatch** buttons to assign available minions.
- Press **Advance Day** to process time.
- Returning minions generate narrative log entries with rewards and outcomes.

## Project Structure

- `project.godot`: project config and run scene.
- `scenes/Main.tscn`: single UI scene.
- `scripts/main.gd`: game state, UI wiring, day progression.
- `scripts/mission_system.gd`: mission generation and resolution math.
- `scripts/story_generator.gd`: template-based mission return stories.
- `data/towns.json`: nearby towns.
- `data/events.json`: story fragments by outcome.

## Extension Ideas

- Add named mission chains per town.
- Add minion traits that unlock unique story outcomes.
- Add save/load for campaign persistence.
- Add simple portraits/icons while keeping text-first gameplay.
