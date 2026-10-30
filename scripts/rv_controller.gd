extends CharacterBody3D

class_name RVController

## ===== NODE REFERENCES =====
@onready var camera: Camera3D = $Camera3D
@onready var kitchen_area: Area3D = $KitchenArea
@onready var sell_area: Area3D = $SellArea

## ===== DRIVING SETTINGS =====
@export var max_speed: float = 15.0
@export var acceleration: float = 8.0
@export var brake_force: float = 12.0
@export var turn_speed: float = 2.5
@export var friction: float = 3.0

## ===== STATE =====
var current_speed: float = 0.0
var is_braking: bool = false
var target_rotation: float = 0.0

# Baking
var baking_timer: float = 0.0
var baking_recipe: String = ""
var baking_output: int = 0
var is_baking: bool = false

# Customers in range
var nearby_customers: Array[Node3D] = []

## ===== SIGNALS =====
signal speed_changed(speed: float)
signal baking_completed(recipe_id: String, output: int)
signal customer_in_range(customer: Node3D)
signal customer_out_of_range(customer: Node3D)

func _ready() -> void:
	# Connect area signals
	kitchen_area.body_entered.connect(_on_kitchen_body_entered)
	kitchen_area.body_exited.connect(_on_kitchen_body_exited)
	sell_area.body_entered.connect(_on_sell_body_entered)
	sell_area.body_exited.connect(_on_sell_body_exited)

	# Listen for GameManager upgrade changes
	GameManager.upgrade_changed.connect(_on_upgrade_changed)

	# Initial stats from GameManager
	max_speed = GameManager.get_max_speed()
	acceleration = GameManager.get_acceleration()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if GameManager.is_paused:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_handle_input(delta)
	_handle_movement(delta)
	_handle_baking(delta)
	_update_camera()

	# Update GameManager position
	GameManager.rv_position = global_position
	GameManager.is_driving = current_speed > 0.5

	move_and_slide()

func _handle_input(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	is_braking = Input.is_action_pressed("brake")

	# Handle turning
	if input_dir.x != 0 and current_speed > 0.5:
		target_rotation += input_dir.x * turn_speed * delta * (current_speed / max_speed)
		rotation.y = target_rotation

	# Acceleration / braking
	if input_dir.y < 0 and not is_braking:
		current_speed = min(current_speed + acceleration * delta, max_speed)
	elif input_dir.y > 0 and not is_braking:
		current_speed = max(current_speed - acceleration * delta * 0.5, -max_speed * 0.3)
	elif is_braking:
		var brake = brake_force * delta
		if current_speed > 0:
			current_speed = max(current_speed - brake, 0.0)
		elif current_speed < 0:
			current_speed = min(current_speed + brake, 0.0)
	else:
		# Friction
		if current_speed > 0:
			current_speed = max(current_speed - friction * delta, 0.0)
		elif current_speed < 0:
			current_speed = min(current_speed + friction * delta, 0.0)

	# Apply velocity in local space
	velocity.x = 0
	velocity.z = -current_speed
	velocity = global_transform.basis * velocity
	velocity.y = 0

	speed_changed.emit(current_speed)
	AudioManager.update_engine_pitch(abs(current_speed), max_speed)

func _handle_movement(delta: float) -> void:
	# Keep RV on ground
	var ray_query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2, global_position - Vector3.UP * 5)
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	if result:
		global_position.y = result.position.y + 1.0

func _handle_baking(delta: float) -> void:
	if is_baking:
		baking_timer -= delta
		if baking_timer <= 0:
			is_baking = false
			GameManager.add_baked_good(baking_recipe, baking_output)
			baking_completed.emit(baking_recipe, baking_output)
			UIManager.show_message("Selesai memanggang %s (+%d)!" % [GameManager.RECIPES[baking_recipe].name, baking_output])
			AudioManager.play_bake_complete()

func _update_camera() -> void:
	# Camera follows RV smoothly
	camera.global_position = lerp(camera.global_position, global_position + Vector3(0, 2.2, 1.0), 0.15)
	camera.global_rotation = lerp(camera.global_rotation, global_rotation, 0.15)

func get_speed() -> float:
	return abs(current_speed) * 3.6 # Convert to km/h

# ===== BAKING =====
func start_baking(recipe_id: String, time: float, output: int) -> void:
	if is_baking:
		UIManager.show_message("Sedang memanggang, tunggu selesai!")
		return

	# Must be stopped to bake
	if current_speed > 0.5:
		UIManager.show_message("Harus berhenti dulu untuk memanggang!")
		return

	baking_recipe = recipe_id
	baking_timer = time
	baking_output = output
	is_baking = true
	UIManager.show_message("Memulai memanggang %s..." % GameManager.RECIPES[recipe_id].name)

func _on_upgrade_changed() -> void:
	max_speed = GameManager.get_max_speed()
	acceleration = GameManager.get_acceleration()

# ===== KITCHEN AREA =====
func _on_kitchen_body_entered(body: Node3D) -> void:
	if body.is_in_group("rv"):
		UIManager.show_message("Di area dapur - Tekan E untuk buka menu")

func _on_kitchen_body_exited(body: Node3D) -> void:
	if body.is_in_group("rv"):
		pass

# ===== SELL AREA =====
func _on_sell_body_entered(body: Node3D) -> void:
	if body.has_method("is_customer") and body.is_customer():
		nearby_customers.append(body)
		customer_in_range.emit(body)
		body.show_sell_indicator(true)

func _on_sell_body_exited(body: Node3D) -> void:
	if body in nearby_customers:
		nearby_customers.erase(body)
		customer_out_of_range.emit(body)
		body.show_sell_indicator(false)

func try_sell_to_customer(customer: Node3D) -> bool:
	if customer not in nearby_customers:
		return false

	# Find a baked good to sell
	for good in GameManager.baked_goods:
		var count = GameManager.baked_goods[good]
		if count > 0:
			var price = GameManager.get_sell_price(good)
			GameManager.remove_baked_good(good, 1)
			GameManager.add_money(price)
			GameManager.add_reputation(2)
			GameManager.add_heat(GameManager.HEAT_PER_SALE)
			customer.on_purchase(good, price)
			AudioManager.play_sell_sound()
			UIManager.show_message("Terjual %s untuk $%d!" % [GameManager.RECIPES[good].name, price])
			return true

	UIManager.show_message("Tidak ada kue untuk dijual!")
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_sell") and not GameManager.is_paused:
		if nearby_customers.size() > 0:
			# Sell to closest customer
			var closest = nearby_customers[0]
			var min_dist = global_position.distance_to(closest.global_position)
			for c in nearby_customers:
				var d = global_position.distance_to(c.global_position)
				if d < min_dist:
					min_dist = d
					closest = c
			try_sell_to_customer(closest)
		else:
			UIManager.show_message("Tidak ada pelanggan di dekat area jual")