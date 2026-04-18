class_name Habitaculo
extends Node3D

@export var forma: Rect2i
@export var altura: int = 3
var puertas: Array[Vector2i]

var suelo:          Node3D
var contenedor_paredes:        Node3D
var paredes_norte:  Node3D
var paredes_sur:    Node3D
var paredes_este:   Node3D
var paredes_oeste:  Node3D

func _ready() -> void:
	_crear_arbol()

func _init(_forma: Rect2i = Rect2i(), _altura: int = 3) -> void:
	self.forma   = _forma
	self.altura  = _altura


# ── Árbol de nodos ─────────────────────────────────────────────────────────────
func _crear_arbol() -> void:
	contenedor_paredes        = _crear_nodo("Paredes")
	

func _crear_nodo(nombre: String, padre: Node3D = self) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	padre.add_child(nodo)
	return nodo


# ── Puertas ────────────────────────────────────────────────────────────────────
func set_puertas(_puertas: Array[Vector2i]) -> void:
	puertas = _puertas

func añadir_puerta(_posicion: Vector2i) -> void:
	puertas.append(_posicion)


# ── Construcción ───────────────────────────────────────────────────────────────
func construir() -> void:
	_construir_suelo()
	_construir_paredes()
	debug_puertas()

func _construir_suelo() -> void:
	# Un solo bloque cubre todo el suelo → merge de 1 elemento, directo
	suelo = bloque.merge([{
		mesh      = bloque.SUELO,
		tile_pos  = Vector3i(forma.position.x, -1, forma.position.y),
		tile_size = Vector3i(forma.size.x, 1, forma.size.y)
	}], self)

func _construir_paredes() -> void:
	var x_min := forma.position.x
	var x_max := forma.end.x
	var z_min := forma.position.y
	var z_max := forma.end.y
	
	
	print("--- construir_paredes [%s] forma=%s puertas=%s ---" % [name, forma, puertas])
	print("    Norte z=%d x:[%d..%d]" % [z_min, x_min, x_max-1])
	print("    Sur   z=%d x:[%d..%d]" % [z_max-1, x_min, x_max-1])
	print("    Oeste x=%d z:[%d..%d]" % [x_min, z_min+1, z_max-2])
	print("    Este  x=%d z:[%d..%d]" % [x_max-1, z_min+1, z_max-2])

	var bloques_norte: Array = []
	var bloques_sur:   Array = []
	var bloques_este:  Array = []
	var bloques_oeste: Array = []

	for x in range(x_min, x_max):
		_segmentos(Vector2i(x, z_min),     bloques_norte)
		_segmentos(Vector2i(x, z_max - 1), bloques_sur)

	for z in range(z_min + 1, z_max - 1):
		_segmentos(Vector2i(x_min,     z), bloques_oeste)
		_segmentos(Vector2i(x_max - 1, z), bloques_este)

	# Un merge por orientación → un MeshInstance3D por pared
	if bloques_norte: paredes_norte = bloque.merge(bloques_norte, contenedor_paredes)
	if bloques_sur:   paredes_sur = bloque.merge(bloques_sur,   contenedor_paredes)
	if bloques_este:  paredes_este =bloque.merge(bloques_este,   contenedor_paredes)
	if bloques_oeste: paredes_oeste =bloque.merge(bloques_oeste,  contenedor_paredes)


# Rellena `lista` con los diccionarios de bloques para esta posición
func _segmentos(pos: Vector2i, lista: Array) -> void:
	var altura_puerta := 2
	if pos in puertas:
		var altura_dintel := altura - altura_puerta
		if altura_dintel > 0:
			lista.append({
				mesh      = bloque.PARED,
				tile_pos  = Vector3i(pos.x, altura_puerta, pos.y),
				tile_size = Vector3i(1, altura_dintel, 1)
			})
	else:
		lista.append({
			mesh      = bloque.PARED,
			tile_pos  = Vector3i(pos.x, 0, pos.y),
			tile_size = Vector3i(1, altura, 1)
		})


# ── Debug ──────────────────────────────────────────────────────────────────────
func debug_puertas() -> void:
	print("=== PUERTAS [%s] ===" % name)
	if puertas.is_empty():
		print("\t(ninguna)")
		return
	for i in puertas.size():
		var p := puertas[i]
		print("\t[%d] pos=%s | en_pared=%s" % [i, p, _puerta_en_pared(p)])
	print("===================")

func _puerta_en_pared(pos: Vector2i) -> String:
	var x_min := forma.position.x
	var x_max := forma.end.x   - 1
	var z_min := forma.position.y
	var z_max := forma.end.y   - 1
	if pos.y == z_min: return "Norte"
	if pos.y == z_max: return "Sur"
	if pos.x == x_min: return "Oeste"
	if pos.x == x_max: return "Este"
	return "⚠️ FUERA DE PARED"
