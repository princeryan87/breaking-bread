extends Node2D

class_name CustomerSpawner

@export var customer_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(100, 100, 1080, 520)

var active_customers: Array[CharacterBody2D] = []
var preferred_goods: Array[String] = []

signal customer_served(customer: Node, earned: int)
signal customer_left_angry(customer: Node)

func _ready() -> void:
	if not customer_scene:
		_create_default_customer_scene()

func _create_default_customer_scene() -> void:
	# Create a simple customer scene programmatically
	customer_scene = PackedScene.new()
	# This would normally be a .tscn file, but we'll create basic customers in code

func spawn_customers(count: int, preferred: Array[String]) -> void:
	preferred_goods = preferred

	for i in range(count):
		call_deferred("_spawn_single_customer")

func _spawn_single_customer() -> void:
	var customer = CharacterBody2D.new()
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _create_customer_sprites()
	sprite.play("walk")
	customer.add_child(sprite)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision.shape = shape
	customer.add_child(collision)

	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D

@export var move_speed := 50.0
var target_position: Vector2
var patience: float = 30.0
var desired_good: String = ""
var bought: bool = false

func _ready():
	target_position = global_position + Vector2(randi() % 200 - 100, randi() % 200 - 100)
	patience = randf_range(20.0, 40.0)

func _physics_process(delta):
	if bought:
		velocity = (target_position - global_position).normalized() * move_speed
		if global_position.distance_to(target_position) < 20:
			queue_free()
		move_and_slide()
		return

	patience -= delta
	if patience <= 0:
		leave_angry()
		return

	velocity = (target_position - global_position).normalized() * move_speed
	move_and_slide()

func set_desired_good(good: String):
	desired_good = good

func try_buy(good: String, price: int) -> bool:
	if good == desired_good and not bought:
		bought = true
		target_position = Vector2(1300, 360)  # Exit screen right
		return true
	return false

func leave_angry():
	# Signal to game manager
	get_tree().call_group("game_manager", "on_customer_left_angry", self)
	queue_free()
"""
	customer.set_script(script)

	# Random position in spawn area
	customer.global_position = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)

	# Set desired good
	if preferred_goods.size() > 0:
		customer.desired_good = preferred_goods[randi() % preferred_goods.size()]

	add_child(customer)
	active_customers.append(customer)

func on_customer_bought(good: String) -> void:
	for customer in active_customers:
		if not customer.bought and customer.desired_good == good:
			var price = GameManager.recipes.get(good, {"base_price": 20}).base_price
			if customer.try_buy(good, price):
				var earned = GameManager.sell_goods(good, 1, %LocationManager.get_price_multiplier(%LocationManager.current_location, good))
				customer_served.emit(customer, earned)
				active_customers.erase(customer)
				break

func _process(delta: float) -> void:
	# Clean up any null references
	for i in range(active_customers.size() - 1, -1, -1):
		if not is_instance_valid(active_customers[i]):
			active_customers.remove_at(i)

func _create_customer_sprites() -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.add_animation("idle")
	frames.add_animation("happy")
	# In a real project, you'd load actual textures here
	return frames