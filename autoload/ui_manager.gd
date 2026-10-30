extends CanvasLayer

class_name UIManager

## ===== NODE REFERENCES =====
@onready var money_label: Label = $HUD/MoneyLabel
@onready var rep_label: Label = $HUD/RepLabel
@onready var heat_bar: ProgressBar = $HUD/HeatBar
@onready var heat_label: Label = $HUD/HeatLabel
@onready var speed_label: Label = $HUD/SpeedLabel
@onready var inventory_panel: Panel = $HUD/InventoryPanel
@onready var baked_panel: Panel = $HUD/BakedPanel
@onready var kitchen_panel: Panel = $KitchenPanel
@onready var upgrade_panel: Panel = $UpgradePanel
@onready var police_warning: Label = $HUD/PoliceWarning
@onready var message_label: Label = $HUD/MessageLabel
@onready var pause_menu: Panel = $PauseMenu

## ===== STATE =====
var current_message_timer: float = 0.0

## ===== SIGNALS =====
signal kitchen_toggle_requested
signal upgrade_toggle_requested
signal pause_requested

func _ready() -> void:
	# Connect to GameManager signals
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	GameManager.heat_changed.connect(_on_heat_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.baked_goods_changed.connect(_on_baked_changed)
	GameManager.upgrade_changed.connect(_on_upgrade_changed)
	GameManager.police_state_changed.connect(_on_police_state_changed)

	# Initial update
	_on_money_changed(GameManager.money)
	_on_reputation_changed(GameManager.reputation)
	_on_heat_changed(GameManager.heat)
	_on_inventory_changed()
	_on_baked_changed()
	_on_upgrade_changed()

	# Hide panels initially
	kitchen_panel.hide()
	upgrade_panel.hide()
	pause_menu.hide()
	police_warning.hide()

func _process(delta: float) -> void:
	if current_message_timer > 0:
		current_message_timer -= delta
		if current_message_timer <= 0:
			message_label.hide()

	# Update speed label
	if GameManager.is_driving:
		var rv = get_tree().get_first_node_in_group("rv")
		if rv and rv.has_method("get_speed"):
			speed_label.text = "Kecepatan: %.1f km/j" % rv.get_speed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_pause_requested()
	elif event.is_action_pressed("interact_kitchen") and not is_paused:
		_kitchen_toggle_requested()
	elif event.is_action_pressed("interact_sell") and not is_paused:
		# Sell handled in RV script
		pass

func _on_money_changed(amount: int) -> void:
	money_label.text = "Uang: $%d" % amount

func _on_reputation_changed(amount: int) -> void:
	rep_label.text = "Reputasi: %d" % amount

func _on_heat_changed(amount: int) -> void:
	heat_bar.value = amount
	heat_label.text = "Panas: %d/%d" % [amount, GameManager.MAX_HEAT]
	heat_bar.modulate = Color.RED.lerp(Color.GREEN, 1.0 - amount / GameManager.MAX_HEAT)

func _on_inventory_changed() -> void:
	var text = "BAHAN:\n"
	for item, count in GameManager.inventory:
		var name = _get_item_name(item)
		text += "%s: %d\n" % [name, count]
	inventory_panel.get_node("Label").text = text

func _on_baked_changed() -> void:
	var text = "KUE SIAP JUAL:\n"
	var total = 0
	for good, count in GameManager.baked_goods:
		if count > 0:
			var name = _get_recipe_name(good)
			text += "%s: %d\n" % [name, count]
			total += count
	if total == 0:
		text += "(kosong)"
	baked_panel.get_node("Label").text = text

func _on_upgrade_changed() -> void:
	# Update upgrade panel
	var oven_btn = upgrade_panel.get_node("OvenUpgradeBtn")
	var engine_btn = upgrade_panel.get_node("EngineUpgradeBtn")

	oven_btn.disabled = GameManager.oven_level >= 3
	if GameManager.oven_level < 3:
		oven_btn.text = "Upgrade Oven (Lv.%d → %d) - $%d" % [
			GameManager.oven_level, GameManager.oven_level + 1,
			GameManager.OVEN_UPGRADE_COST[GameManager.oven_level]
		]
	else:
		oven_btn.text = "Oven MAX"

	engine_btn.disabled = GameManager.engine_level >= 3
	if GameManager.engine_level < 3:
		engine_btn.text = "Upgrade Mesin (Lv.%d → %d) - $%d" % [
			GameManager.engine_level, GameManager.engine_level + 1,
			GameManager.ENGINE_UPGRADE_COST[GameManager.engine_level]
		]
	else:
		engine_btn.text = "Mesin MAX"

func _on_police_state_changed(alert: bool, distance: float) -> void:
	if alert:
		police_warning.show()
		police_warning.text = "⚠ POLISI MENGEJAR! Jarak: %.0fm" % distance
		police_warning.modulate = Color.RED
	else:
		police_warning.hide()

func _kitchen_toggle_requested() -> void:
	if kitchen_panel.visible:
		kitchen_panel.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		kitchen_panel.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	kitchen_toggle_requested.emit()

func _upgrade_toggle_requested() -> void:
	if upgrade_panel.visible:
		upgrade_panel.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		upgrade_panel.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	upgrade_toggle_requested.emit()

func _pause_requested() -> void:
	if pause_menu.visible:
		pause_menu.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameManager.is_paused = false
	else:
		pause_menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.is_paused = true
	pause_requested.emit()

func show_message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_label.show()
	current_message_timer = duration

func _get_item_name(item: String) -> String:
	match item:
		"sugar": return "Gula Selundupan"
		"flour": return "Tepung"
		"honey": return "Madu"
		"chocolate": return "Cokelat"
		default: return item

func _get_recipe_name(recipe_id: String) -> String:
	return GameManager.RECIPES[recipe_id].name

# Button callbacks (connected in scene)
func _on_oven_upgrade_pressed() -> void:
	if GameManager.upgrade_oven():
		show_message("Oven diupgrade ke Lv.%d!" % GameManager.oven_level)
	else:
		show_message("Uang tidak cukup atau oven sudah MAX")

func _on_engine_upgrade_pressed() -> void:
	if GameManager.upgrade_engine():
		show_message("Mesin diupgrade ke Lv.%d!" % GameManager.engine_level)
	else:
		show_message("Uang tidak cukup atau mesin sudah MAX")

func _on_buy_sugar_pressed() -> void:
	if GameManager.spend_money(50):
		GameManager.add_inventory("sugar", 5)
		show_message("Beli 5 Gula Selundupan ($50)")
	else:
		show_message("Uang tidak cukup")

func _on_buy_flour_pressed() -> void:
	if GameManager.spend_money(20):
		GameManager.add_inventory("flour", 10)
		show_message("Beli 10 Tepung ($20)")
	else:
		show_message("Uang tidak cukup")

func _on_buy_honey_pressed() -> void:
	if GameManager.reputation >= 10:
		if GameManager.spend_money(80):
			GameManager.add_inventory("honey", 3)
			show_message("Beli 3 Madu ($80)")
		else:
			show_message("Uang tidak cukup")
	else:
		show_message("Butuh Reputasi 10+")

func _on_buy_chocolate_pressed() -> void:
	if GameManager.reputation >= 25:
		if GameManager.spend_money(150):
			GameManager.add_inventory("chocolate", 2)
			show_message("Beli 2 Cokelat ($150)")
		else:
			show_message("Uang tidak cukup")
	else:
		show_message("Butuh Reputasi 25+")

func _on_craft_brownie_pressed() -> void:
	_craft_recipe("brownie")

func _on_craft_karamel_pressed() -> void:
	_craft_recipe("karamel_layer")

func _on_craft_tart_pressed() -> void:
	_craft_recipe("dark_honey_tart")

func _craft_recipe(recipe_id: String) -> void:
	if not GameManager.can_craft(recipe_id):
		var recipe = GameManager.RECIPES[recipe_id]
		var reason = []
		if GameManager.oven_level < recipe.oven_level_required:
			reason.append("Oven Lv.%d" % recipe.oven_level_required)
		if GameManager.reputation < recipe.min_reputation:
			reason.append("Rep %d" % recipe.min_reputation)
		for item, cost in recipe.cost:
			if GameManager.inventory[item] < cost:
				reason.append("%s %d" % [_get_item_name(item), cost])
		show_message("Tidak bisa buat: " + ", ".join(reason))
		return

	var time = GameManager.get_recipe_time(recipe_id)
	var output = GameManager.get_recipe_output(recipe_id)
	GameManager.craft(recipe_id)

	# Start baking timer on RV
	var rv = get_tree().get_first_node_in_group("rv")
	if rv and rv.has_method("start_baking"):
		rv.start_baking(recipe_id, time, output)

	show_message("Memanggang %s (%.1fs)..." % [GameManager.RECIPES[recipe_id].name, time])

func _on_resume_pressed() -> void:
	_pause_requested()

func _on_quit_pressed() -> void:
	get_tree().quit()