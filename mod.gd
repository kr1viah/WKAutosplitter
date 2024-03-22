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
	var creditser = Label.new()
	
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
		creditser.text = "autosplitter by kr1v

"
		creditser.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		creditser.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		creditser.autowrap_mode = TextServer.AUTOWRAP_OFF
		creditser.label_settings = LabelSettings
		creditser.justification_flags = TextServer.JUSTIFICATION_KASHIDA
		creditser.justification_flags = TextServer.JUSTIFICATION_WORD_BOUND
		creditser.justification_flags = TextServer.JUSTIFICATION_SKIP_LAST_LINE
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
		modUtils.addCustomOptionTab("speedrun")
		modUtils.addCustomToggleOption("", "split on boss spawn", "speedrun", "splitOnSpawn", false)
		modUtils.addCustomToggleOption("", "split on ultra weapon", "speedrun", "splitOnUltraWeapon", false)
		modUtils.addCustomToggleOption("", "split on escape", "speedrun", "splitOnEscape", false)
		modUtils.addCustomToggleOption("useful for 100% speedruns", "reset on death", "speedrun", "resetOnDeath", true)
		modUtils.addCustomToggleOption("useful for 100% speedruns", "reset on exit", "speedrun", "resetOnExit", true)
		modUtils.addCustomToggleOption("useful for death% speedruns", "split on death", "speedrun", "splitOnDeath", false)
		modUtils.bossDied.connect(handle_boss_died)
		modUtils.onMain.connect(handle_start)
		modUtils.onTitle.connect(handle_reset)
		modUtils.bossSpawned.connect(handle_boss_spawn)
		modUtils.onEscape.connect(handle_escape)
			
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
	
	
	func _process(_delta) -> void:
		# print("func `_process()` got called")
		if Global.ultraUpgrade && Global.options["splitOnUltraWeapon"] && canSplitOnOrbWeapon:
			canSplitOnOrbWeapon = false
			print("canSplitOnOrbWeapon being set to false: ", canSplitOnOrbWeapon)
			split()
		if Global.dead:
			if Global.options["resetOnDeath"]:
				handle_reset(Node)
			elif Global.options["splitOnDeath"]:
				split()
		
	func on_new_node(node:Node):
		if node.get_script() != null:
			print("1")
			if node.get_script().get_path() == "res://src/title/panel/creditsScreen.gd":
				print("2")
				if node.get_node("MarginContainer2/ScrollContainer/MarginContainer/credits"):
					var vbox = node.get_node("MarginContainer2/ScrollContainer/MarginContainer")
					vbox.add_child(creditser)
					print("3")
		
		if node.name == "OMmodUtils" and modUtils==null:
			modUtils = node
			postReady()
		elif modUtils==null:
			return
	
	func handle_boss_spawn(node):
		if Global.options["splitOnSpawn"]:
			split()
	
	func handle_ultra_upgrade():
		if Global.options["splitOnOrbWeapon"]:
			split()
	
	func handle_escape(node):
		if Global.options["splitOnEscape"]:
			split()
		
	func handle_reset(node):
		if Global.options["resetOnExit"]:
			reset()
	
	func handle_boss_died(node):
		split()
	
	func handle_start(_node):
		if Global.options["resetOnDeath"]:
			reset()
		start()

		
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
