class_name Board
extends RefCounted
## A board loaded from JSON (format: boards/README.md). Read-only after
## loading, except for its moving platforms (press, set_platform).

const TYPES := ["depot", "relay", "lot", "market", "wildcard", "workshop",
		"toll", "detour", "junction", "dice", "arcade",
		"interest", "break", "plot", "warp", "switch"]

var name := ""
var goal := 10000
var start_cash := 1500
var base_salary := 200
var relay_bonus := 150
var theme := "sea"  # the backdrop round the board (Scenery)
var blocks := {}  # block id -> {name: String, color: Color}
var spaces: Array[Dictionary] = []
## Scenery a 3D board stands on: {kind: "island" | "tower", at: [x, y, z],
## size: [...], depth}, in tiles (BoardView draws them).
var props: Array = []
## Which way the camera looks at the board from, [x, y, z] (optional).
var camera: Array = []
var depot := -1
## Moving platforms: id -> {"spaces": [ids], "states": [{"shift": [dx, dy],
## "links": [[a, b], ...]}, ...], "state": index}. A platform's spaces sit at
## their own x, y moved by its state's shift, and its state's links (both
## ways) join it to the board; a switch space (`platform`) moves it on to the
## next state (press). The board changes during a game: each game loads its own.
## "look" is how it is drawn: "deck" (steel on rails) or "island" (the spaces
## float on their own, no deck or rails).
var platforms := {}


static func load_file(path: String) -> Board:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Board: cannot read %s" % path)
		return null
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Board: %s is not a JSON object" % path)
		return null
	var b := Board.new()
	var err := b.load_data(data)
	if err != "":
		push_error("Board %s: %s" % [path, err])
		return null
	return b


## Fills the board from parsed JSON. Returns "" or the first problem found.
func load_data(data: Dictionary) -> String:
	name = str(data.get("name", "Untitled"))
	theme = str(data.get("theme", theme))
	goal = int(data.get("goal", goal))
	start_cash = int(data.get("start_cash", start_cash))
	base_salary = int(data.get("base_salary", base_salary))
	relay_bonus = int(data.get("relay_bonus", relay_bonus))

	var raw_blocks: Dictionary = data.get("blocks", {})
	for id in raw_blocks:
		var blk: Dictionary = raw_blocks[id]
		blocks[str(id)] = {
			"name": str(blk.get("name", id)),
			"color": Color.html(str(blk.get("color", "#888888"))),
		}

	props = data.get("props", [])
	camera = data.get("camera", [])
	var raw_spaces: Array = data.get("spaces", [])
	if raw_spaces.is_empty():
		return "no spaces"
	for i in raw_spaces.size():
		var s: Dictionary = raw_spaces[i]
		if int(s.get("id", -1)) != i:
			return "space %d has id %s (must equal its index)" % [i, s.get("id")]
		var type := str(s.get("type", ""))
		if type not in TYPES:
			return "space %d has unknown type '%s'" % [i, type]
		var next: Array[int] = []
		for n in s.get("next", []):
			next.append(int(n))
		var space := {
			"id": i,
			"type": type,
			"x": float(s.get("x", 0)),
			"y": float(s.get("y", 0)),
			"next": next,
			"name": str(s.get("name", "")),
			"block": str(s.get("block", "")),
			"price": int(s.get("price", 0)),
			"pair": int(s.get("pair", -1)),
			"mark": str(s.get("mark", "")),
			"color": Color.html(str(s.get("color", "#888888"))),
			# A 3D board: where the space is in the world (in tiles: across, up,
			# towards the camera; else x, 0, y) and which way it faces ("up", or
			# "front": standing on a wall facing the camera, or [x, y, z]: the way
			# its top points, e.g. outwards on the side of a bottle).
			"at": s.get("at", []),
			"face": s.get("face", "up"),  # "up", "front", or a direction [x, y, z]
			"platform": str(s.get("platform", "")),  # a switch: the platform it moves
		}
		space.home = Vector2(space.x, space.y)  # where a platform's space sits before its shift
		if type == "lot":
			if not blocks.has(space.block):
				return "lot %d has unknown block '%s'" % [i, space.block]
			if space.price <= 0:
				return "lot %d has no price" % i
		if type == "depot":
			if depot != -1:
				return "more than one depot (%d and %d)" % [depot, i]
			depot = i
		spaces.append(space)

	if depot == -1:
		return "no depot"
	var raw_platforms: Dictionary = data.get("platforms", {})
	for pid in raw_platforms:
		var p: Dictionary = raw_platforms[pid]
		var ids: Array[int] = []
		for id in p.get("spaces", []):
			ids.append(int(id))
		var states := []
		for st in p.get("states", []):
			var shift: Array = st.get("shift", [0, 0])
			var links := []
			for l in st.get("links", []):
				var a := int(l[0])
				var b := int(l[1])
				if a < 0 or a >= spaces.size() or b < 0 or b >= spaces.size():
					return "platform %s links missing spaces %d-%d" % [pid, a, b]
				links.append([a, b])
			states.append({"shift": Vector2(float(shift[0]), float(shift[1])), "links": links})
		if ids.is_empty() or states.size() < 2:
			return "platform %s needs spaces and at least two states" % pid
		for id in ids:
			if id < 0 or id >= spaces.size():
				return "platform %s holds missing space %d" % [pid, id]
		platforms[str(pid)] = {"spaces": ids, "states": states, "state": -1, "look": str(p.get("look", "deck"))}
		set_platform(str(pid), int(p.get("start", 0)))
	for s in spaces:
		if s.next.is_empty():
			return "space %d has no next space" % s.id
		for n in s.next:
			if n < 0 or n >= spaces.size():
				return "space %d points to missing space %d" % [s.id, n]
		if s.type == "detour":
			if s.pair < 0 or s.pair >= spaces.size() or spaces[s.pair].type != "detour":
				return "detour %d has no valid pair" % s.id
		if s.type == "switch" and not platforms.has(s.platform):
			return "switch %d moves unknown platform '%s'" % [s.id, s.platform]
	return ""


## Moves platform `pid` to `state`: its last state's links go, the new
## state's links join it (both ways) and its spaces move by the new shift.
func set_platform(pid: String, state: int) -> void:
	var p: Dictionary = platforms[pid]
	if p.state >= 0:
		for l in p.states[p.state].links:
			spaces[l[0]].next.erase(l[1])
			spaces[l[1]].next.erase(l[0])
	p.state = state
	var st: Dictionary = p.states[state]
	for l in st.links:
		if l[1] not in spaces[l[0]].next:
			spaces[l[0]].next.append(l[1])
		if l[0] not in spaces[l[1]].next:
			spaces[l[1]].next.append(l[0])
	for id in p.spaces:
		var home: Vector2 = spaces[id].home
		spaces[id].x = home.x + st.shift.x
		spaces[id].y = home.y + st.shift.y


## A switch is pressed: its platform moves on to its next state. Returns the
## platform's id.
func press(switch_id: int) -> String:
	var pid: String = spaces[switch_id].platform
	var p: Dictionary = platforms[pid]
	set_platform(pid, (p.state + 1) % p.states.size())
	return pid


## Every place space `id` can be (x, y): where it is, or for a platform's
## space, where each of its states puts it. Lets maps and the camera leave
## room for a platform that is yet to move.
func places(id: int) -> Array[Vector2]:
	var pid := platform_of(id)
	if pid == "":
		return [Vector2(spaces[id].x, spaces[id].y)]
	var out: Array[Vector2] = []
	for st in platforms[pid].states:
		out.append(spaces[id].home + st.shift)
	return out


## The platform space `id` rides on, or "".
func platform_of(id: int) -> String:
	for pid in platforms:
		if id in platforms[pid].spaces:
			return pid
	return ""


func lot_ids() -> Array[int]:
	var out: Array[int] = []
	for s in spaces:
		if s.type == "lot":
			out.append(s.id)
	return out


func lots_in_block(block: String) -> Array[int]:
	var out: Array[int] = []
	for s in spaces:
		if s.type == "lot" and s.block == block:
			out.append(s.id)
	return out


func relay_ids() -> Array[int]:
	var out: Array[int] = []
	for s in spaces:
		if s.type == "relay":
			out.append(s.id)
	return out
