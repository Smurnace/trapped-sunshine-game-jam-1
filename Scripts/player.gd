extends CharacterBody2D
signal eliminated

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

@export var jump_action: String = "jump_p1"
@export var jump_strength: float = -450.0
@export var gravity: float = 1200.0
@export var mash_action: String = "mash_p1"
@export var max_hp: int = 3
@export var player_texture: Texture2D
@export var invulnerability_duration: float = 0.5

var hp: int = 3
var joined: bool = false
var can_move: bool = false
var invulnerable: bool = false
var alive: bool = true
var hit_tween: Tween

func _ready() -> void:
	hp = max_hp
	
	update_health_bar()
	
	alive = true
	joined = false
	can_move = false
	
	# Configure the health bar.
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp

	# Hide the bar if the player hasn't joined yet.
	health_bar.hide()
	
	# Apply player texture in the inspector
	if player_texture != null:
		sprite.texture = player_texture

func _physics_process(delta: float) -> void:
	if not alive:
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

func take_damage() -> void:
	if not alive or invulnerable:
		return
		
	hp -= 1
	
	# Update the visual health bar.
	update_health_bar()
	
	play_hit_effect()
	print(name, "HP: ", hp)
	
	if hp <= 0:
		eliminate()
		
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

	if hp >= 3:
		health_bar.modulate = Color.GREEN
	elif hp == 2:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED 
