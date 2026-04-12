extends Camera3D

# --- Parámetros ajustables ---
@export var move_speed    : float = 10.0
@export var zoom_speed    : float = 2.0
@export var zoom_min      : float = 3.0
@export var zoom_max      : float = 30.0

@export var iso_yaw       : float = 45.0
@export var iso_pitch     : float = -35.264

# Duración de la animación de giro en segundos
@export var rotate_duration : float = 0.25

@onready var _current_zoom  : float = 8.0

var _yaw_current  : float = 45.0   # ángulo real interpolado
var _yaw_target   : float = 45.0   # ángulo destino (múltiplo de 90°)
var _rotating     : bool  = false

func _ready() -> void:
    projection = PROJECTION_ORTHOGONAL
    near = -500.0
    far  =  500.0
    size = _current_zoom
    _yaw_current = iso_yaw
    _yaw_target  = iso_yaw
    _apply_rotation()

func _apply_rotation() -> void:
    rotation_degrees = Vector3(iso_pitch, _yaw_current, 0.0)

func _process(delta: float) -> void:
    _handle_movement(delta)
    _handle_zoom_smooth(delta)
    _update_rotation(delta)

func _handle_movement(delta: float) -> void:
    var input_dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_W): input_dir.y -= 1
    if Input.is_key_pressed(KEY_S): input_dir.y += 1
    if Input.is_key_pressed(KEY_A): input_dir.x -= 1
    if Input.is_key_pressed(KEY_D): input_dir.x += 1

    if input_dir != Vector2.ZERO:
        input_dir = input_dir.normalized()
        var yaw_rad := deg_to_rad(_yaw_target)   # usamos el target para que no derive durante el giro
        var forward := Vector3(-sin(yaw_rad), 0.0, -cos(yaw_rad))
        var right   := Vector3( cos(yaw_rad), 0.0, -sin(yaw_rad))
        global_position += (forward * -input_dir.y + right * input_dir.x) * move_speed * delta

func _input(event: InputEvent) -> void:
    # Scroll → zoom
    if event is InputEventMouseButton and event.is_pressed():
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _current_zoom -= zoom_speed
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _current_zoom += zoom_speed
        _current_zoom = clamp(_current_zoom, zoom_min, zoom_max)

    # Teclado → giro en pasos de 90°
    # Permitimos encolar el siguiente giro aunque el actual no haya terminado
    if event is InputEventKey and event.is_pressed() and not event.echo:
        if event.keycode == KEY_Q:
            _yaw_target -= 90.0
            _rotating = true
        elif event.keycode == KEY_E:
            _yaw_target += 90.0
            _rotating = true

func _update_rotation(delta: float) -> void:
    if not _rotating:
        return

    # Velocidad angular: 90° / duración elegida
    var step := (90.0 / rotate_duration) * delta

    if abs(_yaw_target - _yaw_current) <= step:
        _yaw_current = _yaw_target
        _rotating = false
    else:
        _yaw_current += step * sign(_yaw_target - _yaw_current)

    _apply_rotation()

func _handle_zoom_smooth(delta: float) -> void:
    size = lerp(size, _current_zoom, 10.0 * delta)
