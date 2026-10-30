extends Node

class_name GameManager

## ===== STATE =====
# Uang & Reputasi
var money: int = 500
var reputation: int = 0
var heat: int = 0

# Persediaan bahan
var inventory: Dictionary = {
	"sugar": 0,      # gula selundupan
	"flour": 0,      # tepung
	"honey": 0,      # madu
	"chocolate": 0,  # cokelat
}

# Produksi kue (siap jual)
var baked_goods: Dictionary = {
	"brownie": 0,
	"karamel_layer": 0,
	"dark_honey_tart": 0,
}

# Upgrade level
var oven_level: int = 1
var engine_level: int = 1

# Resep yang terbuka
var unlocked_recipes: Array[String] = ["brownie"]

# Posisi RV & status
var rv_position: Vector3 = Vector3.ZERO
var is_driving: bool = false
var is_paused: bool = false

# Polisi
var police_alert: bool = false
var police_distance: float = 0.0
var police_lost_timer: float = 0.0

# Konstan
const MAX_HEAT: int = 100
const HEAT_PER_SALE: int = 10
const POLICE_CHASE_THRESHOLD: int = 50
const POLICE_LOST_DISTANCE: float = 110.0
const POLICE_LOST_TIME: float = 4.0

## ===== SIGNALS =====
signal money_changed(new_amount: int)
signal reputation_changed(new_amount: int)
signal heat_changed(new_amount: int)
signal inventory_changed()
signal baked_goods_changed()
signal upgrade_changed()
signal police_state_changed(alert: bool, distance: float)
signal game_over(reason: String)

## ===== HELPERS =====
func _ready() -> void:
	pass

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func add_reputation(amount: int) -> void:
	reputation += amount
	reputation_changed.emit(reputation)

func add_heat(amount: int) -> void:
	heat = clamp(heat + amount, 0, MAX_HEAT)
	heat_changed.emit(heat)

	if heat >= POLICE_CHASE_THRESHOLD and not police_alert:
		police_alert = true
		police_state_changed.emit(true, police_distance)
	elif heat < POLICE_CHASE_THRESHOLD and police_alert:
		police_alert = false
		police_state_changed.emit(false, 0.0)

func reduce_heat_over_time(delta: float) -> void:
	if heat > 0:
		heat = max(0, heat - int(delta * 2))
		heat_changed.emit(heat)

func add_inventory(item: String, amount: int) -> void:
	if item in inventory:
		inventory[item] += amount
		inventory_changed.emit()

func remove_inventory(item: String, amount: int) -> bool:
	if item in inventory and inventory[item] >= amount:
		inventory[item] -= amount
		inventory_changed.emit()
		return true
	return false

func add_baked_good(good: String, amount: int) -> void:
	if good in baked_goods:
		baked_goods[good] += amount
		baked_goods_changed.emit()

func remove_baked_good(good: String, amount: int) -> bool:
	if good in baked_goods and baked_goods[good] >= amount:
		baked_goods[good] -= amount
		baked_goods_changed.emit()
		return true
	return false

func get_total_baked_goods() -> int:
	var total = 0
	for count in baked_goods.values():
		total += count
	return total

## ===== RESEP =====
const RECIPES: Dictionary = {
	"brownie": {
		"name": "Brownies Gula",
		"cost": {"sugar": 2, "flour": 1},
		"output": 1,
		"time": 8.0,
		"base_price": 50,
		"min_reputation": 0,
		"oven_level_required": 1,
	},
	"karamel_layer": {
		"name": "Lapis Karamel",
		"cost": {"sugar": 3, "flour": 1, "honey": 1},
		"output": 1,
		"time": 12.0,
		"base_price": 80,
		"min_reputation": 10,
		"oven_level_required": 2,
	},
	"dark_honey_tart": {
		"name": "Tart Madu Gelap",
		"cost": {"sugar": 2, "flour": 1, "honey": 2, "chocolate": 1},
		"output": 1,
		"time": 18.0,
		"base_price": 130,
		"min_reputation": 25,
		"oven_level_required": 3,
	},
}

func can_craft(recipe_id: String) -> bool:
	var recipe = RECIPES[recipe_id]
	if not recipe:
		return false
	if oven_level < recipe.oven_level_required:
		return false
	if reputation < recipe.min_reputation:
		return false
	for item, cost in recipe.cost:
		if inventory[item] < cost:
			return false
	return true

func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false

	var recipe = RECIPES[recipe_id]
	for item, cost in recipe.cost:
		remove_inventory(item, cost)

	# Return baking time, actual output added when timer completes
	return true

func get_recipe_output(recipe_id: String) -> int:
	return RECIPES[recipe_id].output

func get_recipe_time(recipe_id: String) -> float:
	var recipe = RECIPES[recipe_id]
	var time = recipe.time
	# Oven level 2 = 20% faster, level 3 = 40% faster
	if oven_level >= 2:
		time *= 0.8
	if oven_level >= 3:
		time *= 0.6
	return time

func get_sell_price(recipe_id: String) -> int:
	var recipe = RECIPES[recipe_id]
	var price = recipe.base_price
	# Reputation bonus: +5% per 10 rep
	price = int(price * (1.0 + reputation * 0.005))
	return price

## ===== UPGRADES =====
const OVEN_UPGRADE_COST: Array[int] = [0, 300, 800]  # level 2, 3
const ENGINE_UPGRADE_COST: Array[int] = [0, 400, 1000]

func can_upgrade_oven() -> bool:
	return oven_level < 3 and money >= OVEN_UPGRADE_COST[oven_level]

func upgrade_oven() -> bool:
	if not can_upgrade_oven():
		return false
	spend_money(OVEN_UPGRADE_COST[oven_level])
	oven_level += 1
	# Unlock recipes
	if oven_level == 2:
		if "karamel_layer" not in unlocked_recipes:
			unlocked_recipes.append("karamel_layer")
	elif oven_level == 3:
		if "dark_honey_tart" not in unlocked_recipes:
			unlocked_recipes.append("dark_honey_tart")
	upgrade_changed.emit()
	return true

func can_upgrade_engine() -> bool:
	return engine_level < 3 and money >= ENGINE_UPGRADE_COST[engine_level]

func upgrade_engine() -> bool:
	if not can_upgrade_engine():
		return false
	spend_money(ENGINE_UPGRADE_COST[engine_level])
	engine_level += 1
	upgrade_changed.emit()
	return true

func get_max_speed() -> float:
	# Base 15, level 2 = 20, level 3 = 28
	return 15.0 + (engine_level - 1) * 5.0 + (engine_level == 3) * 3.0

func get_acceleration() -> float:
	return 8.0 + (engine_level - 1) * 3.0

## ===== POLICE =====
func update_police(delta: float, rv_pos: Vector3, police_pos: Vector3) -> void:
	if not police_alert:
		return

	police_distance = rv_pos.distance_to(police_pos)

	if police_distance > POLICE_LOST_DISTANCE:
		police_lost_timer += delta
		if police_lost_timer >= POLICE_LOST_TIME:
			police_alert = false
			police_lost_timer = 0.0
			police_state_changed.emit(false, 0.0)
	else:
		police_lost_timer = 0.0

	police_state_changed.emit(true, police_distance)

func on_caught_by_police() -> void:
	var fine = money / 2
	money = money / 2
	var lost_goods = get_total_baked_goods() / 2
	for good in baked_goods:
		baked_goods[good] = baked_goods[good] / 2

	money_changed.emit(money)
	baked_goods_changed.emit()
	heat = 0
	heat_changed.emit(heat)
	police_alert = false
	police_state_changed.emit(false, 0.0)

	game_over.emit("Tertangkap polisi! Denda: $%d, Kue disita: %d" % [fine, lost_goods])

## ===== SAVE/LOAD =====
func get_save_data() -> Dictionary:
	return {
		"money": money,
		"reputation": reputation,
		"heat": heat,
		"inventory": inventory,
		"baked_goods": baked_goods,
		"oven_level": oven_level,
		"engine_level": engine_level,
		"unlocked_recipes": unlocked_recipes,
	}

func load_save_data(data: Dictionary) -> void:
	money = data.get("money", 500)
	reputation = data.get("reputation", 0)
	heat = data.get("heat", 0)
	inventory = data.get("inventory", inventory)
	baked_goods = data.get("baked_goods", baked_goods)
	oven_level = data.get("oven_level", 1)
	engine_level = data.get("engine_level", 1)
	unlocked_recipes = data.get("unlocked_recipes", ["brownie"])

	money_changed.emit(money)
	reputation_changed.emit(reputation)
	heat_changed.emit(heat)
	inventory_changed.emit()
	baked_goods_changed.emit()
	upgrade_changed.emit()