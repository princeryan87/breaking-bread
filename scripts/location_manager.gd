extends Node2D

class_name LocationManager

@export var locations: Dictionary = {
	"suburbs": {
		"name": "Suburbs",
		"position": Vector2(200, 200),
		"customer_density": 0.8,
		"police_patrol": 0.2,
		"fuel_cost": 5.0,
		"drive_time": 2.0,
		"preferred_goods": ["bread", "cookie"]
	},
	"downtown": {
		"name": "Downtown",
		"position": Vector2(800, 300),
		"customer_density": 1.2,
		"police_patrol": 0.6,
		"fuel_cost": 10.0,
		"drive_time": 4.0,
		"preferred_goods": ["cake", "brownie"]
	},
	"park": {
		"name": "City Park",
		"position": Vector2(500, 100),
		"customer_density": 1.0,
		"police_patrol": 0.3,
		"fuel_cost": 8.0,
		"drive_time": 3.0,
		"preferred_goods": ["cookie", "fruit_tart"]
	},
	"industrial": {
		"name": "Industrial District",
		"position": Vector2(1000, 500),
		"customer_density": 0.6,
		"police_patrol": 0.8,
		"fuel_cost": 15.0,
		"drive_time": 5.0,
		"preferred_goods": ["bread"]
	},
	"market": {
		"name": "Farmers Market",
		"position": Vector2(300, 500),
		"customer_density": 1.5,
		"police_patrol": 0.1,
		"fuel_cost": 12.0,
		"drive_time": 4.0,
		"preferred_goods": ["fruit_tart", "cake"]
	},
	"supplier": {
		"name": "Wholesale Supplier",
		"position": Vector2(100, 400),
		"customer_density": 0.0,
		"police_patrol": 0.0,
		"fuel_cost": 8.0,
		"drive_time": 3.0,
		"type": "shop",
		"sells": ["flour", "sugar", "butter", "eggs", "chocolate", "fruit"]
	},
	"mechanic": {
		"name": "RV Mechanic",
		"position": Vector2(1100, 100),
		"customer_density": 0.0,
		"police_patrol": 0.0,
		"fuel_cost": 10.0,
		"drive_time": 3.0,
		"type": "service",
		"services": ["repair", "refuel", "upgrade"]
	}
}

var current_location: String = "map"
var active_customers: Array[Node] = []

signal location_changed(location_name: String)
signal customer_arrived(customer: Node)
signal customer_left(customer: Node)

func _ready() -> void:
	pass

func get_location_data(location_id: String) -> Dictionary:
	return locations.get(location_id, {})

func travel_to(location_id: String) -> bool:
	var rv = %RV
	var loc_data = get_location_data(location_id)

	if not loc_data:
		return false

	var fuel_cost = loc_data.fuel_cost
	var drive_time = loc_data.drive_time

	if rv.start_drive_to(location_id, drive_time, fuel_cost):
		current_location = location_id
		location_changed.emit(location_id)
		return true
	return false

func on_arrived_at_location(location_id: String) -> void:
	current_location = location_id
	var loc_data = get_location_data(location_id)

	if loc_data.type == "shop":
		%UIManager.show_location_panel(location_id)
	elif loc_data.type == "service":
		%UIManager.show_location_panel(location_id)
	else:
		# Selling location
		spawn_customers(loc_data.customer_density)
		%UIManager.show_sell_panel()

func spawn_customers(density: float) -> void:
	var spawner = %CustomerSpawner
	var count = int(randi() % 3 + 1) * density
	spawner.spawn_customers(count, locations[current_location].preferred_goods)

func get_price_multiplier(location_id: String, recipe_id: String) -> float:
	var loc_data = get_location_data(location_id)
	if recipe_id in loc_data.preferred_goods:
		return 1.3
	return 1.0

func get_police_risk(location_id: String) -> float:
	return get_location_data(location_id).police_patrol