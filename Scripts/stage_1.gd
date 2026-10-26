extends Node2D

signal stage_complete(surviving_actions: Array[String])
signal stage_failed

@export var fireball_scene: PackedScene

@export var survival_time: float = 60.0
@export var initial_speed: float = 350.0
@export var speed_increase: float = 100.0

@export var min_spawn_intervals: float = 1.0
@export var max_spawn_intervals: float = 2.5

@export var catch_progress_seconds: float = 2.0
@export var progress_lost: float = 5.0


var lane_fireball_y: Array[float] = [190.0, 290.0, 390.0, 490.0]

var catch_progress: float = 0.0

@onready var players: Node2D = $Players
@onready var timer_label: Label = $HUD/TimerPanel/TimerLabel
@onready var countdown_label: Label = $HUD/TimerPanel/CountdownLabel

@onready var catch_progress_bar: ProgressBar = $HUD/CatchProgressBar
@onready var result_label: Label = $HUD/ResultLabel

@export var countdown_duration: float = 5.0
var countdown_remaining: float = 5.0

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

# Random timer for each lane
var lane_spawn_timers: Array[float] = []

var finished: bool = false
var eliminated_count: int = 0

func _ready() -> void:
	game_state = GameState.WAITING
	
	countdown_remaining = countdown_duration
	
	timer_label.hide()
	countdown_label.hide
	
	# Catch progress
	catch_progress = 0.0
	catch_progress_bar.min_value = 0.0
	catch_progress_bar.max_value = 100.0
	catch_progress_bar.value = 0.0
	
	result_label.hide()
	
	# Prepare the transition overlay.
	transition_overlay.visible = true
	transition_overlay.color = Color(0, 0, 0, 0)
	
	for player in players.get_children():
		
		player.joined = false
		player.can_move = false
		
		player.eliminated.connect(_on_player_eliminated)
		
		if player.has_signal("player_downed"):
			player.player_downed.connect(on_player_downed)
		
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
	
func get_surviving_actions() -> Array[String]:
	var actions: Array[String] = []

	for player in players.get_children():
		if player.alive and player.joined and not player.downed:
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
	
	# Every lane has random spawn times
	setup_spawn_timers()

	# Enable movement for all players.
	# The player script still checks whether joined.
	for player in players.get_children():
		player.can_move = true
		
	$Background.scrolling_enabled = true
		
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

func setup_spawn_timers() -> void:
	lane_spawn_timers.clear()
	
	for i in range(lane_fireball_y.size()):
		var random_time: float = randf_range(
			min_spawn_intervals,
			max_spawn_intervals
		)

		lane_spawn_timers.append(random_time)

func update_fireball_spawning(delta: float, current_speed: float) -> void:

	for i in range(lane_fireball_y.size()):

		# Count down this lane's timer.
		lane_spawn_timers[i] -= delta

		# Spawn when the timer reaches zero.
		if lane_spawn_timers[i] <= 0.0:

			spawn_fireball(
				lane_fireball_y[i],
				current_speed
			)

			# Generate a new random delay for this lane.
			lane_spawn_timers[i] = randf_range(
				min_spawn_intervals,
				max_spawn_intervals)
				
func spawn_fireball(lane_y: float, current_speed: float) -> void:

	if fireball_scene == null:
		push_error("Fireball scene is NULL!")
		return

	var fireball = fireball_scene.instantiate()

	add_child(fireball)

	fireball.global_position = Vector2(1104.0, lane_y)
	fireball.speed = current_speed
		
func update_catch_progress(delta: float) -> void:
	catch_progress += catch_progress_seconds * delta
	
	catch_progress = clampf(catch_progress, 0.0, 100.0)
	
	catch_progress_bar.value = catch_progress
	
	if catch_progress >= 100.0:
		dragon_caught()

func update_gameplay(delta: float) -> void:

	elapsed += delta

	# Calculate remaining time.
	var remaining: float = maxf(
		0.0,
		survival_time - elapsed
	)

	timer_label.text = "Dragon escapes in: %02d" % \
		ceili(remaining)

	# Check whether the stage is complete.
	if elapsed >= survival_time:
		dragon_escaped()
		return

	update_catch_progress(delta)
		
	if finished:
		return
		
	# Increase fireball speed over time.
	var current_speed: float = \
		initial_speed + \
		(elapsed / 10.0) * speed_increase

	# Update each lane's independent spawn timer.
	update_fireball_spawning(delta, current_speed)
			
func play_transition() -> void:
	
	# Stop players from moving during the transition.
	stop_gameplay()
	
	# Make sure the transition overlay starts transparent.
	transition_overlay.visible = true
	transition_overlay.color = Color(0, 0, 0, 0)

	# Fade the screen to black.
	var tween = create_tween()
	tween.tween_property(
		transition_overlay,
		"color:a",
		1.0,
		1.0
	)

	# Wait until the fade finishes.
	await tween.finished

	# Switch to Stage 2 with the surviving players.
	stage_complete.emit(get_surviving_actions())
	
func on_player_downed() -> void:
	if finished or game_state != GameState.PLAYING:
		return
		
	catch_progress = maxf(catch_progress - progress_lost, 0.0)
	
	catch_progress_bar.value = catch_progress
	
func dragon_caught() -> void:
	if finished:
		return
		
	finished = true
	
	result_label.text = "Caught Dragon...Time to fight!"
	result_label.show()
	
	stop_gameplay()
	await get_tree().create_timer(2.0).timeout
	play_transition()
	
func dragon_escaped() -> void:
	if finished:
		return
		
	finished = true
	
	result_label.text = "Dragon Escaped!"
	result_label.show()
	
	stop_gameplay()
	await get_tree().create_timer(2.0).timeout

	get_tree().reload_current_scene()
	
func stop_gameplay() -> void:
	for player in players.get_children():
		player.can_move = false
