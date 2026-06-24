extends Node
class_name RedButtonSystem

signal choice_required(effects)

var effects: Array = []
var safe_triggers = 0
const SAFE_TRIGGERS_PER_RUN = 1

func setup(config) -> void:
	effects = config.create_red_button_effects()
	safe_triggers = 0

func reset_for_run() -> void:
	safe_triggers = 0

func begin_trigger(_hero_hp_ratio: float) -> void:
	# Full rage is a decision point, not a hidden instant-loss test.
	if safe_triggers >= SAFE_TRIGGERS_PER_RUN:
		return
	choice_required.emit(effects)

func mark_safe_trigger_used() -> void:
	safe_triggers = min(SAFE_TRIGGERS_PER_RUN, safe_triggers + 1)

func safe_triggers_left() -> int:
	return max(0, SAFE_TRIGGERS_PER_RUN - safe_triggers)
