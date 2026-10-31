extends Node3D
## Penghubung semua bagian game.

const CityScript = preload("res://scripts/city.gd")
const RVScript = preload("res://scripts/rv.gd")
const CustomersScript = preload("res://scripts/customers.gd")
const PoliceScript = preload("res://scripts/police.gd")
const HudScript = preload("res://scripts/hud.gd")

var rv
var customers
var hud
var police = null
var started: bool = false
var kitchen_open: bool = false
var spawn_cool: float = 0.0


func _ready() -> void:
    randomize()
    _setup_input()
    _setup_environment()
    Game.load_game()

    var city = CityScript.new()
    add_child(city)
    city.build()

    rv = RVScript.new()
    add_child(rv)

    customers = CustomersScript.new()
    add_child(customers)
    customers.setup()

    hud = HudScript.new()
    add_child(hud)
    hud.start_pressed.connect(_on_start)
    hud.reset_pressed.connect(_on_reset)
    hud.kitchen_pressed.connect(_toggle_kitchen)
    hud.sell_pressed.connect(_try_sell)
    hud.close_kitchen_pressed.connect(_toggle_kitchen)
    Game.toast.connect(hud.show_toast)


func _setup_input() -> void:
    _add_action("steer_left", [KEY_A, KEY_LEFT])
    _add_action("steer_right", [KEY_D, KEY_RIGHT])
    _add_action("gas", [KEY_W, KEY_UP])
    _add_action("brake", [KEY_S, KEY_DOWN])
    _add_action("kitchen", [KEY_E])
    _add_action("sell", [KEY_SPACE])


func _add_action(action: String, keys: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for k in keys:
        var ev := InputEventKey.new()
        ev.physical_keycode = k
        InputMap.action_add_event(action, ev)


func _setup_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("2b2144")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("9a88c0")
    env.ambient_light_energy = 0.9
    env.fog_enabled = true
    env.fog_light_color = Color("2b2144")
    env.fog_density = 0.008
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.light_color = Color("bfc4ff")
    sun.light_energy = 0.8
    sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
    add_child(sun)


func _on_start() -> void:
    started = true
    hud.hide_intro()
    hud.set_drive_enabled(true)


func _on_reset() -> void:
    Game.reset()
    _on_start()


func _unhandled_input(event: InputEvent) -> void:
    if not started:
        return
    if event.is_action_pressed("kitchen"):
        _toggle_kitchen()
    elif event.is_action_pressed("sell") and not kitchen_open:
        _try_sell()


func _toggle_kitchen() -> void:
    if not started:
        return
    if kitchen_open:
        kitchen_open = false
        rv.frozen = false
        hud.show_kitchen(false)
        hud.set_drive_enabled(true)
        return
    if police != null:
        hud.show_toast("Polisi mengejar! Tidak bisa masuk dapur")
        return
    if absf(rv.speed) >= 3.0:
        hud.show_toast("Berhenti dulu untuk masuk dapur")
        return
    kitchen_open = true
    rv.frozen = true
    hud.set_drive_enabled(false)
    hud.show_kitchen(true)


func _try_sell() -> void:
    var near: Dictionary = customers.nearest(rv.position)
    if near["node"] == null or float(near["dist"]) > 11.0:
        hud.show_toast("Belum ada pelanggan di dekatmu")
        return
    if absf(rv.speed) >= 4.0:
        hud.show_toast("Pelan dulu, nanti curiga")
        return
    var res: Dictionary = Game.sell_one()
    if res.is_empty():
        hud.show_toast("Stok kue kosong. Buka dapur.")
        return
    customers.serve(near["c"])
    hud.show_toast("%s terjual %s" % [res["name"], Game.fmt(int(res["price"]))])


func _physics_process(delta: float) -> void:
    if not started:
        return
    var near: Dictionary = customers.nearest(rv.position)
    var can_sell: bool = near["node"] != null and float(near["dist"]) < 11.0 \
        and absf(rv.speed) < 4.0 and Game.best_cake() != ""
    hud.set_near(float(near["dist"]), can_sell)
    hud.set_chase(police != null)
    if kitchen_open:
        return
    if police == null:
        spawn_cool -= delta
        Game.heat = maxf(0.0, Game.heat - 1.2 * delta)
        if Game.heat >= 50.0 and spawn_cool <= 0.0:
            _spawn_police()


func _spawn_police() -> void:
    var a: float = randf_range(0.0, TAU)
    var p: Vector3 = rv.position + Vector3(cos(a), 0.0, sin(a)) * 85.0
    p.x = clampf(p.x, -230.0, 230.0)
    p.z = clampf(p.z, -230.0, 230.0)
    police = PoliceScript.new()
    police.target = rv
    add_child(police)
    police.position = p
    police.caught.connect(_on_caught)
    police.lost.connect(_on_lost)
    hud.show_toast("Polisi mengejar! Kabur sejauh mungkin")


func _on_caught() -> void:
    police = null
    var fine: int = Game.busted()
    rv.speed = 0.0
    spawn_cool = 15.0
    hud.show_toast("Tertangkap! Denda %s, separuh kue disita" % Game.fmt(fine))


func _on_lost() -> void:
    police = null
    Game.heat *= 0.3
    spawn_cool = 10.0
    hud.show_toast("Polisi kehilangan jejak")
