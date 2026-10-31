extends Node2D

class_name Police

@export var patrol_scene: PackedScene
@export var max_patrols: int = 3
@export var base_spawn_chance: float = 0.02
@export var heat_multiplier: float = 1.5

var active_patrols: Array[CharacterBody2D] = []
var patrol_timer: float = 0.0
var spawn_interval: float = 10.0

signal police_spotted(rv: Node)
signal police_raid(reason: String)

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	patrol_timer += delta

	if patrol_timer >= spawn_interval:
		patrol_timer = 0.0
		_try_spawn_patrol()

	_update_patrol_behavior(delta)

func _try_spawn_patrol() -> void:
	if active_patrols.size() >= max_patrols:
		return

	var heat_factor = GameManager.heat / GameManager.max_heat
	var spawn_chance = base_spawn_chance * (1.0 + heat_factor * heat_multiplier)

	var loc_risk = %LocationManager.get_police_risk(%LocationManager.current_location)
	spawn_chance *= (1.0 + loc_risk)

	if randf() < spawn_chance:
		_spawn_patrol()

func _spawn_patrol() -> void:
	var patrol = CharacterBody2D.new()
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _create_police_sprites()
	sprite.play("drive")
	patrol.add_child(sprite)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 30)
	collision.shape = shape
	patrol.add_child(collision)

	var area = Area2D.new()
	var detect_shape = CircleShape2D.new()
	detect_shape.radius = 200.0
	var detect_collision = CollisionShape2D.new()
	detect_collision.shape = detect_shape
	area.add_child(detect_collision)
	area.body_entered.connect(_on_detect_body.bind(patrol))
	patrol.add_child(area)

	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D

@export var patrol_speed := 200.0
@export var chase_speed := 300.0
var state: String = "patrol"
var target: Node = null
var patrol_points: Array[Vector2] = []
var current_point: int = 0
var detection_range: float = 200.0

func _ready():
	# Generate random patrol points
	for i in range(4):
		patrol_points.append(Vector2(randf_range(100, 1180), randf_range(100, 620)))

func _physics_process(delta):
	match state:
		"patrol":
			_do_patrol(delta)
		"chase":
			_do_chase(delta)
		"investigate":
			_do_investigate(delta)
	move_and_slide()

func _do_patrol(delta):
	if patrol_points.is_empty():
		return

	var target_pos = patrol_points[current_point]
	var direction = (target_pos - global_position).normalized()
	velocity = direction * patrol_speed

	if global_position.distance_to(target_pos) < 50:
		current_point = (current_point + 1) % patrol_points.size()

func _do_chase(delta):
	if not is_instance_valid(target):
		state = "patrol"
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * chase_speed

	if global_position.distance_to(target.global_position) < 30:
		# Caught the RV
		get_tree().call_group("game_manager", "on_police_caught", self)

func _do_investigate(delta):
	# Move to last known position
	pass

func set_target(new_target: Node):
	target = new_target
	state = "chase"

func investigate_position(pos: Vector2):
	# Add to patrol points temporarily
	patrol_points.insert(0, pos)
	state = "investigate"
"""
	patrol.set_script(script)

	# Spawn at edge of screen
	var edge = randi() % 4
	match edge:
		0: patrol.global_position = Vector2(-50, randf_range(0, 720))
		1: patrol.global_position = Vector2(1330, randf_range(0, 720))
		2: patrol.global_position = Vector2(randf_range(0, 1280), -50)
		3: patrol.global_position = Vector2(randf_range(0, 1280), 770)

	add_child(patrol)
	active_patrols.append(patrol)

func _on_detect_body(body: Node, patrol: Node) -> void:
	if body.is_in_group("rv"):
		patrol.set_target(body)
		police_spotted.emit(body)
		GameManager.add_heat(5.0)

func _update_patrol_behavior(delta: float) -> void:
	for i in range(active_patrols.size() - 1, -1, -1):
		var patrol = active_patrols[i]
		if not is_instance_valid(patrol):
			active_patrols.remove_at(i)
			continue

		# Despawn if too far off screen
		if patrol.global_position.x < -100 or patrol.global_position.x > 1380 or \
		   patrol.global_position.y < -100 or patrol.global_position.y > 820:
			patrol.queue_free()
			active_patrols.remove_at(i)

func _create_police_sprites() -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.add_animation("drive")
	frames.add_animation("chase")
	frames.add_animation("idle")
	return frames

func increase_heat_spawn() -> void:
	# Called when player does suspicious activity
	spawn_interval = max(2.0, spawn_interval - 1.0)

func decrease_heat_spawn() -> void:
	# Called when heat decreases
	spawn_interval = min(30.0, spawn_interval + 0.5)

func clear_all_patrols() -> void:
	for patrol in active_patrols:
		if is_instance_valid(patrol):
			patrol.queue_free()
	active_patrols.clear()