extends "GUMM_mod.gd"

func _initialize(scene_tree):
	var spawner = AutoSplitter.new()
	spawner.gumm = self
	scene_tree.root.call_deferred("add_child", spawner)
	

class AutoSplitter extends Node:
	var gumm
	var modUtils
	var path:String
	var modName:String = "autosplitter"
	var tcp_client = StreamPeerTCP.new()
	var error
	var title:Control = null
	#region logic variables
	var amountOfTimesEscaped
	var oldTokenVar = 0
	var canSplitOnPerkBought = true
	#endregion
	var canSplitOnOrbWeapon = true

	func _ready():
		get_tree().node_added.connect(on_new_node)
		for i in get_tree().root.get_children():
			if i.name == "OMmodUtils":
				modUtils = i
				print("found")
		if modUtils == null:return
		postReady()
		
	func postReady():
		#region mod options and signals
		modUtils.addCustomOptionTab("speedrun")
		modUtils.addCustomToggleOption("", "split on boss spawn", "speedrun", "splitOnSpawn", false)
		modUtils.addCustomToggleOption("", "split on ultra weapon", "speedrun", "splitOnUltraWeapon", false)
		modUtils.addCustomToggleOption("", "split on escape", "speedrun", "splitOnBroksplitOnEscape", false)
		modUtils.addCustomToggleOption("", "split on boss fight start", "speedrun", "splitOnBossFightStart", false)
		modUtils.addCustomToggleOption("", "split on token grab", "speedrun", "splitOnTokenGrab", false)
		modUtils.addCustomToggleOption("", "split on perk", "speedrun", "splitOnPerkBought", false)
		modUtils.addCustomToggleOption("useful for 100% speedruns", "reset on death", "speedrun", "resetOnDeath", true)
		modUtils.addCustomToggleOption("useful for 100% speedruns", "reset on exit", "speedrun", "resetOnExit", true)
		modUtils.addCustomToggleOption("useful for death% speedruns", "split on death", "speedrun", "splitOnDeath", false)
		modUtils.onMain.connect(handle_start)
		modUtils.onTitle.connect(handle_reset)
		modUtils.bossSpawned.connect(handle_boss_spawn)
		modUtils.bossDied.connect(handle_boss_death)
		modUtils.onEscape.connect(handle_escape)
		modUtils.upgradeBought.connect(handle_upgradeBought)
		#endregion
		#region connecting to livesplit
		error = tcp_client.connect_to_host("127.0.0.1", 16834)
		for n in 60:
			if tcp_client.get_status() == tcp_client.STATUS_CONNECTED:
				print("connected to livesplit")
				break
			else: 
				print(tcp_client.get_status())
				tcp_client.poll()
			if n == 1:
				print("failed connecting. is the livesplit server running?")
				tcp_client.disconnect_from_host()
			
		if error == OK:
			tcp_client.set_no_delay(true)
			tcp_client.poll()
			var host = tcp_client.get_connected_host()
			var port = tcp_client.get_connected_port()
			var localport = tcp_client.get_local_port()
			var status = tcp_client.get_status()
			print("
host: ", host, "
port: ", port, "
localport: ", localport, "
status: ", status, "
")		
		else:
			print("help somethihng went wring") # <-- if this line runs youve done something wrong
		#endregion
	
	func _process(_delta) -> void:
		# print("func `_process()` got called")
		handle_ultra_upgrade()
		handle_death()
		handle_tokens()
		print(Global.main.windowVel3)
	
	func handle_upgradeBought(_node):
		print("hiiiii")
		if Global.options["splitOnPerkBought"] && canSplitOnPerkBought:
			canSplitOnPerkBought = false
			split()
	func handle_tokens():
		if Global.tokens > oldTokenVar && Global.options["splitOnTokenGrab"]:
			print("its higher!")
			canSplitOnPerkBought = true
			split()
		oldTokenVar = Global.tokens
	func handle_ultra_upgrade():
		if Global.ultraUpgrade && Global.options["splitOnUltraWeapon"] && canSplitOnOrbWeapon:
			canSplitOnOrbWeapon = false
			print("canSplitOnOrbWeapon being set to false: ", canSplitOnOrbWeapon)
			split()
	func handle_death():
		if Global.dead:
			if Global.options["resetOnDeath"]:
				handle_reset(Node)
			elif Global.options["splitOnDeath"]:
				split()
	func on_new_node(node:Node):
		if node.name == "OMmodUtils" and modUtils==null:
			modUtils = node
			postReady()
		elif modUtils==null:
			return
		#region handeling different events that happen in the game
	func handle_boss_spawn(_node):
		if Global.options["splitOnSpawn"]:
			split()
	
	func handle_escape(_node):
		if Global.options["splitOnEscape"] && amountOfTimesEscaped < 1:
			split()
			amountOfTimesEscaped =+ 1
		elif Global.options["splitOnBossFightStart"]:
			split()
			amountOfTimesEscaped =+ 1
	
	func handle_reset(_node):
		if Global.options["resetOnExit"]:
			reset()
	
	func handle_boss_death(_node):
		split()
	
	func handle_start(_node):
		if Global.options["resetOnDeath"]:
			reset()
		start()
		amountOfTimesEscaped = 0
	#endregion
		#region interacting with livesplit
	func reset() -> void:
		tcp_client.poll()
		print(error.poll())
		var message = "reset\r\n"
		tcp_client.put_data(message.to_ascii_buffer())
		tcp_client.poll()
		
	func split() -> void:
		tcp_client.poll()
		print(error.poll())
		var message = "split\r\n"
		tcp_client.put_data(message.to_ascii_buffer())
		tcp_client.poll()
		
	func start() -> void:
		tcp_client.poll()
		print(error.poll())
		var message = "starttimer\r\n"
		tcp_client.put_data(message.to_ascii_buffer())
		tcp_client.poll()
	#endregion
