extends Node
## Data permainan (uang, bahan, kue, upgrade). Didaftarkan sebagai autoload "Game".

signal toast(msg: String)

const RECIPES := {
    "brownies": {"name": "Brownies gula", "gula": 2, "tepung": 1, "price": 40, "lv": 1},
    "lapis": {"name": "Lapis karamel", "gula": 3, "tepung": 2, "price": 85, "lv": 2},
    "tart": {"name": "Tart madu gelap", "gula": 5, "tepung": 3, "price": 170, "lv": 3},
}
const SELL_ORDER := ["tart", "lapis", "brownies"]
const SAVE_PATH := "user://save.json"

var money: int = 50
var rep: int = 0
var heat: float = 0.0
var gula: int = 4
var tepung: int = 6
var oven_level: int = 1
var rv_level: int = 1
var cakes: Dictionary = {"brownies": 0, "lapis": 0, "tart": 0}
var baking_key: String = ""
var baking_left: float = 0.0


func _process(delta: float) -> void:
    if baking_key == "":
        return
    baking_left -= delta
    if baking_left <= 0.0:
        var k: String = baking_key
        cakes[k] = int(cakes[k]) + batch_size()
        baking_key = ""
        toast.emit("%s matang" % RECIPES[k]["name"])
        save_game()


func fmt(n: int) -> String:
    var s := str(n * 1000)
    var out := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        out = s[i] + out
        count += 1
        if count % 3 == 0 and i > 0:
            out = "." + out
    return "Rp" + out


func total_cakes() -> int:
    var t := 0
    for k in cakes:
        t += int(cakes[k])
    return t


func best_cake() -> String:
    for k in SELL_ORDER:
        if int(cakes[k]) > 0:
            return k
    return ""


func max_speed() -> float:
    return 24.0 + (rv_level - 1) * 5.0


func batch_size() -> int:
    return 1 + oven_level


func bake_time() -> float:
    return 7.0 - oven_level * 1.5


func oven_cost() -> int:
    if oven_level >= 3:
        return 0
    return 150 if oven_level == 1 else 400


func rv_cost() -> int:
    if rv_level >= 3:
        return 0
    return 200 * rv_level


func buy(item: String, price: int) -> void:
    if money < price:
        toast.emit("Uang kurang")
        return
    money -= price
    if item == "gula":
        gula += 1
    else:
        tepung += 1
    save_game()


func start_bake(k: String) -> void:
    var r: Dictionary = RECIPES[k]
    if baking_key != "":
        toast.emit("Oven masih dipakai")
        return
    if oven_level < int(r["lv"]):
        toast.emit("Butuh oven level %d" % int(r["lv"]))
        return
    if gula < int(r["gula"]) or tepung < int(r["tepung"]):
        toast.emit("Bahan kurang")
        return
    gula -= int(r["gula"])
    tepung -= int(r["tepung"])
    baking_key = k
    baking_left = bake_time()


func upgrade(what: String) -> void:
    var cost: int = oven_cost() if what == "oven" else rv_cost()
    if cost == 0:
        return
    if money < cost:
        toast.emit("Uang kurang")
        return
    money -= cost
    if what == "oven":
        oven_level += 1
    else:
        rv_level += 1
    toast.emit("Upgrade berhasil")
    save_game()


## Menjual satu kue terbaik. Mengembalikan {} bila stok kosong.
func sell_one() -> Dictionary:
    var k: String = best_cake()
    if k == "":
        return {}
    var base: int = int(RECIPES[k]["price"])
    var price: int = int(round(base * (1.0 + rep * 0.03)))
    cakes[k] = int(cakes[k]) - 1
    money += price
    rep += 1
    heat = minf(100.0, heat + 10.0)
    save_game()
    return {"name": RECIPES[k]["name"], "price": price}


## Dipanggil saat polisi menangkap. Mengembalikan jumlah denda.
func busted() -> int:
    var fine: int = mini(money, 40)
    money -= fine
    for k in cakes:
        cakes[k] = floori(float(cakes[k]) / 2.0)
    heat = 10.0
    save_game()
    return fine


func reset() -> void:
    money = 50
    rep = 0
    heat = 0.0
    gula = 4
    tepung = 6
    oven_level = 1
    rv_level = 1
    cakes = {"brownies": 0, "lapis": 0, "tart": 0}
    baking_key = ""
    baking_left = 0.0
    save_game()


func save_game() -> void:
    var data := {
        "money": money, "rep": rep, "gula": gula, "tepung": tepung,
        "oven_level": oven_level, "rv_level": rv_level, "cakes": cakes,
    }
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))


func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return
    var data = JSON.parse_string(f.get_as_text())
    if typeof(data) != TYPE_DICTIONARY:
        return
    money = int(data.get("money", money))
    rep = int(data.get("rep", rep))
    gula = int(data.get("gula", gula))
    tepung = int(data.get("tepung", tepung))
    oven_level = clampi(int(data.get("oven_level", oven_level)), 1, 3)
    rv_level = clampi(int(data.get("rv_level", rv_level)), 1, 3)
    var c = data.get("cakes", {})
    if typeof(c) == TYPE_DICTIONARY:
        for k in cakes:
            cakes[k] = int(c.get(k, 0))
