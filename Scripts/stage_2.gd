
extends Control

signal victory
signal failure

@export var battle_time: float = 10.0
@export var mash_per_press: float = 10.0

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var timer_label: Label = $TimerLabel
@onready var instruction_label: Label = $InstructionLabel
@onready var result_label: Label = $ResultLabel

var elapsed: float = 0.0
var finished: bool = false

var mash_actions: Array[String] = [
	"mash_p1",
	"mash_p2",
	"mash_p3",
    "mash_p4"
]

func _ready() -> void:
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

	instruction_label.text = "MASH YOUR BUTTONS!"
	result_label.text = ""

func _process(delta: float) -> void:
	if finished:
		return

	elapsed += delta

	var remaining: float = maxf(
		battle_time - elapsed, 0.0
	)
	timer_label.text = "TIME: %02d" % ceili(remaining)

	if elapsed >= battle_time:
		finished = true

		if progress_bar.value >= 100.0:
			result_label.text = "THE DRAGON IS DEFEATED!"
			victory.emit()
		else:
			result_label.text = "THE PARTY HAS FALLEN!"
			failure.emit()

func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return

	for action in mash_actions:
		if event.is_action_pressed(action):
			progress_bar.value = minf(
				progress_bar.value + mash_per_press,
				100.0
			)

			if progress_bar.value >= 100.0:
				finished = true
				result_label.text = "THE DRAGON IS DEFEATED!"
				victory.emit()

			get_viewport().set_input_as_handled()
			return
			
func set_surviving_players(actions: Array[String]) -> void:
	mash_actions = actions
