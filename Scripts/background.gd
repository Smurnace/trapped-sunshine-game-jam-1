extends Node2D

@export var background_speed: float = 100.0
@export var cloud_1_speed: float = 20.0
@export var cloud_2_speed: float = 40.0

@onready var background_parallax: Parallax2D = $BackgroundParallax
@onready var cloud_parallax_1: Parallax2D = $CloudParallax1
@onready var cloud_parallax_2: Parallax2D = $CloudParallax2

var scrolling_enabled: bool = false


func _process(delta: float) -> void:
	if not scrolling_enabled:
		return

	background_parallax.scroll_offset.x -= background_speed * delta
	cloud_parallax_1.scroll_offset.x -= cloud_1_speed * delta
	cloud_parallax_2.scroll_offset.x -= cloud_2_speed * delta
