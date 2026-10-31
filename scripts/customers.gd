extends Node3D
## Pelanggan: orang dengan penanda merah muda di pinggir jalan.

const Util = preload("res://scripts/util.gd")

var list: Array = []


func setup() -> void:
    for n in range(7):
        var g := Node3D.new()
        var b := Util.box(Vector3(1.0, 1.8, 0.7), Color("e8dff5"))
        b.position.y = 0.9
        g.add_child(b)
        var head := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.45
        sm.height = 0.9
        sm.radial_segments = 6
        sm.rings = 3
        head.mesh = sm
        head.material_override = Util.mat(Color("f0c8a8"))
        head.position.y = 2.2
        g.add_child(head)
        var beacon := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 1.1
        cm.bottom_radius = 0.0
        cm.height = 7.0
        cm.radial_segments = 6
        beacon.mesh = cm
        beacon.material_override = Util.mat(Color("ff7ab8"), false, 0.55, true)
        beacon.position.y = 9.0
        g.add_child(beacon)
        add_child(g)
        var c := {"node": g, "alive": true}
        list.append(c)
        _place(c)


func _place(c: Dictionary) -> void:
    var vertical: bool = randf() < 0.5
    var i: int = randi_range(-3, 3)
    var t: float = randf_range(-200.0, 200.0)
    var side: float = 7.6 if randf() < 0.5 else -7.6
    var n: Node3D = c["node"]
    if vertical:
        n.position = Vector3(i * 60.0 + side, 0.0, t)
    else:
        n.position = Vector3(t, 0.0, i * 60.0 + side)
    n.visible = true
    c["alive"] = true


## Pelanggan hidup terdekat: {"node": Node3D atau null, "dist": float, "c": Dictionary}
func nearest(pos: Vector3) -> Dictionary:
    var best := {"node": null, "dist": 1.0e9, "c": null}
    for c in list:
        if not c["alive"]:
            continue
        var n: Node3D = c["node"]
        var d: float = Vector2(n.position.x - pos.x, n.position.z - pos.z).length()
        if d < float(best["dist"]):
            best = {"node": n, "dist": d, "c": c}
    return best


func serve(c: Dictionary) -> void:
    c["alive"] = false
    var n: Node3D = c["node"]
    n.visible = false
    get_tree().create_timer(8.0).timeout.connect(func(): _place(c))


func _process(delta: float) -> void:
    for c in list:
        var n: Node3D = c["node"]
        n.rotation.y += delta
