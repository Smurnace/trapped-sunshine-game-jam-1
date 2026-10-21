extends Node

@export var stage1_scene: PackedScene
@export var stage2_scene: PackedScene

var current_stage: Node

func _ready() -> void:
	start_stage1()

func clear_stage() -> void:
	if current_stage != null:
		remove_child(current_stage)
		current_stage.queue_free()
		current_stage = null

func start_stage1() -> void:
	clear_stage()

	current_stage = stage1_scene.instantiate()
	add_child(current_stage)

	current_stage.stage_complete.connect(start_stage2)
	current_stage.stage_failed.connect(restart_game)

func start_stage2(surviving_actions: Array[String]) -> void:
	clear_stage()

	current_stage = stage2_scene.instantiate()
	add_child(current_stage)
	
	current_stage.set_surviving_players(surviving_actions)
	current_stage.victory.connect(on_victory)
	current_stage.failure.connect(restart_game)

func restart_game() -> void:
	start_stage1()

func on_victory() -> void:
	print("Congratulations! The party defeated the dragon!")
