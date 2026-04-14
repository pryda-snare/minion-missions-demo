extends SceneTree

## Headless smoke test: load Main, dispatch one mission, advance days until it resolves.
## Run: godot --headless --path "<project>" --script res://tools/smoke_test.gd
##
## Uses call_deferred (not await process_frame) so headless CI runners advance reliably.

func _initialize() -> void:
	_begin.call_deferred()


func _begin() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	var main: Node = packed.instantiate()
	root.add_child(main)
	_run_checks.call_deferred(main)


func _run_checks(main: Node) -> void:
	var available: Array = main.available_missions
	if available.is_empty():
		push_error("smoke: no available missions")
		quit(1)
		return

	var mission: Dictionary = available[0]
	var duration: int = int(mission["duration"])
	var active_before: int = main.active_missions.size()

	main._dispatch_to_mission(mission)

	if main.active_missions.size() != active_before + 1:
		push_error("smoke: dispatch did not append active mission")
		quit(1)
		return

	for _i in range(duration):
		main._on_advance_day_pressed()

	for j in main.minions.size():
		if not main.minions[j]["available"]:
			push_error("smoke: minion %d still unavailable after resolution" % j)
			quit(1)
			return

	if not main.active_missions.is_empty():
		push_error("smoke: active missions not empty after advances")
		quit(1)
		return

	if main.story_entries.size() < 2:
		push_error("smoke: expected opening story plus at least one return story")
		quit(1)
		return

	print("smoke_test: ok")
	quit(0)
