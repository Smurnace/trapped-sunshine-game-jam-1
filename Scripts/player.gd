extends CharacterBody2D
signal eliminated
signal player_downed

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var downed_label: Label = $DownedLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var jump_action: String = "jump_p1"
@export var mash_action: String = "mash_p1"
@export var run_animation: String = "red_run"

@export var max_hp: int = 3
@export var revive_per_press: float = 10

@export var jump_strength: float = -450.0
@export var gravity: float = 1200.0

@export var player_texture: Texture2D
@export var invulnerability_duration: float = 0.5

var hp: int = 3
var alive: bool = true
var downed: bool = false
var revive_progress: float = 0.0
var health_fill_style: StyleBoxFlat

var joined: bool = false
var can_move: bool = false
var invulnerable: bool = false

var hit_tween: Tween

func _ready() -> void:
	$AnimatedSprite2D.play(run_animation)
	var original_style = health_bar.get_theme_stylebox("fill")

	if original_style is StyleBoxFlat:
		health_fill_style = original_style.duplicate() as StyleBoxFlat
	else:
		health_fill_style = StyleBoxFlat.new()

	health_bar.add_theme_stylebox_override("fill", health_fill_style)
	
	setup_health_bar()
	update_health_bar()
	
	
	joined = false
	can_move = false
	

	# Hide the bar if the player hasn't joined yet.
	health_bar.hide()
	
	# Apply player texture in the inspector
	if player_texture != null:
		sprite.texture = player_texture

func _physics_process(delta: float) -> void:
	if not alive or downed or not can_move:
		return

	# Apply gravity while the character is in the air.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if joined and can_move:
		if Input.is_action_just_pressed(jump_action):
			if is_on_floor():
				velocity.y = jump_strength
	move_and_slide()

	# Jump using the assigned player's button.
	#if Input.is_action_just_pressed(jump_action) and is_on_floor():
		#velocity.y = jump_strength

	#move_and_slide()

func take_damage(amount: int = 1) -> void:
	if not alive or downed:
		return
		
	hp -= amount
	hp = maxi(hp, 0)
	
	# Update the visual health bar.
	update_health_bar()
	
	play_hit_effect()
	print(name, "HP: ", hp)
	
	if hp <= 0:
		enter_downed_state()
		
func eliminate() -> void:
	if not alive:
		return
		
	alive = false
	can_move = false
	velocity = Vector2.ZERO
	
	#prevent further collisions and jumping
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Hide character and health bar
	sprite.hide()
	health_bar.hide()
	
	eliminated.emit()
	
func play_hit_effect() -> void:
	
	if hit_tween and hit_tween.is_running():
		hit_tween.kill()

	sprite.modulate = Color.WHITE

	hit_tween = create_tween()

	# Flash red
	hit_tween.tween_property(
		sprite,
		"modulate",
		Color(1.0, 0.2, 0.2),
		0.1
	)

	# Return to normal
	hit_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.15
	)
	
	# Wait until invulnerability ends.
	await get_tree().create_timer(
		invulnerability_duration
	).timeout

	invulnerable = false
  
func update_health_bar() -> void:
	health_bar.value = hp

	if hp >= max_hp:
		set_health_bar_colour(Color.GREEN)
	elif hp == 2:
		set_health_bar_colour(Color.YELLOW)
	else:
		set_health_bar_colour(Color.RED)

func setup_health_bar() -> void:
	hp = max_hp
	alive = true
	downed = false
	revive_progress = 0.0

	$HealthBar.min_value = 0
	$HealthBar.max_value = max_hp
	$HealthBar.value = hp
	$HealthBar.show()

func enter_downed_state() -> void:
	if downed or not alive:
		return

	downed = true
	player_downed.emit()
	revive_progress = 0.0
	
	show_downed_message()

	# Turn the health bar into a revive bar.
	$HealthBar.min_value = 0
	$HealthBar.max_value = 100
	$HealthBar.value = 0
	set_health_bar_colour(Color.YELLOW)
	$HealthBar.show()

	# Prevent normal movement while downed.
	can_move = false

func _unhandled_input(event: InputEvent) -> void:
	if not downed or not alive:
		return

	if event.is_action_pressed(mash_action) and not event.is_echo():
		revive_progress = minf(revive_progress + revive_per_press, 100.0)
		$HealthBar.value = revive_progress

		if revive_progress >= 100.0:
			revive_player()

		get_viewport().set_input_as_handled()

func revive_player() -> void:
	if not downed or not alive:
		return

	downed = false
	hp = max_hp
	revive_progress = 0.0

	# Restore the normal health bar.
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp

	update_health_bar()
	health_bar.show()
	
	hide_downed_message()

	# Allow the player to move again.
	can_move = true
	

func set_health_bar_colour(colour: Color) -> void:
	if health_fill_style != null:
		health_fill_style.bg_color = colour


func show_downed_message() -> void:
	downed_label.text = "DOWNED! MASH TO REVIVE!"
	downed_label.show()


func hide_downed_message() -> void:
	downed_label.hide()
