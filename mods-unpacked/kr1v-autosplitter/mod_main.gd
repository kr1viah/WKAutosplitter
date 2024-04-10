extends Node

const AUTHORNAME_MODNAME_DIR := "kr1v-autosplitter"
const AUTHORNAME_MODNAME_LOG_NAME := "kr1v-autosplitter:Main"

signal apply_config(config:ModConfig)
signal disable()

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

var oldTokenVar
var tcp_client = StreamPeerTCP.new()
var config
var canSplitOnOrbWeapon = true
var canSplitOnUltraBossWon = true
var canResetInTitle = false
# var amount = 1
var amountOfTimesSplitOnToken = 0
var amountOfTimesSplitOnPerk = 0
var killed_bosses = []
var spawned_bosses = []

func _init() -> void:
	print("func _init() just ran")
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(AUTHORNAME_MODNAME_DIR)
	## Add extensions
	install_script_extensions()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_extension("res://mods-unpacked/kr1v-autosplitter/extensions/src/enemy/boss_virus_ultra/bossVirusUltra.gd")

func _on_current_config_changed(config: ModConfig) -> void:
	if config.mod_id == "kr1v-autosplitter":
		print("config changes")
		apply_config.emit(config) # help

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	config = ModLoaderConfig.get_current_config("kr1v-autosplitter")
	oldTokenVar = Stats.stats.totalTokens
	
	#signals
	Unlocks.sUnlocked.connect(handle_achievement)
	Events.bossSpawned.connect(handle_boss_spawn) # 
	Events.bossKilled.connect(handle_boss_died) #
	Events.runStarted.connect(handle_start) #
	Events.runEnded.connect(handle_game_over)
	Events.perkBought.connect(handle_split_on_perk)
	Events.perkManifested.connect(handle_split_on_perk)
	Events.titleReturn.connect(handle_reset)
	Events.windowBroken.connect(handle_window_broken)
	Events.windowEscaped.connect(handle_escape)
	ModLoader.current_config_changed.connect(_on_current_config_changed)
	
	var error = tcp_client.connect_to_host("127.0.0.1", config.data.portToConnect)
	for n in 60: # connects to livesplit for 60 frames
		if tcp_client.get_status() == tcp_client.STATUS_CONNECTED:
			print("connected to livesplit")
			break
		else: 
			print(tcp_client.get_status())
			tcp_client.poll()
		if n == 59:
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
		print("help somethihng went wring")
	ModLoaderLog.info("Ready!", AUTHORNAME_MODNAME_LOG_NAME)

func _disable():
	Global.disable.emit()

func _process(_delta) -> void:
	if Stats.stats.totalTokens > oldTokenVar && amountOfTimesSplitOnToken < 4 && config.data.splitOnToken:
		oldTokenVar = Stats.stats.totalTokens
		amountOfTimesSplitOnToken += 1
		print("token obtained")
		split()
	# print("func `_process()` got called")
	if Global.ultraUpgrade && config.data.splitOnUltraWeapon && canSplitOnOrbWeapon:
		canSplitOnOrbWeapon = false
		print("ultraUpgrade")
		split()
	if Global.ultraBossWon && canSplitOnUltraBossWon:
		canSplitOnUltraBossWon = false
		print("ultra smiley won")
		split()

## handles with configs
func handle_boss_spawn(node):
	if config.data.splitOnBossSpawn:
		if !spawned_bosses.has(node.get_meta("boss_name")) && config.data.splitOnlyOnFirstBossKill:
			print("hey thats new!")
			spawned_bosses.append(node.get_meta("boss_name"))
			print(spawned_bosses)
			split()
		else: 
			print("already seen this boss! not splitting")

func handle_boss_died(node):
	print("boss fucking died")
	if config.data.splitOnBossKill:
		if !killed_bosses.has(node.get_meta("boss_name")) && config.data.splitOnlyOnFirstBossKill:
			print("hey thats new!")
			killed_bosses.append(node.get_meta("boss_name"))
			print(spawned_bosses)
			split()
		else: 
			print("already seen this boss! not splitting")
	else: print("didnt split")

func handle_ultra_upgrade():
	if config.data.splitOnOrbWeapon:
		print("ultra upgrade gained")
		split()

func handle_escape():
	if config.data.splitOnEscaped:
		print("escaped the window")
		split()
	
func handle_reset():
	if config.data.resetOnDeath || config.data.resetOnExit:
		print("reset")
		reset()

func handle_split_on_perk(_node):
	if config.data.splitOnTokenUpgrade && amountOfTimesSplitOnPerk < 4:
		amountOfTimesSplitOnPerk += 1
		print("perk bought")
		split()
	
func handle_window_broken():
	if config.data.splitOnBrokenWindow:
		print("broken the window")
		split()
	
func handle_ultra_virus_smacked():
	if config.data.splitOnUltraVirusSmacked:
		print("ultra virus smacked")
		split()
	
func handle_achievement(_item):
	if config.data.splitOnAchievement:
		print("oh my god theyre insane (they got an achievement)")
		split()

## other handles
func handle_start():
	amountOfTimesSplitOnPerk = 0
	amountOfTimesSplitOnToken = 0
	oldTokenVar = Stats.stats.totalTokens
	killed_bosses = []
	spawned_bosses = []
	print("started")
	if config.data.resetOnDeath || config.data.resetOnExit:
		print("reset")
		reset()
	canSplitOnOrbWeapon = true
	canSplitOnUltraBossWon = true
	start()

func handle_game_over():
	print("bro really said 'im outta here'")
	if config.data.resetOnDeath:
		handle_reset()
	elif config.data.splitOnDeath:
		split()

## livesplit interaction
func reset() -> void:
	print_debug("reset the fucntion")
	var message = "reset\r\n"
	tcp_client.put_data(message.to_ascii_buffer())
	tcp_client.poll()
	
func split() -> void:
	# print_debug("split the fucntion. amount of times split: ", amount)
	# amount = amount + 1
	var message = "split\r\n"
	tcp_client.put_data(message.to_ascii_buffer())
	tcp_client.poll()
	
func start() -> void:
	print_debug("start the fucntion")
	var message = "starttimer\r\n"
	tcp_client.put_data(message.to_ascii_buffer())
	tcp_client.poll()
