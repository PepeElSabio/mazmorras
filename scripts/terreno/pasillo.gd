class_name Pasillo
extends Habitaculo

@export var anchura: int = 3

# Referencias a las salas conectadas
@export var sala_a: Sala
@export var sala_b: Sala

var puerta_a: Vector2i
var puerta_b: Vector2i

func _init(_sala_a: Sala = null, _sala_b: Sala = null, _anchura: int = 3) -> void:
	super._init(Rect2i())
	if _sala_a != null and _sala_b != null:
		sala_a = _sala_a
		sala_b = _sala_b
		if _anchura < 3:
			_anchura = 3
		anchura = _anchura

func _ready() -> void:
	if sala_a != null and sala_b != null:
		_calcular_geometria()
	super._ready()

func _calcular_geometria() -> void:
	var offset= anchura/2
	var rect_a = sala_a.forma
	var rect_b = sala_b.forma
	
	# Determinar si la conexión es mayormente horizontal o vertical
	var diff_x = abs(rect_a.get_center().x - rect_b.get_center().x)
	var diff_y = abs(rect_a.get_center().y - rect_b.get_center().y)

	if diff_x > diff_y:
		# --- CONEXIÓN HORIZONTAL ---
		var izq = rect_a if rect_a.position.x < rect_b.position.x else rect_b
		var der = rect_b if izq == rect_a else rect_a
		
		# El pasillo empieza en el borde derecho de la sala izquierda
		# y termina en el borde izquierdo de la sala derecha
		var x_inicio = izq.end.x - 1
		var x_final  = der.position.x
		var ancho_pasillo = x_final - x_inicio + 1
		
		self.forma = Rect2i(x_inicio, izq.get_center().y - offset, ancho_pasillo, anchura)
		
		# Puertas en los puntos exactos de contacto
		puerta_a = Vector2i(x_inicio, izq.get_center().y)
		puerta_b = Vector2i(x_final, izq.get_center().y)
		
	else:
		# --- CONEXIÓN VERTICAL ---
		var sup = rect_a if rect_a.position.y < rect_b.position.y else rect_b
		var inf = rect_b if sup == rect_a else rect_a
		
		# El pasillo empieza en el borde inferior de la sala superior
		# y termina en el borde superior de la sala inferior
		var y_inicio = sup.end.y - 1
		var y_final  = inf.position.y
		var alto_pasillo = y_final - y_inicio + 1
		
		self.forma = Rect2i(sup.get_center().x - offset, y_inicio, anchura, alto_pasillo)
		
		# Puertas en los puntos exactos de contacto
		puerta_a = Vector2i(sup.get_center().x, y_inicio)
		puerta_b = Vector2i(sup.get_center().x, y_final)

	# El pasillo también debe tener sus propios huecos para no bloquear
	añadir_puerta(puerta_a)
	añadir_puerta(puerta_b)
	sala_a.añadir_puerta(puerta_a)
	sala_b.añadir_puerta(puerta_b)
