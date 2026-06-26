extends Node
class_name RageSystem

signal rage_changed(value)
signal rage_full()

var rage = 0.0
var full_locked = false

func reset_for_run() -> void:
	rage = 0.0
	full_locked = false
	rage_changed.emit(rage)

func reset_to(value: float) -> void:
	rage = clamp(value, 0.0, 100.0)
	full_locked = false
	rage_changed.emit(rage)

func process_battle(delta: float, wave_time: float, hero_near_commander: bool) -> void:
	var gain = 1.6 + wave_time * 0.018
	if hero_near_commander:
		gain += 4.4
	add(gain * delta)

func add(amount: float) -> void:
	if amount <= 0.0:
		return
	rage = clamp(rage + amount, 0.0, 100.0)
	rage_changed.emit(rage)
	if rage >= 100.0 and not full_locked:
		full_locked = true
		rage_full.emit()

func reduce(amount: float) -> void:
	if amount <= 0.0:
		return
	rage = clamp(rage - amount, 0.0, 100.0)
	rage_changed.emit(rage)
