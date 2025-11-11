extends Node
class_name InputBuffer

@export var BUFFER_MS: int = 500
@export var MAX_BUFFER_ENTRIES: int = 16

var _entries: Array = []
var _next_read_index: int = 0
var _tokens_to_watch: Array[StringName] = []

# Public API
func set_tokens_to_watch(tokens: Array) -> void:
	_tokens_to_watch.clear()
	for t in tokens:
		_tokens_to_watch.append(StringName(t))

func process_frame(now_ms: int, now_frame: int) -> void:
	for token in _tokens_to_watch:
		if Input.is_action_just_pressed(token):
			_append_entry(token, now_ms, now_frame)
	prune(now_ms)

func consume_new() -> Array:
	var out: Array = []
	var n: int = _entries.size()
	if _next_read_index < n:
		for i in range(_next_read_index, n):
			out.append(_entries[i])
		_next_read_index = n
	return out

func get_entries() -> Array:
	return _entries.duplicate(true)

func prune(now_ms: int) -> void:
	var cutoff: int = now_ms - BUFFER_MS
	var removed: int = 0
	# Entries are chronological; drop from the front while older than cutoff.
	while _entries.size() > 0 and int(_entries[0]["t_ms"]) < cutoff:
		_entries.remove_at(0)
		removed += 1
	if removed > 0:
		_next_read_index = max(0, _next_read_index - removed)

# Internal helpers
func _append_entry(token: StringName, now_ms: int, now_frame: int) -> void:
	var entry := {
		"token": StringName(token),
		"t_ms": int(now_ms),
		"frame": int(now_frame),
	}
	_entries.append(entry)
	# Enforce MAX_BUFFER_ENTRIES as a ring by trimming the oldest.
	var removed: int = 0
	while _entries.size() > MAX_BUFFER_ENTRIES:
		_entries.remove_at(0)
		removed += 1
	if removed > 0:
		_next_read_index = max(0, _next_read_index - removed)
