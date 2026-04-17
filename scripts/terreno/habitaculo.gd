class_name Habitaculo
extends Node3D

@export var forma: Rect2i
@export var altura: int = 3

var puetas : Array[Vector2i] 

var contenedor_suelo: Node3D
var contenedor_paredes: Node3D
var contenedor_paredes_norte: Node3D
var contenedor_paredes_sur: Node3D
var contenedor_paredes_este: Node3D
var contenedor_paredes_oeste: Node3D

func _ready() -> void:
	_crear_arbol()
	construir()

func _init(_forma: Rect2i = Rect2i(), _altura: int = 3) -> void:
	self.forma = _forma
	self.altura = _altura

# --- Árbol de nodos ---

func _crear_arbol() -> void:
	contenedor_suelo          = _crear_nodo("Suelo")
	contenedor_paredes        = _crear_nodo("Paredes")
	contenedor_paredes_norte  = _crear_nodo("ParedesNorte", contenedor_paredes)
	contenedor_paredes_sur    = _crear_nodo("ParedesSur",   contenedor_paredes)
	contenedor_paredes_este   = _crear_nodo("ParedesEste",  contenedor_paredes)
	contenedor_paredes_oeste  = _crear_nodo("ParedesOeste", contenedor_paredes)

func _crear_nodo(nombre: String, padre: Node3D = self) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	padre.add_child(nodo)
	return nodo

# --- Construcción ---

func construir() -> void:
	_construir_suelo()
	_construir_paredes()
	

func _construir_suelo() -> void:
	bloque.add(bloque.SUELO, Vector3i(forma.position.x, 0, forma.position.y), Vector3i(forma.size.x, 0, forma.size.y), contenedor_suelo)

func _construir_paredes() -> void:
	var x_min = forma.position.x
	var x_max = forma.end.x
	var z_min = forma.position.y
	var z_max = forma.end.y

	for x in range(x_min, x_max):
		var pos_n = Vector2i(x, z_min)
		if not pos_n in puetas:
			bloque.add(bloque.PARED, Vector3i(x, 0, z_min), Vector3i(1, altura, 1), contenedor_paredes_norte)
		var pos_s = Vector2i(x, z_max - 1)
		if not pos_s in puetas:
			bloque.add(bloque.PARED, Vector3i(x, 0, z_max - 1), Vector3i(1, altura, 1), contenedor_paredes_sur)


	for z in range(z_min + 1, z_max - 1):
		var pos_o = Vector2i(x_min, z)
		if not pos_o in puetas:
			bloque.add(bloque.PARED, Vector3i(x_min, 0, z), Vector3i(1, altura, 1), contenedor_paredes_oeste)

		var pos_e = Vector2i(x_max - 1, z)
		if not pos_e in puetas:
			bloque.add(bloque.PARED, Vector3i(x_max - 1, 0, z), Vector3i(1, altura, 1), contenedor_paredes_este)


func añadir_puerta(_posicion: Vector2i):
	puetas.append(_posicion)
	for p in puetas:
		_pared_a_dindel(_posicion)
	

func _pared_a_dindel(_posicion: Vector2i) -> void:
	if contenedor_paredes == null:
		_crear_arbol()
	
	if contenedor_paredes.get_child_count() == 0:
		return

	var altura_puerta : int = 2
	var altura_dintel : float = altura - altura_puerta
	if altura_dintel <= 0: return

	for contenedor in contenedor_paredes.get_children():
		for pared in contenedor.get_children():
			var pos_pared = Vector2i(roundi(pared.position.x), roundi(pared.position.z))
			if pos_pared == _posicion:
				var nueva_y = altura_puerta 
				pared.position.y = nueva_y

				var escala_y = altura_dintel / float(altura)
				pared.scale.y = escala_y
