extends CharacterBody3D
## RV pemain: kamera first-person di dalam kabin, setir, gas, rem.

const Util = preload("res://scripts/util.gd")

var speed: float = 0.0
var steer: float = 0.0
var frozen: bool = false
var cam: Camera3D
var _wheel: Node3D


func _ready() -> void:
    motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.8, 2.6, 6.0)
    cs.shape = shape
    cs.position = Vector3(0.0, 1.3, 0.0)
    add_child(cs)

    cam = Camera3D.new()
    cam.position = Vector3(0.0, 2.4, 0.8)
    cam.fov = 75.0
    cam.far = 320.0
    add_child(cam)
    cam.current = true

    var dash := Util.box(Vector3(2.8, 0.5, 0.9), Color("1b1726"))
    dash.position = Vector3(0.0, -0.85, -1.5)
    cam.add_child(dash)
    var stripe := Util.box(Vector3(2.8, 0.06, 0.06), Color("ff7ab8"), true)
    stripe.position = Vector3(0.0, -0.58, -1.95)
    cam.add_child(stripe)

    _wheel = Node3D.new()
    _wheel.position = Vector3(-0.55, -0.45, -1.2)
    cam.add_child(_wheel)
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.3
    tm.outer_radius = 0.42
    tm.rings = 12
    tm.ring_segments = 6
    ring.mesh = tm
    ring.material_override = Util.mat(Color("0e0b14"))
    ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
    _wheel.add_child(ring)


func _physics_process(delta: float) -> void:
    if frozen:
        speed = 0.0
        velocity = Vector3.ZERO
        return
    var max_s: float = Game.max_speed()
    if Input.is_action_pressed("gas"):
        speed += 16.0 * delta
    elif Input.is_action_pressed("brake"):
        speed -= (34.0 if speed > 0.0 else 12.0) * delta
    speed -= speed * 0.35 * delta
    speed = clampf(speed, -8.0, max_s)

    var target_steer := Input.get_axis("steer_right", "steer_left")
    steer = lerpf(steer, target_steer, minf(1.0, 8.0 * delta))
    rotation.y += steer * 1.7 * clampf(speed / 10.0, -1.0, 1.0) * delta

    var fwd := -global_transform.basis.z
    velocity = fwd * speed
    move_and_slide()
    speed = clampf(velocity.dot(fwd), -8.0, max_s)
    position.y = 0.0
    _wheel.rotation.z = -steer * 0.8
