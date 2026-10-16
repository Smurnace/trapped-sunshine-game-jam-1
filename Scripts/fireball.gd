extends Area2D

@export var speed: float = 350.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.x -= speed * delta

	# Remove fireballs once they leave the screen.
	if position.x < -100.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
		queue_free()
		
