extends Node

@export var stage1_scene: PackedScene
@export var stage2_scene: PackedScene

# Emitted when players successfully defeat the dragon.
signal stage_won

# Emitted when players fail to defeat the dragon.
signal stage_lost

# Stores the currently active stage
var current_stage: Node

func _ready() -> void:
	# Start stage 1 when the game opens
	start_stage1()

func clear_stage() -> void:
	if current_stage != null:
		remove_child(current_stage)
		current_stage.queue_free()
		current_stage = null

func start_stage1() -> void:
	# Remove previous stage if there is one
	clear_stage()

	current_stage = stage1_scene.instantiate()
	add_child(current_stage)
	
	# is stage 1 complete?
	current_stage.stage_complete.connect(on_stage_1_complete)
	# Have all players been eliminated
	current_stage.stage_failed.connect(on_stage_1_failed)
	
func on_stage_1_complete(surviving_actions: Array[String]) -> void:
	
	print("Stage 1 complete!")
	
	#Start stage 2
	start_stage2(surviving_actions)
	
func on_stage_1_failed() -> void:
	
	print("All players defeated by dragon!")
	
	#Restart stage 1
	start_stage1()

func start_stage2(surviving_actions: Array[String]) -> void:
	#Remove stage 1
	clear_stage()

	current_stage = stage2_scene.instantiate()
	add_child(current_stage)
	
	# Which players survived, potentially removing this
	current_stage.set_surviving_players(surviving_actions)
	
	current_stage.stage_won.connect(on_stage_2_won)
	
	current_stage.stage_lost.connect(on_stage_2_lost)
	
func on_stage_2_won() -> void:
	print("Players defeated the dragon!")
	
func on_stage_2_lost() -> void:
	print("Dragon has won")
	
	#Restart from stage 1
	start_stage1()
