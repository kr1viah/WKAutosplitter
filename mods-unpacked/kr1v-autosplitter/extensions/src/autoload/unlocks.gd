extends "res://src/autoload/unlocks.gd"
signal achievement_unlocked
var keysGotten = []
# This overrides the method with the same name, changing the value of its argument:
func _process(Variant) -> void:
	for key in items.keys():
		if items[key].unlocked && !keysGotten.has(key): 
			keysGotten.append(key)
			achievement_unlocked.emit()
	
	super._process(Variant)
