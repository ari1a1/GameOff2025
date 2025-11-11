extends Node

@onready var buffer: InputBuffer = $InputBuffer
@onready var hud: MatcherDebugHUD = $MatcherDebugHUD

func _ready() -> void:
    # Bind runtime sources
    buffer.set_tokens_to_watch([&"attack", &"push", &"pull", &"microwave"])
    hud.bind_buffer(buffer)

func _process(_delta: float) -> void:
    var now_ms: int = Time.get_ticks_msec()
    var now_frame: int = Engine.get_process_frames()
    buffer.process_frame(now_ms, now_frame)
    # Drain new entries; HUD queries full buffer for display
    buffer.consume_new()

