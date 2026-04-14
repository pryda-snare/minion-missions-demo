extends RefCounted
class_name MissionSystem

var towns: Array = []
var mission_types: Array = ["Scout", "Gather", "Negotiate", "Guard"]

func _init(town_data: Array) -> void:
	towns = town_data.duplicate(true)

func generate_missions(day: int) -> Array:
	var missions: Array = []
	for town in towns:
		var risk_roll := randi_range(1, 3)
		var reward_base := 8 + day + (risk_roll * 2)
		var mission_type: String = mission_types.pick_random()
		var mission := {
			"id": "%s_%s_%d" % [town["id"], mission_type.to_lower(), day],
			"town_id": town["id"],
			"town_name": town["name"],
			"mood": town["mood"],
			"type": mission_type,
			"risk": risk_roll,
			"duration": 1 + int(randi() % 2),
			"reward": reward_base
		}
		missions.append(mission)
	return missions

func resolve_mission(minion: Dictionary, mission: Dictionary) -> Dictionary:
	var power: int = int(minion["cunning"]) + int(minion["charm"]) + int(minion["grit"])
	var target: int = 10 + (int(mission["risk"]) * 3)
	var roll := randi_range(1, 12) + int(power / 2)
	var outcome := "partial"
	if roll >= target + 3:
		outcome = "success"
	elif roll <= target - 3:
		outcome = "failure"

	var gold_delta := 0
	var reputation_delta := 0
	match outcome:
		"success":
			gold_delta = mission["reward"]
			reputation_delta = 2
		"partial":
			gold_delta = int(mission["reward"] / 2)
			reputation_delta = 1
		"failure":
			gold_delta = max(1, int(mission["reward"] / 4))
			reputation_delta = -1

	return {
		"outcome": outcome,
		"roll": roll,
		"target": target,
		"gold_delta": gold_delta,
		"reputation_delta": reputation_delta
	}
