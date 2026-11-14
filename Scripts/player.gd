extends CharacterBody3D
## Third-person player controller.
## Sizes/speeds are scaled up because the fight arena is imported at ~78x scale
## (the arena floor is roughly 930 x 960 units).

@export var move_speed: float = 90.0
@export var sprint_multiplier: float = 1.8
@export var acceleration: float = 600.0
@export var jump_velocity: float = 80.0
@export var gravity: float = 160.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -70.0
@export var max_pitch_deg: float = 30.0

@onready var _pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _model: Node3D = $Model


func _ready() -> void:
	_ensure_input_actions()
	_spring_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		_spring_arm.rotation.x = clamp(
			_spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Move relative to where the camera is looking.
	var dir := (Basis(Vector3.UP, _pivot.global_rotation.y) * Vector3(input.x, 0, input.y)).normalized()

	var speed := move_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
	var target := dir * speed
	var horizontal := Vector3(velocity.x, 0, velocity.z).move_toward(target, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if dir != Vector3.ZERO:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-dir.x, -dir.z), 12.0 * delta)

	move_and_slide()


## Creates WASD / Space / Shift actions if they aren't in the Input Map yet.
func _ensure_input_actions() -> void:
	var binds := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"sprint": KEY_SHIFT,
	}
	for action in binds:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = binds[action]
		InputMap.action_add_event(action, ev)
