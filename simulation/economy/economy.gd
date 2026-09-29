class_name Economy
extends RefCounted
## Gold ledger. Gold is the only currency and never goes negative.

var _events: SimEvents
var _gold: int = 0


func _init(events: SimEvents, starting_gold: int) -> void:
	_events = events
	_gold = maxi(starting_gold, 0)


func get_gold() -> int:
	return _gold


func can_afford(cost: int) -> bool:
	return cost >= 0 and _gold >= cost


## Spends `cost` gold. Returns false and changes nothing if the cost is negative or unaffordable.
func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	_gold -= cost
	_events.gold_changed.emit(_gold, -cost)
	return true


## Adds `amount` gold. Returns false and changes nothing if the amount is negative.
func grant(amount: int) -> bool:
	if amount < 0:
		return false
	_gold += amount
	_events.gold_changed.emit(_gold, amount)
	return true
