extends Node

class_name GameManager

signal money_changed(new_amount: int)
signal reputation_changed(new_amount: int)
signal heat_changed(new_amount: float)
signal day_changed(new_day: int)
signal game_over(reason: String)

## Game State
var money: int = 500
var reputation: int = 50
var heat: float = 0.0
var current_day: int = 1
var max_heat: float = 100.0

## RV State
var rv_fuel: float = 100.0
var rv_condition: float = 100.0
var rv_max_fuel: float = 100.0

## Inventory
var ingredients: Dictionary = {
	"flour": 10,
	"sugar": 10,
	"butter": 5,
	"eggs": 12,
	"chocolate": 5,
	"fruit": 8
}

var baked_goods: Dictionary = {}

## Upgrades
var upgrades: Dictionary = {
	"better_oven": false,
	"fridge": false,
	"solar_panel": false,
	"bigger_tank": false,
	"stealth_paint": false
}

var upgrade_costs: Dictionary = {
	"better_oven": 300,
	"fridge": 250,
	"solar_panel": 400,
	"bigger_tank": 200,
	"stealth_paint": 500
}

## Recipe definitions
var recipes: Dictionary = {
	"bread": {
		"ingredients": {"flour": 2, "water": 1},
		"time": 5.0,
		"base_price": 15,
		"reputation_gain": 2
	},
	"cookie": {
		"ingredients": {"flour": 1, "sugar": 1, "butter": 1},
		"time": 3.0,
		"base_price": 20,
		"reputation_gain": 3
	},
	"cake": {
		"ingredients": {"flour": 2, "sugar": 2, "eggs": 2, "butter": 1},
		"time": 8.0,
		"base_price": 50,
		"reputation_gain": 5
	},
	"brownie": {
		"ingredients": {"flour": 1, "sugar": 2, "chocolate": 1, "eggs": 1},
		"time": 6.0,
		"base_price": 35,
		"reputation_gain": 4
	},
	"fruit_tart": {
		"ingredients": {"flour": 1, "sugar": 1, "fruit": 2, "butter": 1},
		"time": 7.0,
		"base_price": 40,
		"reputation_gain": 4
	}
}

func _ready() -> void:
	_load_game()

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
	_check_game_over()

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func add_reputation(amount: int) -> void:
	reputation = clamp(reputation + amount, 0, 100)
	reputation_changed.emit(reputation)

func add_heat(amount: float) -> void:
	heat = clamp(heat + amount, 0.0, max_heat)
	heat_changed.emit(heat)
	if heat >= max_heat:
		game_over.emit("Police caught you! Heat reached maximum.")

func next_day() -> void:
	current_day += 1

	# Daily heat decay
	heat = max(0.0, heat - 5.0)
	heat_changed.emit(heat)

	# RV fuel consumption per day
	rv_fuel = max(0.0, rv_fuel - 10.0)

	# RV condition degradation
	rv_condition = max(0.0, rv_condition - 2.0)

	day_changed.emit(current_day)
	_save_game()

func can_afford_upgrade(upgrade_id: String) -> bool:
	return money >= upgrade_costs.get(upgrade_id, 9999)

func buy_upgrade(upgrade_id: String) -> bool:
	if not upgrades.has(upgrade_id) or upgrades[upgrade_id]:
		return false

	if spend_money(upgrade_costs[upgrade_id]):
		upgrades[upgrade_id] = true
		_apply_upgrade(upgrade_id)
		_save_game()
		return true
	return false

func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"better_oven":
			for recipe in recipes.values():
				recipe.time *= 0.7
		"fridge":
			# Ingredients spoil slower (handled in ingredient system)
			pass
		"solar_panel":
			rv_max_fuel = 150.0
			rv_fuel = rv_max_fuel
		"bigger_tank":
			rv_max_fuel = 150.0
		"stealth_paint":
			max_heat = 150.0

func consume_ingredients(recipe_id: String) -> bool:
	var recipe = recipes.get(recipe_id)
	if not recipe:
		return false

	for ingredient_name, amount in recipe.ingredients:
		if ingredients.get(ingredient_name, 0) < amount:
			return false

	for ingredient_name, amount in recipe.ingredients:
		ingredients[ingredient_name] -= amount

	return true

func add_baked_good(recipe_id: String, quality: float = 1.0) -> void:
	var current = baked_goods.get(recipe_id, 0)
	baked_goods[recipe_id] = current + 1

func sell_goods(recipe_id: String, quantity: int, price_multiplier: float = 1.0) -> int:
	var available = baked_goods.get(recipe_id, 0)
	var sell_amount = min(quantity, available)

	if sell_amount <= 0:
		return 0

	var recipe = recipes[recipe_id]
	var base_price = recipe.base_price
	var earned = int(sell_amount * base_price * price_multiplier)

	baked_goods[recipe_id] -= sell_amount
	add_money(earned)
	add_reputation(recipe.reputation_gain * sell_amount)

	return earned

func buy_ingredients(ingredient_list: Dictionary) -> bool:
	var total_cost = 0
	for ingredient, amount in ingredient_list:
		var price = _get_ingredient_price(ingredient)
		total_cost += price * amount

	if spend_money(total_cost):
		for ingredient, amount in ingredient_list:
			ingredients[ingredient] = ingredients.get(ingredient, 0) + amount
		return true
	return false

func _get_ingredient_price(ingredient: String) -> int:
	match ingredient:
		"flour": return 5
		"sugar": return 8
		"butter": return 15
		"eggs": return 10
		"chocolate": return 25
		"fruit": return 12
		_: return 10

func drive_to_location(fuel_cost: float) -> bool:
	if rv_fuel >= fuel_cost:
		rv_fuel -= fuel_cost
		return true
	return false

func repair_rv(amount: float = 20.0, cost: int = 100) -> bool:
	if spend_money(cost):
		rv_condition = min(100.0, rv_condition + amount)
		return true
	return false

func refuel_rv(amount: float = 50.0, cost: int = 80) -> bool:
	if spend_money(cost):
		rv_fuel = min(rv_max_fuel, rv_fuel + amount)
		return true
	return false

func _check_game_over() -> void:
	if money <= 0 and _get_total_asset_value() < 100:
		game_over.emit("Bankrupt! No money and no assets to sell.")

	if rv_condition <= 0:
		game_over.emit("Your RV broke down completely!")

func _get_total_asset_value() -> int:
	var value = 0
	for ingredient, amount in ingredients:
		value += amount * _get_ingredient_price(ingredient)
	for good, amount in baked_goods:
		var recipe = recipes.get(good)
		if recipe:
			value += amount * recipe.base_price
	return value

func _save_game() -> void:
	var save_data = {
		"money": money,
		"reputation": reputation,
		"heat": heat,
		"current_day": current_day,
		"rv_fuel": rv_fuel,
		"rv_condition": rv_condition,
		"ingredients": ingredients,
		"baked_goods": baked_goods,
		"upgrades": upgrades
	}

	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func _load_game() -> void:
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	if file and file.get_length() > 0:
		var save_data = file.get_var()
		file.close()

		money = save_data.get("money", 500)
		reputation = save_data.get("reputation", 50)
		heat = save_data.get("heat", 0.0)
		current_day = save_data.get("current_day", 1)
		rv_fuel = save_data.get("rv_fuel", 100.0)
		rv_condition = save_data.get("rv_condition", 100.0)
		ingredients = save_data.get("ingredients", ingredients)
		baked_goods = save_data.get("baked_goods", {})
		upgrades = save_data.get("upgrades", upgrades)

		money_changed.emit(money)
		reputation_changed.emit(reputation)
		heat_changed.emit(heat)
		day_changed.emit(current_day)