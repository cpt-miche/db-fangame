extends RefCounted

const SpeakerRegistryScript = preload("res://scripts/dialogue/speaker_registry.gd")

var _speaker_registry: RefCounted
var _session_defaults := {
	"player_portrait": null,
	"npc_portrait": null,
}

func _init(speaker_registry: RefCounted = null) -> void:
	_speaker_registry = speaker_registry if speaker_registry != null else SpeakerRegistryScript.new()

func begin_dialogue(dialogue_schema: Dictionary) -> Dictionary:
	_session_defaults["player_portrait"] = _resolve_dialogue_default(dialogue_schema, "player_portrait", "player_speaker_id")
	_session_defaults["npc_portrait"] = _resolve_dialogue_default(dialogue_schema, "npc_portrait", "npc_speaker_id")
	return {
		"player_portrait": _session_defaults["player_portrait"],
		"npc_portrait": _session_defaults["npc_portrait"],
	}

func present_line(line: Dictionary) -> Dictionary:
	var speaker_id := StringName(line.get("speaker_id", &""))
	var side := String(line.get("side", ""))
	if side == "":
		side = _speaker_registry.get_side(speaker_id, "npc")

	var speaker := String(line.get("speaker", ""))
	if speaker == "":
		speaker = _speaker_registry.get_display_name(speaker_id, "")

	var player_portrait := _resolve_line_portrait(line, "player_portrait", "player_speaker_id", _session_defaults["player_portrait"])
	var npc_portrait := _resolve_line_portrait(line, "npc_portrait", "npc_speaker_id", _session_defaults["npc_portrait"])

	if side == "player" and player_portrait == _session_defaults["player_portrait"]:
		player_portrait = _speaker_registry.get_default_portrait(speaker_id, player_portrait)
	if side == "npc" and npc_portrait == _session_defaults["npc_portrait"]:
		npc_portrait = _speaker_registry.get_default_portrait(speaker_id, npc_portrait)

	return {
		"speaker": speaker,
		"text": String(line.get("text", "...")),
		"side": side,
		"player_portrait": player_portrait,
		"npc_portrait": npc_portrait,
	}

func _resolve_dialogue_default(dialogue_schema: Dictionary, portrait_key: String, speaker_key: String) -> Texture2D:
	if dialogue_schema.has(portrait_key):
		return _speaker_registry.resolve_texture(dialogue_schema.get(portrait_key), null)
	if dialogue_schema.has(speaker_key):
		return _speaker_registry.get_default_portrait(StringName(dialogue_schema.get(speaker_key, &"")), null)
	return null

func _resolve_line_portrait(line: Dictionary, portrait_key: String, speaker_key: String, fallback: Texture2D) -> Texture2D:
	if line.has(portrait_key):
		return _speaker_registry.resolve_texture(line.get(portrait_key), fallback)
	if line.has(speaker_key):
		return _speaker_registry.get_default_portrait(StringName(line.get(speaker_key, &"")), fallback)
	return fallback
