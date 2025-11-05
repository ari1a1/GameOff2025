extends CharacterBody3D

signal moved(new_global_position: Vector3)

@export var speed: float = 4.0

var _dir2: Vector2 = Vector2.ZERO

func _ready() -> void:
    add_to_group("player")

func _physics_process(_delta: float) -> void:
    _dir2 = _get_input_vector()
    velocity.x = _dir2.x * speed
    velocity.z = -_dir2.y * speed
    velocity.y = 0.0
    move_and_slide()
    moved.emit(global_position)

func _get_input_vector() -> Vector2:
    var has_move: bool = InputMap.has_action("move_left") and InputMap.has_action("move_right") and InputMap.has_action("move_forward") and InputMap.has_action("move_back")
    if has_move:
        return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

