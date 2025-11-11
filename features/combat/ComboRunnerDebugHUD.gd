extends CanvasLayer
class_name ComboRunnerDebugHUD

var _buffer: InputBuffer
var _runner: ComboRunner

@onready var _l_buffer: Label = $VBox/L_buffer
@onready var _l_state: Label = $VBox/L_state
@onready var _l_combo: Label = $VBox/L_combo
@onready var _l_step: Label = $VBox/L_step
@onready var _l_window: Label = $VBox/L_window
@onready var _l_time: Label = $VBox/L_time
@onready var _l_last: Label = $VBox/L_last

var _cache_buffer := ""
var _cache_state := ""
var _cache_combo := ""
var _cache_step := ""
var _cache_window := ""
var _cache_time := ""
var _cache_last := "Last Combo: -"
var _time_accum: float = 0.0

func bind_sources(buffer: InputBuffer, runner: ComboRunner) -> void:
	_buffer = buffer
	_runner = runner

func _ready() -> void:
	# Nodes laid out in scene via VBox.
	pass

func update_view(now_ms: int) -> void:
	# Buffer line (change-driven)
	var entries: Array = _buffer.get_entries() if _buffer else []
	var toks := PackedStringArray()
	for e in entries:
		toks.append(String(e["token"]))
	var buf_text := "Buffer: %s" % String(" ".join(toks))
	if buf_text != _cache_buffer:
		_cache_buffer = buf_text
		_l_buffer.text = buf_text

	# State/Combo/Step/Window lines (event-driven)
	if _runner == null:
		_set_if_changed(_l_state, _cache_state, "State: (no runner)")
		return

	var snap: Dictionary = _runner.get_snapshot(now_ms)
	var is_idle := String(snap["state"]) == "IDLE"
	_set_if_changed(_l_state, _cache_state, "State: %s" % ("Idle" if is_idle else "Step Active"))

	if is_idle:
		# Clear active details when idle
		_set_if_changed(_l_combo, _cache_combo, "Combo: -")
		_set_if_changed(_l_step, _cache_step, "Step: -/-   Next: -")
		_set_if_changed(_l_window, _cache_window, "Window: -")
		_set_if_changed(_l_time, _cache_time, "t_left: -")
	else:
		var parts := PackedStringArray()
		for t in snap["active_combo_tokens"]:
			parts.append(String(t))
		_set_if_changed(_l_combo, _cache_combo, "Combo: %s" % String("->".join(parts)))

		var step_i: int = int(snap["step_index"]) + 1
		var step_n: int = int(snap["steps_total"]) 
		var next_tok = snap["next_token"]
		var next_txt := (String(next_tok) if next_tok != null else "-")
		_set_if_changed(_l_step, _cache_step, "Step: %d/%d   Next: %s" % [step_i, step_n, next_txt])

		var open_closed := ("OPEN" if bool(snap["window_open"]) else "CLOSED")
		_set_if_changed(_l_window, _cache_window, "Window: %s" % open_closed)

		# Time left throttled ~100ms rounded to 50ms
		_time_accum += 0.016
		if _time_accum >= 0.1:
			_time_accum = 0.0
			var t_left: int = int(snap["t_left"]) 
			var rounded := int(roundi(float(t_left) / 50.0) * 50)
			var t_text := "t_left: %dms" % rounded
			if t_text != _cache_time:
				_cache_time = t_text
				_l_time.text = t_text

	# Last result line (updates only on completion/break)
	if _runner != null and _runner.last_result.has("status") and String(_runner.last_result["status"]) != "":
		var parts2 := PackedStringArray()
		for t2 in _runner.last_result["tokens"]:
			parts2.append(String(t2))
		var status_txt := String(_runner.last_result["status"]) 
		var last_text := "Last Combo: %s (%s)" % [String("->".join(parts2)), status_txt]
		if last_text != _cache_last:
			_cache_last = last_text
			_l_last.text = last_text

func _set_if_changed(label: Label, cache_var: String, new_text: String) -> void:
	if new_text == cache_var:
		return
	# Update the cache and the label.
	if label == _l_buffer:
		_cache_buffer = new_text
	elif label == _l_state:
		_cache_state = new_text
	elif label == _l_combo:
		_cache_combo = new_text
	elif label == _l_step:
		_cache_step = new_text
	elif label == _l_window:
		_cache_window = new_text
	elif label == _l_time:
		_cache_time = new_text
	elif label == _l_last:
		_cache_last = new_text
	label.text = new_text
