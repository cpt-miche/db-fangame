extends Control

signal action_pressed(action_id: StringName)
signal infusion_changed(value: float)
signal debug_mode_toggled(enabled: bool)

@onready var combat_log: RichTextLabel = $Margin/VBox/Log
@onready var infusion_slider: HSlider = $Margin/VBox/InfusionRow/InfusionSlider
@onready var infusion_label: Label = $Margin/VBox/InfusionRow/InfusionValue
@onready var debug_panel: PanelContainer = $DebugPanel
@onready var debug_label: RichTextLabel = $DebugPanel/Margin/Stats

var debug_mode_enabled := false

func _ready() -> void:
	infusion_slider.value_changed.connect(_on_infusion_changed)
	for button: Button in $Margin/VBox/Actions.get_children():
		button.pressed.connect(func() -> void: action_pressed.emit(StringName(button.name)))
	debug_panel.visible = false
	_on_infusion_changed(infusion_slider.value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.ctrl_pressed and key_event.keycode == KEY_T:
			debug_mode_enabled = not debug_mode_enabled
			debug_panel.visible = debug_mode_enabled
			debug_mode_toggled.emit(debug_mode_enabled)
			get_viewport().set_input_as_handled()

func append_log(line: String) -> void:
	if combat_log.text.is_empty() or combat_log.text == "Combat log...":
		combat_log.text = line
	else:
		combat_log.text = "%s\n%s" % [combat_log.text, line]
	combat_log.scroll_to_line(maxi(combat_log.get_line_count() - 1, 0))

func _on_infusion_changed(value: float) -> void:
	infusion_label.text = "%d%%" % int(value)
	infusion_changed.emit(value / 100.0)

func set_debug_stats(lines: PackedStringArray) -> void:
	debug_label.text = "\n".join(lines)
