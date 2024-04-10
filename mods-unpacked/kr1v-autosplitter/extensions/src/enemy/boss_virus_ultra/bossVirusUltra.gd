extends "res://src/enemy/boss_virus_ultra/bossVirusUltra.gd"
signal bossVirusUltraSmacked

func _ready():
	bossVirusUltraSmacked.connect(ModLoader.get_node("kr1v-autosplitter").handle_ultra_virus_smacked)
	super._ready()

func smack():
	super.smack()
	bossVirusUltraSmacked.emit()

