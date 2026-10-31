extends CanvasLayer

class_name UIManager

@onready var money_label: Label = $HUD/MoneyLabel
@onready var reputation_bar: ProgressBar = $HUD/ReputationBar
@onready var heat_bar: ProgressBar = $HUD/HeatBar
@onready var day_label: Label = $HUD/DayLabel
@onready var fuel_bar: ProgressBar = $HUD/RVStatus/FuelBar
@onready var condition_bar: ProgressBar = $HUD/RVStatus/ConditionBar

@onready var kitchen_panel: Control = $Panels/KitchenPanel
@onready var recipe_list: VBoxContainer = $Panels/KitchenPanel/RecipeList
@onready var inventory_panel: Control = $Panels/InventoryPanel
@onready var location_panel: Control = $Panels/LocationPanel
@onready var upgrade_panel: Control = $Panels/UpgradePanel
@onready var sell_panel: Control = $Panels/SellPanel
@onready var pause_menu: Control = $Menus/PauseMenu
@onready var game_over_screen: Control = $Menus/GameOverScreen

@onready var rv_controller: RVController = %RV

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	GameManager.heat_changed.connect(_on_heat_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.game_over.connect(_on_game_over)

	_hide_all_panels()
	_update_all()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _update_all() -> void:
	_on_money_changed(GameManager.money)
	_on_reputation_changed(GameManager.reputation)
	_on_heat_changed(GameManager.heat)
	_on_day_changed(GameManager.current_day)
	_update_rv_status()

func _on_money_changed(amount: int) -> void:
	money_label.text = "$%d" % amount

func _on_reputation_changed(amount: int) -> void:
	reputation_bar.value = amount

func _on_heat_changed(amount: float) -> void:
	heat_bar.value = amount
	if amount > 70:
		heat_bar.modulate = Color.RED
	elif amount > 40:
		heat_bar.modulate = Color.YELLOW
	else:
		heat_bar.modulate = Color.GREEN

func _on_day_changed(day: int) -> void:
	day_label.text = "Day %d" % day

func _update_rv_status() -> void:
	if rv_controller:
		fuel_bar.value = rv_controller.get_fuel_percentage() * 100
		condition_bar.value = rv_controller.get_condition_percentage() * 100

func show_kitchen_panel() -> void:
	_hide_all_panels()
	kitchen_panel.visible = true
	_populate_recipe_list()

func _populate_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	for recipe_id, recipe in GameManager.recipes:
		var btn = Button.new()
		btn.text = "%s ($%d)" % [recipe_id.capitalize(), recipe.base_price]
		btn.pressed.connect(_on_recipe_selected.bind(recipe_id))
		recipe_list.add_child(btn)

func _on_recipe_selected(recipe_id: String) -> void:
	var kitchen = %Kitchen
	if kitchen.start_bake(recipe_id):
		_update_rv_status()

func show_inventory_panel() -> void:
	_hide_all_panels()
	inventory_panel.visible = true
	_populate_inventory()

func _populate_inventory() -> void:
	# Update ingredient counts and baked goods
	pass

func show_location_panel(location_name: String) -> void:
	_hide_all_panels()
	location_panel.visible = true
	# Populate location-specific options

func show_sell_panel() -> void:
	_hide_all_panels()
	sell_panel.visible = true
	_populate_sell_list()

func _populate_sell_list() -> void:
	for child in sell_panel.get_node("SellList").get_children():
		child.queue_free()

	for good, amount in GameManager.baked_goods:
		if amount > 0:
			var recipe = GameManager.recipes.get(good)
			if recipe:
				var hbox = HBoxContainer.new()
				var label = Label.new()
				label.text = "%s x%d ($%d each)" % [good.capitalize(), amount, recipe.base_price]
				var sell_btn = Button.new()
				sell_btn.text = "Sell 1"
				sell_btn.pressed.connect(_on_sell_one.bind(good))
				hbox.add_child(label)
				hbox.add_child(sell_btn)
				sell_panel.get_node("SellList").add_child(hbox)

func _on_sell_one(recipe_id: String) -> void:
	GameManager.sell_goods(recipe_id, 1)
	_populate_sell_list()
	_on_money_changed(GameManager.money)

func show_upgrade_panel() -> void:
	_hide_all_panels()
	upgrade_panel.visible = true
	_populate_upgrades()

func _populate_upgrades() -> void:
	for child in upgrade_panel.get_node("UpgradeList").get_children():
		child.queue_free()

	for upgrade_id, owned in GameManager.upgrades:
		if not owned:
			var cost = GameManager.upgrade_costs[upgrade_id]
			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.text = "%s - $%d" % [upgrade_id.replace("_", " ").capitalize(), cost]
			var buy_btn = Button.new()
			buy_btn.text = "Buy"
			buy_btn.disabled = not GameManager.can_afford_upgrade(upgrade_id)
			buy_btn.pressed.connect(_on_buy_upgrade.bind(upgrade_id))
			hbox.add_child(label)
			hbox.add_child(buy_btn)
			upgrade_panel.get_node("UpgradeList").add_child(hbox)

func _on_buy_upgrade(upgrade_id: String) -> void:
	if GameManager.buy_upgrade(upgrade_id):
		_populate_upgrades()
		_on_money_changed(GameManager.money)

func _hide_all_panels() -> void:
	kitchen_panel.visible = false
	inventory_panel.visible = false
	location_panel.visible = false
	upgrade_panel.visible = false
	sell_panel.visible = false

func _toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused

func _on_game_over(reason: String) -> void:
	game_over_screen.visible = true
	game_over_screen.get_node("ReasonLabel").text = reason
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()