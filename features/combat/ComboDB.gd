extends Resource
class_name ComboDB

# Use plain Array to avoid nested typed-collection export issues.
@export var tokens: Array = []
@export var combos: Array = []

func validate() -> Dictionary:
    var errors := PackedStringArray()
    # Tokens must exist and be unique.
    if tokens.is_empty():
        errors.append("Tokens list is empty.")
    var seen := {}
    for t in tokens:
        var k := String(t)
        if seen.has(k):
            errors.append("Duplicate token: %s" % k)
        else:
            seen[k] = true
    # Each combo must be non-empty and only use declared tokens.
    for i in range(combos.size()):
        var c: Array = combos[i]
        if c.is_empty():
            errors.append("Combo %d is empty." % i)
            continue
        for tt in c:
            var name := String(tt)
            if not seen.has(name):
                errors.append("Combo %d uses undeclared token '%s'." % [i, name])
    return { "ok": errors.is_empty(), "errors": errors }
