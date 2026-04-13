class_name sala
extends  Node3D


var contenedor_suelo         : Node3D
var contenedor_paredes       : Node3D
var contenedor_paredes_norte : Node3D
var contenedor_paredes_sur   : Node3D
var contenedor_paredes_este  : Node3D
var contenedor_paredes_oeste : Node3D
var contenedor_techo         : Node3D

@export var altura_pared : int = 4

# ── Datos 2D ──────────────────────────────────────────────────────────────────



@export var forma: Rect2i
var tiles: PackedVector2Array
var puertas: PackedVector2Array
var paredes: PackedVector2Array


func _init(_forma: Rect2i ) -> void:
	if _forma != Rect2i():
		forma = _forma
		tiles = PackedVector2Array()
		puertas = PackedVector2Array()
		paredes = PackedVector2Array()




func _ready():
	if forma != Rect2i():
		tiles = PackedVector2Array()
		puertas = PackedVector2Array()
		paredes = PackedVector2Array()

		for y in forma.size.y:
			for x in forma.size.x:
				var tile = forma.position + Vector2i(x, y)
				tiles.append(tile)

				if x == 0 or x == forma.size.x - 1 or y == 0 or y == forma.size.y - 1:
					paredes.append(tile)
	_crear_arbol()



func _crear_arbol() -> void:
	contenedor_suelo = _crear_nodo("Suelo")
	contenedor_paredes = _crear_nodo("Paredes")
	contenedor_paredes_norte = _crear_nodo("ParedesNorte", contenedor_paredes)
	contenedor_paredes_sur   = _crear_nodo("ParedesSur",   contenedor_paredes)
	contenedor_paredes_este  = _crear_nodo("ParedesEste",  contenedor_paredes)
	contenedor_paredes_oeste = _crear_nodo("ParedesOeste", contenedor_paredes)

	contenedor_techo         = _crear_nodo("Techo")



func _crear_nodo(nombre: String, padre: Node3D = self) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	padre.add_child(nodo)
	return nodo

func _exit_tree() -> void:
	pass

func add_puertas(puerta : Vector2i):
	puertas.append(puerta)

func dibujar() -> void:
	var px := forma.position.x
	var py := forma.position.y
	var sx := forma.size.x
	var sy := forma.size.y

	bloque.add(bloque.SUELO, Vector3i(px, 0, py), Vector3i(sx, 0, sy), contenedor_suelo)
	_pared_h(px,        py,        sx, contenedor_paredes_norte)
	_pared_h(px,        py + sy-1, sx, contenedor_paredes_sur)
	_pared_v(px,        py,        sy, contenedor_paredes_oeste)
	_pared_v(px + sx-1, py,        sy, contenedor_paredes_este)

func _pared_h(px: int, fila: int, longitud: int, con: Node3D) -> void:
	bloque.add(bloque.PARED, Vector3i(px, 0, fila), Vector3i(longitud, altura_pared, 1), con)

func _pared_v(col: int, py: int, longitud: int, con: Node3D) -> void:
	bloque.add(bloque.PARED, Vector3i(col, 0, py), Vector3i(1, altura_pared, longitud), con)
