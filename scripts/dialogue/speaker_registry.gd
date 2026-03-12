extends RefCounted

var _speakers: Dictionary = {}
var _portrait_cache: Dictionary = {}

func configure(speakers: Dictionary) -> void:
	_speakers = speakers.duplicate(true)

func get_speaker(speaker_id: StringName) -> Dictionary:
	if speaker_id == &"":
		return {}
	var speaker: Variant = _speakers.get(speaker_id, {})
	if speaker is Dictionary:
		return speaker
	return {}

func get_display_name(speaker_id: StringName, fallback: String = "") -> String:
	var speaker := get_speaker(speaker_id)
	if speaker.has("display_name"):
		return String(speaker["display_name"])
	return fallback

func get_side(speaker_id: StringName, fallback: String = "npc") -> String:
	var speaker := get_speaker(speaker_id)
	if speaker.has("side"):
		return String(speaker["side"])
	return fallback

func get_default_portrait(speaker_id: StringName, fallback: Texture2D = null) -> Texture2D:
	var speaker := get_speaker(speaker_id)
	if speaker.is_empty():
		return fallback
	return resolve_texture(speaker.get("default_portrait", null), fallback)

func resolve_texture(value: Variant, fallback: Texture2D = null) -> Texture2D:
	if value is Texture2D:
		return value
	if value is String:
		var path := String(value)
		if path == "":
			return fallback
		if _portrait_cache.has(path):
			return _portrait_cache[path]
		var loaded := load(path)
		if loaded is Texture2D:
			_portrait_cache[path] = loaded
			return loaded
	return fallback
