extends CanvasLayer
class_name DebugTextHUD

var _buffer: InputBuffer

@onready var _label: Label = $Label
var _last_text: String = ""

func bind_buffer(buffer: InputBuffer) -> void:
    _buffer = buffer

func _process(_delta: float) -> void:
    _update_view()

func _update_view() -> void:
    var text: String
    if _buffer == null:
        text = "Buffer: —"
    else:
        var tokens := PackedStringArray()
        for e in _buffer.get_entries():
            tokens.append(String(e["token"]))
        var body: String = " ".join(tokens)
        text = "Buffer: %s" % body
    if text != _last_text:
        _last_text = text
        _label.text = text
