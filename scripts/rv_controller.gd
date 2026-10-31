extends CharacterBody2D

class_name RVController

@export var speed: float = 300.0
@export var acceleration: float = 500.0
@export var deceleration: float = 800.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_location: String = "map"
var target_location: String = ""
var is_driving: bool = false
var drive_progress: float = 0.0
var drive_duration: float = 3.0

signal arrived_at_location(location_name: String)
signal fuel_low
signal rv_damaged

func _physics_process(delta: float) -> void:
	if not is_driving:
		_handle_movement_input(delta)
	else:
		_handle_driving(delta)

	move_and_slide()

func _handle_movement_input(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		_update_animation(input_dir)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		animated_sprite.play("idle")

func _handle_driving(delta: float) -> void:
	drive_progress += delta
	var progress = drive_progress / drive_duration

	# Visual feedback during drive
	if progress >= 1.0:
		is_driving = false
		drive_progress = 0.0
		current_location = target_location
		arrived_at_location.emit(current_location)
		visible = true

func _update_animation(direction: Vector2) -> void:
	if direction.x > 0:
		animated_sprite.play("drive_right")
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.play("drive_right")
		animated_sprite.flip_h = true
	elif direction.y < 0:
		animated_sprite.play("drive_up")
	else:
		animated_sprite.play("drive_down")

func start_drive_to(location_name: String, duration: float = 3.0, fuel_cost: float = 10.0) -> bool:
	var gm = GameManager
	if not gm.drive_to_location(fuel_cost):
		return false

	target_location = location_name
	drive_duration = duration
	is_driving = true
	drive_progress = 0.0
	visible = false
	return true

func get_fuel_percentage() -> float:
	return GameManager.rv_fuel / GameManager.rv_max_fuel

func get_condition_percentage() -> float:
	return GameManager.rv_condition / 100.0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("location_trigger"):
		_on_location_trigger(body.location_name)
	elif body.is_in_group("police"):
		GameManager.add_heat(15.0)

func _on_location_trigger(location_name: String) -> void:
	# Show interaction prompt
	pass