extends Node

@onready var buffer: InputBuffer = $InputBuffer
@onready var hud: DebugTextHUD = $DebugTextHUD

func _ready() -> void:
    # Bind the tokens we expect to watch; must exist in InputMap.
    buffer.set_tokens_to_watch([&"attack", &"push", &"pull", &"microwave"])
    hud.bind_buffer(buffer)

func _process(_delta: float) -> void:
    var now_ms: int = Time.get_ticks_msec()
    var now_frame: int = Engine.get_process_frames()
    buffer.process_frame(now_ms, now_frame)
    # Drain new entries but avoid spamming the console.
    buffer.consume_new()
