extends CanvasLayer
class_name ComboDesignerHUD

@export var db_path: String = "res://features/combat/data/combos.tres"

var _db: ComboDB
var _buffer: InputBuffer
var _last_text: String = ""

@onready var _label: RichTextLabel = $RichTextLabel

func bind_buffer(buffer: InputBuffer) -> void:
	_buffer = buffer

func _ready() -> void:
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 8
	_label.offset_top = 8
	_label.offset_right = -8
	_label.offset_bottom = -8
	_label.bbcode_enabled = true
	_label.scroll_active = false
	var res: Resource = load(db_path)
	if res is ComboDB:
		_db = res as ComboDB
	else:
		_label.text = "[b]Available Combos[/b]\n[error]Missing ComboDB: %s" % db_path

func _process(_delta: float) -> void:
	var text: String = _compose()
	if text != _last_text:
		_last_text = text
		_label.text = text

func _compose() -> String:
	if _db == null:
		return "[b]Available Combos[/b]\n(no db)"
	var sb: Array = []
	sb.append("[b]Available Combos[/b]\n")
	# Get buffer tail tokens
	var buf_tokens: Array = []
	if _buffer != null:
		for e in _buffer.get_entries():
			buf_tokens.append(StringName(String(e["token"])))
	var has_input: bool = buf_tokens.size() > 0
	# Render all combos from DB order
	for i in range(_db.combos.size()):
		var combo: Array = _db.combos[i]
		var match_len: int = _match_len(combo, buf_tokens)
		if match_len > 0:
			# Matched prefix green, rest white.
			var green := PackedStringArray()
			var white := PackedStringArray()
			for j in range(match_len):
				green.append(String(combo[j]))
			for j in range(match_len, combo.size()):
				white.append(String(combo[j]))
			var line := "[color=green]%s[/color]%s" % [String("→".join(green)), ("→%s" % String("→".join(white)) if white.size() > 0 else "")]
			sb.append(line + "\n")
		else:
			var parts := PackedStringArray()
			for t in combo:
				parts.append(String(t))
			var text_line := String("→".join(parts))
			if has_input:
				sb.append("[color=red]%s[/color]\n" % text_line)
			else:
				sb.append(text_line + "\n")
	return "".join(sb)

func _match_len(combo: Array, buffer_tokens: Array) -> int:
	# Longest k such that combo[0..k-1] equals the tail of buffer_tokens.
	var buf_len: int = buffer_tokens.size()
	var max_k: int = min(combo.size(), buf_len)
	for k in range(max_k, 0, -1):
		var offset: int = buf_len - k
		var ok: bool = true
		for idx in range(k):
			if combo[idx] != buffer_tokens[offset + idx]:
				ok = false
				break
		if ok:
			return k
	return 0
