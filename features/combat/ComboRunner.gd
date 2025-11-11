extends Node
class_name ComboRunner

enum State { IDLE, STEP_ACTIVE }

@export var STEP_DUR_MS: int = 300
@export var WINDOW_MS: int = 150
@export var ALWAYS_OPEN: bool = false

var _db: ComboDB
var _buffer: InputBuffer
var _matcher: ComboMatcher

var state: int = State.IDLE
var active_combo_index: int = -1
var active_combo_tokens: Array = []
var step_index: int = -1
var step_start_ms: int = 0
var step_end_ms: int = 0
var window_open_ms: int = 0

var last_result: Dictionary = { "tokens": [], "status": "" }

func setup(db: ComboDB, buffer: InputBuffer, matcher: ComboMatcher) -> void:
    _db = db
    _buffer = buffer
    _matcher = matcher
    _reset()

func _reset() -> void:
    state = State.IDLE
    active_combo_index = -1
    active_combo_tokens = []
    step_index = -1
    step_start_ms = 0
    step_end_ms = 0
    window_open_ms = 0

func process_frame(now_ms: int, now_frame: int) -> void:
    if _db == null or _buffer == null or _matcher == null:
        return

    var new_inputs: Array = _buffer.consume_new()

    if state == State.IDLE:
        # Gate starts on new input only to avoid retriggering from stale buffer.
        if new_inputs.is_empty():
            return
        var entries: Array = _buffer.get_entries()
        var tokens: Array = []
        for e in entries:
            tokens.append(StringName(String(e["token"])))
        var res: Dictionary = _matcher.find_longest_suffix(_db.combos, tokens)
        if res["found"] and int(res["matched_len"]) == 1:
            var idx: int = int(res["combo_index"])
            var first_tok: StringName = StringName(_db.combos[idx][0])
            var anchor_ms: int = _find_anchor_ms_in_new(new_inputs, first_tok)
            if anchor_ms == -1:
                # Fallback: last entry time if for some reason not in new_inputs.
                if entries.size() > 0:
                    anchor_ms = int(entries[entries.size()-1]["t_ms"])
                else:
                    anchor_ms = now_ms
            _start_combo_from_match(res, anchor_ms)
        return

    if state == State.STEP_ACTIVE:
        _advance_with_inputs(new_inputs)
        # Finish or break on step timeout
        if now_ms >= step_end_ms:
            if step_index == active_combo_tokens.size() - 1:
                # Completed
                last_result = {
                    "tokens": active_combo_tokens.duplicate(true),
                    "status": "completed",
                }
            else:
                # Broken
                last_result = {
                    "tokens": active_combo_tokens.duplicate(true),
                    "status": "broken",
                }
            _reset()

func _start_combo_from_match(match: Dictionary, anchor_ms: int) -> void:
    active_combo_index = int(match["combo_index"])
    active_combo_tokens = _db.combos[active_combo_index]
    step_index = 0
    _set_step_timing(anchor_ms)
    state = State.STEP_ACTIVE

func _advance_with_inputs(new_inputs: Array) -> void:
    if active_combo_tokens.is_empty():
        return
    var last_step_index: int = active_combo_tokens.size() - 1
    for e in new_inputs:
        if step_index >= last_step_index:
            # Final step accepted already; ignore inputs until step end.
            continue
        var press_ms: int = int(e["t_ms"]) 
        if not ALWAYS_OPEN and press_ms < window_open_ms:
            # No early-queueing
            continue
        var token: StringName = StringName(String(e["token"]))
        var expected: StringName = StringName(active_combo_tokens[step_index + 1])
        if token == expected:
            step_index += 1
            _set_step_timing(press_ms)

func _set_step_timing(anchor_ms: int) -> void:
    step_start_ms = anchor_ms
    step_end_ms = step_start_ms + STEP_DUR_MS
    window_open_ms = step_end_ms - WINDOW_MS

func _find_anchor_ms_in_new(new_inputs: Array, token: StringName) -> int:
    # Search from newest to oldest within this frame’s inputs for the press of the first token.
    for i in range(new_inputs.size() - 1, -1, -1):
        var e: Dictionary = new_inputs[i]
        var t: StringName = StringName(String(e["token"]))
        if t == token:
            return int(e["t_ms"])
    return -1

func get_snapshot(now_ms: int) -> Dictionary:
    var snapshot := {
        "state": ("STEP_ACTIVE" if state == State.STEP_ACTIVE else "IDLE"),
        "active_combo_index": active_combo_index,
        "active_combo_tokens": active_combo_tokens.duplicate(true),
        "step_index": step_index,
        "steps_total": active_combo_tokens.size(),
        "window_open": state == State.STEP_ACTIVE and (ALWAYS_OPEN or now_ms >= window_open_ms),
        "t_left": max(0, step_end_ms - now_ms),
        "next_token": (active_combo_tokens[step_index + 1] if state == State.STEP_ACTIVE and step_index + 1 < active_combo_tokens.size() else null),
        "last_result": last_result,
    }
    return snapshot
