class_name Sala
extends Habitaculo

func _init(_forma: Rect2i) -> void:
	if _forma != Rect2i():
		self.forma = _forma
