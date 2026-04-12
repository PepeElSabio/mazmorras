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
@export var nPuertas: int = 0
var tiles: PackedVector2Array
var puertas: PackedVector2Array
var paredes: PackedVector2Array


func _init(_forma: Rect2i = Rect2i(), _nPuertas: int = 0) -> void:
	if _forma != Rect2i():
		forma = _forma
		nPuertas = _nPuertas
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
		@warning_ignore("integer_division")
		var centros_puertas = [
			forma.position + Vector2i(forma.size.x / 2, 0),
			forma.position + Vector2i(forma.size.x / 2, forma.size.y - 1),
			forma.position + Vector2i(forma.size.x - 1, forma.size.y / 2),
			forma.position + Vector2i(0, forma.size.y / 2),
		]

		for i in min(nPuertas, centros_puertas.size()):
			puertas.append(centros_puertas[i])

	_crear_arbol()
	dibujar()



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


func dibujar() -> void:
	var pos_suelo := Vector3i(forma.position.x, 0, forma.position.y)
	var tam_suelo := Vector3i(forma.size.x, 0, forma.size.y)
	bloque.add(bloque.SUELO, pos_suelo, tam_suelo, contenedor_suelo)


	var px := forma.position.x
	var py := forma.position.y
	var sx := forma.size.x
	var sy := forma.size.y

	# Norte (y = py) y Sur (y = py + sy - 1): bloques horizontales
	var segmentos_h := _segmentos_con_puertas(
		PackedVector2Array([
			Vector2(px, py),
			Vector2(px, py + sy - 1),
		]),
		sx, true
	)
	for seg in segmentos_h:
		var ini : int  = seg[0]
		var lon : int  = seg[1]
		var fila: int  = seg[2]
		var con : Node3D = contenedor_paredes_norte if fila == py else contenedor_paredes_sur
		bloque.add(bloque.PARED, Vector3i(ini, 0, fila), Vector3i(lon, altura_pared, 1), con)

	# Oeste (x = px) y Este (x = px + sx - 1): bloques verticales
	var segmentos_v := _segmentos_con_puertas(
		PackedVector2Array([
			Vector2(px,        py),
			Vector2(px + sx - 1, py),
		]),
		sy, false
	)
	for seg in segmentos_v:
		var ini : int  = seg[0]
		var lon : int  = seg[1]
		var col : int  = seg[2]
		var con : Node3D = contenedor_paredes_oeste if col == px else contenedor_paredes_este
		bloque.add(bloque.PARED, Vector3i(col, 0, ini), Vector3i(1, altura_pared, lon), con)


# Devuelve Array de [inicio, longitud, coordenada_fija]
# axis_fixed: true = recorre X (paredes N/S), false = recorre Z (paredes O/E)
func _segmentos_con_puertas(filas: PackedVector2Array, longitud: int, axis_fixed: bool) -> Array:
	var resultado := []
	for fila in filas:
		var coord_fija : int = int(fila.y) if axis_fixed else int(fila.x)
		var coord_ini  : int = int(fila.x) if axis_fixed else int(fila.y)

		# Recoger posiciones de puertas en esta fila/columna
		var huecos := PackedInt32Array()
		for puerta in puertas:
			if axis_fixed and int(puerta.y) == coord_fija:
				huecos.append(int(puerta.x))
			elif not axis_fixed and int(puerta.x) == coord_fija:
				huecos.append(int(puerta.y))
		huecos.sort()

		# Partir la pared en segmentos continuos saltando los huecos
		var cursor := coord_ini
		var fin    := coord_ini + longitud
		for hueco in huecos:
			if hueco > cursor:
				resultado.append([cursor, hueco - cursor, coord_fija])
			# Dintel sobre la puerta
			resultado.append([hueco, 1, coord_fija])  # <-- ver nota abajo
			cursor = hueco + 1
		if cursor < fin:
			resultado.append([cursor, fin - cursor, coord_fija])

	return resultado
