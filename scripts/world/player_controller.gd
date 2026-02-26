extends CharacterBody2D

@export var move_speed: float = 180.0
@export var iso_x: Vector2 = Vector2(1, 0.5)
@export var iso_y: Vector2 = Vector2(-1, 0.5)

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var iso_dir := (iso_x * input_vector.x + iso_y * input_vector.y).normalized()
	velocity = iso_dir * move_speed
	move_and_slide()
