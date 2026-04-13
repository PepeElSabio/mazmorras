class_name pasillo
extends Node3D


var contenedor_suelo         : Node3D
var contenedor_paredes       : Node3D
var contenedor_paredes_norte : Node3D
var contenedor_paredes_sur   : Node3D
var contenedor_paredes_este  : Node3D
var contenedor_paredes_oeste : Node3D
var contenedor_techo         : Node3D

@export var altura_pared : int = 4
@export var anchura      : int = 2   # grosor del pasillo en tiles

# ── Referencias a las salas conectadas ───────────────────────────────────────
@export var sala_a : sala
@export var sala_b : sala

# ── Datos 2D ──────────────────────────────────────────────────────────────────
var forma    : Rect2i          # AABB que envuelve el pasillo
var tiles    : PackedVector2Array
var paredes  : PackedVector2Array
var puerta_a : Vector2i        # tile de conexión con sala_a
var puerta_b : Vector2i        # tile de conexión con sala_b
var horizontal : bool          # true = corre en X, false = corre en Z


func _init(_sala_a: sala = null, _sala_b: sala = null, _anchura: int = 2, _puerta_a: Vector2i = Vector2i.ZERO, _puerta_b: Vector2i = Vector2i.ZERO) -> void:
	if _sala_a != null and _sala_b != null:
		sala_a   = _sala_a
		sala_b   = _sala_b
		anchura  = _anchura



func _ready() -> void:
	if sala_a != null and sala_b != null:
		_calcular_geometria()
		_crear_arbol()


# ── Geometría ────────────────────────────────────────────────────────────────

func _calcular_geometria() -> void:
	tiles   = PackedVector2Array()
	paredes = PackedVector2Array()

	var delta := puerta_b - puerta_a
	horizontal = abs(delta.x) >= abs(delta.y)

	var anchura_total := anchura + 2

	if horizontal:
		var x_ini : int = min(puerta_a.x, puerta_b.x)
		var x_fin : int = max(puerta_a.x, puerta_b.x)
		@warning_ignore("integer_division")
		var z_centro := (puerta_a.y + puerta_b.y) / 2
		@warning_ignore("integer_division")
		var z_ini := z_centro - anchura_total / 2
		forma = Rect2i(x_ini, z_ini, x_fin - x_ini + 1, anchura_total)
	else:
		var z_ini : int = min(puerta_a.y, puerta_b.y)
		var z_fin : int = max(puerta_a.y, puerta_b.y)
		@warning_ignore("integer_division")
		var x_centro := (puerta_a.x + puerta_b.x) / 2
		@warning_ignore("integer_division")
		var x_ini := x_centro - anchura_total / 2
		forma = Rect2i(x_ini, z_ini, anchura_total, z_fin - z_ini + 1)

	for y in forma.size.y:
		for x in forma.size.x:
			var tile := forma.position + Vector2i(x, y)
			tiles.append(tile)
			if x == 0 or x == forma.size.x - 1 or y == 0 or y == forma.size.y - 1:
				paredes.append(tile)

# ── Árbol de nodos ───────────────────────────────────────────────────────────

func _crear_arbol() -> void:
	contenedor_suelo         = _crear_nodo("Suelo")
	contenedor_paredes       = _crear_nodo("Paredes")
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


# ── Dibujo ───────────────────────────────────────────────────────────────────
func dibujar() -> void:
	var px := forma.position.x
	var py := forma.position.y
	var sx := forma.size.x
	var sy := forma.size.y

	bloque.add(bloque.SUELO, Vector3i(px, 0, py), Vector3i(sx, 0, sy), contenedor_suelo)

	# Norte y sur: longitud completa
	_pared_h(px,        py,        sx, contenedor_paredes_norte)
	_pared_h(px,        py + sy-1, sx, contenedor_paredes_sur)

	# Este y oeste: sin las esquinas (py+1, sy-2)
	_pared_v(px,        py+1, sy-2, contenedor_paredes_oeste)
	_pared_v(px + sx-1, py+1, sy-2, contenedor_paredes_este)

func _pared_h(px: int, fila: int, longitud: int, con: Node3D) -> void:
	bloque.add(bloque.PARED, Vector3i(px, 0, fila), Vector3i(longitud, altura_pared, 1), con)

func _pared_v(col: int, py: int, longitud: int, con: Node3D) -> void:
	bloque.add(bloque.PARED, Vector3i(col, 0, py), Vector3i(1, altura_pared, longitud), con)
