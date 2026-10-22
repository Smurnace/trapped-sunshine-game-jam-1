class_name Dragon
extends RigidBody2D
@onready var animation_player = $AnimationPlayer 

func hurt():
	animation_player.play("Hurt")
	
func attack():
	animation_player.play("Attack")
	
func reset():
	animation_player.play("RESET")

func die():
	animation_player.play("Die")
	
func _ready() -> void:
	reset()
