# Our base script is the original game script.
extends "res://src/autoload/global.gd"

# This overrides the method with the same name, changing the value of its argument:
func _ready():
	super._ready()
	
	print_debug("i'm global.gd lol")
