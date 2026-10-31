extends Node2D

class_name Kitchen

@export var bake_station_positions: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0), Vector2(200, 0)]

@onready var oven_animation: AnimationPlayer = $OvenAnimation
@onready var ingredient_ui: Control = $IngredientUI

var active_recipes: Array[Dictionary] = []
var max_simultaneous_bakes: int = 1

signal bake_completed(recipe_id: String, quality: float)
signal ingredient_shortage(recipe_id: String)

func _ready() -> void:
	visible = false
	ingredient_ui.visible = false

func open_kitchen() -> void:
	visible = true
	ingredient_ui.visible = true
	_refresh_ingredient_display()

func close_kitchen() -> void:
	visible = false
	ingredient_ui.visible = false

func can_bake(recipe_id: String) -> bool:
	var recipe = GameManager.recipes.get(recipe_id)
	if not recipe:
		return false

	if active_recipes.size() >= max_simultaneous_bakes:
		return false

	return GameManager.consume_ingredients(recipe_id)

func start_bake(recipe_id: String) -> bool:
	if not can_bake(recipe_id):
		ingredient_shortage.emit(recipe_id)
		return false

	var recipe = GameManager.recipes[recipe_id]
	var bake_data = {
		"recipe_id": recipe_id,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"duration": recipe.time,
		"quality": 1.0
	}

	active_recipes.append(bake_data)
	oven_animation.play("bake")

	return true

func _process(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var completed = []

	for i in range(active_recipes.size() - 1, -1, -1):
		var bake = active_recipes[i]
		var elapsed = current_time - bake.start_time

		if elapsed >= bake.duration:
			completed.append(bake)
			active_recipes.remove_at(i)

	for bake in completed:
		_on_bake_finished(bake)

func _on_bake_finished(bake_data: Dictionary) -> void:
	var recipe_id = bake_data.recipe_id
	var quality = bake_data.quality

	GameManager.add_baked_good(recipe_id, quality)
	bake_completed.emit(recipe_id, quality)
	oven_animation.play("idle")
	_refresh_ingredient_display()

func _refresh_ingredient_display() -> void:
	# Update UI with current ingredient counts
	for child in ingredient_ui.get_children():
		if child.has_method("update_display"):
			child.update_display()

func get_bake_progress(recipe_index: int) -> float:
	if recipe_index >= active_recipes.size():
		return 0.0

	var bake = active_recipes[recipe_index]
	var elapsed = Time.get_ticks_msec() / 1000.0 - bake.start_time
	return clamp(elapsed / bake.duration, 0.0, 1.0)

func upgrade_oven() -> void:
	max_simultaneous_bakes = 2
	for recipe in GameManager.recipes.values():
		recipe.time *= 0.7

func upgrade_fridge() -> void:
	# Ingredients spoil 50% slower
	pass