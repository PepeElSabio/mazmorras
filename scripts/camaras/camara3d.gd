extends Camera3D

# --- Parámetros ajustables ---
@export var move_speed    : float = 10.0
@export var rotate_speed  : float = 80.0
@export var zoom_speed    : float = 2.0
@export var zoom_min      : float = 5.0
@export var zoom_max      : float = 50.0

# Almacenamos la altura actual (Y) como nuestro valor de zoom
@onready var _current_zoom : float = position.y

func _process(delta: float) -> void:
    _handle_movement(delta)
    _handle_rotation(delta)
    _apply_zoom_smooth(delta)

func _handle_movement(delta: float) -> void:
    var input_dir := Vector3.ZERO

    # Capturamos el input
    if Input.is_key_pressed(KEY_W): input_dir.z -= 1
    if Input.is_key_pressed(KEY_S): input_dir.z += 1
    if Input.is_key_pressed(KEY_A): input_dir.x -= 1
    if Input.is_key_pressed(KEY_D): input_dir.x += 1

    if input_dir != Vector3.ZERO:
        input_dir = input_dir.normalized()

        # PRO TIP: Para Top-Down, proyectamos el movimiento sobre el plano XZ
        # para que la inclinación de la cámara no afecte la velocidad.
        var forward = -transform.basis.z
        forward.y = 0
        forward = forward.normalized()

        var right = transform.basis.x
        right.y = 0
        right = right.normalized()

        var relative_dir = (forward * input_dir.z + right * input_dir.x)
        global_position += relative_dir * move_speed * delta

func _handle_rotation(delta: float) -> void:
    var rot_input := 0.0
    if Input.is_key_pressed(KEY_Q): rot_input += 1
    if Input.is_key_pressed(KEY_E): rot_input -= 1

    if rot_input != 0.0:
        # Rotamos sobre el eje Y global para evitar que la cámara se tuerza
        rotate_y(deg_to_rad(rot_input * rotate_speed * delta))

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.is_pressed():
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _current_zoom -= zoom_speed
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _current_zoom += zoom_speed

        _current_zoom = clamp(_current_zoom, zoom_min, zoom_max)

func _apply_zoom_smooth(delta: float) -> void:
    if projection == PROJECTION_ORTHOGONAL:
        size = lerp(size, _current_zoom, 10.0 * delta)
    else:
        # En Top-Down, el zoom es básicamente cambiar la altura (Y)
        position.y = lerp(position.y, _current_zoom, 10.0 * delta)
