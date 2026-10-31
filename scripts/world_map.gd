extends Node2D

class_name WorldMap

@onready var location_markers: Node2D = $LocationMarkers
@onready var rv_marker: Sprite2D = $RVMarker
@onready var path_drawer: Line2D = $PathDrawer

var locations_data: Dictionary = {}
var selected_location: String = ""
var show_paths: bool = false

func _ready() -> void:
	_build_location_markers()
	visible = false

func _build_location_markers() -> void:
	locations_data = %LocationManager.locations

	for loc_id, loc_data in locations_data:
		var marker = TextureButton.new()
		var texture = _create_marker_texture(loc_data.type if loc_data.has("type") else "sell")
		marker.texture_normal = texture
		marker.texture_hovered = texture
		marker.texture_pressed = texture
		marker.position = loc_data.position
		marker.name = loc_id
		marker.tooltip_text = loc_data.name
		marker.pressed.connect(_on_location_selected.bind(loc_id))
		location_markers.add_child(marker)

		# Add label
		var label = Label.new()
		label.text = loc_data.name
		label.position = Vector2(0, -40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_child(label)

func _create_marker_texture(type: String) -> Texture2D:
	# Create a simple colored circle as texture
	var image = Image.new()
	image.create(40, 40, false, Image.FORMAT_RGBA8)
	image.lock()

	var color: Color
	match type:
		"shop": color = Color.BLUE
		"service": color = Color.GREEN
		"sell": color = Color.YELLOW
		_: color = Color.WHITE

	for x in range(40):
		for y in range(40):
			var dx = x - 20
			var dy = y - 20
			if dx * dx + dy * dy <= 400:  # radius 20
				image.set_pixel(x, y, color)

	image.unlock()
	return ImageTexture.create_from_image(image)

func _on_location_selected(loc_id: String) -> void:
	selected_location = loc_id
	_show_travel_options(loc_id)

func _show_travel_options(loc_id: String) -> void:
	var loc_data = locations_data[loc_id]
	var panel = %UIManager.location_panel
	panel.visible = true

	# Update panel with location info
	panel.get_node("NameLabel").text = loc_data.name
	panel.get_node("FuelCostLabel").text = "Fuel Cost: %.1f" % loc_data.fuel_cost
	panel.get_node("DriveTimeLabel").text = "Drive Time: %.1fs" % loc_data.drive_time
	panel.get_node("RiskLabel").text = "Police Risk: %d%%" % int(loc_data.police_patrol * 100)

	if loc_data.has("type"):
		if loc_data.type == "shop":
			panel.get_node("ActionButton").text = "Buy Ingredients"
			panel.get_node("ActionButton").pressed.connect(_on_buy_ingredients.bind(loc_id))
		elif loc_data.type == "service":
			panel.get_node("ActionButton").text = "Service RV"
			panel.get_node("ActionButton").pressed.connect(_on_service_rv.bind(loc_id))
	else:
		panel.get_node("ActionButton").text = "Sell Here"
		panel.get_node("ActionButton").pressed.connect(_on_travel_to.bind(loc_id))

func _on_travel_to(loc_id: String) -> void:
	var rv = %RV
	if rv.start_drive_to(loc_id, locations_data[loc_id].drive_time, locations_data[loc_id].fuel_cost):
		hide_map()

func _on_buy_ingredients(loc_id: String) -> void:
	# Open shop interface
	%UIManager.show_location_panel(loc_id)

func _on_service_rv(loc_id: String) -> void:
	# Open service interface
	%UIManager.show_location_panel(loc_id)

func show_map() -> void:
	visible = true
	update_rv_marker()

func hide_map() -> void:
	visible = false
	%UIManager._hide_all_panels()

func update_rv_marker() -> void:
	var rv = %RV
	if rv and rv.visible:
		rv_marker.global_position = rv.global_position
		rv_marker.visible = true
	else:
		rv_marker.visible = false

func _process(delta: float) -> void:
	if visible:
		update_rv_marker()
		_draw_paths()

func _draw_paths() -> void:
	if not show_paths:
		path_drawer.points = []
		return

	# Draw paths from RV to all locations
	var rv_pos = %RV.global_position
	path_drawer.points = []

	for loc_id, loc_data in locations_data:
		path_drawer.points.append(rv_pos)
		path_drawer.points.append(loc_data.position)