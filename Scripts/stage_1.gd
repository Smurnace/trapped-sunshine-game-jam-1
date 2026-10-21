extends Node2D

signal stage_complete(surviving_actions: Array[String])
signal stage_failed

@export var fireball_scene: PackedScene
@export var survival_time: float = 60.0
@export var initial_speed: float = 350.0
@export var speed_increase: float = 100.0
@export var spawn_interval: float = 1.5

@export var lane_spawn_intervals: Array[float] = [1.8, 1.5, 1.3, 1.6]

var lane_fireball_y: Array[float] = [112.0, 240.0, 368.0, 496.0]

@onready var players: Node = $Players
@onready var timer_label: Label = $HUD/TimerLabel

var elapsed: float = 0.0
var lane_spawn_elapsed: Array[float] = [0.0, 0.0, 0.0, 0.0]
var finished: bool = false
var eliminated_count: int = 0

func _ready() -> void:
	for player in players.get_children():
		player.eliminated.connect(_on_player_eliminated)
		

func _on_player_eliminated() -> void:
	eliminated_count += 1

	var total_players: int = players.get_child_count()

	if eliminated_count >= total_players and not finished:
		finished = true
		stage_failed.emit()




func _process(delta: float) -> void:
	if finished:
		return
	
	elapsed += delta

	# Update the survival timer
	var remaining = max(0.0, survival_time - elapsed)
	timer_label.text = "SURVIVE: %02d" % ceili(remaining)

	# Calculate fireball speed
	var current_speed: float = initial_speed + (elapsed / 10.0) * speed_increase

	# Update each lane's independent spawn timer
	for i in range(lane_fireball_y.size()):
		lane_spawn_elapsed[i] += delta

		if lane_spawn_elapsed[i] >= lane_spawn_intervals[i]:
			lane_spawn_elapsed[i] = 0.0
			spawn_fireball(lane_fireball_y[i], current_speed)

	# Stage complete
	if elapsed >= survival_time:
		finished = true
		play_transition()

func spawn_fireball(lane_y: float, current_speed: float) -> void:
	print("Fireball scene: ", fireball_scene)

	if fireball_scene == null:
		push_error("Fireball scene is NULL!")
		return
	
	# Spawn one fireball on every players lane
	var fireball = fireball_scene.instantiate()
	add_child(fireball)
		
	fireball.global_position = Vector2(1104.0, lane_y)
	fireball.speed = current_speed
	print("Spawned fireball at: ", fireball.global_position)
	

func get_surviving_actions() -> Array[String]:
	var actions: Array[String] = []

	for player in players.get_children():
		if player.alive:
			actions.append(player.mash_action)

	return actions
	

func play_transition() -> void:
	var overlay: ColorRect = $HUD/TransitionOverlay

	overlay.visible = true
	overlay.color = Color(0, 0, 0, 0)

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)

	await tween.finished

	stage_complete.emit(get_surviving_actions())
