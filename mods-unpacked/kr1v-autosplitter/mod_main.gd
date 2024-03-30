extends Node

const AUTHORNAME_MODNAME_DIR := "kr1v-autosplitter"
const AUTHORNAME_MODNAME_LOG_NAME := "kr1v-autosplitter:Main"


var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

var Global1:Node
var oldTokenVar
var tcp_client = StreamPeerTCP.new()
var error
var config
var canSplitOnOrbWeapon = true
var canSplitOnUltraBossWon = true
var canResetInTitle = false
var amount = 0

func _init() -> void:
	print("func _init() just ran")
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(AUTHORNAME_MODNAME_DIR)
	## Add extensions
	#install_script_extensions()
	
	## Add global script
	Global1 = load("res://mods-unpacked/kr1v-autosplitter/global.gd").new()
	Global1.name = "Global"
	add_child(Global1)
	
	postinit()
	
func postinit():
	pass
func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_extension("res://mods-unpacked/kr1v-autosplitter/extensions/src/autoload/global.gd")
	#ModLoaderMod.install_script_extension("res://mods-unpacked/kr1v-autosplitter/extensions/src/element/power_token/powerToken.gd")

func _on_current_config_changed(config: ModConfig) -> void:
	if config.mod_id == "kr1v-autosplitter":
		print("config changes")
		Global1.apply_config.emit(config) # help

func _ready() -> void:
	config = ModLoaderConfig.get_current_config("kr1v-autosplitter")
	
	oldTokenVar = Stats.stats.totalTokens
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.bossSpawned.connect(handle_boss_spawn) # 
	Events.bossKilled.connect(handle_boss_died) #
	Events.runStarted.connect(handle_start) #
	Events.runEnded.connect(handle_game_over)
	Events.perkBought.connect(handle_split_on_perk)
	Events.titleReturn.connect(handle_reset)
	Events.windowBroken.connect(handle_window_broken)
	Events.windowEscaped.connect(handle_escape)
	ModLoader.current_config_changed.connect(_on_current_config_changed)
	
	ModLoaderLog.info("Ready!", AUTHORNAME_MODNAME_LOG_NAME)
	
	error = tcp_client.connect_to_host("127.0.0.1", config.data.portToConnect)
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
		print("help somethihng went wring") # <-- if this line runs youve done something wrong, liek verty veri wrong





func _disable():
	Global.disable.emit()

func _process(_delta) -> void:
	if Stats.stats.totalTokens > oldTokenVar && config.data.splitOnToken:
		oldTokenVar = Stats.stats.totalTokens
		print("token obtained")
		split()
	# print("func `_process()` got called")
	if Global.ultraUpgrade && config.data.splitOnUltraWeapon && canSplitOnOrbWeapon:
		canSplitOnOrbWeapon = false
		print("ultraUpgrade")
		split()
	if Global.ultraBossWon && canSplitOnUltraBossWon:
		canSplitOnUltraBossWon = false
		print("ultra bios won")
		split()


## handles with configs
func handle_boss_spawn(_node):
	if config.data.splitOnBossSpawn:
		split()

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
	if config.data.splitOnTokenUpgrade:
		print("perk bought")
		split()
		
func handle_window_broken():
	if config.data.splitOnBrokenWindow:
		print("broken the window")
		split()

func handle_boss_died(_node):
	print("boss fucking died")
	split()

func handle_start():
	oldTokenVar = Stats.stats.totalTokens
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


func reset() -> void:
	print_debug("reset the fucntion")
	var message = "reset\r\n"
	tcp_client.put_data(message.to_ascii_buffer())
	tcp_client.poll()
	
func split() -> void:
	print_debug("split the fucntion. amount of times split: ", amount)
	amount = amount + 1
	var message = "split\r\n"
	tcp_client.put_data(message.to_ascii_buffer())
	tcp_client.poll()
	
func start() -> void:
	print_debug("start the fucntion")
	var message = "starttimer\r\n"
	tcp_client.put_data(message.to_ascii_buffer())
	tcp_client.poll()
