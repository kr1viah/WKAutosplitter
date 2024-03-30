extends "res://src/element/power_token/powerToken.gd"

# This overrides the method with the same name, changing the value of its argument:
func hit(body:Node2D):
	print_debug("i'm pwoer token lol")
	super.hit(body)
