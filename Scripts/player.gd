extends CharacterBody2D
signal eliminated

@onready var sprite: Sprite2D = $Sprite2D

@export var jump_action: String = "jump_p1"
@export var jump_strength: float = -450.0
@export var gravity: float = 1200.0
@export var mash_action: String = "mash_p1"
@export var max_hp: int = 3

var hp: int = 3
var alive: bool = true
var hit_tween: Tween

func _ready() -> void:
	hp = max_hp

func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Apply gravity while the character is in the air.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump using the assigned player's button.
	if Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = jump_strength

	move_and_slide()

func take_damage() -> void:
	if not alive:
		return
		
	hp -= 1
	play_hit_effect()
	print(name, "HP: ", hp)
	
	if hp <= 0:
		eliminate()
		
func eliminate() -> void:
	if not alive:
		return
		
	alive = false
	velocity = Vector2.ZERO
	
	#prevent further collisions and jumping
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Hide character
	hide()
	
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
   
