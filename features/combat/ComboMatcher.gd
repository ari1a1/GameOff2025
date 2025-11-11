extends RefCounted
class_name ComboMatcher

# Find the longest combo whose prefix matches the buffer's suffix.
# Args:
#   combos: Array of combos (each combo is an Array of tokens)
#   buffer_tokens: Array of tokens (chronological)
# Returns Dictionary:
#   { "found": bool, "combo_index": int, "matched_len": int }
func find_longest_suffix(combos: Array, buffer_tokens: Array) -> Dictionary:
	var best_len: int = 0
	var best_index: int = -1
	var buf_len: int = buffer_tokens.size()
	for i in range(combos.size()):
		var combo: Array = combos[i]
		if combo.is_empty():
			continue
		var max_k: int = min(combo.size(), buf_len)
		var k: int = max_k
		var matched: int = 0
		# Find longest k where combo[0..k-1] == buffer_tail[k]
		while k > 0:
			if _prefix_equals_suffix(combo, buffer_tokens, k):
				matched = k
				break
			k -= 1
		if matched > best_len:
			best_len = matched
			best_index = i
		# Tie-breaker: keep the first combo with that length (do nothing)
	var found: bool = (best_len >= 1)
	return {
		"found": found,
		"combo_index": best_index if found else -1,
		"matched_len": best_len if found else 0,
	}

func _prefix_equals_suffix(combo: Array, buffer_tokens: Array, k: int) -> bool:
	# Compare combo[0..k-1] to the last k tokens of buffer_tokens
	var offset: int = buffer_tokens.size() - k
	for idx in range(k):
		if combo[idx] != buffer_tokens[offset + idx]:
			return false
	return true
