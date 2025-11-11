extends Node

@onready var buffer: InputBuffer = $InputBuffer
@onready var runner: ComboRunner = $ComboRunner
@onready var hud: ComboRunnerDebugHUD = $ComboRunnerDebugHUD

func _ready() -> void:
	var db: ComboDB = load("res://features/combat/data/combos.tres") as ComboDB
	var matcher := ComboMatcher.new()
	buffer.set_tokens_to_watch(db.tokens)
	runner.setup(db, buffer, matcher)
	hud.bind_sources(buffer, runner)

func _process(_delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var now_frame: int = Engine.get_process_frames()
	buffer.process_frame(now_ms, now_frame)
	runner.process_frame(now_ms, now_frame)
	hud.update_view(now_ms)
