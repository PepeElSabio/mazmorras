class_name bloque
extends  Node3D

const SUELO : BoxMesh = preload("res://Assets/Terreno/suelo.tres")
const PARED : BoxMesh = preload("res://Assets/Terreno/pared.tres")


static func add(mesh: BoxMesh, tile_pos: Vector3i, tile_size: Vector3i, contenedor: Node3D) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = mesh.duplicate() as BoxMesh
	box.size = Vector3(tile_size)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(tile_pos) + Vector3(tile_size) / 2.0
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	contenedor.add_child(mesh_instance)
	
static func merge(bloques: Array, contenedor: Node3D) -> MeshInstance3D:
	if bloques.is_empty():
		return null
	
	var material: Material = (bloques[0].mesh as BoxMesh).material
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for b in bloques:
		var box := (b.mesh as BoxMesh).duplicate() as BoxMesh
		box.size = Vector3(b.tile_size)
		var offset := Vector3(b.tile_pos) + Vector3(b.tile_size) / 2.0
		var transform := Transform3D(Basis.IDENTITY, offset)
		st.append_from(box, 0, transform)

	var array_mesh: ArrayMesh = st.commit()


	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.material_overlay = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	contenedor.add_child(mesh_instance)
	return mesh_instance
