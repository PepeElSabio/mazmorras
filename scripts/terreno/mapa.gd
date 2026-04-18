extends Node3D

@onready var nodo_salas:    Node3D = $Salas
@onready var nodo_pasillos: Node3D = $Pasillos

var salas:    Array[Sala]    = []
var pasillos: Array[Pasillo] = []

@export var max_profundidad  : int   = 4
@export var prob_rama        : float = 0.9
@export var tam_sala_min     : int   = 6
@export var tam_sala_max     : int   = 14
@export var margen_salas     : int   = 2
@export var grosor_pasillo   : int   = 3
@export var semilla          : int   = 0

signal mapa_listo()

const DIRECCIONES := {
	"N": {"vec": Vector2i.UP,    "opuesta": "S"},
	"S": {"vec": Vector2i.DOWN,  "opuesta": "N"},
	"E": {"vec": Vector2i.RIGHT, "opuesta": "O"},
	"O": {"vec": Vector2i.LEFT,  "opuesta": "E"}
}

var _rng         := RandomNumberGenerator.new()
var _tiles_usados  := {}
var _conexiones    : Array = []

# ── Ciclo de vida ──────────────────────────────────────────

func _ready() -> void:
	generar_y_dibujar()

func generar_y_dibujar() -> void:
	limpiar()
	generar()
	construir()
	mapa_listo.emit()

# ── Generación de salas ────────────────────────────────────
func construir() -> void:
	for sala in salas:
		sala.construir()
	for pasillo in pasillos:
		pasillo.construir()

func generar() -> void:
	_rng.seed = semilla if semilla != 0 else int(Time.get_ticks_msec())
	# Crear sala inicial
	var forma_inicial := Rect2i(0, 0, 10, 10)
	var sala_raiz := _crear_sala(forma_inicial)
	_expandir(sala_raiz, "", 0)

func _expandir(padre: Sala, dir_entrada: String, profundidad: int) -> void:
	if profundidad >= max_profundidad:
		return

	var direcciones_mezcladas = DIRECCIONES.keys()
	direcciones_mezcladas.shuffle()

	for dir_nombre in direcciones_mezcladas:
		if dir_nombre == dir_entrada or _rng.randf() > prob_rama:
			continue

		var datos_dir = DIRECCIONES[dir_nombre]
		var vector_dir = datos_dir["vec"]

		var forma_hijo := _calcular_forma_hijo(padre.forma, vector_dir)
		if forma_hijo == Rect2i():
			continue

		var hijo := _crear_sala(forma_hijo)

		# Guardamos la conexión para crear el pasillo después
		_conexiones.append([padre, hijo])
		generarPasillo(padre, hijo)

		_expandir(hijo, datos_dir["opuesta"], profundidad + 1)

func _crear_sala(forma: Rect2i) -> Sala:
	# Usamos el constructor que creamos antes
	var nueva := Sala.new(forma)
	nodo_salas.add_child(nueva)
	salas.append(nueva)
	_tiles_usados[forma] = true
	return nueva

func _calcular_forma_hijo(forma_padre: Rect2i, dir: Vector2i) -> Rect2i:
	var tam_hijo := Vector2i(
		_rng.randi_range(tam_sala_min, tam_sala_max),
		_rng.randi_range(tam_sala_min, tam_sala_max)
	)
	var gap := margen_salas
	var pos := Vector2i.ZERO

	if dir.x != 0: # Horizontal
		pos.y = _centrar(forma_padre.position.y, forma_padre.size.y, tam_hijo.y)
		pos.x = forma_padre.end.x + gap if dir.x > 0 else forma_padre.position.x - tam_hijo.x - gap
	else: # Vertical
		pos.x = _centrar(forma_padre.position.x, forma_padre.size.x, tam_hijo.x)
		pos.y = forma_padre.end.y + gap if dir.y > 0 else forma_padre.position.y - tam_hijo.y - gap

	var candidata := Rect2i(pos, tam_hijo)
	return candidata if not _colisiona(candidata) else Rect2i()

func _centrar(origen: int, largo_padre: int, largo_hijo: int) -> int:
	return origen + (largo_padre / 2) - (largo_hijo / 2) + _rng.randi_range(-2, 2)

# ── Generación de pasillos ──────────────────────

func generarPasillo(sala1, sala2) -> void:
		var p := Pasillo.new(sala1, sala2, grosor_pasillo)
		nodo_pasillos.add_child(p)
		pasillos.append(p)

# ── Colisiones ─────────────────────────────────────────────

func _colisiona(forma_candidata: Rect2i) -> bool:
	for rect in _tiles_usados:
		# grow(1) evita que las salas se toquen paredes con paredes
		if forma_candidata.grow(1).intersects(rect):
			return true
	return false

# ── Limpieza ──────────────────────────────────────

func limpiar() -> void:
	for s in salas: s.queue_free()
	for p in pasillos: p.queue_free()
	salas.clear()
	pasillos.clear()
	_tiles_usados.clear()
	_conexiones.clear()
