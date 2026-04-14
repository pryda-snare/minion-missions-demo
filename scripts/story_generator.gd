extends RefCounted
class_name StoryGenerator

var event_fragments: Dictionary = {}

func _init(event_data: Dictionary) -> void:
	event_fragments = event_data

func build_story(minion: Dictionary, mission: Dictionary, result: Dictionary, day: int) -> String:
	var intro := "%s returned from %s." % [minion["name"], mission["town_name"]]
	var action_line := "%s took on a %s mission in a %s town." % [
		minion["name"],
		String(mission["type"]).to_lower(),
		mission["mood"]
	]
	var twist := _pick_fragment("twists", "They found an unexpected turn.")
	var tone_key := "%s_lines" % result["outcome"]
	var outcome_line := _pick_fragment(tone_key, _default_outcome_line(result["outcome"]))
	var reward_line := "Reward: %+d gold, %+d reputation." % [result["gold_delta"], result["reputation_delta"]]
	return "[Day %d] %s %s %s %s %s" % [
		day,
		intro,
		action_line,
		twist,
		outcome_line,
		reward_line
	]

func _pick_fragment(key: String, fallback: String) -> String:
	if not event_fragments.has(key):
		return fallback
	var choices: Array = event_fragments[key]
	if choices.is_empty():
		return fallback
	return choices.pick_random()

func _default_outcome_line(outcome: String) -> String:
	match outcome:
		"success":
			return "Everything went better than expected."
		"partial":
			return "The mission was messy, but still worthwhile."
		_:
			return "The town resisted, and the mission stumbled."
