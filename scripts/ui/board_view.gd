class_name BoardView
extends Node3D
## Basic 3D board built from placeholder meshes: box tiles, a building on each
## lot sized by its value, a house framed in its block's colour, with a signpost
## showing the price (or rent once owned),
## suit beacons on the Relays, walking figures and floating text popups. Call build() for a new game and sync() after every change.

const SPACING := 1.15
const TILE := 1.0
const TILE_H := 0.16
const MOVE_TIME := 0.24
const VALUE_FOR_FULL_SIZE := 2000.0  # lot value whose building reaches full size
const BUILDING_MIN_H := 0.06
const BUILDING_MAX_H := 1.0
const UNOWNED_BUILDING := Color("#d8d8de")
const FIGURE_SCALE := 1.35
const SIGN_HEIGHT := 0.32
const SUIT_HEIGHT := 0.65
const WALL_SIGN_TILT := 45.0  # degrees a wall space's sign tips further out, towards the camera
const WALL_PLOT_TOP := 0.7  # how far a plot's model stands out from a wall, for its sign
const CAMERA_DIR := Vector3(0, 0.85, 0.55)  # from the look point towards the camera
const FOLLOW_DIST := 7.5   # camera distance when following a player
const CAMERA_EASE := 5.0   # how quickly the camera glides to where it should be
const TURN_EASE := 2.2     # how quickly the following camera turns with the player (3D boards)
const FREE_PAN := 6.0      # View Map's free camera: tiles a second at the board's size
const FREE_TURN := 1.8     # radians a second
const SPOT_DIM := 0.62     # how dark the rest of the board goes round a spotlit block
const CONFETTI_COLORS := [Color("#ff6b6b"), Color("#ffd23f"), Color("#4fc3f7"), Color("#7ccf5a"), Color("#ff9ad5")]
const FIREWORKS := 6
const PAYDAY_SECONDS := 2.8  # the PAYDAY show, banner and fireworks, start to finish
const FIREWORK_COLORS := [Color("#ff4a5a"), Color("#ffd84a"), Color("#4ae0ff"), Color("#7dff6a"), Color("#ff7ae8"), Color("#ffffff")]
const ROOF_COLOR := Color("#ffd84a")  # whole-block buildings wear gold roofs
const SWITCH_YELLOW := Color("#ffc81a")  # the switches' buttons and the platforms' hazard edges
const STEEL := Color("#8a929e")  # a moving platform's deck and rails
const PLATFORM_SLIDE := 1.6  # seconds a platform takes to slide to its new place
## A lot's tile is a frame in its block's colour round a panel: cream while for
## sale, the owner's colour once bought.
const FRAME := 0.08  # the border's width
const RELAY_FRAME := Color("#f3ecd9")  # the suit spaces' cream-white border
const WILDCARD_MARK := Color("#5ee05a")  # the Card space's green ?
const DICE_GREEN := Color("#22b84a")
const STAR_SQUARES := [Color("#1f6fb8"), Color("#1f9a5a"), Color("#4cc878")]  # blue edge, green middle
const MOON_SQUARES := [Color("#1c2566"), Color("#38409c"), Color("#6a62c8")]  # night blue to soft purple
const MOON_YELLOW := Color("#fff2b0")
const WARP_SQUARES := [Color("#3a2a8a"), Color("#5a4ac8"), Color("#9a8aff")]
const WARP_GLOW := Color("#7ad8ff")
## Turtle Islands's beach and turtles are faded this much towards FADE_TO, so the
## spaces on them stand out.
const PROP_FADE := 0.25
const FADE_TO := Color("#a8c4cc")
const MOON_RIM := Color("#d9a83a")
const STAR_YELLOW := Color("#ffd84a")
const STAR_RIM := Color("#d9841a")
const STAR_THICK := 0.02
const CABINET := Color("#2b3fa8")  # the arcade cabinet's body
const CABINET_STRIPE := Color("#ffd84a")
const ARCADE_FLOOR := [Color("#26262c"), Color("#2e2e35"), Color("#37373f")]
const DICE_BLOCK := 0.3  # the rolled dice block's size
const DICE_NUMBER := Color("#2450c8")
const INK_ALPHA := 0.1  # the dice outlines' opacity (90% see-through)
const DICE_DEPTH := 1.6  # how far in front of the camera the hit block bounces
const BLOCK_HEIGHT := 1.05  # the dice block over a head, above the token's feet
const BOUNCE_SECONDS := 1.1
const UNOWNED_ROOF := Color("#8e8e96")  # houses are all grey until bought
const EARTH := Color("#8a5a34")
const GRASS := Color("#4fb83c")
const SALE_RED := Color("#e8463a")
const STONE := Color("#9a958c")
const BANK_STONE := Color("#f1e6cc")
const BANK_GOLD := Color("#f2bf2a")
const BANK_CARPET := Color("#c8283c")
const BANK_SCALE := 1.15  # the Bank on its tile (any bigger crowds the players)
const WOOD := Color("#a0703c")
const HOUSE_WINDOW := Color("#fff2b0")
const HOUSE_DOOR := Color("#6b4a2e")
const HOUSE_TRIM := Color("#8a6a55")  # the chimney
const PANEL_FOR_SALE := Color("#ece6d4")
const TYPE_COLORS := {
	"depot": Color("#f2f2f2"), "market": Color("#2e8b80"), "wildcard": Color("#6a35b0"),
	"workshop": Color("#b07a4a"), "toll": Color("#d9534f"), "dice": Color("#3fb6c9"), "arcade": Color("#ff8c3a"), "interest": Color("#e8b630"), "break": Color("#2a3570"), "plot": Color("#8a8f99"),
	"detour": Color("#9a8fe0"), "junction": Color("#6c6c78"), "switch": Color("#ffc81a"),
}
const TYPE_LABELS := {
	"depot": "", "market": "MARKET", "wildcard": "?", "workshop": "WORKSHOP",
	"toll": "TOLL", "dice": "DICE", "arcade": "ARCADE", "interest": "STAR", "break": "MOON", "plot": "", "detour": "DETOUR", "junction": "", "switch": "",
}
const PLAYER_COLORS := [Color("#e84a4a"), Color("#4a7fe8"), Color("#48b860"), Color("#e8a02a")]
const SUIT_SYMBOLS := {"Spade": "♠", "Heart": "♥", "Diamond": "♦", "Club": "♣"}

var game: GameState
var highlight: Array[int] = []  # spaces offered as a branch choice
var zoom_for_highlight := true  # pull back to the whole board while highlighting
var hold_overview := false  # whole board until switched off (View Map)
var always_overview := false  # the player's option: never follow, show the whole board
var walk_speed := 1.0  # Faster walking: 2
var dice_speed := 1.0  # Faster dice: 2

var _camera: Camera3D
var _root: Node3D
var _tiles := {}                     # space id -> {mesh, base, sub, building}
var _links: Node3D  # the paths between spaces (_draw_links)
var _tokens: Array[Node3D] = []      # holders; tweened between spaces
var _token_space: Array[int] = []
var _token_from := {}  # player index -> the space its figure last went to
var _ring: MeshInstance3D
var _arrows: Array[Node3D] = []
var _popups: Array[Label3D] = []
var _spinners: Array[Node3D] = []  # suit symbols swaying above the Relays
var _paddles: Array = []  # [flipper, phase, front?]: turtles' flippers, paddling
var _time := 0.0
var _center := Vector3.ZERO  # middle of the board
var _preview := {}  # player index -> space shown while planning a route
var _overview_pos := Vector3.ZERO
var _overview_look := Vector3.ZERO
var _overview_until := 0.0  # show the whole board until this _time
var _focus_pos := Vector3.ZERO  # a close look at one block (whole_block)
var _focus_look := Vector3.ZERO
var _focus_until := 0.0
var _cam_look := Vector3.ZERO
var _turning := false  # a 3D board: the following camera turns with the player
var _walls := false  # level ground and walls (Sky Station): the camera turns only on and off a wall
var _heading := {}  # player index -> the way their figure last walked
var _follow_dir := Vector3.ZERO  # towards the camera from the player, eased (3D boards)
var free_cam := false  # View Map: drag, wheel, WASD or the sticks move the camera
var _free_look := Vector3.ZERO
var _free_yaw := 0.0    # radians round the up axis, 0 = the board's own view
var _free_pitch := 0.0  # radians above the level
var _free_dist := 10.0
var _drag_from := Vector2.ZERO
var _dragging := -1  # mouse button held on the board (-1: none)
var _dragged := false  # moved far enough that the press is not a click
var _spot: Array[int] = []  # spaces in the spotlight; everything else dims
var _spot_nodes: Array[Node] = []  # lights and glows made for the spotlight
var _dimmed := {}  # node -> what was there before the spotlight dimmed it
var _dim_mat: StandardMaterial3D
var _day := {}  # the backdrop's normal light (_build_scenery): what the spotlight and night go back to
var _light_tw: Tween  # the one tween changing the board's light (_light_tween)
var _victory_until := 0.0  # fireworks keep going over the winner until then
var _env: Environment  # tinted by sunset()
var theme := "auto"  # the backdrop (Scenery.THEMES), or "auto" for the board's own
var _scenery: Scenery
var _lo := Vector3.ZERO  # the board's extent
var _hi := Vector3.ZERO
var _sun: DirectionalLight3D
var _block: Node3D  # the dice block (show_block / hit_block)
var _block_mode := ""  # "spin" over a head, "bounce" in front of the camera
var _block_vel := Vector3.ZERO  # while bouncing, in camera space
var _block_spin := Vector3.ZERO
var _block_flick := 0.0  # seconds until its numbers change
var _block_index := -1  # whose head it spins over

signal block_hit     # a player's fist meets the dice block
signal block_bounce  # it hits the bottom of the screen
signal block_landed  # it settles showing the roll
signal space_clicked(id: int)  # a click on a space on the board (Warp Gate)
signal thunder  # a thunderclap in the backdrop (Storm Clouds)


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8cc8f0")  # a clear sky over the golf course
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#bcd4ee")  # sky-tinted fill, so shade looks cool
	env.ambient_light_energy = 0.34
	# A touch darker, with a little more contrast: a sunny day, not a glare.
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.92
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 0.95
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("#fff0d8")  # warm afternoon sun
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	add_child(sun)
	_env = env
	_sun = sun
	_camera = Camera3D.new()
	_camera.fov = 40
	add_child(_camera)
	get_viewport().size_changed.connect(_frame_camera)


func build(g: GameState) -> void:
	game = g
	if _root:
		_root.queue_free()
	_root = Node3D.new()
	add_child(_root)
	_tiles.clear()
	_preview.clear()
	_tokens.clear()
	_token_space.clear()
	_token_from.clear()
	_arrows.clear()
	_spinners.clear()
	_paddles.clear()
	_heading.clear()
	_spot.clear()
	_spot_nodes.clear()
	_dimmed.clear()
	if _light_tw and _light_tw.is_valid():
		_light_tw.kill()  # _build_scenery sets the new board's daylight
	_victory_until = 0.0
	_focus_until = 0.0
	free_cam = false
	highlight = []
	if g == null:
		return
	_turning = g.board.spaces.any(func(s): return s.get("at", []).size() == 3)
	# Level ground and walls both (Sky Station; the bottle is all glass and
	# keeps the turning camera).
	var level: bool = g.board.spaces.any(func(s): return str(s.get("face", "up")) == "up")
	var wall: bool = g.board.spaces.any(func(s): return str(s.get("face", "up")) != "up")
	_walls = level and wall
	_follow_dir = _cam_dir()

	var lo := Vector3(INF, 0, INF)
	var hi := Vector3(-INF, 0, -INF)
	for s in g.board.spaces:
		for at in _places(s.id):  # room for platforms out in their other places
			lo = lo.min(at)
			hi = hi.max(at)
	_center = (lo + hi) / 2  # the board floats; the theme's scenery lies below it
	_lo = lo
	_hi = hi
	_build_scenery()

	_links = Node3D.new()
	_root.add_child(_links)
	_draw_links()
	_build_props()
	_build_rails()
	for s in g.board.spaces:
		_add_space(s)

	for p in g.players:
		var figure := Character.new()
		_root.add_child(figure)
		figure.setup(PLAYER_COLORS[p.index], p.character)
		figure.scale = Vector3.ONE * FIGURE_SCALE
		_tokens.append(figure)
		_token_space.append(-1)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.14
	torus.outer_radius = 0.19
	_ring.mesh = torus
	_ring.material_override = _material(Color.WHITE, 0.8)
	_root.add_child(_ring)

	_frame_camera()
	_camera.position = _overview_pos
	_cam_look = _overview_look
	_camera.look_at(_cam_look, Vector3.UP)
	overview(1.5)
	sync(true)
	# Dev switch --look=<space type>[@distance]: hold the camera on the first one.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--look="):
			var parts := arg.substr(7).split("@")
			for s in g.board.spaces:
				if s.type == parts[0]:
					_focus_look = _pos(s.id) + Vector3(0, 0.3, 0)
					_focus_pos = _focus_look + _cam_dir() * (float(parts[1]) if parts.size() > 1 else 2.6)
					_focus_until = INF
					break


## Brings every mesh in line with the game state. Tokens glide unless `instant`.
func sync(instant := false) -> void:
	if game == null:
		return
	for id in game.plots:
		_sync_plot(id)
	for id in game.lots:
		var t: Dictionary = _tiles[id]
		var lot: Dictionary = game.lots[id]
		var mat: StandardMaterial3D = t.mesh.material_override
		# The house's size follows the lot's value; the sign shows the price
		# while it is for sale and the rent once owned, in the owner's colour.
		var building: Node3D = t.building
		var size := sqrt(game.lot_value(id) / VALUE_FOR_FULL_SIZE)
		var h := BUILDING_MIN_H + BUILDING_MAX_H * size
		var w := 0.2 + 0.3 * minf(size, 1.0)
		var key := Vector2(snappedf(w, 0.01), snappedf(h, 0.01))
		if t.get("house_size") != key:
			t.house_size = key
			_build_house(t, key.x, key.y)
			_lift_wall_sign(t)  # the house grew: its wall sign stays out past it
		var roof_at: Node3D = t.roof_at
		roof_at.position = building.position + Vector3(0, t.house_top, 0)
		var whole: bool = lot.owner >= 0 and game.whole_block_owner(game.space(id).block) == lot.owner
		var sign_mat: StandardMaterial3D = t.sign_board.material_override
		var bmat: StandardMaterial3D = t.body_mat
		var rmat: StandardMaterial3D = t.roof_mat
		var pmat: StandardMaterial3D = t.panel.material_override
		mat.albedo_color = t.base  # the frame always shows the block
		rmat.emission_enabled = whole
		if lot.owner < 0:
			pmat.albedo_color = PANEL_FOR_SALE
			bmat.albedo_color = UNOWNED_BUILDING
			rmat.albedo_color = UNOWNED_ROOF
			sign_mat.albedo_color = Color("#f4f1e6")
			t.sign_label.modulate = Color("#202020")
			t.sign_label.text = "%d G" % game.lot_value(id)
			t.sign_label.font_size = 58
		elif game.players[lot.owner].on_break:  # the Moon: shut until their next turn
			pmat.albedo_color = PLAYER_COLORS[lot.owner].darkened(0.55)
			bmat.albedo_color = PLAYER_COLORS[lot.owner].lerp(Color.WHITE, 0.45).darkened(0.45)
			rmat.albedo_color = (ROOF_COLOR if whole else PLAYER_COLORS[lot.owner].darkened(0.25)).darkened(0.45)
			sign_mat.albedo_color = Color("#2a2a32")
			t.sign_label.modulate = Color("#ff5a5a")
			t.sign_label.text = "✕ CLOSED"
			t.sign_label.font_size = 38  # fits the sign on one line
		else:
			pmat.albedo_color = PLAYER_COLORS[lot.owner].lightened(0.2)
			bmat.albedo_color = PLAYER_COLORS[lot.owner].lerp(Color.WHITE, 0.45)
			rmat.albedo_color = ROOF_COLOR if whole else PLAYER_COLORS[lot.owner].darkened(0.25)
			sign_mat.albedo_color = PLAYER_COLORS[lot.owner]
			t.sign_label.modulate = Color.WHITE
			t.sign_label.text = "%d G" % game.rent(id)
			t.sign_label.font_size = 58

	for id in _tiles:
		var parts: Array = [_tiles[id].mesh]
		if _tiles[id].has("panel"):
			parts.append(_tiles[id].panel)
		for part: MeshInstance3D in parts:
			var mat: StandardMaterial3D = part.material_override
			mat.emission_enabled = id in highlight or id in _spot
			mat.emission = Color.WHITE
			mat.emission_energy_multiplier = 0.5 if id in highlight else 0.25
	_dim_labels()  # the signs were just rewritten
	for a in _arrows:
		a.queue_free()
	_arrows.clear()
	for id in highlight:
		var arrow := _label("▼", 96, Color.WHITE, true)
		arrow.position = _pos(id) + _up(id) * 1.0
		_root.add_child(arrow)
		_arrows.append(arrow)

	for p in game.players:
		var holder := _tokens[p.index]
		holder.visible = not p.broke
		var shown: int = _preview.get(p.index, p.position)
		var target := _token_spot(p.index)
		if _token_space[p.index] == shown:
			continue
		_token_space[p.index] = shown
		var up := _up(shown)
		var was: int = _token_from.get(p.index, -1)
		_token_from[p.index] = shown
		var warped: bool = was >= 0 and game.space(was).type == "warp" and game.space(shown).type == "warp" \
				and shown in game.space(was).next
		var way := target - holder.position
		way -= up * way.dot(up)
		if not instant and not warped and way.length() > 0.05:
			_heading[p.index] = way.normalized()
		if instant or warped:
			if warped:  # a flash at each end of the warp
				_burst(holder.position + up * 0.4, WARP_GLOW, _root)
				_burst(target + up * 0.4, WARP_GLOW, _root)
			holder.position = target
			if up.is_equal_approx(Vector3.UP):
				holder.rotation = Vector3.ZERO  # face the camera
			else:
				(holder as Character).stand(up, Vector3.DOWN)
		else:
			(holder as Character).walk_to(target, MOVE_TIME / walk_speed, up)


func popup_at_player(index: int, text: String, color: Color) -> void:
	_popup(_tokens[index].position + Vector3(0, 0.75, 0), text, color)


func popup_at_space(id: int, text: String, color: Color) -> void:
	_popup(_pos(id) + _up(id) * 0.9, text, color)


## Shows player `index` standing on `id` while they plan a route (the game
## state only changes once the route is confirmed).
func preview(index: int, id: int) -> void:
	_preview[index] = id
	sync()


func clear_preview(index: int) -> void:
	_preview.erase(index)


## The dice block appears over player `index`'s head, spinning with its numbers
## flicking, until hit_block().
func show_block(index: int) -> void:
	clear_block()
	_block = _dice_block()
	_root.add_child(_block)
	_block.position = _tokens[index].position + _up(game.players[index].position) * BLOCK_HEIGHT
	_block_index = index
	_block.scale = Vector3.ZERO
	create_tween().tween_property(_block, "scale", Vector3.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_block_mode = "spin"


## Player `index` punches the block: it flies at the screen, bounces round the
## bottom of it as if just in front of the camera, and settles face on
## showing `result`, then vanishes. Returns once it has gone.
func hit_block(index: int, result: int) -> void:
	if _block == null:
		show_block(index)
	var figure := _tokens[index] as Character
	figure.punch()
	await get_tree().create_timer(Character.PUNCH_IMPACT).timeout
	block_hit.emit()
	_burst(_block.global_position, Color.WHITE, _root)
	# Hand it over to the camera at the same spot on screen and the same size,
	# kept on screen and above the bounce floor however the camera is turned
	# (on a 3D board the head may be near the edge, low, or close to the
	# lens), so every throw starts alike.
	var held := _block.global_transform
	var at := _camera.to_local(held.origin)
	var shrink := clampf(DICE_DEPTH / maxf(-at.z, 0.5), 0.3, 0.9)
	var half_h := _half_height()
	var view := get_viewport().get_visible_rect().size
	var half_w := half_h * view.x / maxf(view.y, 1.0)
	var start := Vector3(at.x, at.y, 0.0) * (DICE_DEPTH / maxf(-at.z, 0.5))
	start.x = clampf(start.x, -half_w * 0.5, half_w * 0.5)
	start.y = clampf(start.y, -half_h * 0.3, half_h * 0.5)
	start.z = -DICE_DEPTH
	_root.remove_child(_block)
	_camera.add_child(_block)
	_block.global_transform = held
	_block.position = start
	_block.scale = Vector3.ONE * shrink
	create_tween().tween_property(_block, "scale", Vector3.ONE * 0.75, 0.3)
	var side := -signf(start.x) if absf(start.x) > 0.05 else (1.0 if randf() < 0.5 else -1.0)
	_block_vel = Vector3(side * randf_range(0.6, 1.2), 2.4, 0)
	_block_spin = Vector3(randf_range(7, 11), randf_range(4, 8), randf_range(-6, 6))
	_block_mode = "bounce"
	await get_tree().create_timer(BOUNCE_SECONDS / dice_speed).timeout
	# Settle face on, the roll on its front.
	_block_mode = ""
	var faces: Array = _block.get_meta("faces")
	for f in faces:
		(f as Label3D).text = str(result)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_block, "position", Vector3(0, -_half_height() * 0.1, -DICE_DEPTH), 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_block, "quaternion", Quaternion.IDENTITY, 0.35)
	tw.tween_property(_block, "scale", Vector3.ONE * 0.95, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	block_landed.emit()
	await get_tree().create_timer(0.8 / dice_speed).timeout
	var out := create_tween()
	out.tween_property(_block, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await out.finished
	clear_block()


## Landing on the Star: a smiling star rises out of player `index` and grows
## slowly, turned to face the camera, twinkles popping round it, then shrinks
## away at the end of `seconds`.
func star_rise(index: int, seconds: float) -> void:
	var holder := Node3D.new()
	holder.position = _tokens[index].position + Vector3(0, 0.7, 0)
	holder.scale = Vector3.ONE * 0.15
	_root.add_child(holder)
	var star := _smiling_star()
	star.rotation.x = atan2(_cam_dir().z, _cam_dir().y)  # its face towards the camera
	holder.add_child(star)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(holder, "position:y", holder.position.y + 1.1, seconds).set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_SINE)
	tw.tween_property(holder, "scale", Vector3.ONE * 1.5, seconds).set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_SINE)
	tw.tween_property(holder, "rotation:y", 0.35, seconds).from(-0.35).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_property(holder, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(holder.queue_free)
	for k in int(seconds / 0.09):  # twinkles round it as it goes
		var twinkle := _label("✦", 64, [STAR_YELLOW, Color.WHITE, Color("#fff2b0")][k % 3], true)
		twinkle.outline_size = 0
		twinkle.no_depth_test = true
		twinkle.scale = Vector3.ZERO
		_root.add_child(twinkle)
		var t := create_tween()
		t.tween_interval(k * 0.09)
		t.tween_callback(func():
			var spread := 0.25 + 0.3 * holder.scale.x
			twinkle.position = holder.position + Vector3(randf_range(-spread, spread),
					randf_range(-spread, spread) * 0.8, randf_range(-0.1, 0.1)))
		t.tween_property(twinkle, "scale", Vector3.ONE * randf_range(0.5, 1.0), 0.12)
		t.tween_property(twinkle, "scale", Vector3.ZERO, 0.25)
		t.tween_callback(twinkle.queue_free)


func clear_block() -> void:
	if _block:
		_block.queue_free()
	_block = null
	_block_mode = ""


## Half the screen's height, in camera space, at the bouncing block's depth.
func _half_height() -> float:
	return DICE_DEPTH * tan(deg_to_rad(_camera.fov / 2))


func _move_block(delta: float) -> void:
	_block_flick -= delta
	if _block_mode != "" and _block_flick <= 0.0:
		_block_flick = 0.07
		for f in _block.get_meta("faces"):
			(f as Label3D).text = str(randi_range(2, 2 * GameState.DIE_SIDES))
	match _block_mode:
		"spin":
			_block.rotation.y += delta * 5.0
			_block.rotation.x = sin(_time * 3.0) * 0.4
			# Over their head wherever they are, even if they are still walking,
			# at whatever height their space is (a turtle, the tower, the glass).
			var feet := _tokens[_block_index].position
			var up := _up(_preview.get(_block_index, game.players[_block_index].position))
			_block.position = feet + up * (BLOCK_HEIGHT + sin(_time * 4.0) * 0.04)
		"bounce":
			var half_h := _half_height()
			var view := get_viewport().get_visible_rect().size
			var half_w := half_h * view.x / maxf(view.y, 1.0)
			_block_vel.y -= 9.0 * delta
			_block.position += _block_vel * delta
			var floor_y := -half_h * 0.55
			if _block.position.y < floor_y and _block_vel.y < 0.0:
				_block.position.y = floor_y
				if _block_vel.y < -0.6:  # a real bounce, with its tap
					_block_vel.y *= -0.62
					_block_vel.x *= 0.85
					_block_spin *= 0.7
					block_bounce.emit()
				else:  # too slow to bounce: it rolls along the floor, quietly
					_block_vel.y = 0.0
					_block_vel.x *= 0.9
					_block_spin *= 0.9
			if absf(_block.position.x) > half_w * 0.75 and signf(_block_vel.x) == signf(_block.position.x):
				_block_vel.x = -_block_vel.x
			_block.rotation += _block_spin * delta

## A block has just come into one player's hands: the camera moves in on its
## lots for `seconds` while, one after another, each building spins round,
## puts on its gold roof and throws sparks, under a WHOLE BLOCK! banner.
func whole_block(ids: Array[int], seconds: float) -> void:
	if ids.is_empty():
		return
	var center := focus_on(ids, seconds, 4.5)
	spotlight(ids)
	get_tree().create_timer(seconds).timeout.connect(func(): if _spot == ids: clear_spotlight())
	_confetti(center + _view_up(ids) * 3.2, seconds, 3.0)
	var owner: int = game.lots[ids[0]].owner
	var color: Color = PLAYER_COLORS[owner] if owner >= 0 else ROOF_COLOR
	for i in ids.size():
		var t: Dictionary = _tiles[ids[i]]
		var roof: Node3D = t.roof
		roof.scale = Vector3.ZERO
		var delay := Music.FANFARE_LEAD_IN + i * Music.FANFARE_STEP  # in time with its note
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(t.building, "rotation:y", TAU, 0.55) \
				.from(0.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(roof, "scale", Vector3.ONE, 0.45) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			t.building.rotation.y = 0.0
			var top: Vector3 = (t.roof_at as Node3D).position + Vector3(0, 0.3, 0)
			_burst(top, ROOF_COLOR, _root)
			_burst(top, color, _root))
	var label := _label("WHOLE BLOCK!", 110, ROOF_COLOR, true)
	label.no_depth_test = true
	label.outline_size = 16
	label.position = center + _view_up(ids) * 1.6
	label.scale = Vector3.ONE * 0.2
	_root.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.5, seconds - 0.8))
	tw.tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)


## A player owns more than one lot of a block: the camera moves in on the
## block for `seconds` with the rest of the board dimmed and confetti falling,
## and the houses of `owned`, one after another, squash down, leap up
## stretched and spinning, land with a wobble and burst into sparks; each then
## shows `labels` (lot id -> text: its new value and rent; the block's bond
## price on the first) over it.
func block_focus(ids: Array[int], owned: Array[int], labels: Dictionary, seconds: float) -> void:
	if ids.is_empty():
		return
	var center := focus_on(ids, seconds, 4.0)
	spotlight(ids)
	get_tree().create_timer(seconds).timeout.connect(func(): if _spot == ids: clear_spotlight())
	_confetti(center + _view_up(ids) * 3.0, seconds, 2.4)
	for i in owned.size():
		var t: Dictionary = _tiles[owned[i]]
		var house: Node3D = t.building
		var rest := house.position
		var tw := create_tween()
		tw.tween_interval(0.3 + i * 0.32)
		# Squash, then leap: stretched tall, a full spin, up off the tile...
		tw.tween_property(house, "scale", Vector3(1.35, 0.6, 1.35), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(house, "scale", Vector3(0.8, 2.0, 0.8), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(house, "position", rest + Vector3(0, 0.55, 0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(house, "rotation:y", TAU, 0.42).from(0.0).set_trans(Tween.TRANS_SINE)
		# ...back down with a thump, a wobble, and settle a size up for a moment.
		tw.tween_property(house, "position", rest, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(house, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
		tw.tween_property(house, "scale", Vector3(1.6, 0.75, 1.6), 0.08)
		tw.tween_property(house, "scale", Vector3.ONE * 1.25, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		if labels.has(owned[i]):
			var id: int = owned[i]
			tw.tween_callback(func(): _stat_tag(id, labels[id], seconds - 1.2 - i * 0.32))
		tw.tween_callback(func():
			house.rotation.y = 0.0
			_burst(house.global_position + _up(owned[i]) * 0.6, ROOF_COLOR, _root)
			_burst(house.global_position + _up(owned[i]) * 0.9, CONFETTI_COLORS[i % CONFETTI_COLORS.size()], _root))
		tw.tween_interval(maxf(0.2, seconds - 1.6 - i * 0.32))
		tw.tween_property(house, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Points the camera at spaces `ids` for `seconds`, close enough to show them
## all (at least `min_dist` away). On a 3D board it looks from their side of
## the board, along their up, so a block on a turtle, a wall or round the
## bottle is seen from outside. Returns their middle.
func focus_on(ids: Array[int], seconds: float, min_dist := 4.0) -> Vector3:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for id in ids:
		lo = lo.min(_pos(id))
		hi = hi.max(_pos(id))
	var center := (lo + hi) / 2
	var view := get_viewport().get_visible_rect().size
	var aspect := view.x / maxf(view.y, 1.0)
	var size := (hi - lo).length()
	var need := maxf(size, size / aspect) * 0.8 + 3.0
	var dist := maxf(min_dist, need * 0.5 / tan(deg_to_rad(_camera.fov * 0.5)))
	_focus_look = center + _view_up(ids) * 0.3
	_focus_pos = _focus_look + _view_dir(ids) * dist
	_focus_until = _time + seconds
	return center


## Which way is up for spaces `ids` together (their ups averaged).
func _view_up(ids: Array[int]) -> Vector3:
	var up := Vector3.ZERO
	for id in ids:
		up += _up(id)
	return up.normalized() if up.length() > 0.01 else Vector3.UP


## Towards the camera when looking at spaces `ids`: the board's own view on a
## flat board; on a 3D board from above them and out from the board's middle.
func _view_dir(ids: Array[int]) -> Vector3:
	if not _turning:
		return _cam_dir()
	var up := _view_up(ids)
	if _walls:  # as the following camera: level ground the board's view, a wall square on
		if up.dot(Vector3.UP) > 0.95:
			return _cam_dir()
		return (up * 0.85 + Vector3.UP * 0.45).normalized()
	var center := Vector3.ZERO
	for id in ids:
		center += _pos(id)
	var out := center / ids.size() - _center
	out -= up * out.dot(up)
	if out.length() < 0.5:
		return _cam_dir()
	var lift := CAMERA_DIR.normalized()
	return (up * lift.y + out.normalized() * lift.z).normalized()


## Confetti falling from `at` for `seconds`, spread over `width` tiles.
func _confetti(at: Vector3, seconds: float, width: float) -> void:
	var c := CPUParticles3D.new()
	c.position = at
	c.amount = 140
	c.lifetime = 2.6
	c.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	c.emission_box_extents = Vector3(width, 0.2, width)
	c.direction = Vector3.DOWN
	c.spread = 30.0
	c.initial_velocity_min = 0.4
	c.initial_velocity_max = 1.2
	c.gravity = Vector3(0, -2.0, 0)
	c.angular_velocity_min = -360.0
	c.angular_velocity_max = 360.0
	c.scale_amount_min = 0.7
	c.scale_amount_max = 1.3
	var bit := BoxMesh.new()
	bit.size = Vector3(0.08, 0.015, 0.05)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bit.material = mat
	c.mesh = bit
	var colours := Gradient.new()
	colours.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	colours.colors = PackedColorArray(CONFETTI_COLORS)
	c.color_initial_ramp = colours
	_root.add_child(c)
	c.emitting = true
	var root := _root
	get_tree().create_timer(seconds).timeout.connect(func():
		if is_instance_valid(c):
			c.emitting = false)
	get_tree().create_timer(seconds + c.lifetime + 0.2).timeout.connect(func():
		if is_instance_valid(c) and is_instance_valid(root):
			c.queue_free())


## A small panel of text floating over space `id` for `seconds`.
func _stat_tag(id: int, text: String, seconds: float) -> void:
	var tag := _label(text, 44, Color.WHITE, true)
	tag.outline_size = 12
	tag.outline_modulate = Color("#1a1a24")
	tag.no_depth_test = true
	tag.position = _pos(id) + _up(id) * 1.5
	tag.scale = Vector3.ONE * 0.2
	_root.add_child(tag)
	var tw := create_tween()
	tw.tween_property(tag, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.6, seconds))
	tw.tween_property(tag, "modulate:a", 0.0, 0.3)
	tw.tween_callback(tag.queue_free)


## Spotlights spaces `ids` (a block): the light falls, every other space and
## everything on it darkens, and the chosen ones glow under lights of their
## own. Stays until clear_spotlight() or another spotlight. An empty list
## clears it.
func spotlight(ids: Array[int]) -> void:
	if ids == _spot:
		return
	clear_spotlight()
	if ids.is_empty() or game == null:
		return
	_spot.assign(ids)
	if _dim_mat == null:
		_dim_mat = StandardMaterial3D.new()
		_dim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_dim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_dim_mat.albedo_color = Color(0.02, 0.02, 0.06, SPOT_DIM)
	var tw := _light_tween()
	tw.tween_property(_sun, "light_energy", _day.sun * 0.35, 0.3)
	tw.tween_property(_env, "ambient_light_energy", _day.ambient * 0.4, 0.3)
	tw.tween_property(_env, "background_color", (_day.sky as Color).darkened(0.55), 0.3)
	for id in _tiles:
		if id in _spot:
			continue
		_dim_tree(_tiles[id].holder)
	for id in _spot:
		var light := OmniLight3D.new()
		light.position = _pos(id) + _up(id) * 1.4
		light.omni_range = 2.4
		light.light_energy = 2.2
		light.light_color = Color("#fff4dc")
		_root.add_child(light)
		_spot_nodes.append(light)
	sync()


## Puts the board's light back after spotlight().
func clear_spotlight() -> void:
	if _spot.is_empty():
		return
	_spot.clear()
	for n in _spot_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_spot_nodes.clear()
	for n in _dimmed:
		if not is_instance_valid(n):
			continue
		if n is Label3D:
			(n as Label3D).modulate = _dimmed[n]
			n.remove_meta("dim_to")
		else:
			(n as GeometryInstance3D).material_overlay = _dimmed[n]
	_dimmed.clear()
	var tw := _light_tween()
	tw.tween_property(_sun, "light_energy", _day.sun, 0.3)
	tw.tween_property(_env, "ambient_light_energy", _day.ambient, 0.3)
	tw.tween_property(_env, "background_color", _day.sky, 0.3)
	if game != null:
		sync()


## A fresh parallel tween for the board's light, stopping the last one, so a
## dimming and a brightening never fight over it. Every change of light goes
## to or from _day, never to whatever the light was halfway through a change.
func _light_tween() -> Tween:
	if _light_tw and _light_tw.is_valid():
		_light_tw.kill()
	_light_tw = create_tween().set_parallel(true)
	return _light_tw


## Darkens every mesh under `node` (a dark see-through coat over it) and its
## words (Label3D: their colour, kept to put back).
func _dim_tree(node: Node) -> void:
	if node is Label3D:
		_dim_label(node)
	elif node is GeometryInstance3D and (node as GeometryInstance3D).material_overlay != _dim_mat:
		_dimmed[node] = (node as GeometryInstance3D).material_overlay
		(node as GeometryInstance3D).material_overlay = _dim_mat
	for child in node.get_children():
		_dim_tree(child)


## Darkens a label, unless it still shows the darkened colour it was given.
func _dim_label(l: Label3D) -> void:
	if l.has_meta("dim_to") and l.modulate == l.get_meta("dim_to"):
		return
	_dimmed[l] = l.modulate
	l.modulate = l.modulate.darkened(SPOT_DIM)
	l.set_meta("dim_to", l.modulate)


## sync() rewrites the signs' colours; dims the ones under the spotlight's
## shade again (and catches a house rebuilt meanwhile).
func _dim_labels() -> void:
	if _spot.is_empty():
		return
	for id in _tiles:
		if id in _spot:
			continue
		var t: Dictionary = _tiles[id]
		if t.has("sign_label"):
			_dim_label(t.sign_label)
		if t.has("building"):
			_dim_tree(t.building)


## The winner: the camera close on them, fireworks bursting overhead and
## confetti raining down, the figure celebrating, under a WINNER! banner,
## until the board is rebuilt.
func victory(index: int) -> void:
	var fig: Node3D = _tokens[index]
	var id: int = game.players[index].position
	var up := _up(id)
	_focus_look = fig.position + up * 0.6
	_focus_pos = _focus_look + _view_dir([id]) * 5.0
	_focus_until = INF
	_victory_until = INF
	clear_spotlight()
	var label := _label("WINNER!", 130, ROOF_COLOR, true)
	label.no_depth_test = true
	label.outline_size = 18
	label.position = fig.position + up * 1.9
	label.scale = Vector3.ONE * 0.2
	_root.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bob := create_tween().set_loops()
	bob.tween_property(label, "position", label.position + up * 0.12, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "position", label.position, 0.6).set_trans(Tween.TRANS_SINE)
	bob.bind_node(label)
	_confetti(fig.position + up * 3.0, 3600.0, 2.0)
	_victory_show(index, _root)


## One round of the winner's fireworks and cheering, again and again while
## the victory lasts (and the board it was for is still up).
func _victory_show(index: int, root: Node3D) -> void:
	if not is_instance_valid(root) or root != _root or _time >= _victory_until:
		return
	var fig: Node3D = _tokens[index]
	var up := _up(game.players[index].position)
	(fig as Character).celebrate()
	for i in 4:
		var side := Vector3(randf_range(-1.4, 1.4), 0, randf_range(-1.0, 0.6))
		var burst_at := fig.position + up * randf_range(1.6, 2.6) + side
		get_tree().create_timer(i * 0.3).timeout.connect(_launch_firework.bind(fig.position, burst_at, root))
	get_tree().create_timer(Character.CELEBRATE_SECONDS).timeout.connect(_victory_show.bind(index, root))


## Pulls the camera back to show the whole board for `seconds`.
func overview(seconds: float) -> void:
	_overview_until = maxf(_overview_until, _time + seconds)


## Whole board during an overview or while choices are highlighted, else close
## behind the current player. On a 3D board the following camera turns with
## the player, easing round behind them as they change direction. View Map's
## free camera goes wherever it is steered.
func _move_camera(delta: float) -> void:
	var look := _overview_look
	var pos := _overview_pos
	var turn := minf(1.0, delta * TURN_EASE)
	_follow_dir = _ease_dir(_follow_dir, _behind(game.current), turn)
	if _time < _focus_until:
		look = _focus_look
		pos = _focus_pos
	elif free_cam:
		_steer_free_cam(delta)
		look = _free_look
		pos = look + _free_dir() * _free_dist
	elif _time >= _overview_until and not hold_overview and not always_overview \
			and (highlight.is_empty() or not zoom_for_highlight):
		look = _tokens[game.current].position
		pos = look + _follow_dir * FOLLOW_DIST
	var k := minf(1.0, delta * CAMERA_EASE)
	_camera.position = _camera.position.lerp(pos, k)
	_cam_look = _cam_look.lerp(look, k)
	var up := Vector3.UP
	if absf((_camera.position - _cam_look).normalized().dot(up)) > 0.98:
		up = Vector3.FORWARD  # straight down: any other up will do
	_camera.look_at(_cam_look, up)


## Towards the camera from player `index` when following them: the board's
## own view on a flat board; on a 3D board behind and above the way they last
## walked, measured from their space's up (a wall or the bottle's side).
func _behind(index: int) -> Vector3:
	if not _turning or index < 0 or index >= _tokens.size():
		return _cam_dir()
	var id: int = _preview.get(index, game.players[index].position)
	var up := _up(id)
	if _walls:
		# Level ground with walls (Sky Station): the board's own view
		# on level ground, and square on to the wall, a little above, while on
		# it; the camera only turns stepping on or off.
		if up.dot(Vector3.UP) > 0.95:
			return _cam_dir()
		return (up * 0.85 + Vector3.UP * 0.45).normalized()
	var ahead: Vector3 = _heading.get(index, Vector3.ZERO)
	ahead -= up * ahead.dot(up)
	if ahead.length() < 0.01:
		return _cam_dir()  # not walked yet: the board's own view
	var lift := CAMERA_DIR.normalized()
	return (up * lift.y - ahead.normalized() * lift.z).normalized()


## Turns `from` a step `k` of the way to `to` (unit vectors), round the side
## when they point opposite ways.
static func _ease_dir(from: Vector3, to: Vector3, k: float) -> Vector3:
	if from.length() < 0.01:
		return to
	if from.dot(to) < -0.97:  # straight round: pick a side to turn by
		var side := from.cross(Vector3.UP)
		if side.length() < 0.01:
			side = from.cross(Vector3.RIGHT)
		to = (to + side.normalized() * 0.3).normalized()
	return from.slerp(to, k).normalized()


## Opens or closes View Map's free camera, starting from the whole board.
func set_free_cam(on: bool) -> void:
	free_cam = on
	_dragging = -1
	if not on:
		return
	_free_look = _overview_look
	_free_dist = _overview_pos.distance_to(_overview_look)
	_free_yaw = 0.0
	_free_pitch = 0.0


## Towards the free camera from what it looks at: the board's view turned by
## the yaw and tilted by the pitch.
func _free_dir() -> Vector3:
	var d := _cam_dir()
	var flat := Vector3(d.x, 0, d.z)
	var level := atan2(d.y, flat.length())
	var pitch := clampf(level + _free_pitch, deg_to_rad(8), deg_to_rad(88))
	_free_pitch = pitch - level  # no winding up past the limits
	var heading := atan2(flat.x, flat.z) + _free_yaw
	return Vector3(sin(heading) * cos(pitch), sin(pitch), cos(heading) * cos(pitch))


## Free camera from the keyboard and pad: WASD (or the left stick) slide it
## over the board, Q/E (or the right stick) turn round it, R/F (right stick
## up/down) tilt, Z/X (or the triggers) zoom.
func _steer_free_cam(delta: float) -> void:
	var move := Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	var turn := float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
	var tilt := float(Input.is_key_pressed(KEY_R)) - float(Input.is_key_pressed(KEY_F))
	var zoom := float(Input.is_key_pressed(KEY_X)) - float(Input.is_key_pressed(KEY_Z))
	for pad in Input.get_connected_joypads():
		var left := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		var right := Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y))
		if left.length() > 0.2:
			move += left
		if absf(right.x) > 0.2:
			turn += right.x
		if absf(right.y) > 0.2:
			tilt -= right.y
		zoom += Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT)
	_free_yaw += turn * FREE_TURN * delta
	_free_pitch += tilt * FREE_TURN * 0.6 * delta
	_free_dist = clampf(_free_dist * (1.0 + zoom * delta * 1.2), 2.5, _max_free_dist())
	_pan_free_cam(move * FREE_PAN * delta * (_free_dist / 12.0))


## Slides the free camera's aim over the board, `by` in screen terms (x right,
## y down), kept over the board.
func _pan_free_cam(by: Vector2) -> void:
	var d := _free_dir()
	var right := Vector3(d.z, 0, -d.x).normalized()  # across the screen, level
	var down := Vector3(d.x, 0, d.z).normalized()    # towards the camera, level
	_free_look += right * by.x + down * by.y
	var margin := Vector3(3, 0, 3)
	_free_look = _free_look.clamp(_lo - margin, _hi + margin)
	_free_look.y = clampf(_free_look.y, _lo.y - 3.0, maxf(_hi.y, 0.0) + 6.0)


func _max_free_dist() -> float:
	return _overview_pos.distance_to(_overview_look) * 1.6

## A plot: earth and a SALE sign while empty; once built, the owner's colour,
## a model of the building (_plot_model) and a sign with what rivals pay.
func _sync_plot(id: int) -> void:
	var t: Dictionary = _tiles[id]
	var plot: Dictionary = game.plots[id]
	var mat: StandardMaterial3D = t.mesh.material_override
	var sign_mat: StandardMaterial3D = t.sign_board.material_override
	t.sale.visible = plot.owner < 0
	# An empty plot shows only its SALE sign; the cost is on the landing menu.
	for part: Node3D in [t.sign_post, t.sign_board, t.sign_label]:
		part.visible = plot.owner >= 0
	var key := "%s|%d|%d" % [plot.kind, plot.owner, plot.level] if plot.owner >= 0 else ""
	if t.get("model_key", "") != key:
		t.model_key = key
		for child in (t.model_at as Node3D).get_children():
			child.queue_free()
		if key != "":
			t.model_at.add_child(_plot_model(plot.kind, PLAYER_COLORS[plot.owner], plot.level))
	if plot.owner < 0:
		mat.albedo_color = TYPE_COLORS.plot
		return
	var colour: Color = PLAYER_COLORS[plot.owner]
	mat.albedo_color = colour.lerp(Color.WHITE, 0.25)
	sign_mat.albedo_color = colour
	t.sign_label.font_size = 40
	t.sign_label.modulate = Color.WHITE
	match plot.kind:
		"bridge":
			t.sign_label.text = "Toll %d G" % plot.toll
		"tax":
			t.sign_label.text = "Tax %d%%" % roundi(Plots.TAX_RATE * 100)
		_:
			t.sign_label.text = "%d G" % Plots.rival_charge(game, id, null)


## Take a break (the Moon space): night falls on the board in time with the
## NightSky veil over the view: the light cools to blue and dims, then the sun
## is nearly out and the fill turns moonlit blue, every house's windows light up, and it all
## comes back with the dawn. The camera shows the whole board meanwhile so the
## closed signs can be seen. Same phases as NightSky.play(seconds).
func nightfall(seconds: float) -> void:
	overview(seconds)
	clear_spotlight()
	var sky: Color = _day.sky
	var ambient: Color = _day.ambient_color
	var ambient_energy: float = _day.ambient
	var light: Color = _day.sun_color
	var energy: float = _day.sun
	var dusk := seconds * 0.2
	var tw := _light_tween()
	tw.tween_property(_sun, "light_color", Color("#a8b8ff"), dusk)  # cooling to blue, no red sunset
	tw.tween_property(_env, "background_color", Color("#2a3a7a"), dusk)
	tw.tween_property(_sun, "light_energy", energy * 0.6, dusk)
	tw.chain().tween_property(_sun, "light_energy", energy * 0.08, dusk)
	tw.tween_property(_env, "background_color", Color("#070b26"), dusk)
	tw.tween_property(_env, "ambient_light_color", Color("#6a80d8"), dusk)
	tw.tween_property(_env, "ambient_light_energy", ambient_energy * 0.7, dusk)
	tw.tween_callback(_light_windows.bind(true))
	tw.chain().tween_interval(seconds * 0.35)
	tw.chain().tween_property(_sun, "light_energy", energy, seconds * 0.25)
	tw.tween_property(_sun, "light_color", light, seconds * 0.25)
	tw.tween_property(_env, "background_color", sky, seconds * 0.25)
	tw.tween_property(_env, "ambient_light_color", ambient, seconds * 0.25)
	tw.tween_property(_env, "ambient_light_energy", ambient_energy, seconds * 0.25)
	tw.tween_callback(_light_windows.bind(false))


## A wall space's sign (t.wall_sign) floats out from the wall past the top
## of its house's roof (or a plot's model), nearer the camera than the
## house, so it is never hidden behind it.
func _lift_wall_sign(t: Dictionary) -> void:
	if not t.get("wall_sign", false):
		return
	var top: float = t.get("house_top", WALL_PLOT_TOP)
	(t.sign_pivot as Node3D).position = Vector3(0, top - SIGN_HEIGHT + 0.12, 0)


## Every house's windows glow (night) or go back to plain glass.
func _light_windows(on: bool) -> void:
	for id in _tiles:
		var t: Dictionary = _tiles[id]
		if not t.has("building"):
			continue
		for pane in (t.building as Node3D).get_children():
			if pane.has_meta("window"):
				var m: StandardMaterial3D = (pane as MeshInstance3D).material_override
				m.emission_enabled = on
				m.emission = HOUSE_WINDOW
				m.emission_energy_multiplier = 1.6


## PAYDAY: fireworks over the Depot, a big gold banner and the player
## celebrating, with the camera held close on them (not pulled back) just far
## enough to take in the banner and the bursts.
func payday(index: int, amount: int) -> void:
	var at := _pos(game.board.depot)
	var up := _up(game.board.depot)
	var label := _label("PAYDAY!\n+%d G" % amount, 110, Color("#ffd84a"), true)
	label.no_depth_test = true
	label.outline_size = 16
	label.position = at + up * 1.5
	label.scale = Vector3.ONE * 0.2
	_root.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.3)
	tw.tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)
	var dir := _follow_dir if _turning else _cam_dir()
	var across := dir.cross(up).normalized()
	for i in FIREWORKS:
		var burst_at := at + across * randf_range(-1.6, 1.6) + up * randf_range(1.6, 2.6) - dir * randf_range(0.0, 0.8)
		get_tree().create_timer(i * 0.25).timeout.connect(_launch_firework.bind(at, burst_at, _root))
	_focus_look = at + up * 1.1
	_focus_pos = _focus_look + dir * 6.2
	_focus_until = maxf(_focus_until, _time + PAYDAY_SECONDS)
	(_tokens[index] as Character).celebrate()


## A glowing rocket rises from `from` and bursts into sparks at `to`.
func _launch_firework(from: Vector3, to: Vector3, root: Node3D) -> void:
	if not is_instance_valid(root):
		return
	var color: Color = FIREWORK_COLORS[randi() % FIREWORK_COLORS.size()]
	var rocket := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.04
	ball.height = 0.08
	rocket.mesh = ball
	rocket.material_override = _glow_material(color)
	rocket.position = from + Vector3(0, 0.3, 0)
	root.add_child(rocket)
	var tw := create_tween()
	tw.tween_property(rocket, "position", to, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		rocket.queue_free()
		_burst(to, color, root))


func _burst(at: Vector3, color: Color, root: Node3D) -> void:
	if not is_instance_valid(root):
		return
	var sparks := CPUParticles3D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 90
	sparks.lifetime = 1.2
	sparks.direction = Vector3.UP
	sparks.spread = 180.0
	sparks.initial_velocity_min = 1.4
	sparks.initial_velocity_max = 2.2
	sparks.gravity = Vector3(0, -2.0, 0)
	sparks.damping_min = 1.0
	sparks.damping_max = 1.6
	var fade := Gradient.new()
	fade.set_color(0, color.lightened(0.3))
	fade.set_color(1, Color(color, 0.0))
	sparks.color_ramp = fade
	var dot := SphereMesh.new()
	dot.radius = 0.045
	dot.height = 0.09
	dot.radial_segments = 6
	dot.rings = 3
	sparks.mesh = dot
	var m := _glow_material(Color.WHITE)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sparks.material_override = m
	sparks.position = at
	root.add_child(sparks)
	sparks.emitting = true
	get_tree().create_timer(sparks.lifetime + 0.3).timeout.connect(sparks.queue_free)


func _glow_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m


func _process(delta: float) -> void:
	_time += delta
	if game == null or _tokens.is_empty():
		return
	for paddle in _paddles:  # slow strokes, front and back flippers out of step
		var k: float = sin(_time * 0.9 + paddle[1])
		(paddle[0] as Node3D).rotation.y = paddle[3] + k * (0.45 if paddle[2] else 0.25)
	_move_camera(delta)
	if _block:
		_move_block(delta)
	_ring.position = _tokens[game.current].position + Vector3(0, 0.03, 0)
	for i in _spinners.size():
		var s := _spinners[i]
		s.rotation.y = sin(_time * 1.2 + i) * 0.45
		s.position.y = s.get_meta("rest_y", SUIT_HEIGHT) + sin(_time * 2.0 + i) * 0.05
	for a in _arrows:
		a.position.y = 1.0 + sin(_time * 6.0) * 0.08
	_turn_signs(delta)
	for n in _spot_nodes:  # the spotlit tiles' glow breathes
		if n is OmniLight3D:
			(n as OmniLight3D).light_energy = 2.2 + sin(_time * 3.0) * 0.5


## Every price / rent sign on a level tile swings round it by the camera's
## turn (the way it faces, not where it stands, so all the signs keep the
## same angle and none look bent): with the board's own view they stay as
## built; as a turning camera goes round, they all turn with it. Signs on a
## wall or the bottle's glass always stay as built.
func _turn_signs(delta: float) -> void:
	var k := minf(1.0, delta * 6.0)
	var back := _camera.global_basis.z  # from the view towards the camera
	var turn := atan2(back.x, back.z) - atan2(_cam_dir().x, _cam_dir().z)
	if Vector2(back.x, back.z).length() < 0.05:
		turn = 0.0  # looking straight down: no way round to speak of
	for id in _tiles:
		var t: Dictionary = _tiles[id]
		if not t.has("sign_pivot") or _up(id).dot(Vector3.UP) < 0.95:
			continue
		var pivot: Node3D = t.sign_pivot
		pivot.rotation.y = lerp_angle(pivot.rotation.y, turn, k)


# --- construction -------------------------------------------------------

func _add_space(s: Dictionary) -> void:
	var before := _root.get_child_count()
	var spinners_before := _spinners.size()
	_build_space(s)
	# Everything just made for it goes in a holder at the space, turned the
	# way the space faces (a wall space stands on its edge).
	var holder := Node3D.new()
	holder.position = _pos(s.id)
	holder.basis = _basis(s.id)
	var made: Array[Node] = []
	for i in range(before, _root.get_child_count()):
		made.append(_root.get_child(i))
	_root.add_child(holder)
	for n in made:
		var keep: Transform3D = (n as Node3D).transform
		_root.remove_child(n)
		holder.add_child(n)
		(n as Node3D).transform = keep.translated(-_pos(s.id))
	for i in range(spinners_before, _spinners.size()):
		_spinners[i].set_meta("rest_y", _spinners[i].position.y)
	var t: Dictionary = _tiles[s.id]
	t.holder = holder
	# A sign (post, board and words) turns round its tile to face the camera
	# (_turn_signs), so its price or rent reads from any side.
	if t.has("sign_board"):
		var pivot := Node3D.new()
		holder.add_child(pivot)
		for part: Node3D in [t.sign_post, t.sign_board, t.sign_label]:
			var keep := part.transform
			holder.remove_child(part)
			pivot.add_child(part)
			part.transform = keep
		t.sign_pivot = pivot
		# On a wall where the camera faces the wall square on (Sky Station's
		# tower), the sign tips further out from the wall to face the camera,
		# and floats (no post) out past the house's roof, so the house sticking
		# out towards the camera never hides it (_lift_wall_sign).
		if _walls and _up(s.id).dot(Vector3.UP) < 0.95:
			pivot.rotation.x = -deg_to_rad(WALL_SIGN_TILT)
			t.wall_sign = true
			(t.sign_post as Node3D).visible = false
			_lift_wall_sign(t)


func _build_space(s: Dictionary) -> void:
	var base: Color = TYPE_COLORS.get(s.type, Color.GRAY)
	if s.type == "lot":
		base = game.board.blocks[s.block].color
	elif s.type in ["relay", "dice", "interest", "break", "arcade", "warp"]:
		base = RELAY_FRAME
	var tile := _box(Vector3(TILE, TILE_H, TILE), base)
	tile.position = _pos(s.id) + Vector3(0, TILE_H / 2, 0)
	_root.add_child(tile)
	var entry := {"mesh": tile, "base": base}

	var title: String = TYPE_LABELS.get(s.type, "")
	match s.type:
		"lot":
			title = ""
			var panel := _box(Vector3(TILE - 2 * FRAME, 0.012, TILE - 2 * FRAME), PANEL_FOR_SALE)
			panel.position = _pos(s.id) + Vector3(0, TILE_H + 0.006, 0)
			_root.add_child(panel)
			entry.panel = panel
			# The house: sync() builds it to the lot's size (_build_house) and
			# colours it; whole_block() spins it and pops its roof.
			var building := Node3D.new()
			building.position = _pos(s.id) + Vector3(0, TILE_H, -0.12)
			_root.add_child(building)
			entry.building = building
			entry.body_mat = _material(Color.WHITE)
			entry.roof_mat = _material(ROOF_COLOR, 0.35)
			entry.roof_mat.emission_enabled = false  # lit for a whole block
			var roof_at := Node3D.new()  # the top of the roof, for the bursts
			_root.add_child(roof_at)
			entry.roof_at = roof_at
			var post := _box(Vector3(0.03, SIGN_HEIGHT, 0.03), Color("#7a5a3a"))
			post.position = _pos(s.id) + Vector3(0, TILE_H + SIGN_HEIGHT / 2, 0.34)
			_root.add_child(post)
			entry.sign_post = post
			var board := _box(Vector3(0.74, 0.24, 0.03), Color.WHITE)  # fits "1088 G"
			board.position = _pos(s.id) + Vector3(0, TILE_H + SIGN_HEIGHT, 0.34)
			board.rotation_degrees.x = -35  # tilted back towards the camera
			_root.add_child(board)
			entry.sign_board = board
			var amount := _label("", 58, Color.BLACK)
			amount.rotation_degrees.x = -35
			amount.outline_size = 0
			amount.pixel_size = 0.0035
			amount.position = board.position + board.basis.z * 0.02
			_root.add_child(amount)
			entry.sign_label = amount
		"relay":
			# A white frame round a square of the suit's colour mixed with
			# white, the suit glowing on it under the floating one.
			title = ""
			_glow_squares(s.id, s.color, entry)
			var symbol: String = SUIT_SYMBOLS.get(s.mark, "")
			var at := _pos(s.id) + Vector3(0, TILE_H + 0.02, 0.02)
			for ring in [[90, 0.15], [60, 0.25], [34, 0.45]]:  # the glow, fading outwards
				var halo := _label(symbol, 190, Color(s.color, 0.0))
				halo.outline_size = ring[0]
				halo.outline_modulate = Color(s.color.lightened(0.45), ring[1])
				halo.position = at
				_root.add_child(halo)
			var mark := _label(symbol, 190, s.color.lightened(0.3))
			mark.outline_size = 8
			mark.outline_modulate = Color(1, 1, 1, 0.9)
			mark.position = at + Vector3(0, 0.002, 0)
			_root.add_child(mark)
			var suit := _suit(s.mark, s.color)
			suit.scale = Vector3.ONE * 2.6
			suit.position = _pos(s.id) + Vector3(0, SUIT_HEIGHT, -0.15)
			_root.add_child(suit)
			_spinners.append(suit)
		"dice":  # a flat die on green that glows lighter to the middle
			title = ""
			_glow_squares(s.id, DICE_GREEN, entry, 0.6, 0.45)
			var die := _flat_die()
			die.position = _pos(s.id) + Vector3(0, TILE_H + 0.012, 0)
			_root.add_child(die)
		"interest":  # a smiling star lying on green and blue
			title = ""
			_squares(s.id, STAR_SQUARES, entry, 0.25)
			var star := _smiling_star()
			star.position = _pos(s.id) + Vector3(0, TILE_H + 0.012, 0)
			_root.add_child(star)
		"arcade":
			title = ""
			_squares(s.id, ARCADE_FLOOR, entry)  # a dim arcade-room floor
			var cabinet := _arcade_cabinet()
			cabinet.position = _pos(s.id) + Vector3(0, TILE_H + 0.012, -0.05)
			cabinet.rotation_degrees.y = -6  # nearly square on, a touch of the side showing
			_root.add_child(cabinet)
		"warp":  # a glowing pad, rings turning above it
			title = ""
			_squares(s.id, WARP_SQUARES, entry, 0.4)
			for k in 3:
				var ring := MeshInstance3D.new()
				var torus := TorusMesh.new()
				torus.inner_radius = 0.3 - k * 0.07
				torus.outer_radius = 0.34 - k * 0.07
				ring.mesh = torus
				ring.material_override = _material(WARP_GLOW.lerp(Color.WHITE, k * 0.3), 1.2)
				ring.position = _pos(s.id) + Vector3(0, TILE_H + 0.12 + k * 0.12, 0)
				_root.add_child(ring)
				_spinners.append(ring)
		"break":  # a sleepy crescent moon lying on night-blue squares, like the Star
			title = ""
			_squares(s.id, MOON_SQUARES, entry, 0.25)
			var moon := _sleepy_moon()
			moon.position = _pos(s.id) + Vector3(0, TILE_H + 0.012, 0)
			_root.add_child(moon)
		"depot":  # the Bank: a grand bank with a money bag on top, a red carpet to its door
			title = ""
			var bank := _bank_building()
			bank.scale = Vector3.ONE * BANK_SCALE
			bank.position = _pos(s.id) + Vector3(0, TILE_H, -0.27)
			_root.add_child(bank)
			var carpet := _box(Vector3(0.18, 0.01, 0.56), BANK_CARPET)
			carpet.position = _pos(s.id) + Vector3(0, TILE_H + 0.005, 0.2)
			_root.add_child(carpet)
			for x in [-0.1, 0.1]:  # its gold edging
				var edge := _box(Vector3(0.02, 0.012, 0.56), BANK_GOLD)
				edge.position = _pos(s.id) + Vector3(x, TILE_H + 0.006, 0.2)
				_root.add_child(edge)
			var word := _label("BANK", 64, BANK_GOLD)
			word.outline_size = 14
			word.outline_modulate = Color("#5a2a7a")
			word.position = _pos(s.id) + Vector3(0, TILE_H + 0.014, 0.36)
			_root.add_child(word)
		"switch":  # a big yellow push button on a dark plate, in a hazard-yellow frame
			title = ""
			var plate := _box(Vector3(TILE - 2 * FRAME, 0.012, TILE - 2 * FRAME), Color("#2a2a32"))
			plate.position = _pos(s.id) + Vector3(0, TILE_H + 0.006, 0)
			_root.add_child(plate)
			for k in 4:  # black stripes across the yellow frame's corners
				var stripe := _box(Vector3(0.22, 0.014, 0.05), Color("#1a1a1e"))
				var corner := Vector3(0.43 * (1 if k % 2 == 0 else -1), 0, 0.43 * (1 if k < 2 else -1))
				stripe.position = _pos(s.id) + Vector3(corner.x, TILE_H + 0.007, corner.z)
				stripe.rotation.y = PI / 4 * (1 if (k == 0 or k == 3) else -1)
				_root.add_child(stripe)
			var ring := _cyl(0.33, 0.35, 0.06, Color("#141418"))
			ring.position = _pos(s.id) + Vector3(0, TILE_H + 0.03, 0)
			_root.add_child(ring)
			var button := _cyl(0.25, 0.27, 0.12, SWITCH_YELLOW)
			button.material_override = _material(SWITCH_YELLOW, 0.35)
			button.position = _pos(s.id) + Vector3(0, TILE_H + 0.1, 0)
			_root.add_child(button)
			entry.button = button

	var pid := game.board.platform_of(s.id)
	if pid != "" and game.board.platforms[pid].look != "island":
		# A space on a moving platform stands on a steel deck with hazard
		# stripes front and back; it all slides with the platform.
		var deck := _box(Vector3(TILE * 1.14, 0.1, TILE * 1.14), STEEL)
		deck.position = _pos(s.id) + Vector3(0, -0.05, 0)
		_root.add_child(deck)
		for z in [-0.55, 0.55]:
			var edge := _box(Vector3(TILE * 1.14, 0.11, 0.06), SWITCH_YELLOW)
			edge.position = _pos(s.id) + Vector3(0, -0.05, z)
			_root.add_child(edge)

	if title != "":
		var label := _label(title, 30, Color.WHITE)
		label.position = _pos(s.id) + Vector3(0, TILE_H + 0.01, 0.12)
		if s.type == "wildcard":  # a big green ? on purple
			label.font_size = 130
			label.modulate = WILDCARD_MARK
			label.outline_size = 18
			label.outline_modulate = Color("#2a1440")
			label.position.z = _pos(s.id).z
		_root.add_child(label)
		entry.title = label
	if s.type == "plot":
		# Its building (a model) and a sign with what rivals pay; sync() fills
		# them in once something is built.
		var model_at := Node3D.new()
		model_at.position = _pos(s.id) + Vector3(0, TILE_H, -0.08)
		_root.add_child(model_at)
		entry.model_at = model_at
		# While nothing is built: bare earth with grass round it and a
		# cartoon SALE sign.
		var sale := _for_sale()
		sale.position = _pos(s.id) + Vector3(0, TILE_H, 0)
		_root.add_child(sale)
		entry.sale = sale
		var post := _box(Vector3(0.03, SIGN_HEIGHT, 0.03), Color("#7a5a3a"))
		post.position = _pos(s.id) + Vector3(0, TILE_H + SIGN_HEIGHT / 2, 0.34)
		_root.add_child(post)
		entry.sign_post = post
		var board := _box(Vector3(0.74, 0.24, 0.03), Color.WHITE)
		board.position = _pos(s.id) + Vector3(0, TILE_H + SIGN_HEIGHT, 0.34)
		board.rotation_degrees.x = -35
		_root.add_child(board)
		entry.sign_board = board
		var fee := _label("", 40, Color.BLACK)
		fee.rotation_degrees.x = -35
		fee.outline_size = 0
		fee.pixel_size = 0.0035
		fee.position = board.position + board.basis.z * 0.02
		_root.add_child(fee)
		entry.sign_label = fee
	_tiles[s.id] = entry


## (Re)builds a lot's house `w` wide and `h` tall (walls, not counting the
## roof) in its holder: walls with a door and a row of windows per floor, a
## gabled roof facing the camera and a chimney. Colours come from the tile's
## body_mat and roof_mat, which sync() sets.
static func _build_house(t: Dictionary, w: float, h: float) -> void:
	var holder: Node3D = t.building
	for child in holder.get_children():
		child.queue_free()
	var d := w * 0.85
	var body := _box(Vector3(w, h, d), Color.WHITE)
	body.material_override = t.body_mat
	body.position.y = h / 2
	holder.add_child(body)
	var rh := w * 0.6
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(w * 1.2, rh, d * 1.12)
	roof.mesh = prism
	roof.material_override = t.roof_mat
	roof.position.y = h + rh / 2
	holder.add_child(roof)
	t.roof = roof
	t.house_top = h + rh
	var chimney := _box(Vector3(w * 0.14, rh * 0.7, w * 0.14), HOUSE_TRIM)
	chimney.position = Vector3(w * 0.3, h + rh * 0.55, -d * 0.15)
	holder.add_child(chimney)
	var front := d / 2 + 0.006
	var door_h := minf(0.15, h * 0.6)
	var door := _box(Vector3(w * 0.26, door_h, 0.012), HOUSE_DOOR)
	door.position = Vector3(0, door_h / 2, front)
	holder.add_child(door)
	var floors := clampi(roundi(h / 0.2), 1, 6)
	var floor_h := h / floors
	var pane := minf(w * 0.2, floor_h * 0.45)
	for f in floors:
		var y := door_h * 0.6 if f == 0 else (f + 0.5) * floor_h
		for x in ([-0.32, 0.32] if f == 0 else [-0.22, 0.22]):
			var window := _box(Vector3(pane, pane, 0.012), HOUSE_WINDOW)
			window.set_meta("window", true)  # lit at night (_light_windows)
			window.position = Vector3(w * x, y, front)
			holder.add_child(window)


## Squares on space `id` stepping lighter towards the middle: `color` at the
## edge, mostly white in the centre (the Relays, the Dice space). The outer
## one is the entry's panel; `glow` makes them shine, `whiten` (0..1) how pale
## the middle gets.
func _glow_squares(id: int, color: Color, entry: Dictionary, glow := 0.0, whiten := 1.0) -> void:
	_squares(id, [color.lerp(Color.WHITE, 0.15 * whiten), color.lerp(Color.WHITE, 0.4 * whiten),
			color.lerp(Color.WHITE, 0.65 * whiten)], entry, glow)


## Three squares on space `id`, outermost first, in `colors`.
func _squares(id: int, colors: Array, entry: Dictionary, glow := 0.0) -> void:
	var sizes := [TILE - 2 * FRAME, 0.68, 0.48]
	for i in sizes.size():
		var square := _box(Vector3(sizes[i], 0.012, sizes[i]), Color.WHITE)
		square.material_override = _material(colors[i], glow)
		square.position = _pos(id) + Vector3(0, TILE_H + 0.006 + i * 0.002, 0)
		_root.add_child(square)
		if i == 0:
			entry.panel = square


## A flat, smiling star lying on the tile, with a darker rim.
static func _smiling_star() -> Node3D:
	var root := Node3D.new()
	var rim := _star_mesh(0.34, 0.15, STAR_RIM)
	root.add_child(rim)
	var star := _star_mesh(0.3, 0.13, STAR_YELLOW, 0.3)
	star.position.y = 0.012
	root.add_child(star)
	var top := 0.012 + STAR_THICK
	for x in [-0.05, 0.05]:  # eyes
		var eye := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.5
		ball.height = 1.0
		eye.mesh = ball
		eye.material_override = _material(Color("#2a1a10"))
		eye.scale = Vector3(0.028, 0.01, 0.05)
		eye.position = Vector3(x, top, -0.02)
		root.add_child(eye)
	for i in 7:  # the smile: dots along an arc, lowest in the middle
		var a := deg_to_rad(25.0 + i * 130.0 / 6)
		var dot := _box(Vector3(0.022, 0.01, 0.022), Color("#b83a1a"))
		dot.position = Vector3(cos(a) * 0.065, top, 0.015 + sin(a) * 0.05)
		root.add_child(dot)
	return root


## A flat five-pointed star, `outer`/`inner` in radius and STAR_THICK thick,
## its top point away from the camera.
static func _star_mesh(outer: float, inner: float, color: Color, glow := 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for k in 10:
		var a := deg_to_rad(-90.0 + k * 36.0)
		var r := outer if k % 2 == 0 else inner
		ring.append(Vector3(cos(a) * r, 0, sin(a) * r))
	var up := Vector3(0, STAR_THICK, 0)
	for k in 10:
		var a := ring[k]
		var b := ring[(k + 1) % 10]
		st.add_vertex(up)  # top face, a fan from the middle
		st.add_vertex(a + up)
		st.add_vertex(b + up)
		for v in [a, b, b + up, a, b + up, a + up]:  # the edge
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := _material(color, glow)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi


## A flat, sleepy crescent moon lying on the tile (the Moon space), with a
## darker rim, a closed eye, a little smile and a few small stars round it.
static func _sleepy_moon() -> Node3D:
	var root := Node3D.new()
	var rim := _flat_shape(_crescent(0.33), STAR_THICK, MOON_RIM)
	root.add_child(rim)
	var face := _flat_shape(_crescent(0.3), STAR_THICK, MOON_YELLOW, 0.3)
	face.position.y = 0.012
	root.add_child(face)
	var top := 0.012 + STAR_THICK
	for i in 5:  # the closed eye: a short arc, lowest in the middle
		var a := deg_to_rad(30.0 + i * 30.0)
		var dot := _box(Vector3(0.02, 0.01, 0.016), Color("#5a4220"))
		dot.position = Vector3(-0.13 + cos(a) * 0.045, top, -0.07 + sin(a) * 0.02)
		root.add_child(dot)
	for i in 5:  # the smile
		var a := deg_to_rad(30.0 + i * 30.0)
		var dot := _box(Vector3(0.018, 0.01, 0.018), Color("#b8603a"))
		dot.position = Vector3(-0.1 + cos(a) * 0.05, top, 0.07 + sin(a) * 0.035)
		root.add_child(dot)
	for at in [Vector3(0.24, 0.0, -0.22), Vector3(0.3, 0.0, 0.12), Vector3(0.14, 0.0, 0.28)]:
		var star := _star_mesh(0.06, 0.025, MOON_YELLOW, 0.5)
		star.position = at + Vector3(0, 0.012, 0)
		root.add_child(star)
	return root


## A crescent `r` in radius, its points to the right (+x): the part of a disc
## left over once a second disc, shifted right, is cut out of it. Points run
## round the outline in order, on the x/z plane.
static func _crescent(r: float) -> PackedVector2Array:
	var cut_at := Vector2(r * 0.55, -r * 0.12)  # the bite's centre
	var cut_r := r * 0.85
	var pts := PackedVector2Array()
	for k in 65:  # the outer edge, round the back
		var p := Vector2.from_angle(TAU * k / 64.0) * r
		if p.distance_to(cut_at) >= cut_r:
			pts.append(p)
	for k in range(64, -1, -1):  # back along the bite
		var p := cut_at + Vector2.from_angle(TAU * k / 64.0) * cut_r
		if p.length() < r:
			pts.append(p)
	return pts


## A flat shape `thick` thick lying on y = 0 with outline `pts` (x/z),
## filled and edged, in `color`.
static func _flat_shape(pts: PackedVector2Array, thick: float, color: Color, glow := 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := Vector3(0, thick, 0)
	var tris := Geometry2D.triangulate_polygon(pts)
	for i in tris:
		st.add_vertex(Vector3(pts[i].x, 0, pts[i].y) + up)
	for k in pts.size():
		var a := Vector3(pts[k].x, 0, pts[k].y)
		var b := Vector3(pts[(k + 1) % pts.size()].x, 0, pts[(k + 1) % pts.size()].y)
		for v in [a, b, b + up, a, b + up, a + up]:  # the edge
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := _material(color, glow)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi


## A classic upright arcade cabinet, facing the camera: a lit marquee, a
## glowing screen with a maze of dots on it, a control panel with a joystick
## and two buttons, and a coin door.
static func _arcade_cabinet() -> Node3D:
	var root := Node3D.new()
	var body := _box(Vector3(0.36, 0.72, 0.3), CABINET)
	body.position.y = 0.36
	root.add_child(body)
	for x in [-0.181, 0.181]:  # stripes down the sides
		var stripe := _box(Vector3(0.004, 0.08, 0.3), CABINET_STRIPE)
		stripe.position = Vector3(x, 0.5, 0)
		root.add_child(stripe)
	var marquee := _box(Vector3(0.36, 0.11, 0.08), Color("#ffd84a"))
	marquee.material_override = _material(Color("#ffd84a"), 0.6)
	marquee.position = Vector3(0, 0.665, 0.17)
	root.add_child(marquee)
	var sign_text := _label("ARCADE", 40, Color("#d43a1a"), false)
	sign_text.rotation_degrees.x = 0
	sign_text.outline_size = 4
	sign_text.outline_modulate = Color.WHITE
	sign_text.pixel_size = 0.0016
	sign_text.position = Vector3(0, 0.665, 0.212)
	root.add_child(sign_text)
	var screen_at := Node3D.new()  # the screen, tipped back a little
	screen_at.position = Vector3(0, 0.48, 0.152)
	screen_at.rotation_degrees.x = -12
	root.add_child(screen_at)
	screen_at.add_child(_box(Vector3(0.3, 0.24, 0.01), Color("#151515")))  # bezel
	var glass := _box(Vector3(0.26, 0.2, 0.01), Color.WHITE)
	glass.material_override = _material(Color("#0a1440"), 0.8)
	glass.position.z = 0.004
	screen_at.add_child(glass)
	for wall in [[0, 0.085, 0.24, 0.012], [0, -0.085, 0.24, 0.012], [-0.115, 0, 0.012, 0.18],
			[0.115, 0, 0.012, 0.18], [0, 0.02, 0.1, 0.012], [-0.06, -0.035, 0.012, 0.06], [0.06, -0.035, 0.012, 0.06]]:
		var line := _box(Vector3(wall[2], wall[3], 0.004), Color.WHITE)
		line.material_override = _material(Color("#3a6aff"), 1.5)
		line.position = Vector3(wall[0], wall[1], 0.011)
		screen_at.add_child(line)
	for x in range(-4, 5):  # dots along the corridors
		for y in [-0.05, 0.055]:
			var pellet := _box(Vector3(0.008, 0.008, 0.004), Color.WHITE)
			pellet.material_override = _material(Color("#ffe8a0"), 1.5)
			pellet.position = Vector3(x * 0.024, y, 0.011)
			screen_at.add_child(pellet)
	var panel := _box(Vector3(0.36, 0.04, 0.14), CABINET.darkened(0.3))
	panel.position = Vector3(0, 0.32, 0.2)
	panel.rotation_degrees.x = 15  # sloping towards the player
	root.add_child(panel)
	var stick := _box(Vector3(0.012, 0.06, 0.012), Color("#202020"))
	stick.position = Vector3(-0.08, 0.36, 0.21)
	root.add_child(stick)
	var knob := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.022
	ball.height = 0.044
	knob.mesh = ball
	knob.material_override = _material(Color("#e8302a"))
	knob.position = Vector3(-0.08, 0.395, 0.21)
	root.add_child(knob)
	for b in [[0.04, Color("#3a8aff")], [0.1, Color("#ffd84a")]]:
		var button := MeshInstance3D.new()
		var cap := CylinderMesh.new()
		cap.top_radius = 0.016
		cap.bottom_radius = 0.016
		cap.height = 0.02
		button.mesh = cap
		button.material_override = _material(b[1], 0.3)
		button.position = Vector3(b[0], 0.345, 0.22)
		button.rotation_degrees.x = 15
		root.add_child(button)
	var door := _box(Vector3(0.14, 0.12, 0.01), Color("#1a1a1a"))
	door.position = Vector3(0, 0.15, 0.153)
	root.add_child(door)
	for x in [-0.03, 0.03]:  # lit coin slots
		var slot := _box(Vector3(0.02, 0.035, 0.006), Color.WHITE)
		slot.material_override = _material(Color("#ff8c3a"), 1.0)
		slot.position = Vector3(x, 0.16, 0.159)
		root.add_child(slot)
	return root


## A die drawn flat on the tile, like the Star space's star: a white face with
## a grey rim showing five pips, turned a little for a casual look.
static func _flat_die() -> Node3D:
	const PIP := 0.11  # a pip's offset from the face's centre
	var root := Node3D.new()
	root.rotation_degrees.y = 14
	var rim := _box(Vector3(0.48, 0.02, 0.48), Color("#b8b8b0"))
	rim.position.y = 0.01
	root.add_child(rim)
	var edge := _outline(Vector3(0.48, 0.02, 0.48), 0.012)
	edge.position.y = 0.01
	root.add_child(edge)
	var lines := _edges(Vector3(0.48, 0.02, 0.48), 0.01)
	lines.position.y = 0.01
	root.add_child(lines)
	var face := _box(Vector3(0.43, 0.024, 0.43), Color("#fbfbf6"))
	face.position.y = 0.014
	root.add_child(face)
	for p in [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)]:
		var pip := MeshInstance3D.new()
		var dot := CylinderMesh.new()
		dot.top_radius = 0.04
		dot.bottom_radius = 0.04
		dot.height = 0.006
		pip.mesh = dot
		pip.material_override = _material(Color("#202028"))
		pip.position = Vector3(p.x * PIP, 0.028, p.y * PIP)
		root.add_child(pip)
	return root


## A dark outline round a box `size` big: a slightly bigger black box showing
## only its inside, so just a rim of it shows round the edges.
static func _outline(size: Vector3, width: float) -> MeshInstance3D:
	var hull := _box(size + Vector3.ONE * width * 2, Color.BLACK)
	var m := _ink()
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	hull.material_override = m
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return hull


## The outlines' colour: the dice numbers' blue, untouched by the light and a
## little see-through so they read soft rather than harsh.
static func _ink() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(DICE_NUMBER, INK_ALPHA)  # the numbers' blue
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## A dark line along each of the 12 edges of a box `size` big, so every face
## of it is outlined (the dice).
static func _edges(size: Vector3, width: float) -> Node3D:
	var root := Node3D.new()
	var h := size / 2
	for axis in 3:
		for a in [-1, 1]:
			for b in [-1, 1]:
				var dims := Vector3.ONE * width
				dims[axis] = size[axis] + width
				var at := Vector3.ZERO
				at[(axis + 1) % 3] = a * h[(axis + 1) % 3]
				at[(axis + 2) % 3] = b * h[(axis + 2) % 3]
				var line := _box(dims, Color.BLACK)
				line.material_override = _ink()
				line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				line.position = at
				root.add_child(line)
	return root


## The dice block rolled over a player's head: a white cube with a number on
## every face (the block's "faces" meta, the front (+z) face first).
static func _dice_block() -> Node3D:
	var root := Node3D.new()
	var cube := _box(Vector3.ONE * DICE_BLOCK, Color.WHITE)
	cube.material_override = _material(Color("#fbfbf6"), 0.15)
	cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # it flies right up to the camera
	root.add_child(cube)
	root.add_child(_outline(Vector3.ONE * DICE_BLOCK, 0.018))
	root.add_child(_edges(Vector3.ONE * DICE_BLOCK, 0.014))
	var h := DICE_BLOCK / 2 + 0.002
	var faces: Array[Label3D] = []
	for f in [[Vector3(0, 0, h), Vector3.ZERO], [Vector3(0, 0, -h), Vector3(0, 180, 0)],
			[Vector3(h, 0, 0), Vector3(0, 90, 0)], [Vector3(-h, 0, 0), Vector3(0, -90, 0)],
			[Vector3(0, h, 0), Vector3(-90, 0, 0)], [Vector3(0, -h, 0), Vector3(90, 0, 0)]]:
		var number := Label3D.new()
		number.font_size = 120
		number.pixel_size = DICE_BLOCK / 150.0
		number.modulate = DICE_NUMBER
		number.outline_size = 0
		number.double_sided = false
		number.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		number.position = f[0]
		number.rotation_degrees = f[1]
		root.add_child(number)
		faces.append(number)
	root.set_meta("faces", faces)
	return root


## An empty plot: bare earth, tufts of grass round its edge and a cartoon
## SALE sign on two posts.
static func _for_sale() -> Node3D:
	var root := Node3D.new()
	var inner := TILE - 2 * FRAME
	var earth := _box(Vector3(inner, 0.02, inner), EARTH)
	earth.position.y = 0.01
	root.add_child(earth)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # every plot looks the same
	for i in 5:  # clods
		var clod := _box(Vector3(0.07, 0.03, 0.05), EARTH.darkened(0.25))
		clod.position = Vector3(rng.randf_range(-0.3, 0.3), 0.025, rng.randf_range(-0.05, 0.3))
		clod.rotation.y = rng.randf() * PI
		root.add_child(clod)
	for i in 14:  # grass round the edge
		var side := i % 4
		var along := rng.randf_range(-0.36, 0.36)
		var edge := inner / 2 - 0.04
		var at := Vector3(along, 0, edge * (1 if side == 0 else -1)) if side < 2 \
				else Vector3(edge * (1 if side == 2 else -1), 0, along)
		for blade in 3:
			var tuft := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.03
			cone.height = rng.randf_range(0.07, 0.12)
			cone.radial_segments = 4
			tuft.mesh = cone
			tuft.material_override = _material(GRASS.lightened(rng.randf() * 0.2))
			tuft.position = at + Vector3((blade - 1) * 0.03, 0.02 + cone.height / 2, rng.randf_range(-0.02, 0.02))
			tuft.rotation_degrees.z = (blade - 1) * 18
			root.add_child(tuft)
	var sign := Node3D.new()
	sign.position = Vector3(0, 0, -0.1)
	sign.rotation_degrees = Vector3(-15, 0, 4)  # leaning back, a little crooked
	root.add_child(sign)
	for x in [-0.2, 0.2]:
		var post := _box(Vector3(0.035, 0.5, 0.035), Color("#7a5a3a"))
		post.position = Vector3(x, 0.25, -0.02)
		sign.add_child(post)
	var backing := _box(Vector3(0.62, 0.3, 0.03), Color.WHITE)
	backing.position.y = 0.42
	sign.add_child(backing)
	var board := _box(Vector3(0.56, 0.24, 0.03), SALE_RED)
	board.position = Vector3(0, 0.42, 0.006)
	sign.add_child(board)
	var word := _label("SALE", 80, Color("#fff3b0"), false)
	word.rotation_degrees.x = 0  # stands on the board, not flat on the tile
	word.outline_size = 14
	word.outline_modulate = Color("#7a1410")
	word.pixel_size = 0.0045
	word.position = Vector3(0, 0.42, 0.025)
	sign.add_child(word)
	return root


## The Bank on the Depot: a columned building on a plinth with steps, a gold
## trimmed pediment, a dome, and a big gold money bag sitting on the dome.
## Its front faces +z; it stands narrow and deep so the four player spots on
## the tile stay clear.
static func _bank_building() -> Node3D:
	var root := Node3D.new()
	var add := func(node: Node3D, at: Vector3) -> Node3D:
		node.position = at
		root.add_child(node)
		return node
	add.call(_box(Vector3(0.5, 0.05, 0.36), BANK_STONE.darkened(0.1)), Vector3(0, 0.025, 0.02))  # plinth
	add.call(_box(Vector3(0.3, 0.025, 0.06), BANK_STONE), Vector3(0, 0.0125, 0.21))  # steps
	add.call(_box(Vector3(0.44, 0.46, 0.28), BANK_STONE), Vector3(0, 0.28, -0.01))
	add.call(_box(Vector3(0.1, 0.2, 0.01), Color("#6b3a1e")), Vector3(0, 0.15, 0.135))  # door
	add.call(_box(Vector3(0.12, 0.02, 0.012), BANK_GOLD), Vector3(0, 0.26, 0.136))
	for x in [-0.165, -0.085, 0.085, 0.165]:
		add.call(_cyl(0.022, 0.026, 0.42, Color.WHITE), Vector3(x, 0.26, 0.16))
	for side in [-1, 1]:  # windows behind the columns
		add.call(_box(Vector3(0.05, 0.08, 0.01), Color("#ffe98a")), Vector3(side * 0.125, 0.36, 0.135))
	add.call(_box(Vector3(0.5, 0.05, 0.34), BANK_STONE.lightened(0.2)), Vector3(0, 0.535, 0.01))
	add.call(_box(Vector3(0.5, 0.015, 0.345), BANK_GOLD), Vector3(0, 0.5, 0.01))
	var pediment := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.5, 0.12, 0.34)
	pediment.mesh = prism
	pediment.material_override = _material(BANK_STONE.lightened(0.15))
	add.call(pediment, Vector3(0, 0.62, 0.01))
	add.call(_cyl(0.13, 0.14, 0.08, BANK_STONE), Vector3(0, 0.62, -0.06))  # the dome's drum
	add.call(_cyl(0.145, 0.145, 0.02, BANK_GOLD), Vector3(0, 0.665, -0.06))
	var dome := MeshInstance3D.new()
	var half := SphereMesh.new()
	half.radius = 0.13
	half.height = 0.26
	half.is_hemisphere = true
	dome.mesh = half
	dome.material_override = _material(BANK_STONE.lightened(0.1))
	add.call(dome, Vector3(0, 0.675, -0.06))
	# The money bag sitting on the dome, leaning to one side: a round sack,
	# tied at the neck, the top flaring out, a G on its front.
	var bag := Node3D.new()
	bag.rotation = Vector3(-0.15, 0.3, 0.3)  # tipped over to the left, turned a little
	add.call(bag, Vector3(0, 0.76, -0.06))
	var sack := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.16
	ball.height = 0.29
	sack.mesh = ball
	sack.material_override = _material(BANK_GOLD, 0.25)
	sack.position.y = 0.15
	bag.add_child(sack)
	var neck := _cyl(0.045, 0.065, 0.05, BANK_GOLD.darkened(0.25))
	neck.position.y = 0.31
	bag.add_child(neck)
	var top := _cyl(0.095, 0.04, 0.08, BANK_GOLD)
	top.position.y = 0.37
	bag.add_child(top)
	var g := _label("G", 70, BANK_GOLD.darkened(0.45))
	g.rotation_degrees.x = 0
	g.outline_size = 0
	g.pixel_size = 0.0034
	g.position = Vector3(0, 0.15, 0.162)
	bag.add_child(g)
	return root


## A plot's building, standing on the tile, with the owner's `colour` in it:
##   bridge   a wooden bridge on stone piers over water, a toll booth and a
##            striped barrier on it
##   airport  an airliner on the runway, the terminal and control tower in
##            front of it
##   tax      a columned office with steps and a % on its pediment
##   repair   a garage with a roll-up door, a spanner on the roof and tyres
##   centre   a giant shopping mall: a tall white-clad block with louvres on
##            top and a red MALL sign, a curved glass entrance under a white
##            canopy, a long glass wing with a tall SHOPS sign and a terrace,
##            and a lamp post with banners; taller for each `level`
static func _plot_model(kind: String, colour: Color, level: int) -> Node3D:
	var root := Node3D.new()
	var add := func(node: Node3D, at: Vector3) -> Node3D:
		node.position = at
		root.add_child(node)
		return node
	match kind:
		"bridge":
			add.call(_box(Vector3(0.5, 0.012, 0.34), Color("#3f8fd8")), Vector3(0, 0.006, 0))  # water
			for x in [-0.28, 0.28]:
				add.call(_box(Vector3(0.12, 0.22, 0.3), STONE), Vector3(x, 0.11, 0))
			add.call(_box(Vector3(0.74, 0.05, 0.3), WOOD), Vector3(0, 0.245, 0))
			for z in [-0.14, 0.14]:  # railings
				add.call(_box(Vector3(0.74, 0.025, 0.02), colour), Vector3(0, 0.33, z))
				for x in [-0.33, -0.11, 0.11, 0.33]:
					add.call(_box(Vector3(0.02, 0.08, 0.02), colour.darkened(0.3)), Vector3(x, 0.29, z))
			add.call(_box(Vector3(0.12, 0.16, 0.12), colour.lerp(Color.WHITE, 0.3)), Vector3(0.24, 0.35, -0.06))
			add.call(_box(Vector3(0.15, 0.03, 0.15), colour.darkened(0.3)), Vector3(0.24, 0.445, -0.06))
			for i in 5:  # the barrier arm, red and white
				add.call(_box(Vector3(0.05, 0.025, 0.025), Color("#e8463a") if i % 2 == 0 else Color.WHITE),
						Vector3(0.12 - i * 0.05, 0.36, 0.06))
		"airport":  # an airliner on the runway, the terminal and tower in front
			add.call(_box(Vector3(0.92, 0.012, 0.28), Color("#45454d")), Vector3(0, 0.006, -0.18))
			for x in [-0.32, -0.16, 0.0, 0.16, 0.32]:  # the centre line
				add.call(_box(Vector3(0.08, 0.004, 0.018), Color.WHITE), Vector3(x, 0.014, -0.18))
			for x in [-0.43, 0.43]:  # threshold stripes at each end
				for z in [-0.28, -0.24, -0.12, -0.08]:
					add.call(_box(Vector3(0.035, 0.004, 0.022), Color.WHITE), Vector3(x, 0.014, z))
			var plane := _airliner(colour)
			plane.rotation.y = -0.12  # rolling down the runway, nose to the right
			add.call(plane, Vector3(0.08, 0.0, -0.18))
			add.call(_cyl(0.04, 0.05, 0.36, Color("#f2f2f2")), Vector3(-0.38, 0.18, 0.16))  # tower
			var cab := _cyl(0.085, 0.065, 0.08, Color.WHITE)
			cab.material_override = _material(Color("#7fd0ff"), 0.4)
			add.call(cab, Vector3(-0.38, 0.4, 0.16))
			add.call(_cyl(0.0, 0.095, 0.05, colour), Vector3(-0.38, 0.465, 0.16))
			add.call(_box(Vector3(0.42, 0.12, 0.13), Color("#f2f2f2")), Vector3(0.16, 0.06, 0.13))  # terminal
			add.call(_box(Vector3(0.42, 0.025, 0.132), colour), Vector3(0.16, 0.1, 0.13))
			var glass := _box(Vector3(0.34, 0.045, 0.005), Color.WHITE)
			glass.material_override = _material(Color("#7fd0ff"), 0.3)
			add.call(glass, Vector3(0.16, 0.05, 0.197))
		"tax":
			add.call(_box(Vector3(0.64, 0.04, 0.44), STONE.lightened(0.2)), Vector3(0, 0.02, 0.02))  # steps
			add.call(_box(Vector3(0.58, 0.04, 0.38), STONE.lightened(0.3)), Vector3(0, 0.06, 0.01))
			add.call(_box(Vector3(0.5, 0.3, 0.26), Color("#efe6d2")), Vector3(0, 0.23, -0.04))
			add.call(_box(Vector3(0.1, 0.16, 0.01), Color("#6b4a2e")), Vector3(0, 0.16, 0.095))  # door
			for x in [-0.2, -0.07, 0.07, 0.2]:
				add.call(_cyl(0.026, 0.03, 0.3, Color.WHITE), Vector3(x, 0.23, 0.14))
			add.call(_box(Vector3(0.58, 0.04, 0.36), Color.WHITE), Vector3(0, 0.4, 0.01))
			var pediment := MeshInstance3D.new()
			var prism := PrismMesh.new()
			prism.size = Vector3(0.6, 0.13, 0.36)
			pediment.mesh = prism
			pediment.material_override = _material(colour.lerp(Color.WHITE, 0.2))
			add.call(pediment, Vector3(0, 0.485, 0.01))
			var mark := _label("%", 60, Color.WHITE)
			mark.rotation_degrees.x = 0
			mark.outline_size = 8
			mark.outline_modulate = colour.darkened(0.4)
			mark.pixel_size = 0.0018
			add.call(mark, Vector3(0, 0.47, 0.195))
		"repair":
			add.call(_box(Vector3(0.56, 0.3, 0.38), colour.lerp(Color.WHITE, 0.45)), Vector3(0, 0.15, -0.02))
			add.call(_box(Vector3(0.62, 0.035, 0.44), colour.darkened(0.3)), Vector3(0, 0.318, -0.02))
			add.call(_box(Vector3(0.32, 0.22, 0.01), Color("#a8acb4")), Vector3(-0.06, 0.11, 0.175))  # door
			for i in 4:
				add.call(_box(Vector3(0.32, 0.008, 0.012), Color("#7c808a")), Vector3(-0.06, 0.03 + i * 0.055, 0.18))
			var spanner := Node3D.new()  # standing on the roof
			add.call(spanner, Vector3(0.05, 0.45, -0.02))
			spanner.rotation_degrees.z = 40
			var handle := _box(Vector3(0.04, 0.22, 0.03), Color("#c9ced6"))
			spanner.add_child(handle)
			for x in [-0.035, 0.035]:  # the open jaw
				var jaw := _box(Vector3(0.025, 0.06, 0.03), Color("#c9ced6"))
				jaw.position = Vector3(x, 0.13, 0)
				spanner.add_child(jaw)
			for y in [0.025, 0.07]:  # a stack of tyres
				var tyre := MeshInstance3D.new()
				var ring := TorusMesh.new()
				ring.inner_radius = 0.025
				ring.outer_radius = 0.06
				tyre.mesh = ring
				tyre.material_override = _material(Color("#26262a"))
				add.call(tyre, Vector3(0.24, y, 0.25))
		_:  # centre: a giant shopping mall
			var h := 0.5 + 0.08 * level  # the main block, taller with each expansion
			var white := Color("#efeee9")
			var main := Vector3(-0.16, 0, -0.12)
			add.call(_box(Vector3(0.52, h, 0.46), white), main + Vector3(0, h / 2, 0))
			for i in range(1, 6):  # panel joints across the cladding
				add.call(_box(Vector3(0.524, 0.006, 0.464), Color("#d2d1ca")), main + Vector3(0, h * i / 6.0, 0))
			add.call(_box(Vector3(0.5, 0.1, 0.44), Color("#dcdcd6")), main + Vector3(0, h + 0.05, 0))  # louvres
			for i in 11:
				add.call(_box(Vector3(0.008, 0.09, 0.006), Color("#b8b8b2")),
						main + Vector3(-0.23 + i * 0.046, h + 0.05, 0.222))
			var sign := _label("MALL", 90, Color("#d8202c"))
			sign.rotation_degrees.x = 0
			sign.autowrap_mode = TextServer.AUTOWRAP_OFF
			sign.width = 0
			sign.outline_size = 10
			sign.outline_modulate = Color.WHITE
			sign.pixel_size = 0.0024
			add.call(sign, main + Vector3(0.06, h * 0.84, 0.234))
			# The curved glass entrance with its white canopy.
			var hall := _cyl(0.16, 0.17, 0.26, Color.WHITE)
			hall.material_override = _glass(Color("#4f8f9a"))
			add.call(hall, Vector3(-0.28, 0.13, 0.13))
			for y in [0.09, 0.18]:  # glazing bars
				var bar := MeshInstance3D.new()
				var ring := TorusMesh.new()
				ring.inner_radius = 0.163
				ring.outer_radius = 0.173
				bar.mesh = ring
				bar.material_override = _material(Color("#d8e8ea"))
				add.call(bar, Vector3(-0.28, y, 0.13))
			var canopy := _cyl(0.17, 0.17, 0.018, Color("#e9eff0"))
			canopy.rotation.x = 0.12
			add.call(canopy, Vector3(-0.28, 0.27, 0.14))
			add.call(_box(Vector3(0.1, 0.12, 0.01), Color("#26323a")), Vector3(-0.28, 0.06, 0.3))  # doors
			# The long glass wing, a tall shop sign on its corner, a terrace in front.
			var wing_h := 0.3 + 0.04 * level
			var wing := _box(Vector3(0.36, wing_h, 0.5), Color.WHITE)
			wing.material_override = _glass(Color("#7fb6bc"))
			add.call(wing, Vector3(0.25, wing_h / 2, -0.08))
			for y in [wing_h * 0.4, wing_h * 0.75]:
				add.call(_box(Vector3(0.362, 0.01, 0.502), Color("#e8f0f0")), Vector3(0.25, y, -0.08))
			add.call(_box(Vector3(0.37, 0.05, 0.51), Color("#9aa4a8")), Vector3(0.25, wing_h + 0.025, -0.08))
			add.call(_box(Vector3(0.06, 0.28, 0.02), Color.WHITE), Vector3(0.1, wing_h * 0.5 + 0.04, 0.18))
			var shops := _label("S\nH\nO\nP\nS", 40, Color("#3a3446"))
			shops.rotation_degrees.x = 0
			shops.outline_size = 0
			shops.pixel_size = 0.0016
			shops.width = 0
			shops.autowrap_mode = TextServer.AUTOWRAP_OFF
			add.call(shops, Vector3(0.1, wing_h * 0.5 + 0.04, 0.191))
			add.call(_box(Vector3(0.34, 0.05, 0.08), Color("#3a3a42")), Vector3(0.25, 0.025, 0.21))
			add.call(_box(Vector3(0.16, 0.022, 0.005), colour), Vector3(0.25, 0.03, 0.251))
			var awning := _box(Vector3(0.36, 0.012, 0.13), Color.WHITE)
			awning.rotation.x = 0.28
			add.call(awning, Vector3(0.25, 0.13, 0.22))
			for x in [0.09, 0.41]:
				add.call(_box(Vector3(0.01, 0.12, 0.01), Color.WHITE), Vector3(x, 0.06, 0.27))
			# A lamp post with banners in the owner's colour.
			add.call(_cyl(0.008, 0.01, 0.46, Color("#5a5e66")), Vector3(-0.02, 0.23, 0.27))
			for x in [-0.045, 0.005]:
				add.call(_box(Vector3(0.04, 0.09, 0.004), colour), Vector3(x, 0.32, 0.27))
	return root


## An airliner `colour` on the tail, nose to +x, wheels on y = 0: fuselage
## with a window line and cockpit, swept wings with an engine under each, a
## tailplane and a fin.
static func _airliner(colour: Color) -> Node3D:
	var plane := Node3D.new()
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.055
	capsule.height = 0.62
	body.mesh = capsule
	body.material_override = _material(Color.WHITE)
	body.rotation_degrees.z = 90
	body.position.y = 0.11
	plane.add_child(body)
	var windows := _box(Vector3(0.42, 0.014, 0.112), Color("#2a3a4a"))
	windows.position = Vector3(0.0, 0.125, 0)
	plane.add_child(windows)
	var stripe := _box(Vector3(0.48, 0.012, 0.111), colour)
	stripe.position = Vector3(-0.01, 0.096, 0)
	plane.add_child(stripe)
	var cockpit := _box(Vector3(0.03, 0.02, 0.08), Color("#2a3a4a"))
	cockpit.position = Vector3(0.27, 0.13, 0)
	plane.add_child(cockpit)
	for side in [-1, 1]:
		var wing := _box(Vector3(0.11, 0.012, 0.27), Color("#e4e4ea"))
		wing.position = Vector3(-0.02, 0.09, side * 0.15)
		wing.rotation.y = side * 0.4  # swept back
		plane.add_child(wing)
		var engine := _cyl(0.026, 0.026, 0.1, Color("#9aa0a8"))
		engine.rotation.z = PI / 2
		engine.position = Vector3(0.03, 0.065, side * 0.13)
		plane.add_child(engine)
		var stab := _box(Vector3(0.06, 0.01, 0.11), Color("#e4e4ea"))
		stab.position = Vector3(-0.28, 0.13, side * 0.06)
		stab.rotation.y = side * 0.4
		plane.add_child(stab)
	var fin := _box(Vector3(0.1, 0.13, 0.012), colour)
	fin.position = Vector3(-0.27, 0.2, 0)
	fin.rotation.z = -0.35
	plane.add_child(fin)
	for at in [Vector3(0.2, 0.03, 0), Vector3(-0.04, 0.03, -0.05), Vector3(-0.04, 0.03, 0.05)]:
		var wheel := _cyl(0.012, 0.012, 0.06, Color("#26262a"))
		wheel.position = at
		plane.add_child(wheel)
	return plane


## Tinted glass: shiny and slightly see-through.
static func _glass(colour: Color) -> StandardMaterial3D:
	var m := _material(Color(colour, 0.85))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.4
	m.roughness = 0.12
	return m


static func _cyl(top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = _material(color)
	return mi


## What a 3D board stands on (Board.props): towers carry the spaces climbing
## their face, isles are sandy islands down to the sea, a bottle is a giant
## glass bottle the spaces wrap round; "island" draws nothing (the spaces
## float on their own).
## Steel rails under each moving platform's spaces, from one of its places
## to the next, so you can see where it can slide to.
func _build_rails() -> void:
	for pid in game.board.platforms:
		var p: Dictionary = game.board.platforms[pid]
		if p.look == "island":  # floats across the sea, no rails
			continue
		for id in p.spaces:
			var home: Vector2 = game.board.spaces[id].home
			for k in p.states.size() - 1:
				var a: Vector2 = home + p.states[k].shift
				var b: Vector2 = home + p.states[k + 1].shift
				var from := Vector3(a.x, 0, a.y) * SPACING
				var to := Vector3(b.x, 0, b.y) * SPACING
				if from.distance_to(to) < 0.01:
					continue
				var dir := (to - from).normalized()
				var side := dir.cross(Vector3.UP).normalized() * 0.32
				for s in [-1, 1]:
					var rail := _box(Vector3(0.06, 0.05, from.distance_to(to) + TILE), STEEL.darkened(0.3))
					rail.position = (from + to) / 2 + side * s + Vector3(0, -0.13, 0)
					rail.basis = Basis.looking_at(dir, Vector3.UP)
					_root.add_child(rail)


## A switch was pressed (`switch_id`) and platform `pid` has moved on (the
## board already holds its new place and links): the button sinks and pops
## back, the camera takes in the platform's old and new places, and the
## platform slides across over PLATFORM_SLIDE seconds, anyone on it riding
## along; its paths are drawn again once it is in place.
func move_platform(switch_id: int, pid: String) -> void:
	var p: Dictionary = game.board.platforms[pid]
	var ids: Array[int] = []
	ids.assign(p.spaces)
	var t: Dictionary = _tiles[switch_id]
	if t.has("button"):
		var button: Node3D = t.button
		var rest := button.position
		var press := create_tween()
		press.tween_property(button, "position", rest - Vector3(0, 0.07, 0), 0.08)
		press.tween_property(button, "position", rest, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Look at where it was and where it goes, with the spaces it joins.
	var seen: Array[int] = ids.duplicate()
	for st in p.states:
		for l in st.links:
			for id in l:
				if id not in seen:
					seen.append(id)
	focus_on(seen, PLATFORM_SLIDE + 0.9, 5.0)
	_draw_links(ids)
	var slide := create_tween().set_parallel(true)
	slide.tween_interval(0.35)  # the button goes down first
	for id in ids:
		var holder: Node3D = _tiles[id].holder
		slide.tween_property(holder, "position", _pos(id), PLATFORM_SLIDE).set_delay(0.35) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for q in game.players:
		if q.broke or _preview.get(q.index, q.position) not in ids:
			continue
		slide.tween_property(_tokens[q.index], "position", _token_spot(q.index), PLATFORM_SLIDE) \
				.set_delay(0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	slide.chain().tween_callback(func():
		_draw_links()
		sync())


func _build_props() -> void:
	var stone := _material(Color("#a8a49c"))
	for p in game.board.props:
		var at := Vector3(p.at[0], p.at[1], p.at[2]) * SPACING
		match p.get("kind", ""):
			"isle":  # a sandy island under the spaces, down to the sea, palms on it
				_build_isle(at, Vector2(p.size[0], p.size[1]) * SPACING)
			"turtle":  # a giant sea turtle, the spaces on its shell
				var h: Array = p.get("heading", [0, 0, 1])
				_build_turtle(at, float(p.radius) * SPACING, Vector3(h[0], h[1], h[2]).normalized())
			"cloud":  # a big fluffy cloud, the spaces on top
				_build_cloud(at, float(p.radius) * SPACING)
			"sky_tower":  # a very tall stone tower, the spaces on its carved top
				_build_sky_tower(at, float(p.radius) * SPACING)
			"bottle":  # a giant glass bottle the spaces wrap round
				_build_bottle(at, float(p.radius) * SPACING, float(p.height) * SPACING)
			"tower":
				var size := Vector3(p.size[0], p.size[1], p.size[2]) * SPACING
				var tower := _box(size, Color.WHITE)
				tower.material_override = stone
				tower.position = at + Vector3(0, size.y / 2 - 0.3, 0)
				_root.add_child(tower)
				for k in int(size.y / 0.6):  # courses of stone across it
					var course := _box(Vector3(size.x + 0.02, 0.03, size.z + 0.02), Color("#86827a"))
					course.position = at + Vector3(0, k * 0.6, 0)
					_root.add_child(course)


## A sandy island `size` across with its top at `at`, sloping down into the
## sea below (the Pirate Sea lies under the board), with palm trees round its
## edge.
func _build_isle(at: Vector3, size: Vector2) -> void:
	var sand := _material(Color("#d8c08a").lerp(FADE_TO, PROP_FADE))
	var wet := _material(Color("#a8905a").lerp(FADE_TO, PROP_FADE))
	var depth := at.y + 6.0  # down past the waterline
	var top := _cyl(0.5, 0.5, 0.2, Color.WHITE)
	top.material_override = sand
	top.scale = Vector3(size.x * 1.08, 1, size.y * 1.08)
	top.position = at - Vector3(0, 0.12, 0)
	_root.add_child(top)
	var slope := _cyl(0.54, 0.75, depth, Color.WHITE)
	slope.material_override = wet
	slope.scale = Vector3(size.x, 1, size.y)
	slope.position = at - Vector3(0, 0.22 + depth / 2, 0)
	_root.add_child(slope)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 31 + at.z * 17)
	for k in 3:  # palms on the edge, leaning out
		var a := TAU * (k + rng.randf() * 0.5) / 3.0
		var foot := at + Vector3(cos(a) * size.x * 0.52, -0.1, sin(a) * size.y * 0.52)
		var palm := Node3D.new()
		palm.position = foot
		palm.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
		_root.add_child(palm)
		var trunk := _cyl(0.05, 0.08, 1.4, Color("#8a6a3a").lerp(FADE_TO, PROP_FADE))
		trunk.position.y = 0.7
		palm.add_child(trunk)
		for f in 6:
			var frond := _box(Vector3(0.9, 0.02, 0.18), Color("#3a8a3a").lerp(FADE_TO, PROP_FADE))
			frond.position = Vector3(cos(TAU * f / 6.0) * 0.4, 1.38, sin(TAU * f / 6.0) * 0.4)
			frond.rotation = Vector3(0, -TAU * f / 6.0, -0.35)
			palm.add_child(frond)


## A big fluffy white cloud `radius` across under spaces at `at` (their
## height): a flattened pad of cloud just under the tiles, wide enough to
## carry them, with round puffs bulging out of its edge and underneath,
## breathing gently in and out.
func _build_cloud(at: Vector3, radius: float) -> void:
	var white := _material(Color("#f6f8fc"))
	var shade := _material(Color("#d6dee8"))  # the cloud's shadowed underside
	var cloud := Node3D.new()
	cloud.position = at
	_root.add_child(cloud)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 31 + at.z * 17)
	var pad := _ball(1.0, Color.WHITE)
	pad.material_override = white
	pad.scale = Vector3(radius * 1.05, 0.35, radius * 1.05)
	pad.position.y = -0.4  # its top just under the tiles
	cloud.add_child(pad)
	var puffs: Array[Node3D] = []
	for k in 14:  # round the edge, bulging out and up
		var a := TAU * (k + rng.randf() * 0.4) / 14.0
		var r := rng.randf_range(0.55, 0.85)
		var puff := _ball(r, Color.WHITE)
		puff.material_override = white
		puff.position = Vector3(sin(a) * radius * 0.98, rng.randf_range(-0.55, -0.3), cos(a) * radius * 0.98)
		cloud.add_child(puff)
		puffs.append(puff)
	for k in 7:  # underneath, in the shade
		var a := TAU * k / 7.0
		var r := rng.randf_range(0.8, 1.2)
		var puff := _ball(r, Color.WHITE)
		puff.material_override = shade
		puff.scale = Vector3(1, 0.7, 1)
		puff.position = Vector3(sin(a) * radius * 0.5, -0.9, cos(a) * radius * 0.5)
		cloud.add_child(puff)
		puffs.append(puff)
	var phase := rng.randf() * TAU
	var breathe := create_tween().set_loops()
	breathe.tween_method(func(u: float):
		for i in puffs.size():
			puffs[i].scale.x = 1.0 + 0.06 * sin(u + i + phase)
			puffs[i].scale.z = puffs[i].scale.x, 0.0, TAU, 6.0)
	breathe.bind_node(cloud)


## A very tall round stone tower rising from far below, `radius` across at the
## top, its top just under spaces at `at` (their height): a carved stone disc
## with a toothed rim, engraved rings and a star in the middle, the outer band
## the spaces stand on a darker stone, on a long column of stone courses with
## dark windows going down out of sight.
func _build_sky_tower(at: Vector3, radius: float) -> void:
	var light := Color("#c9b48a")
	var mid := Color("#a8925f")
	var dark := Color("#7a6644")
	var band := Color("#a08a5c")  # the outer circle the spaces stand on
	var tower := Node3D.new()
	tower.position = at
	_root.add_child(tower)
	var top := _cyl(radius, radius * 0.97, 0.4, band)
	top.position.y = -0.23  # its face just under the tiles
	tower.add_child(top)
	var inner := _cyl(radius * 0.6, radius * 0.6, 0.4, light)  # the lighter middle, inside the spaces
	inner.position.y = -0.225
	tower.add_child(inner)
	var teeth := 30
	for k in teeth:  # the toothed rim, every other tooth standing a little proud
		var a := TAU * k / teeth
		var tooth := _box(Vector3(TAU * radius / teeth * 0.62, 0.5 if k % 2 == 0 else 0.42, 0.45), mid if k % 2 == 0 else light)
		tooth.position = Vector3(sin(a) * radius, -0.24, cos(a) * radius)
		tooth.rotation.y = a
		tower.add_child(tooth)
	for ring in [0.3, 0.55, 0.88]:  # rings engraved in the face
		var groove := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius * ring - 0.06
		torus.outer_radius = radius * ring + 0.06
		groove.mesh = torus
		groove.material_override = _material(dark)
		groove.scale = Vector3(1, 0.08, 1)
		groove.position.y = -0.02
		tower.add_child(groove)
	var star := Label3D.new()  # a star carved in the middle
	star.text = "★"
	star.font_size = 520
	star.pixel_size = 0.005
	star.modulate = dark
	star.outline_size = 0
	star.rotation_degrees.x = -90
	star.position.y = -0.01
	tower.add_child(star)
	# The column: courses of stone tapering gently down out of sight, past the
	# clouds below, with dark windows here and there.
	var depth := 24.0
	var wide := radius * 0.72
	var narrow := radius * 0.6
	var column := _cyl(wide, narrow, depth, mid)
	column.position.y = -0.43 - depth / 2
	tower.add_child(column)
	for k in int(depth):
		var y := -0.9 - k * 1.0
		var w := lerpf(wide, narrow, (-0.43 - y) / depth)
		var course := _cyl(w + 0.04, w + 0.04, 0.12, dark if k % 2 == 0 else light)
		course.position.y = y
		tower.add_child(course)
		if k % 3 == 1:  # a few windows round this level
			for j in 4:
				var a := TAU * (j + (k % 2) * 0.5) / 4.0 + k * 0.4
				var window := _box(Vector3(0.28, 0.5, 0.08), Color("#2a2420"))
				window.position = Vector3(sin(a) * (w + 0.03), y - 0.5, cos(a) * (w + 0.03))
				window.rotation.y = a
				tower.add_child(window)


## A giant sea turtle swimming in the sea, its shell's flat top carrying the
## spaces at `at` (the spaces' height), `radius` across, swimming towards
## `heading` with its head under the water: a domed brown shell rising out of
## the water, patterned in plates (_shell_material), a flat plate on top for
## the spaces, four flippers paddling slowly at the surface and a little tail.
func _build_turtle(at: Vector3, radius: float, heading: Vector3) -> void:
	var water := -Scenery.SEA_DROP  # where the sea's surface is
	var shell := _shell_material(false)  # brown plates with grooves and rings
	var plate := _shell_material(true, radius * 0.95)  # the flat top: rings round its middle
	var rim := _material(Color("#4a2e18").lerp(FADE_TO, PROP_FADE))
	var skin := _material(Color("#86a05a").lerp(FADE_TO, PROP_FADE))
	var turtle := Node3D.new()
	turtle.position = Vector3(at.x, 0, at.z)
	turtle.basis = Basis.looking_at(-heading, Vector3.UP)  # its +z is the way it faces
	_root.add_child(turtle)
	var top := at.y - 0.12  # the shell's top, just under the spaces
	var rise := top - water + 0.4
	var dome := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 1.0  # a hemisphere's own height
	ball.is_hemisphere = true
	ball.radial_segments = 32
	ball.rings = 12
	dome.mesh = ball
	dome.material_override = shell
	dome.scale = Vector3(radius * 1.15, rise, radius * 1.3)
	dome.position.y = water - 0.4
	turtle.add_child(dome)
	var cap := _cyl(radius * 0.86, radius * 0.95, 0.18, Color.WHITE)  # the flat top the spaces stand on
	cap.material_override = plate
	cap.scale = Vector3(1, 1, 1.12)
	cap.position.y = top - 0.09
	turtle.add_child(cap)
	var band := MeshInstance3D.new()  # its rim
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.86
	torus.outer_radius = radius * 0.98
	band.mesh = torus
	band.material_override = rim
	band.scale = Vector3(1, 0.5, 1.12)
	band.position.y = top - 0.1
	turtle.add_child(band)
	# Four flippers paddling, the tail behind.
	for front in [true, false]:
		for side in [-1, 1]:
			var hinge := Node3D.new()
			hinge.position = Vector3(side * radius * 0.95, water + 0.05, radius * (0.75 if front else -0.8))
			var rest: float = side * (0.6 if front else 2.4)
			hinge.rotation.y = rest
			turtle.add_child(hinge)
			var flipper := _ball(1.0, Color.WHITE)
			flipper.material_override = skin
			var length := radius * (0.85 if front else 0.5)
			flipper.scale = Vector3(length, 0.07, radius * 0.25)
			flipper.position.x = side * length * 0.8
			hinge.add_child(flipper)
			_paddles.append([hinge, randf() * TAU, front, rest])
	var tail := _cyl(0.0, radius * 0.12, radius * 0.4, Color.WHITE)
	tail.material_override = skin
	tail.rotation.x = -PI / 2
	tail.position = Vector3(0, water + 0.1, -radius * 1.4)
	turtle.add_child(tail)
	for n in turtle.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A ball `r` across in `color`.
static func _ball(r: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2
	mi.mesh = mesh
	mi.material_override = _material(color)
	return mi


## A turtle shell's surface. The dome (`top` false): rows of plates round it
## with dark grooves between, fine growth rings in each plate, lighter plate
## middles, darker towards the waterline, a soft sheen on top. The flat top
## (`top` true): rings round its middle and a darker edge.
static func _shell_material(top: bool, span := 1.0) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
uniform bool top = false;
uniform float span = 1.0;  // the flat top's radius
uniform vec3 fade_to : source_color = vec3(0.66, 0.77, 0.8);
uniform float fade = 0.0;
uniform vec3 dark : source_color = vec3(0.24, 0.14, 0.07);
uniform vec3 mid : source_color = vec3(0.42, 0.27, 0.14);
uniform vec3 light : source_color = vec3(0.62, 0.44, 0.24);
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
	vec3 c;
	if (top) {
		float r = length(local.xz) / span;
		float rings = 0.5 + 0.5 * sin(r * 22.0);
		c = mix(mid, light, 0.35 + 0.25 * rings);
		c = mix(c, dark, smoothstep(0.8, 1.0, r));
	} else {
		// Rows of plates up the dome, each row offset, by angle and height.
		float h = clamp(local.y, 0.0, 1.0);
		float row = floor(h * 3.0);
		float count = 9.0 - row * 2.0;
		float u = (atan(local.x, local.z) / 6.28318 + 0.5) * count + row * 0.5;
		vec2 cell = vec2(fract(u), fract(h * 3.0)) - 0.5;
		float edge = max(abs(cell.x) * 1.15, abs(cell.y));
		float groove = smoothstep(0.42, 0.5, edge);
		float rings = 0.5 + 0.5 * sin(edge * 40.0);
		c = mix(light, mid, smoothstep(0.0, 0.4, edge));
		c = mix(c, c * 0.82, rings * 0.5);
		c = mix(c, dark, groove);
		c *= mix(0.55, 1.0, smoothstep(0.0, 0.7, h));  // darker towards the water
	}
	c = mix(c, fade_to, fade);  // faded a little, so the spaces stand out
	ALBEDO = c;
	ROUGHNESS = 0.45;
	SPECULAR = 0.4;
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("top", top)
	m.set_shader_parameter("span", span)
	m.set_shader_parameter("fade", PROP_FADE)
	return m


## A giant glass bottle standing on `at`, `radius` round and `height` up to its
## shoulder: a tinted glass body, the shoulder narrowing to a neck, a lip and
## a thicker glass base; nothing else (the board turns shadows off).
func _build_bottle(at: Vector3, radius: float, height: float) -> void:
	var glass := _material(Color(0.55, 0.85, 0.75, 0.28))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.2
	glass.rim_enabled = true
	glass.rim = 0.6
	var parts := [  # [top radius, bottom radius, height, centre height]
		[radius, radius, height, height / 2],
		[radius * 0.35, radius, radius * 0.9, height + radius * 0.45],
		[radius * 0.35, radius * 0.35, radius * 1.6, height + radius * 1.7],
	]
	for p in parts:
		var piece := _cyl(p[0], p[1], p[2], Color.WHITE)
		(piece.mesh as CylinderMesh).radial_segments = 48
		piece.material_override = glass
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.position = at + Vector3(0, p[3], 0)
		_root.add_child(piece)
	var lip := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.33
	torus.outer_radius = radius * 0.42
	lip.mesh = torus
	lip.material_override = glass
	lip.position = at + Vector3(0, height + radius * 2.5, 0)
	_root.add_child(lip)
	var base := _cyl(radius * 1.02, radius * 1.02, 0.25, Color.WHITE)
	var base_glass := glass.duplicate() as StandardMaterial3D
	base_glass.albedo_color = Color(0.4, 0.7, 0.6, 0.6)
	base.material_override = base_glass
	base.position = at + Vector3(0, 0.12, 0)
	_root.add_child(base)
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A suit symbol modelled from primitives, standing upright (it sways in _process).
static func _suit(mark: String, color: Color) -> Node3D:
	var root := Node3D.new()
	var shape := Node3D.new()
	shape.scale = Vector3(1, 1, 0.35)  # flatten into a thick badge
	root.add_child(shape)
	var m := _material(color, 0.5)
	match mark:
		"Diamond":
			var d := _shape_part(BoxMesh.new(), m, Vector3.ZERO, 0.16)
			d.rotation_degrees.z = 45
			shape.add_child(d)
			shape.scale.y = 1.35
		"Heart", "Spade":
			var lobes := Node3D.new()
			lobes.add_child(_shape_part(SphereMesh.new(), m, Vector3(-0.055, 0.035, 0), 0.13))
			lobes.add_child(_shape_part(SphereMesh.new(), m, Vector3(0.055, 0.035, 0), 0.13))
			var point := _shape_part(BoxMesh.new(), m, Vector3(0, -0.035, 0), 0.13)
			point.rotation_degrees.z = 45
			lobes.add_child(point)
			if mark == "Spade":
				lobes.rotation_degrees.z = 180
				lobes.position.y = 0.03
				shape.add_child(_stem(m))
			shape.add_child(lobes)
		"Club":
			shape.add_child(_shape_part(SphereMesh.new(), m, Vector3(0, 0.07, 0), 0.12))
			shape.add_child(_shape_part(SphereMesh.new(), m, Vector3(-0.065, -0.02, 0), 0.12))
			shape.add_child(_shape_part(SphereMesh.new(), m, Vector3(0.065, -0.02, 0), 0.12))
			shape.add_child(_stem(m))
		_:
			shape.add_child(_shape_part(SphereMesh.new(), m, Vector3.ZERO, 0.16))
	return root


static func _stem(m: Material) -> MeshInstance3D:
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.04
	cyl.height = 0.12
	stem.mesh = cyl
	stem.material_override = m
	stem.position.y = -0.09
	return stem


## A primitive of `size` (diameter, or edge for boxes) at `at`.
static func _shape_part(mesh: PrimitiveMesh, m: Material, at: Vector3, size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = at
	mi.scale = Vector3.ONE * size
	if mesh is SphereMesh:
		mesh.radius = 0.5
		mesh.height = 1.0
	return mi


## The paths between spaces (in _links), drawn again whenever a platform
## moves: those touching its spaces (`skip`) are left out while it slides.
func _draw_links(skip: Array = []) -> void:
	for c in _links.get_children():
		c.queue_free()
	for s in game.board.spaces:
		for n in s.next:
			if s.type == "warp" and game.board.spaces[n].type == "warp":
				continue  # warps jump, no path
			if s.id in skip or n in skip:
				continue
			_add_link(_pos(s.id) + _up(s.id) * 0.02, _pos(n) + _up(n) * 0.02)


func _add_link(a: Vector3, b: Vector3) -> void:
	var link := _box(Vector3(0.12, 0.04, a.distance_to(b)), Color("#55556a"))
	link.position = (a + b) / 2 + Vector3(0, 0.02, 0)
	var hint := Vector3.BACK if absf((b - a).normalized().y) > 0.9 else Vector3.UP  # a link straight up a wall
	link.basis = Basis.looking_at((b - a).normalized(), hint)
	_links.add_child(link)
	# A small cone halfway along shows the direction of travel.
	var cone := MeshInstance3D.new()
	var prism := CylinderMesh.new()
	prism.top_radius = 0.0
	prism.bottom_radius = 0.1
	prism.height = 0.2
	cone.mesh = prism
	cone.material_override = _material(Color("#8888a0"))
	cone.position = (a + b) / 2 + Vector3(0, 0.08, 0)
	cone.basis = Basis.looking_at((b - a).normalized(), hint) * Basis(Vector3.RIGHT, -PI / 2)
	_links.add_child(cone)


func _popup(pos: Vector3, text: String, color: Color) -> void:
	_popups = _popups.filter(func(p): return is_instance_valid(p))
	var stacked := 0
	for p in _popups:
		if Vector2(p.position.x, p.position.z).distance_to(Vector2(pos.x, pos.z)) < 0.5:
			stacked += 1
	var label := _label(text, 64, color, true)
	label.position = pos + Vector3(0, stacked * 0.3, 0)
	label.no_depth_test = true
	_root.add_child(label)
	_popups.append(label)
	var tw := create_tween().set_parallel()
	tw.tween_property(label, "position:y", label.position.y + 0.8, 1.6)
	tw.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.6)
	tw.chain().tween_callback(label.queue_free)


## Works out the whole-board view; _process() moves the camera between it and
## the close follow view of the current player.
func _frame_camera() -> void:
	if game == null or _camera == null:
		return
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for s in game.board.spaces:
		for at in _places(s.id):
			lo = lo.min(at)
			hi = hi.max(at)
	var center := (lo + hi) / 2
	var view := get_viewport().get_visible_rect().size
	var aspect := view.x / maxf(view.y, 1.0)
	var need := maxf(hi.z - lo.z + (hi.y - lo.y) * 0.85, (hi.x - lo.x) / aspect) \
			+ (_scenery.frame_margin if _scenery else 2.6)  # height shows as depth; the theme says how much room round it
	# Islands and turtles: centred and fitted on what the camera sees of them,
	# from the tops down to the sea (a turtle's shell bulges well below its
	# spaces), measured across and up the view.
	var seen: Array[Vector3] = []
	for p in game.board.props:
		var r := 0.0
		var at := Vector3(p.at[0], p.at[1], p.at[2]) * SPACING
		var bottom := -Scenery.SEA_DROP  # down to the sea
		match String(p.get("kind", "")):
			"turtle":
				r = float(p.radius) * 1.15
			"isle":
				r = float(p.size[0]) * 0.5
			"cloud":  # its puffs, a little below its spaces
				r = float(p.radius) * 1.2
				bottom = at.y - 1.2
			"sky_tower":  # its top and title, and the tower a little way down
				r = float(p.radius) * 1.1
				bottom = at.y - 2.5
		if r == 0.0:
			continue
		for k in 16:
			var out := Vector3(sin(TAU * k / 16.0), 0, cos(TAU * k / 16.0)) * r * SPACING
			seen.append(at + out)
			seen.append(Vector3(at.x, bottom, at.z) + out)
	if not seen.is_empty():
		for s in game.board.spaces:
			seen.append(_pos(s.id))
		# Through the camera's perspective (the near turtle looms larger and
		# lower), a few rounds of moving the aim to the middle of what is seen
		# and the camera in or out until it just fits.
		var ahead := -_cam_dir()
		var across := ahead.cross(Vector3.UP).normalized()
		var upward := across.cross(ahead).normalized()
		var half_v := tan(deg_to_rad(_camera.fov * 0.5))
		var far := need * 0.5 / half_v
		for round in 12:
			var eye := center - ahead * far
			var x_lo := INF
			var x_hi := -INF
			var y_lo := INF
			var y_hi := -INF
			for q in seen:
				var rel: Vector3 = q - eye
				var z := maxf(rel.dot(ahead), 0.1)
				x_lo = minf(x_lo, rel.dot(across) / z)
				x_hi = maxf(x_hi, rel.dot(across) / z)
				y_lo = minf(y_lo, rel.dot(upward) / z)
				y_hi = maxf(y_hi, rel.dot(upward) / z)
			center += (across * (x_lo + x_hi) + upward * (y_lo + y_hi)) * 0.5 * far
			far *= maxf((y_hi - y_lo) * 0.5, (x_hi - x_lo) * 0.5 / aspect) / (half_v * 0.94)
		need = far * 2.0 * half_v
	var dist := need * 0.5 / tan(deg_to_rad(_camera.fov * 0.5))
	if _scenery:  # the theme can look further back past the middle
		center.z -= _scenery.frame_back
	_overview_look = center
	_overview_pos = center + _cam_dir() * dist


# --- helpers ------------------------------------------------------------

## Which way the camera looks from (towards it from what it looks at): the
## board's own `camera` if it has one (a tall 3D board is seen more from the
## side), else CAMERA_DIR.
func _cam_dir() -> Vector3:
	if game != null and game.board != null and game.board.camera.size() == 3:
		return Vector3(game.board.camera[0], game.board.camera[1], game.board.camera[2]).normalized()
	return CAMERA_DIR.normalized()


func _pos(id: int) -> Vector3:
	var s := game.board.spaces[id]
	var at: Array = s.get("at", [])
	if at.size() == 3:
		return Vector3(at[0], at[1], at[2]) * SPACING
	return Vector3(s.x * SPACING, 0, s.y * SPACING)



## Every place space `id` can be in the world (Board.places): a moving
## platform's space in each of its states.
func _places(id: int) -> Array[Vector3]:
	if game.board.spaces[id].get("at", []).size() == 3:
		return [_pos(id)]
	var out: Array[Vector3] = []
	for p in game.board.places(id):
		out.append(Vector3(p.x * SPACING, 0, p.y * SPACING))
	return out

## How space `id` is turned: level, or stood on its edge facing the camera.
func _basis(id: int) -> Basis:
	var face = game.board.spaces[id].get("face", "up")
	if face is Array and face.size() == 3:
		# Its top points along `face`; its front edge (the sign side) points down
		# when it stands on a wall, as a "front" space does.
		var up := Vector3(face[0], face[1], face[2]).normalized()
		var down := Vector3.DOWN - up * Vector3.DOWN.dot(up)
		var z := down.normalized() if down.length() > 0.01 else Vector3.BACK
		return Basis(up.cross(z), up, z)
	return Basis(Vector3.RIGHT, PI / 2) if str(face) == "front" else Basis.IDENTITY


## Which way is up on space `id`.
func _up(id: int) -> Vector3:
	return _basis(id).y


## Where a token stands on its space; up to four share a tile, one per corner.
func _token_spot(index: int) -> Vector3:
	var p := game.players[index]
	var off := Vector3(-0.3 if index % 2 == 0 else 0.3, TILE_H, -0.3 if index < 2 else 0.3)
	var id: int = _preview.get(index, p.position)
	return _pos(id) + _basis(id) * off


## Switches the backdrop to `name` (one of Scenery.THEMES, or "auto" for the
## board's own) and rebuilds it now if a board is up.
func set_theme(name: String) -> void:
	theme = name
	if game != null and _root != null:
		_build_scenery()
		_frame_camera()  # the theme decides how close the whole-board view comes


## The backdrop round and below the floating board (Scenery): its scenery,
## sky, light and fog.
func _build_scenery() -> void:
	if _scenery:
		_scenery.queue_free()
	var name := game.board.theme if theme == "auto" else theme
	# Islands and turtles stand in the sea, and island platforms keep the sea calm
	# with the ship off behind the board: keep it close under the board.
	var shallow: bool = game.board.props.any(func(p): return p.get("kind", "") in ["isle", "turtle"]) \
			or game.board.platforms.values().any(func(p): return p.look == "island")
	_scenery = Scenery.make(name, _lo, _hi, shallow)
	_scenery.thunder.connect(thunder.emit)
	_root.add_child(_scenery)
	_env.background_color = _scenery.sky
	_env.ambient_light_color = _scenery.ambient
	_env.ambient_light_energy = _scenery.ambient_energy
	_sun.light_color = _scenery.sun_color
	_sun.light_energy = _scenery.sun_energy
	_day = {"sun": _scenery.sun_energy, "sun_color": _scenery.sun_color, "ambient": _scenery.ambient_energy,
			"ambient_color": _scenery.ambient, "sky": _scenery.sky}
	# A board round a glass bottle shows only the glass: no shadows at all.
	_sun.shadow_enabled = not game.board.props.any(func(p): return p.get("kind", "") == "bottle")
	_env.fog_enabled = _scenery.fog > 0.0
	_env.fog_light_color = _scenery.sky
	_env.fog_density = _scenery.fog


static func _material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _material(color)
	return mi


## Flat labels lie on the tile reading towards the camera; billboards face it.
static func _label(text: String, font_size: int, color: Color, billboard := false) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.005
	l.modulate = color
	l.outline_size = 8
	l.outline_modulate = Color.BLACK
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	else:
		l.width = 190
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.rotation_degrees.x = -90
	return l


## Where space `id` is on screen now (its top's middle), in the board view's
## pixels. A space behind the camera comes back far off-screen.
func screen_pos(id: int) -> Vector2:
	var at := _pos(id) + _up(id) * TILE_H
	if _camera.is_position_behind(at):
		return Vector2(INF, INF)
	return _camera.unproject_position(at)


## A left click on the board: finds the space under the pointer (where the
## ray meets the tiles' tops) and reports it as space_clicked. With the free
## camera on (View Map), dragging with the left button turns round the board,
## the right or middle button slides it, and the wheel zooms; a drag is not a
## click.
func _unhandled_input(event: InputEvent) -> void:
	if game == null:
		return
	if free_cam and event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var k := 0.88 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 0.88
			_free_dist = clampf(_free_dist * k, 2.5, _max_free_dist())
			return
		if event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = event.button_index
			_dragged = false
			_drag_from = event.position
			if event.button_index != MOUSE_BUTTON_LEFT:
				return
		elif not event.pressed and event.button_index == _dragging:
			_dragging = -1
			if _dragged:
				return
	if free_cam and event is InputEventMouseMotion and _dragging >= 0:
		if not _dragged and event.position.distance_to(_drag_from) < 6.0:
			return
		_dragged = true
		var rel: Vector2 = event.relative
		if _dragging == MOUSE_BUTTON_LEFT:
			_free_yaw -= rel.x * 0.008
			_free_pitch += rel.y * 0.006
		else:
			_pan_free_cam(-rel * _free_dist * 0.0018)
		return
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if free_cam:
		if event.pressed:
			return  # a click is taken on release, once it is clearly not a drag
	elif not event.pressed:
		return
	var from := _camera.project_ray_origin(event.position)
	var dir := _camera.project_ray_normal(event.position)
	var best := -1
	var best_far := INF  # the nearest tile the ray meets
	for s in game.board.spaces:
		var up := _up(s.id)
		var top := _pos(s.id) + up * TILE_H
		var facing := dir.dot(up)
		if absf(facing) < 0.0001:
			continue
		var far := (top - from).dot(up) / facing
		var hit := from + dir * far
		var local := _basis(s.id).inverse() * (hit - top)
		if far > 0.0 and far < best_far and absf(local.x) < TILE * 0.55 and absf(local.z) < TILE * 0.55:
			best = s.id
			best_far = far
	if best >= 0:
		space_clicked.emit(best)
