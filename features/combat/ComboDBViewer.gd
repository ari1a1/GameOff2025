extends CanvasLayer
class_name ComboDBViewer

@export var db_path: String = "res://features/combat/data/combos.tres"

@onready var _label: RichTextLabel = $RichTextLabel

var _db: ComboDB
var _last_text: String = ""

func _ready() -> void:
    # Ensure the label is visible and fills the viewport with padding.
    _label.set_anchors_preset(Control.PRESET_FULL_RECT)
    _label.offset_left = 8
    _label.offset_top = 8
    _label.offset_right = -8
    _label.offset_bottom = -8

    var res: Resource = load(db_path)
    if res is ComboDB:
        _db = res as ComboDB
    else:
        _label.text = "[b]ComboDBViewer[/b]\n[error]Failed to load ComboDB at:\n%s" % db_path

func _process(_delta: float) -> void:
    var text: String = _compose_text()
    if text != _last_text:
        _last_text = text
        _label.text = text

func _compose_text() -> String:
    if _db == null:
        return "[b]ComboDBViewer[/b]\n(no db)"
    var sb: Array = []
    sb.append("[b]Tokens:[/b] ")
    var toks := PackedStringArray()
    for t in _db.tokens:
        toks.append(String(t))
    sb.append(String(" ".join(toks)))

    var res: Dictionary = _db.validate()
    if not bool(res["ok"]):
        sb.append("\n[color=red][b]Errors:[/b]\n")
        for e in res["errors"]:
            sb.append(String(e) + "\n")
        sb.append("[/color]")

    sb.append("\n[b]Combos:[/b]\n")
    for i in range(_db.combos.size()):
        var c: Array = _db.combos[i]
        var parts := PackedStringArray()
        for tt in c:
            parts.append(String(tt))
        sb.append("%d) %s\n" % [i + 1, String("→".join(parts))])
    return "".join(sb)
