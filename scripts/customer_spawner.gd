extends Node3D

class_name CustomerSpawner

## ===== SETTINGS =====
@export var max_customers: int = 7
@export var spawn_radius_min: float = 30.0
@export var spawn_radius_max: float = 150.0
@export var respawn_time: float = 30.0
@export var customer_prefab: PackedScene

## ===== STATE =====
var active_customers: Array[Node3D] = []
var spawn_timers: Dictionary = {}
var rng: RandomNumberGenerator

@onready var customer_mat: StandardMaterial3D = preload("res://scenes/main.tscn").get_sub_resource("Material_customer")
@onready var cone_mat: StandardMaterial3D = preload("res://scenes/main.tscn").get_sub_resource("Material_cone")

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	# Create customer scene if not provided
	if not customer_prefab:
		customer_prefab = _create_customer_scene()

	# Initial spawn
	for i in range(max_customers):
		call_deferred("_spawn_customer_delayed", i * 0.5)

func _create_customer_scene() -> PackedScene:
	var scene = PackedScene.new()

	# Root
	var root = CharacterBody3D.new()
	root.name = "Customer"
	root.add_to_group("customers")

	# Body
	var body = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = CapsuleMesh.new()
	body.mesh.height = 1.8
	body.mesh.radius = 0.4
	body.material_override = customer_mat
	body.global_position = Vector3(0, 1.3, 0)
	root.add_child(body)

	# Cone indicator (above head)
	var cone = MeshInstance3D.new()
	cone.name = "SellIndicator"
	cone.mesh = ConeMesh.new()
	cone.mesh.height = 1.5
	cone.mesh.radius = 0.6
	cone.material_override = cone_mat
	cone.global_position = Vector3(0, 3.0, 0)
	cone.visible = false
	root.add_child(cone)

	# Collision
	var collision = CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	collision.shape.height = 1.8
	collision.shape.radius = 0.4
	collision.global_position = Vector3(0, 1.3, 0)
	root.add_child(collision)

	# Script
	var script = GDScript.new()
	script.source_code = _get_customer_script()
	root.script = script

	scene.pack(root)
	return scene

func _get_customer_script() -> String:
	return """
extends CharacterBody3D

var customer_id: int = 0
var preferred_goods: Array[String] = []
var patience: float = 120.0
var sell_indicator: MeshInstance3D
var is_waiting: bool = true

func _ready() -> void:
	sell_indicator = $SellIndicator
	# Random preferences
	var all_goods = ["brownie", "karamel_layer", "dark_honey_tart"]
	preferred_goods = all_goods.duplicate()
	preferred_goods.shuffle()
	preferred_goods.resize(randi_range(1, 3))

func _physics_process(delta: float) -> void:
	if is_waiting:
		patience -= delta
		if patience <= 0:
			_leave()
		# Rotate indicator
		sell_indicator.rotation.y += delta * 2.0

func show_sell_indicator(show: bool) -> void:
	sell_indicator.visible = show

func is_customer() -> bool:
	return true

func on_purchase(good: String, price: int) -> void:
	is_waiting = false
	sell_indicator.visible = false
	queue_free()

func _leave() -> void:
	is_waiting = false
	queue_free()
"""

func _spawn_customer_delayed(delay_id: int) -> void:
	await get_tree().create_timer(delay_id).timeout
	_spawn_customer()

func _spawn_customer() -> void:
	if active_customers.size() >= max_customers:
		return

	var rv = get_tree().get_first_node_in_group("rv")
	if not rv:
		return

	# Find valid spawn position on road
	var spawn_pos = _find_spawn_position(rv.global_position)
	if not spawn_pos:
		return

	var customer = customer_prefab.instantiate()
	customer.global_position = spawn_pos
	customer.customer_id = active_customers.size()
	add_child(customer)
	active_customers.append(customer)

	# Connect signals
	customer.tree_exiting.connect(_on_customer_removed.bind(customer))

func _find_spawn_position(rv_pos: Vector3) -> Vector3:
	var attempts = 20
	for i in range(attempts):
		var angle = rng.randf_range(0, TAU)
		var dist = rng.randf_range(spawn_radius_min, spawn_radius_max)
		var pos = rv_pos + Vector3(cos(angle), 0, sin(angle)) * dist

		# Check if on road (raycast down)
		var query = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 10, pos - Vector3.UP * 5)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		if result and result.collider.is_in_group("ground"):
			return result.position + Vector3.UP * 0.5

	return null

func _on_customer_removed(customer: Node3D) -> void:
	if customer in active_customers:
		active_customers.remove(customer)
		# Schedule respawn
		var timer = Timer.new()
		timer.wait_time = respawn_time
		timer.one_shot = true
		timer.timeout.connect(_spawn_customer)
		add_child(timer)
		timer.start()