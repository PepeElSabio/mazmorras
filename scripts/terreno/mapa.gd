extends Node3D

@onready var Salas:    Node3D = $Salas
@onready var Pasillos: Node3D = $Pasillos

var salas:    Array[sala]    = []
var pasillos: Array[pasillo] = []

@export var max_profundidad : int   = 4
@export var prob_rama       : float = 0.9
@export var tam_sala_min    : int   = 6
@export var tam_sala_max    : int   = 14
@export var margen_salas    : int   = 2
@export var grosor_pasillo  : int   = 2
@export var semilla         : int   = 0

signal mapa_listo()

const DIRS := {
	"N": Vector2i( 0, -1),
	"S": Vector2i( 0,  1),
	"E": Vector2i( 1,  0),
	"O": Vector2i(-1,  0),
}
const OPUESTO := { "N": "S", "S": "N", "E": "O", "O": "E" }

var _rng         := RandomNumberGenerator.new()
var _ocupadas    := {}
var _conexiones  : Array = []

# ── Arranque ───────────────────────────────────────────────

func _ready() -> void:
	generar_y_dibujar()

func generar_y_dibujar() -> void:
	limpiar()
	_generar_datos()
	_generar_pasillos()
	_asignar_puertas()
	dibujar()
	mapa_listo.emit()

func _generar_datos() -> void:
	_rng.seed = semilla if semilla != 0 else int(Time.get_ticks_msec())
	_generar_salas()

# ── Salas ──────────────────────────────────────────────────

func _generar_salas() -> void:
	salas.clear()
	_ocupadas.clear()
	_conexiones.clear()
	var raiz := _crear_sala(Rect2i(0, 0, 20, 20),)
	_expandir(raiz, "", 0)

func _expandir(padre: sala, vino_de: String, profundidad: int) -> void:
	if profundidad >= max_profundidad:
		return
	var dirs_orden: Array = ["N", "S", "E", "O"]
	for dir_nombre in dirs_orden:
		if dir_nombre == vino_de:
			continue
		if _rng.randf() > prob_rama:
			continue
		var dir: Vector2i = DIRS[dir_nombre]
		var forma_hijo := _calcular_forma_hijo(padre.forma, dir)
		if forma_hijo == Rect2i():
			continue
		var hijo := _crear_sala(forma_hijo)
		var puerta_padre := _tile_borde(padre.forma, dir)
		var puerta_hijo  := _tile_borde(forma_hijo, DIRS[OPUESTO[dir_nombre]])
		_conexiones.append([padre, hijo, puerta_padre, puerta_hijo])
		_expandir(hijo, OPUESTO[dir_nombre], profundidad + 1)

func _crear_sala(forma: Rect2i) -> sala:
	var s := sala.new(forma)
	Salas.add_child(s)
	salas.append(s)
	_marcar_ocupada(forma)
	return s

func _calcular_forma_hijo(padre_forma: Rect2i, dir: Vector2i) -> Rect2i:
	var ancho := _rng.randi_range(tam_sala_min, tam_sala_max)
	var alto  := _rng.randi_range(tam_sala_min, tam_sala_max)
	var gap   := margen_salas + 3
	var px    := 0
	var py    := 0

	if dir.x == 0 and dir.y == -1:
		py = padre_forma.position.y - alto - gap
		px = _centrar_en(padre_forma.position.x, padre_forma.size.x, ancho)
	elif dir.x == 0 and dir.y == 1:
		py = padre_forma.end.y + gap
		px = _centrar_en(padre_forma.position.x, padre_forma.size.x, ancho)
	elif dir.x == 1 and dir.y == 0:
		px = padre_forma.end.x + gap
		py = _centrar_en(padre_forma.position.y, padre_forma.size.y, alto)
	elif dir.x == -1 and dir.y == 0:
		px = padre_forma.position.x - ancho - gap
		py = _centrar_en(padre_forma.position.y, padre_forma.size.y, alto)
	else:
		return Rect2i()

	var candidata := Rect2i(Vector2i(px, py), Vector2i(ancho, alto))
	if _colisiona(candidata):
		return Rect2i()
	return candidata

func _centrar_en(origen: int, largo_padre: int, largo_hijo: int) -> int:
	@warning_ignore("integer_division")
	var base   := origen + largo_padre / 2 - largo_hijo / 2
	var jitter := _rng.randi_range(-2, 2)
	return base + jitter

func _tile_borde(forma: Rect2i, dir: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	var cx := forma.position.x + forma.size.x / 2
	@warning_ignore("integer_division")
	var cy := forma.position.y + forma.size.y / 2
	if dir.x == 0 and dir.y == -1:  return Vector2i(cx, forma.position.y)      # Norte: primer tile interior
	if dir.x == 0 and dir.y == 1:   return Vector2i(cx, forma.end.y - 1)       # Sur:   último tile interior
	if dir.x == 1 and dir.y == 0:   return Vector2i(forma.end.x - 1, cy)       # Este:  último tile interior
	if dir.x == -1 and dir.y == 0:  return Vector2i(forma.position.x, cy)      # Oeste: primer tile interior
	return Vector2i.ZERO

# ── Pasillos ───────────────────────────────────────────────

func _generar_pasillos() -> void:
	pasillos.clear()
	for conexion in _conexiones:
		var sa      : sala     = conexion[0]
		var sb      : sala     = conexion[1]
		var p_en_sa : Vector2i = conexion[2]
		var p_en_sb : Vector2i = conexion[3]
		var p := pasillo.new(sa, sb, grosor_pasillo, p_en_sa, p_en_sb)
		Pasillos.add_child(p)
		pasillos.append(p)

# ── Puertas ────────────────────────────────────────────────

func _asignar_puertas() -> void:
	for conexion in _conexiones:
		var sa      : sala     = conexion[0]
		var sb      : sala     = conexion[1]
		var p_en_sa : Vector2i = conexion[2]
		var p_en_sb : Vector2i = conexion[3]
		sa.add_puertas(p_en_sa)
		sb.add_puertas(p_en_sb)


# ── Colisiones ─────────────────────────────────────────────

func _marcar_ocupada(forma: Rect2i) -> void:
	_ocupadas[forma] = true

func _colisiona(forma: Rect2i) -> bool:
	var con_margen := forma.grow(1)
	for rect in _ocupadas:
		if con_margen.intersects(rect):
			return true
	return false

# ── Dibujo ─────────────────────────────────────────────────

func dibujar() -> void:
	for s in salas:
		s.dibujar()
	for p in pasillos:
		p.dibujar()

# ── Limpieza ───────────────────────────────────────────────

func limpiar() -> void:
	for hijo in Salas.get_children():
		hijo.queue_free()
	for hijo in Pasillos.get_children():
		hijo.queue_free()
	salas.clear()
	pasillos.clear()
	_conexiones.clear()
