extends CharacterBody3D

class_name PoliceController

## ===== SETTINGS =====
@export var base_speed: float = 18.0
@export var acceleration: float = 10.0
@export var detection_range: float = 80.0
@export var lose_range: float = 110.0
@export var lose_time: float = 4.0

## ===== STATE =====
var target: Node3D = null
var current_speed: float = 0.0
var is_chasing: bool = false
var lost_timer: float = 0.0
var siren_active: bool = false

@onready var body_mesh: MeshInstance3D = $PoliceBody
@onready var light: OmniLight3D = $PoliceLight

func _ready() -> void:
	GameManager.police_state_changed.connect(_on_police_state_changed)
	light.enabled = false

func _physics_process(delta: float) -> void:
	if GameManager.is_paused:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_chasing:
		# Patrol randomly
		_patrol(delta)
	else:
		_chase(delta)

	velocity.y = 0
	move_and_slide()

	# Update siren
	if siren_active != is_chasing:
		siren_active = is_chasing
		AudioManager.set_police_siren(siren_active)
		light.enabled = siren_active

func _patrol(delta: float) -> void:
	# Simple random patrol
	if randf() < 0.01:
		var angle = randf_range(0, TAU)
		var patrol_pos = global_position + Vector3(cos(angle), 0, sin(angle)) * 50
		_patrol_target = patrol_pos

	if _patrol_target:
		var dir = (_patrol_target - global_position).normalized()
		if global_position.distance_to(_patrol_target) < 5.0:
			_patrol_target = Vector3.ZERO
		else:
			_steer_towards(dir, base_speed * 0.5, delta)

	_steer_towards(velocity.normalized(), base_speed * 0.5, delta)

var _patrol_target: Vector3 = Vector3.ZERO

func _chase(delta: float) -> void:
	if not target:
		return

	var to_target = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)

	# Update lost timer
	if distance > lose_range:
		lost_timer += delta
		if lost_timer >= lose_time:
			_stop_chase()
			return
	else:
		lost_timer = 0.0

	# Chase with higher speed
	var chase_speed = base_speed * 1.2
	_steer_towards(to_target, chase_speed, delta)

	# Try to ram if close
	if distance < 5.0:
		_on_catch_target()

func _steer_towards(direction: Vector3, target_speed: float, delta: float) -> void:
	var target_vel = direction * target_speed
	var steer = (target_vel - velocity).normalized() * acceleration * delta
	velocity += steer
	velocity = velocity.limit_length(target_speed)

	# Rotate to face movement
	if velocity.length() > 0.1:
		var target_rot = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 5.0 * delta)

func _on_police_state_changed(alert: bool, distance: float) -> void:
	if alert and not is_chasing:
		_start_chase()
	elif not alert and is_chasing:
		_stop_chase()

func _start_chase() -> void:
	var rv = get_tree().get_first_node_in_group("rv")
	if rv:
		target = rv
		is_chasing = true
		lost_timer = 0.0

func _stop_chase() -> void:
	is_chasing = false
	target = null
	lost_timer = 0.0
	GameManager.police_state_changed.emit(false, 0.0)

func _on_catch_target() -> void:
	if target and target.has_method("on_caught_by_police"):
		target.on_caught_by_police()
	_stop_chase()

func get_police_position() -> Vector3:
	return global_position