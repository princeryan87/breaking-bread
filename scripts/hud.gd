extends CanvasLayer
## Antarmuka: statistik, tombol sentuh, dapur, layar awal. Semua dibuat lewat kode.

signal start_pressed
signal reset_pressed
signal kitchen_pressed
signal sell_pressed
signal close_kitchen_pressed

var drive_enabled: bool = false

var _lbl_money: Label
var _lbl_rep: Label
var _lbl_cakes: Label
var _lbl_near: Label
var _heat: ProgressBar
var _btn_kitchen: Button
var _btn_sell: Button
var _toast: Label
var _tween: Tween
var _alert: ColorRect
var _pads: Array = []
var _touch_action: Dictionary = {}
var _mouse_down: bool = false
var _near_dist: float = 1.0e9
var _can_sell: bool = false
var _chase: bool = false
var _kitchen: ColorRect
var _intro: ColorRect
var _k_info: Label
var _k_baking: Label
var _k_recipes: Dictionary = {}
var _k_oven_label: Label
var _k_oven_btn: Button
var _k_rv_label: Label
var _k_rv_btn: Button


func _ready() -> void:
    layer = 10
    _alert = ColorRect.new()
    _alert.color = Color(1.0, 0.1, 0.2, 0.0)
    _alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_alert)
    _alert.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _build_top_bar()
    _pad("KIRI", false, 0, "steer_left")
    _pad("KANAN", false, 1, "steer_right")
    _pad("GAS", true, 0, "gas")
    _pad("REM", true, 1, "brake")
    _btn_kitchen = _action_button("Dapur", -210.0)
    _btn_kitchen.pressed.connect(func(): kitchen_pressed.emit())
    _btn_sell = _action_button("Jual kue", 10.0)
    _btn_sell.pressed.connect(func(): sell_pressed.emit())

    _toast = Label.new()
    _toast.add_theme_font_size_override("font_size", 26)
    _toast.add_theme_stylebox_override("normal", _style(Color(0.17, 0.13, 0.27, 0.92), 10))
    _toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _toast.modulate.a = 0.0
    add_child(_toast)
    _toast.anchor_left = 0.5
    _toast.anchor_right = 0.5
    _toast.anchor_top = 1.0
    _toast.anchor_bottom = 1.0
    _toast.offset_left = -320.0
    _toast.offset_right = 320.0
    _toast.offset_top = -200.0
    _toast.offset_bottom = -140.0

    _build_kitchen()
    _build_intro()


func _process(_delta: float) -> void:
    _lbl_money.text = Game.fmt(Game.money)
    _lbl_rep.text = "Reputasi %d" % Game.rep
    _heat.value = Game.heat
    var cakes_text := "Kue: %d" % Game.total_cakes()
    if Game.baking_key != "":
        cakes_text += " (memanggang)"
    _lbl_cakes.text = cakes_text
    if _near_dist < 1.0e8:
        _lbl_near.text = "Pelanggan: %d m" % int(_near_dist)
    else:
        _lbl_near.text = "Pelanggan: -"
    _btn_sell.modulate = Color(0.6, 1.0, 0.7) if _can_sell else Color.WHITE
    if _chase:
        _alert.color.a = 0.14 + 0.14 * sin(Time.get_ticks_msec() / 120.0)
    else:
        _alert.color.a = 0.0
    if _kitchen.visible:
        _refresh_kitchen()


# ---------- API untuk main.gd ----------

func set_near(dist: float, can_sell: bool) -> void:
    _near_dist = dist
    _can_sell = can_sell


func set_chase(v: bool) -> void:
    _chase = v


func show_toast(msg: String) -> void:
    _toast.text = msg
    _toast.modulate.a = 1.0
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_interval(2.2)
    _tween.tween_property(_toast, "modulate:a", 0.0, 0.3)


func hide_intro() -> void:
    _intro.visible = false


func show_kitchen(v: bool) -> void:
    _kitchen.visible = v
    _btn_kitchen.visible = not v
    _btn_sell.visible = not v
    for p in _pads:
        p["panel"].visible = not v
    if v:
        _release_all()
        _refresh_kitchen()


func set_drive_enabled(v: bool) -> void:
    drive_enabled = v
    if not v:
        _release_all()


# ---------- kontrol sentuh (mendukung banyak jari) ----------

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        _touch(event.index, event.position, event.pressed)
    elif event is InputEventScreenDrag:
        _touch(event.index, event.position, true)
    elif not DisplayServer.is_touchscreen_available():
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            _mouse_down = event.pressed
            _touch(-1, event.position, event.pressed)
        elif event is InputEventMouseMotion and _mouse_down:
            _touch(-1, event.position, true)


func _touch(idx: int, pos: Vector2, down: bool) -> void:
    var action := ""
    if down and drive_enabled:
        for p in _pads:
            var panel: Control = p["panel"]
            if panel.visible and panel.get_global_rect().has_point(pos):
                action = p["action"]
                break
    var old: String = _touch_action.get(idx, "")
    if old == action:
        return
    if old != "":
        Input.action_release(old)
    if action != "":
        Input.action_press(action)
        _touch_action[idx] = action
    else:
        _touch_action.erase(idx)


func _release_all() -> void:
    for idx in _touch_action:
        Input.action_release(_touch_action[idx])
    _touch_action.clear()


# ---------- pembangun UI ----------

func _style(color: Color, radius: int = 10) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(radius)
    s.set_content_margin_all(10.0)
    return s


func _chip(parent: Control) -> Label:
    var pc := PanelContainer.new()
    pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pc.add_theme_stylebox_override("panel", _style(Color(0.17, 0.13, 0.27, 0.92), 8))
    var l := Label.new()
    l.add_theme_font_size_override("font_size", 22)
    pc.add_child(l)
    parent.add_child(pc)
    return l


func _build_top_bar() -> void:
    var flow := HFlowContainer.new()
    flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flow.add_theme_constant_override("h_separation", 8)
    flow.add_theme_constant_override("v_separation", 6)
    add_child(flow)
    flow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    flow.offset_left = 12.0
    flow.offset_right = -12.0
    flow.offset_top = 10.0
    _lbl_money = _chip(flow)
    _lbl_rep = _chip(flow)
    var pc := PanelContainer.new()
    pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pc.add_theme_stylebox_override("panel", _style(Color(0.17, 0.13, 0.27, 0.92), 8))
    flow.add_child(pc)
    var hb := HBoxContainer.new()
    hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pc.add_child(hb)
    var hl := Label.new()
    hl.text = "Panas"
    hl.add_theme_font_size_override("font_size", 22)
    hb.add_child(hl)
    _heat = ProgressBar.new()
    _heat.max_value = 100.0
    _heat.show_percentage = false
    _heat.custom_minimum_size = Vector2(150.0, 22.0)
    _heat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    hb.add_child(_heat)
    _lbl_cakes = _chip(flow)
    _lbl_near = _chip(flow)


func _pad(text: String, right_side: bool, slot: int, action: String) -> void:
    var p := Panel.new()
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.add_theme_stylebox_override("panel", _style(Color(0.17, 0.13, 0.27, 0.75), 24))
    add_child(p)
    p.anchor_top = 1.0
    p.anchor_bottom = 1.0
    p.anchor_left = 1.0 if right_side else 0.0
    p.anchor_right = p.anchor_left
    var off: float = 20.0 + slot * 150.0
    if right_side:
        p.offset_right = -off
        p.offset_left = -off - 130.0
    else:
        p.offset_left = off
        p.offset_right = off + 130.0
    p.offset_top = -150.0
    p.offset_bottom = -20.0
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", 28)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.add_child(l)
    l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _pads.append({"panel": p, "action": action})


func _action_button(text: String, left: float) -> Button:
    var b := Button.new()
    b.text = text
    b.add_theme_font_size_override("font_size", 28)
    add_child(b)
    b.anchor_left = 0.5
    b.anchor_right = 0.5
    b.anchor_top = 1.0
    b.anchor_bottom = 1.0
    b.offset_left = left
    b.offset_right = left + 200.0
    b.offset_top = -120.0
    b.offset_bottom = -40.0
    return b


func _button(text: String, parent: Control) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0.0, 64.0)
    b.add_theme_font_size_override("font_size", 24)
    parent.add_child(b)
    return b


func _label(text: String, size: int, parent: Control) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l


func _build_kitchen() -> void:
    _kitchen = ColorRect.new()
    _kitchen.color = Color(0.07, 0.05, 0.13, 0.97)
    _kitchen.visible = false
    add_child(_kitchen)
    _kitchen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _kitchen.add_child(scroll)
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 10)
    scroll.add_child(box)

    _label("Dapur RV", 38, box)
    _k_info = _label("", 24, box)
    var buy_row := HBoxContainer.new()
    buy_row.add_theme_constant_override("separation", 10)
    box.add_child(buy_row)
    var bg := _button("Gula selundupan %s" % Game.fmt(8), buy_row)
    bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bg.pressed.connect(func(): Game.buy("gula", 8))
    var bt := _button("Tepung %s" % Game.fmt(3), buy_row)
    bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bt.pressed.connect(func(): Game.buy("tepung", 3))

    _label("Resep", 28, box)
    for k in Game.RECIPES:
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _style(Color(0.17, 0.13, 0.27, 1.0), 10))
        box.add_child(card)
        var inner := VBoxContainer.new()
        card.add_child(inner)
        var lbl := _label("", 22, inner)
        var btn := _button("", inner)
        var key: String = k
        btn.pressed.connect(func(): Game.start_bake(key))
        _k_recipes[k] = {"label": lbl, "btn": btn}
    _k_baking = _label("", 24, box)

    _label("Upgrade", 28, box)
    _k_oven_label = _label("", 22, box)
    _k_oven_btn = _button("", box)
    _k_oven_btn.pressed.connect(func(): Game.upgrade("oven"))
    _k_rv_label = _label("", 22, box)
    _k_rv_btn = _button("", box)
    _k_rv_btn.pressed.connect(func(): Game.upgrade("rv"))

    var close := _button("Kembali menyetir", box)
    close.pressed.connect(func(): close_kitchen_pressed.emit())


func _refresh_kitchen() -> void:
    _k_info.text = "Uang %s  |  Gula %d  |  Tepung %d" % [Game.fmt(Game.money), Game.gula, Game.tepung]
    for k in _k_recipes:
        var r: Dictionary = Game.RECIPES[k]
        var row: Dictionary = _k_recipes[k]
        var lbl: Label = row["label"]
        var btn: Button = row["btn"]
        lbl.text = "%s\n%d gula + %d tepung, jual %s, stok %d" % [
            r["name"], r["gula"], r["tepung"], Game.fmt(int(r["price"])), int(Game.cakes[k])]
        var locked: bool = Game.oven_level < int(r["lv"])
        if locked:
            btn.text = "Butuh oven level %d" % int(r["lv"])
        else:
            btn.text = "Panggang %d kue" % Game.batch_size()
        btn.disabled = locked or Game.baking_key != ""
    if Game.baking_key != "":
        var nm: String = Game.RECIPES[Game.baking_key]["name"]
        _k_baking.text = "Memanggang %s... %d dtk. Kamu boleh menyetir sambil menunggu." % [nm, ceili(Game.baking_left)]
    else:
        _k_baking.text = "Oven kosong."
    _k_oven_label.text = "Oven level %d/3: kue per batch lebih banyak, lebih cepat, membuka resep baru" % Game.oven_level
    if Game.oven_level >= 3:
        _k_oven_btn.text = "Maksimal"
        _k_oven_btn.disabled = true
    else:
        _k_oven_btn.text = "Tingkatkan oven %s" % Game.fmt(Game.oven_cost())
        _k_oven_btn.disabled = Game.money < Game.oven_cost()
    _k_rv_label.text = "Mesin RV level %d/3: lebih kencang untuk kabur dari polisi" % Game.rv_level
    if Game.rv_level >= 3:
        _k_rv_btn.text = "Maksimal"
        _k_rv_btn.disabled = true
    else:
        _k_rv_btn.text = "Tingkatkan mesin %s" % Game.fmt(Game.rv_cost())
        _k_rv_btn.disabled = Game.money < Game.rv_cost()


func _build_intro() -> void:
    _intro = ColorRect.new()
    _intro.color = Color(0.07, 0.05, 0.13, 0.97)
    add_child(_intro)
    _intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var center := CenterContainer.new()
    _intro.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    center.add_child(box)
    var t := _label("Kue Gelap", 64, box)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var d := _label("Di kota ini gula dilarang. Panggang kue di dapur RV, jual diam-diam ke pelanggan bertanda merah muda, dan jangan sampai tertangkap polisi.\n\nSentuh: tombol KIRI, KANAN, GAS, REM di bawah layar.\nKeyboard: WASD atau panah, E untuk dapur, spasi untuk menjual.", 24, box)
    d.custom_minimum_size = Vector2(760.0, 0.0)
    var go := _button("Mulai", box)
    go.pressed.connect(func(): start_pressed.emit())
    var rs := _button("Mulai dari awal (hapus simpanan)", box)
    rs.pressed.connect(func(): reset_pressed.emit())
