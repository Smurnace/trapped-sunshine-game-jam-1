extends Node2D

signal stage_complete(surviving_actions: Array[String])
signal stage_failed

@export var fireball_scene: PackedScene
@export var survival_time: float = 60.0
@export var initial_speed: float = 350.0
@export var speed_increase: float = 100.0
@export var spawn_interval: float = 1.5

@export var lane_spawn_intervals: Array[float] = [1.8, 1.5, 1.3, 1.6]

var lane_fireball_y: Array[float] = [100.0, 230.0, 360.0, 490.0]

@onready var players: Node2D = $Players
@onready var timer_label: Label = $HUD/TimerPanel/TimerLabel
@onready var countdown_label: Label = $HUD/TimerPanel/CountdownLabel

@export var countdown_duration: float = 5.0
var countdown_remaining: float = 5.0

@onready var camera: Camera2D = $Camera2D

@onready var transition_overlay: ColorRect = \
	$HUD/TransitionOverlay
	
@onready var join_labels: Array[Label] = [
	$HUD/JoinLabels/P1JoinLabel,
	$HUD/JoinLabels/P2JoinLabel,
	$HUD/JoinLabels/P3JoinLabel,
	$HUD/JoinLabels/P4JoinLabel
]

enum GameState {WAITING, COUNTDOWN, PLAYING}

var game_state: GameState = GameState.WAITING

var elapsed: float = 0.0

# Timer for each lane
var lane_spawn_elapsed: Array[float] = [0.0, 0.0, 0.0, 0.0]
var finished: bool = false
var eliminated_count: int = 0

func _ready() -> void:
	game_state = GameState.WAITING
	
	countdown_remaining = countdown_duration
	
	timer_label.hide()
	countdown_label.hide
	
	# Prepare the transition overlay.
	transition_overlay.visible = true
	transition_overlay.color = Color(0, 0, 0, 0)
	
	for player in players.get_children():
		
		player.joined = false
		player.can_move = false
		
		player.eliminated.connect(_on_player_eliminated)
		
	update_join_labels()

func _on_player_eliminated() -> void:
	eliminated_count += 1
	
	update_join_labels()

	var total_players: int = players.get_child_count()

	if eliminated_count >= total_players and not finished:
		finished = true
		stage_failed.emit()

func _process(delta: float) -> void:
	if finished:
		return
		
	check_players_join()
	
	match game_state:
		GameState.WAITING:
			return
			
		GameState.COUNTDOWN:
			update_countdown(delta)
			return
		
		GameState.PLAYING:
			update_gameplay(delta)
	
	#elapsed += delta

	# Update the survival timer
	#var remaining = max(0.0, survival_time - elapsed)
	#timer_label.text = "SURVIVE: %02d" % ceili(remaining)

	# Calculate fireball speed
	#var current_speed: float = initial_speed + (elapsed / 10.0) * speed_increase

	# Update each lane's independent spawn timer
	#for i in range(lane_fireball_y.size()):
		#lane_spawn_elapsed[i] += delta

		#if lane_spawn_elapsed[i] >= lane_spawn_intervals[i]:
			#lane_spawn_elapsed[i] = 0.0
			#spawn_fireball(lane_fireball_y[i], current_speed)

	# Stage complete
	#if elapsed >= survival_time:
		#finished = true
		#play_transition()

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
		if player.alive and player.joined:
			actions.append(player.mash_action)

	return actions
	
	
func check_players_join() ->  void:
	var player_list = players.get_children()
	
	for i in range(player_list.size()):
		var player = player_list[i]
		
		if not player.alive or player.joined:
			continue
		
		if Input.is_action_just_pressed(player.jump_action):
		
			player.joined = true
			player.health_bar.show()
		
			update_join_labels()
		
			if game_state == GameState.WAITING:
				start_countdown()
				
func start_countdown() -> void:
	game_state = GameState.COUNTDOWN

	countdown_remaining = countdown_duration

	countdown_label.show()

	update_countdown_label()

func update_countdown(delta: float) -> void:

	countdown_remaining -= delta

	update_countdown_label()

	if countdown_remaining <= 0.0:
		start_game()

func update_countdown_label() -> void:

	countdown_label.text = "STARTING IN %d" % \
		ceili(maxf(countdown_remaining, 0.0))
		

func start_game() -> void:

	game_state = GameState.PLAYING

	countdown_label.hide()
	timer_label.show()

	elapsed = 0.0

	# Enable movement for all players.
	# The player script still checks whether joined.
	for player in players.get_children():
		player.can_move = true
		

func update_join_labels() -> void:

	var player_list = players.get_children()
	

	for i in range(player_list.size()):

		var player = player_list[i]
		var label: Label = join_labels[i]

		if not player.alive:

			label.text = "DOWNED"
			label.show()

		elif player.joined:
			join_labels[i].text = "READY!"
			label.hide()

		else:

			join_labels[i].text = "PRESS BUTTON TO JOIN"
			label.show()
			

func update_gameplay(delta: float) -> void:

	elapsed += delta

	# Calculate remaining time.
	var remaining: float = maxf(
		0.0,
		survival_time - elapsed
	)

	timer_label.text = "SURVIVE: %02d" % \
		ceili(remaining)

	# Check whether the stage is complete.
	if elapsed >= survival_time:

		finished = true

		play_transition()
		return

	# Increase fireball speed over time.
	var current_speed: float = \
		initial_speed + \
		(elapsed / 10.0) * speed_increase

	# Update each lane's independent spawn timer.
	for i in range(lane_fireball_y.size()):

		lane_spawn_elapsed[i] += delta

		if lane_spawn_elapsed[i] >= \
			lane_spawn_intervals[i]:

			lane_spawn_elapsed[i] = 0.0

			spawn_fireball(
				lane_fireball_y[i],
				current_speed
			)
	
func play_transition() -> void:

	# Find all surviving players.
	var survivors: Array[Node] = []

	for player in players.get_children():

		if player.alive and player.joined:

			survivors.append(player)

	# If nobody survived, restart.
	if survivors.is_empty():

		stage_failed.emit()
		return

	# Freeze all player movement.
	for player in players.get_children():

		player.can_move = false

	# Stop existing fireballs from interfering
	# with the cinematic transition.
	for child in get_children():

		if child is Area2D:
			child.queue_free()

	# Calculate the centre of the survivors.
	var centre := Vector2.ZERO

	for player in survivors:

		centre += player.global_position

	centre /= survivors.size()

	# Animate camera movement and zoom.
	var camera_tween := create_tween()

	camera_tween.set_parallel(true)

	camera_tween.tween_property(
		camera,
		"global_position",
		centre,
		0.8
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_IN_OUT
	)

	camera_tween.tween_property(
		camera,
		"zoom",
		Vector2(1.8, 1.8),
		0.8
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await camera_tween.finished

	# Fade the screen to black.
	transition_overlay.visible = true
	transition_overlay.color = Color(0, 0, 0, 0)

	var fade_tween := create_tween()

	fade_tween.tween_property(
		transition_overlay,
		"color:a",
		1.0,
		0.4
	)

	await fade_tween.finished

	# Begin Stage 2 with surviving players.
	stage_complete.emit(
		get_surviving_actions()
	)
	
