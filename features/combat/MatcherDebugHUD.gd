extends CanvasLayer
class_name MatcherDebugHUD

@export var db_path: String = "res://features/combat/data/combos.tres"

var _buffer: InputBuffer
var _db: ComboDB
var _matcher: ComboMatcher = ComboMatcher.new()

@onready var _label: RichTextLabel = $RichTextLabel
var _last_text: String = ""

func bind_buffer(buffer: InputBuffer) -> void:
    _buffer = buffer

func _ready() -> void:
    _label.set_anchors_preset(Control.PRESET_FULL_RECT)
    _label.offset_left = 8
    _label.offset_top = 8
    _label.offset_right = -8
    _label.offset_bottom = -8
    var res: Resource = load(db_path)
    if res is ComboDB:
        _db = res as ComboDB
    else:
        _label.text = "[b]Matcher Test[/b]\n[error]Missing ComboDB: %s" % db_path

func _process(_delta: float) -> void:
    var text: String = _compose_text()
    if text != _last_text:
        _last_text = text
        _label.text = text

func _compose_text() -> String:
    var sb: Array = []
    sb.append("[b]Matcher Test[/b]\n")
    if _buffer == null:
        sb.append("(no buffer)\n")
        return "".join(sb)
    # Buffer tokens line
    var entries: Array = _buffer.get_entries()
    var tokens_for_display := PackedStringArray()
    var tokens_for_match: Array = []
    for e in entries:
        var t = String(e["token"])  # Text for HUD
        tokens_for_display.append(t)
        tokens_for_match.append(StringName(t))  # Normalize for matcher
    sb.append("[b]Buffer:[/b] %s\n" % String(" ".join(tokens_for_display)))
    # Match line
    if _db != null:
        var res: Dictionary = _matcher.find_longest_suffix(_db.combos, tokens_for_match)
        if res["found"]:
            var idx: int = res["combo_index"]
            var mlen: int = res["matched_len"]
            var combo: Array = _db.combos[idx]
            var parts := PackedStringArray()
            for t in combo:
                parts.append(String(t))
            sb.append("[b]Match:[/b] %d) %s  (len %d)\n" % [idx + 1, String("→".join(parts)), mlen])
        else:
            sb.append("[b]Match:[/b] —\n")
    else:
        sb.append("[b]Match:[/b] (no DB)\n")
    sb.append("\n[i]Press I/J/K/L to change buffer[/i]")
    return "".join(sb)
