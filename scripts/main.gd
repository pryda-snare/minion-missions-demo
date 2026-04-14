extends Control

const MissionSystemScript = preload("res://scripts/mission_system.gd")
const StoryGeneratorScript = preload("res://scripts/story_generator.gd")

@onready var day_label: Label = $"RootMargin/RootColumns/RosterPanel/RosterMargin/RosterVBox/DayLabel"
@onready var resources_label: Label = $"RootMargin/RootColumns/RosterPanel/RosterMargin/RosterVBox/ResourcesLabel"
@onready var minion_list: RichTextLabel = $"RootMargin/RootColumns/RosterPanel/RosterMargin/RosterVBox/MinionList"
@onready var mission_rows: VBoxContainer = $"RootMargin/RootColumns/MissionPanel/MissionMargin/MissionVBox/MissionRows"
@onready var mission_info_label: Label = $"RootMargin/RootColumns/MissionPanel/MissionMargin/MissionVBox/MissionInfoLabel"
@onready var story_log: RichTextLabel = $"RootMargin/RootColumns/StoryPanel/StoryMargin/StoryVBox/StoryLog"
@onready var advance_day_button: Button = $"RootMargin/RootColumns/RosterPanel/RosterMargin/RosterVBox/AdvanceDayButton"

var day: int = 1
var gold: int = 20
var reputation: int = 0

var towns: Array = []
var minions: Array = []
var active_missions: Array = []
var available_missions: Array = []
var story_entries: Array = []

var mission_system: MissionSystem
var story_generator: StoryGenerator

func _ready() -> void:
	randomize()
	_load_data()
	_init_minions()
	mission_system = MissionSystemScript.new(towns)
	story_generator = StoryGeneratorScript.new(_load_event_data())
	available_missions = mission_system.generate_missions(day)
	advance_day_button.pressed.connect(_on_advance_day_pressed)
	_refresh_ui()
	_append_story("[Day 1] The guild opens its doors. Your minions await orders.")

func _load_data() -> void:
	var towns_file := FileAccess.open("res://data/towns.json", FileAccess.READ)
	if towns_file:
		var parsed = JSON.parse_string(towns_file.get_as_text())
		if parsed is Array:
			towns = parsed
	if towns.is_empty():
		towns = [
			{"id": "brambleford", "name": "Brambleford", "mood": "wary"},
			{"id": "sunhollow", "name": "Sunhollow", "mood": "hopeful"},
			{"id": "ironmere", "name": "Ironmere", "mood": "tense"}
		]

func _load_event_data() -> Dictionary:
	var events_file := FileAccess.open("res://data/events.json", FileAccess.READ)
	if events_file:
		var parsed = JSON.parse_string(events_file.get_as_text())
		if parsed is Dictionary:
			return parsed
	return {}

func _init_minions() -> void:
	minions = [
		{"id": "mara", "name": "Mara", "role": "Scout", "cunning": 4, "charm": 2, "grit": 3, "available": true},
		{"id": "bix", "name": "Bix", "role": "Porter", "cunning": 2, "charm": 3, "grit": 4, "available": true},
		{"id": "siva", "name": "Siva", "role": "Speaker", "cunning": 3, "charm": 5, "grit": 2, "available": true}
	]

func _on_advance_day_pressed() -> void:
	day += 1
	_resolve_returning_missions()
	available_missions = mission_system.generate_missions(day)
	_refresh_ui()

func _resolve_returning_missions() -> void:
	var still_out: Array = []
	for assignment in active_missions:
		assignment["days_left"] -= 1
		if assignment["days_left"] > 0:
			still_out.append(assignment)
			continue

		var minion_idx: int = assignment["minion_index"]
		var mission: Dictionary = assignment["mission"]
		var minion: Dictionary = minions[minion_idx]
		var result: Dictionary = mission_system.resolve_mission(minion, mission)
		gold += result["gold_delta"]
		reputation += result["reputation_delta"]
		minions[minion_idx]["available"] = true
		var story := story_generator.build_story(minions[minion_idx], mission, result, day)
		_append_story(story)

	active_missions = still_out

func _refresh_ui() -> void:
	day_label.text = "Day %d" % day
	resources_label.text = "Gold: %d | Reputation: %d" % [gold, reputation]
	_refresh_minion_panel()
	_refresh_mission_buttons()

func _refresh_minion_panel() -> void:
	var lines: Array[String] = []
	for minion in minions:
		var state := "available" if minion["available"] else "on mission"
		var line := "[b]%s[/b] (%s) - C:%d Ch:%d G:%d - [i]%s[/i]" % [
			minion["name"],
			minion["role"],
			minion["cunning"],
			minion["charm"],
			minion["grit"],
			state
		]
		lines.append(line)
	minion_list.text = "\n".join(lines)

func _refresh_mission_buttons() -> void:
	for child in mission_rows.get_children():
		child.queue_free()

	for mission in available_missions:
		var h := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s | %s | risk %d | %d day(s) | reward %d" % [
			mission["town_name"],
			mission["type"],
			mission["risk"],
			mission["duration"],
			mission["reward"]
		]
		h.add_child(label)

		var button := Button.new()
		button.text = "Dispatch"
		button.pressed.connect(func() -> void: _dispatch_to_mission(mission))
		h.add_child(button)
		mission_rows.add_child(h)

func _dispatch_to_mission(mission: Dictionary) -> void:
	var idx := _next_available_minion_index()
	if idx == -1:
		mission_info_label.text = "No available minions. Advance day or wait for returns."
		return

	minions[idx]["available"] = false
	active_missions.append({
		"minion_index": idx,
		"mission": mission.duplicate(true),
		"days_left": mission["duration"]
	})
	available_missions.erase(mission)
	mission_info_label.text = "%s dispatched to %s." % [minions[idx]["name"], mission["town_name"]]
	_refresh_ui()

func _next_available_minion_index() -> int:
	for i in minions.size():
		if minions[i]["available"]:
			return i
	return -1

func _append_story(entry: String) -> void:
	story_entries.append(entry)
	story_log.text = "\n\n".join(story_entries)
