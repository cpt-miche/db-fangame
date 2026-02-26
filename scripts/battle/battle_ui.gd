extends Control

signal action_pressed(action_id: StringName)
signal infusion_changed(value: float)

@onready var combat_log: RichTextLabel = $Margin/VBox/Log
@onready var infusion_slider: HSlider = $Margin/VBox/InfusionRow/InfusionSlider
@onready var infusion_label: Label = $Margin/VBox/InfusionRow/InfusionValue

func _ready() -> void:
	infusion_slider.value_changed.connect(_on_infusion_changed)
	for button: Button in $Margin/VBox/Actions.get_children():
		button.pressed.connect(func() -> void: action_pressed.emit(StringName(button.name)))
	_on_infusion_changed(infusion_slider.value)

func append_log(line: String) -> void:
	combat_log.text = "%s\n%s" % [line, combat_log.text]

func _on_infusion_changed(value: float) -> void:
	infusion_label.text = "%d%%" % int(value)
	infusion_changed.emit(value / 100.0)
