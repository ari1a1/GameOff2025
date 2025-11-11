extends Node

@onready var buffer: InputBuffer = $InputBuffer
@onready var hud: ComboDesignerHUD = $ComboDesignerHUD

func _ready() -> void:
	var db: ComboDB = load("res://features/combat/data/combos.tres") as ComboDB
	buffer.set_tokens_to_watch(db.tokens)
	hud.bind_buffer(buffer)

func _process(_delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var now_frame: int = Engine.get_process_frames()
	buffer.process_frame(now_ms, now_frame)
	buffer.consume_new() # HUD reads full buffer
