extends Node3D
## Mobil polisi: mengejar target, menyerah bila terlalu jauh terlalu lama.

const Util = preload("res://scripts/util.gd")

signal caught
signal lost

var target: Node3D
var speed: float = 0.0
var far_time: float = 0.0
var _mr: StandardMaterial3D
var _mb: StandardMaterial3D


func _ready() -> void:
    var body := Util.box(Vector3(2.2, 0.9, 4.4), Color("16161e"))
    body.position.y = 0.7
    add_child(body)
    var door := Util.box(Vector3(2.25, 0.5, 2.0), Color("e8e8f0"))
    door.position.y = 0.7
    add_child(door)
    var top := Util.box(Vector3(1.6, 0.5, 1.8), Color("16161e"))
    top.position.y = 1.4
    add_child(top)
    var r := Util.box(Vector3(0.7, 0.3, 0.5), Color("ff2030"), true)
    r.position = Vector3(-0.45, 1.8, 0.0)
    add_child(r)
    var b := Util.box(Vector3(0.7, 0.3, 0.5), Color("2050ff"), true)
    b.position = Vector3(0.45, 1.8, 0.0)
    add_child(b)
    _mr = r.material_override as StandardMaterial3D
    _mb = b.material_override as StandardMaterial3D


func _physics_process(delta: float) -> void:
    if target == null:
        return
    var diff: Vector3 = target.global_position - global_position
    diff.y = 0.0
    var d: float = diff.length()
    var target_speed: float = 14.0 + Game.heat * 0.12
    speed = lerpf(speed, target_speed, minf(1.0, 2.0 * delta))
    if d > 0.01:
        global_position += diff / d * speed * delta
        rotation.y = atan2(-diff.x, -diff.z)

    var flash: bool = fmod(Time.get_ticks_msec() / 90.0, 2.0) < 1.0
    _mr.emission = Color("ff2030") if flash else Color("200000")
    _mb.emission = Color("100020") if flash else Color("2050ff")

    if d > 110.0:
        far_time += delta
        if far_time > 4.0:
            lost.emit()
            queue_free()
            return
    else:
        far_time = 0.0
    if d < 4.5:
        caught.emit()
        queue_free()
