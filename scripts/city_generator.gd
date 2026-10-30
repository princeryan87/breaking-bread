extends Node3D

class_name CityGenerator

## ===== SETTINGS =====
@export var city_size: int = 200
@export var block_size: int = 20
@export var building_density: float = 0.6
@export var min_building_height: float = 5.0
@export var max_building_height: float = 25.0
@export var road_width: float = 8.0

## ===== MATERIALS =====
@onready var road_mat: StandardMaterial3D = preload("res://scenes/main.tscn").get_sub_resource("Material_road")
@onready var building_mat: StandardMaterial3D = preload("res://scenes/main.tscn").get_sub_resource("Material_building")
@onready var ground_mat: StandardMaterial3D = preload("res://scenes/main.tscn").get_sub_resource("Material_ground")

func _ready() -> void:
	generate_city()

func generate_city() -> void:
	_create_ground()
	_create_grid_roads()
	_create_buildings()
	_create_boundary_walls()

func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(city_size * 2, city_size * 2)
	ground.mesh.subdivide_width = 10
	ground.mesh.subdivide_depth = 10
	ground.material_override = ground_mat
	ground.transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.01, 0)
	add_child(ground)

	# Ground collision
	var collision = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D(size = Vector3(city_size * 2, 0.1, city_size * 2))
	collision.add_child(shape)
	collision.global_position = Vector3(0, 0, 0)
	add_child(collision)

func _create_grid_roads() -> void:
	var half_size = city_size
	var step = block_size

	# Main roads
	for i in range(-half_size, half_size + 1, step):
		# Vertical roads
		_create_road_segment(Vector3(i - road_width/2, 0.05, -half_size), Vector3(road_width, 0.1, half_size * 2))
		# Horizontal roads
		_create_road_segment(Vector3(-half_size, 0.05, i - road_width/2), Vector3(half_size * 2, 0.1, road_width))

func _create_road_segment(pos: Vector3, size: Vector3) -> void:
	var road = MeshInstance3D.new()
	road.mesh = BoxMesh.new()
	road.mesh.size = size
	road.material_override = road_mat
	road.global_position = pos + Vector3(size.x/2, 0, size.z/2)
	add_child(road)

func _create_buildings() -> void:
	var half_size = city_size
	var step = block_size
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for x in range(-half_size + step, half_size, step):
		for z in range(-half_size + step, half_size, step):
			if rng.randi() % 100 < building_density * 100:
				_create_building_block(Vector3(x, 0, z), rng)

func _create_building_block(origin: Vector3, rng: RandomNumberGenerator) -> void:
	var num_buildings = rng.randi_range(1, 4)
	var block_w = block_size - road_width
	var block_d = block_size - road_width

	for i in range(num_buildings):
		var bw = rng.randi_range(4, 10)
		var bd = rng.randi_range(4, 10)
		var bh = rng.randf_range(min_building_height, max_building_height)

		var bx = origin.x + rng.randi_range(2, int(block_w - bw - 2))
		var bz = origin.z + rng.randi_range(2, int(block_d - bd - 2))

		var building = MeshInstance3D.new()
		building.mesh = BoxMesh.new()
		building.mesh.size = Vector3(bw, bh, bd)
		building.material_override = building_mat
		building.global_position = Vector3(bx + bw/2, bh/2, bz + bd/2)
		add_child(building)

		# Collision
		var collision = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		shape.shape = BoxShape3D(size = Vector3(bw, bh, bd))
		collision.add_child(shape)
		collision.global_position = building.global_position
		add_child(collision)

		# Random color variation
		var mat = building_mat.duplicate()
		var hue = rng.randf_range(0.0, 0.15)
		mat.albedo_color = Color(0.5 + hue, 0.45 + hue * 0.5, 0.4 + hue * 0.3)
		building.material_override = mat

func _create_boundary_walls() -> void:
	var half = city_size
	var h = 10.0
	var th = 2.0

	# Four walls
	_create_wall(Vector3(-half - th/2, h/2, 0), Vector3(th, h, city_size * 2))
	_create_wall(Vector3(half + th/2, h/2, 0), Vector3(th, h, city_size * 2))
	_create_wall(Vector3(0, h/2, -half - th/2), Vector3(city_size * 2, h, th))
	_create_wall(Vector3(0, h/2, half + th/2), Vector3(city_size * 2, h, th))

func _create_wall(pos: Vector3, size: Vector3) -> void:
	var wall = MeshInstance3D.new()
	wall.mesh = BoxMesh.new()
	wall.mesh.size = size
	wall.material_override = building_mat
	wall.global_position = pos
	add_child(wall)

	var collision = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D(size = size)
	collision.add_child(shape)
	collision.global_position = pos
	add_child(collision)