extends RefCounted
## Fungsi bantu untuk membuat bentuk 3D sederhana (low poly) lewat kode.

static func mat(color: Color, emissive: bool = false, alpha: float = 1.0, unshaded: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, alpha)
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if emissive:
        m.emission_enabled = true
        m.emission = color
    if unshaded:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m


static func box(size: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat(color, emissive)
    return mi
