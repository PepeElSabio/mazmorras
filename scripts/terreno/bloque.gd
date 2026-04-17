class_name bloque
extends  Node3D

const SUELO : BoxMesh = preload("res://Assets/Terreno/suelo.tres")
const PARED : BoxMesh = preload("res://Assets/Terreno/pared.tres")


static func add(mesh: BoxMesh, tile_pos: Vector3i, tile_size: Vector3i, contenedor: Node3D) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = mesh.duplicate() as BoxMesh
	box.size = Vector3(tile_size)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(tile_pos) + Vector3(tile_size) / 2.0 - Vector3.ONE*(0.5)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	contenedor.add_child(mesh_instance)
	print(mesh_instance.position)
