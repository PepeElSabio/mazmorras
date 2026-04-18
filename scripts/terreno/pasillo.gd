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
	super._ready()
	if sala_a != null and sala_b != null:
		_calcular_geometria()
	

func _calcular_geometria() -> void:
	var rect_a = sala_a.forma
	var rect_b = sala_b.forma
	var offset = anchura / 2

	var diff = rect_a.get_center() - rect_b.get_center()
	var es_horizontal = abs(diff.x) > abs(diff.y)

	# Identificar sala inicial (s1) y final (s2) según orientación
	var s1 = rect_a if (rect_a.position.x < rect_b.position.x if es_horizontal else rect_a.position.y < rect_b.position.y) else rect_b
	var s2 = rect_b if s1 == rect_a else rect_a
	
	if es_horizontal:
		# Entramos 1 tile en s1 (x_ini - 1) y 1 tile en s2 (x_fin + 1)
		var x_ini = s1.end.x - 1
		var x_fin = s2.position.x
		var z_c = s1.get_center().y
		
		self.forma = Rect2i(x_ini, z_c - offset, x_fin - x_ini + 1, anchura)
		
		# Las puertas ahora coinciden exactamente en la intersección
		puerta_a = Vector2i(x_ini, z_c)
		puerta_b = Vector2i(x_fin, z_c)
	else:
		# Entramos 1 tile en s1 (y_ini - 1) y 1 tile en s2 (y_fin + 1)
		var y_ini = s1.end.y - 1
		var y_fin = s2.position.y
		var x_c = s1.get_center().x
		
		self.forma = Rect2i(x_c - offset, y_ini, anchura, y_fin - y_ini + 1)
		
		puerta_a = Vector2i(x_c, y_ini)
		puerta_b = Vector2i(x_c, y_fin)

	añadir_puerta(puerta_a)
	añadir_puerta(puerta_b)
	
	sala_a.añadir_puerta(puerta_a if s1 == rect_a else puerta_b)
	sala_b.añadir_puerta(puerta_b if s1 == rect_a else puerta_a)
	
