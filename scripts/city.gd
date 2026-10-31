extends Node3D
## Kota low poly: tanah, jalan grid, gedung dengan tabrakan, dan tembok batas.

const Util = preload("res://scripts/util.gd")

const ROAD_W := 14.0
const HALF := 240.0

var palette: Array = [
    Color("5b4b8a"), Color("7a4f7d"), Color("3f5a8a"),
    Color("8a5a6a"), Color("4a7a7a"), Color("6a6a9a"),
]


func build() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    _plane(Vector2(520.0, 520.0), Vector3(0.0, 0.0, 0.0), Color("3a3354"))
    for i in range(-4, 5):
        _plane(Vector2(ROAD_W, 500.0), Vector3(i * 60.0, 0.03, 0.0), Color("25232d"))
        _plane(Vector2(500.0, ROAD_W), Vector3(0.0, 0.03, i * 60.0), Color("25232d"))
    for i in range(-4, 4):
        for j in range(-4, 4):
            for k in range(2):
                _building(rng, i, j)
    var t := 2.0
    _wall(Vector3(-HALF - t, 5.0, 0.0), Vector3(t * 2.0, 10.0, HALF * 2.0 + 8.0))
    _wall(Vector3(HALF + t, 5.0, 0.0), Vector3(t * 2.0, 10.0, HALF * 2.0 + 8.0))
    _wall(Vector3(0.0, 5.0, -HALF - t), Vector3(HALF * 2.0 + 8.0, 10.0, t * 2.0))
    _wall(Vector3(0.0, 5.0, HALF + t), Vector3(HALF * 2.0 + 8.0, 10.0, t * 2.0))


func _plane(size: Vector2, pos: Vector3, color: Color) -> void:
    var mi := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = size
    mi.mesh = pm
    mi.material_override = Util.mat(color)
    mi.position = pos
    add_child(mi)


func _building(rng: RandomNumberGenerator, i: int, j: int) -> void:
    var w := rng.randf_range(10.0, 24.0)
    var d := rng.randf_range(10.0, 24.0)
    var h := rng.randf_range(7.0, 30.0)
    var cx := i * 60.0 + 30.0 + rng.randf_range(-1.0, 1.0) * (23.0 - w / 2.0 - 1.0)
    var cz := j * 60.0 + 30.0 + rng.randf_range(-1.0, 1.0) * (23.0 - d / 2.0 - 1.0)
    var body := StaticBody3D.new()
    body.position = Vector3(cx, h / 2.0, cz)
    body.add_child(Util.box(Vector3(w, h, d), palette[rng.randi() % palette.size()]))
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(w, h, d)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)


func _wall(pos: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.add_child(Util.box(size, Color("1d1730")))
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)
    add_child(body)
