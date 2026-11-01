class_name Scenery
extends Node3D
## The backdrop round and below the board, in one of a few themes, gently
## animated (slow drifting, bobbing, rolling waves, flickering, the odd distant
## cannon shot or meteor; nothing to pull the eye from the board). make()
## builds a theme for a board spanning `lo`..`hi`; the theme also says what
## the sky, the light and the fog look like, which BoardView applies.
##
## The board floats high above the scenery (DROP below it), so the theme's
## world shows between and round the tiles; there is no slab under the board.
## The camera looks down, so each theme is built close round the board, where
## it is always in view, and nothing in front of the board rises high enough
## to cover tiles. Surfaces carry soft natural textures in muted colours, and
## nothing in the scenery takes or casts shadows (the board's shadow does not
## fall on it).
##
##   lagoon   the Pirate Sea with the water still and, instead of the
##            seagulls and the buoy, a fish leaping out of it now and then
##            (Drifting Isles)
##   sea      a rough sea of big rolling waves under an overcast sky, further
##            down than the other themes; one huge pirate ship sailing
##            diagonally across under the board, firing broadsides either
##            side (flash, smoke, a ball arcing over, a splash); seagulls
##            wheeling overhead; rocks, barrels
##   space    stars all round, planets circling slowly below the board, each
##            on its own level so they never meet (a gas giant, a red rocky
##            one, an ice world, a blue-green one, a small moon), meteors
##            streaking past now and then
##   volcano  a sea of lava filling the whole view, glowing into a red haze at
##            the horizon; stone pillars and rocky outcrops standing in it,
##            broken platforms drifting, lava bubbles swelling and popping,
##            embers rising
##   castle   a historic fortress: massive curtain walls with battlements,
##            square towers, a gatehouse with a portcullis, the keep behind,
##            a moat behind and at the sides (the courtyard runs on past the
##            bottom of the screen), banners, soldiers patrolling the walls, cannons;
##            catapults flinging, barrels, crates and hay in the courtyard;
##            a great army filling the ground outside the back gate (ranks of
##            soldiers in companies, knights on horseback, standard bearers,
##            siege cannons, tents), seen over a low back wall
##   racing   a crazy slot-car Grand Prix: five tracks running right across
##            the scene and off the screen at both ends, at three heights so
##            they cross over one another (a main straight under the board
##            with a start gantry, an S-bend in front, two flyovers front to
##            back, a high flyover sweeping across in big S-curves);
##            Formula One cars in team colours, each in its slot at its own
##            speed, riding the climbs smoothly
##   storm    dark storm clouds drifting slowly below the board; the weather
##            turns from rain to hail to snow; lightning flickers inside the
##            clouds, followed by thunder
##   market   a crowded night-market food alley below the board (Spiral
##            Market), at an angle across the view under a dark sky: glowing
##            food counters both sides, steam, neon signs on the shopfronts
##            and over the alley, a crowd; the board stays in soft moonlight
##   sky      high above the clouds on a bright day (Cloud Hop): white
##            clouds drifting slowly far below over a sunlit cloud floor,
##            small grassy rocks floating in the distance, bobbing, hot-air
##            balloons drifting past, birds wheeling under the board

const B := preload("res://scripts/ui/board_view.gd")  # its model builders
const THEMES := ["sea", "lagoon", "space", "volcano", "castle", "racing", "storm", "market", "sky"]
const NAMES := {"sea": "Pirate Sea", "lagoon": "Calm Sea", "space": "Space", "volcano": "Lava Dungeon",
		"castle": "Grand Castle", "racing": "Slot-Car Grand Prix", "storm": "Storm Clouds", "market": "Night Market",
		"sky": "Above the Clouds"}
const TEXTURE_SIZE := 256
const DROP := 3.0  # how far below the board the scenery lies (most themes)
const SEA_DROP := 4.2  # Pirate Sea: how far below the board the water lies (things stand in it)
const SHIP_DROP := 10.0  # Pirate Sea with nothing standing in it: deeper, room for the big ship
const WEATHER_SPELL := 25.0  # Storm Clouds: seconds of rain, then hail, then snow
const THUNDER_DELAY := 0.7  # seconds from a flash to its thunderclap
const BACK_WALL := 1.8  # Grand Castle: the back wall's height
const ARMY_DEPTH := 7.0  # how far back from the moat the army fills
const TRACK_POINTS := 160  # points along each slot-car track
const RACING_HAZE := 0.38  # how much the haze over the F1 tracks lightens them
const MARKET_DROP := 9.0  # Night Market: how far below the board the alley lies
const MARKET_SCALE := 2.2  # the alley's size: everything in it, built at a person's scale, made this much bigger
const MARKET_HAZE := 0.25  # how much the dark haze over the market dims it
const MARKET_PUDDLES := 9
const MARKET_LITTER := 60
const MARKET_ANGLE := -0.6  # radians the alley is turned across the view
const MARKET_ALLEY := 1.8  # the alley's width between its two rows of stalls
const MARKET_STEAM := 0.3  # the share of stalls cooking, steam rising
const MARKET_CROWD := 25
const MARKET_HANGING_SIGNS := 5
const MARKET_STRING_GAP := 2.2  # from one string of lights across the alley to the next (before the scale)
const MARKET_STRING_SAG := 0.45  # how far a string dips in the middle: a slight C
const MARKET_COVERS := 3  # roof covers over stretches of the alley
const MARKET_COVER_COLOURS := [Color("#2a5a9a"), Color("#3a6a4a"), Color("#7a3a32")]
const MARKET_NEON := [Color("#ff3a8a"), Color("#3ae8ff"), Color("#ffe03a"), Color("#8aff5a")]
const MARKET_FOOD := [Color("#e8402a"), Color("#f2a020"), Color("#7ac83a"), Color("#f2d040"), Color("#c86a3a"), Color("#f2e0c0")]
const WAVES := [[0.7, 0.3, 0.0, 1.1], [0.45, 0.0, 0.42, -0.9], [0.12, 0.8, 0.8, 1.8]]  # [height, kx, kz, speed]
const SEA_SHADER := """
shader_type spatial;
render_mode shadows_disabled, cull_disabled;
uniform float wave_time = 0.0;
uniform float wave_scale = 1.0;  // 0: a still, flat sea (Calm Sea)
uniform vec4 deep : source_color = vec4(0.01, 0.12, 0.2, 1.0);
uniform vec4 crest : source_color = vec4(0.03, 0.32, 0.4, 1.0);
uniform vec4 foam : source_color = vec4(0.82, 0.88, 0.9, 1.0);
varying float height;
float wave(vec2 p, float a, float kx, float kz, float speed) {
	return a * sin(p.x * kx + p.y * kz + wave_time * speed);
}
float dwave(vec2 p, float a, float kx, float kz, float speed, float k) {
	return a * k * cos(p.x * kx + p.y * kz + wave_time * speed);
}
void vertex() {
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	height = wave(p, 0.7, 0.3, 0.0, 1.1) + wave(p, 0.45, 0.0, 0.42, -0.9) + wave(p, 0.12, 0.8, 0.8, 1.8);
	height *= wave_scale;
	VERTEX.y += height;
	float dx = dwave(p, 0.7, 0.3, 0.0, 1.1, 0.3) + dwave(p, 0.12, 0.8, 0.8, 1.8, 0.8);
	float dz = dwave(p, 0.45, 0.0, 0.42, -0.9, 0.42) + dwave(p, 0.12, 0.8, 0.8, 1.8, 0.8);
	dx *= wave_scale;
	dz *= wave_scale;
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}
void fragment() {
	vec3 c = mix(deep.rgb, crest.rgb, clamp(height * 0.5 + 0.5, 0.0, 1.0));
	c = mix(c, foam.rgb, smoothstep(1.12, 1.27, height) * 0.6);  // foam only on the highest crests
	ALBEDO = c;
	ROUGHNESS = 0.7;
	SPECULAR = 0.04;  // no bright patches of sky reflected: deep water, not sky
	METALLIC = 0.1;
}
"""

var sky := Color("#8cc8f0")  # the background colour
var ambient := Color("#bcd4ee")
var ambient_energy := 0.34
var sun_color := Color("#fff0d8")
var sun_energy := 0.8
var fog := 0.0  # depth fog density (0: none), fading into the sky colour
var drop := DROP  # how far below the board this theme lies
var shrink := 1.0  # the whole backdrop's size (Racing: smaller, so more of it shows)
var shift_back := 0.0  # how far back it sits, per unit of drop (Castle: centred under the board)
var wave_scale := 1.0  # the sea's waves (Calm Sea: 0, still water)
var shallow := false  # the sea lies SEA_DROP down, not SHIP_DROP (make)
var frame_margin := 2.6  # room round the board in the whole-board view (Castle: less, closer in)
var frame_back := 0.0  # how far the whole-board view looks back past the board's middle (Castle: more of the army)

signal thunder  # a thunderclap after a lightning flash (Storm Clouds)

var _time := 0.0
var _anims: Array[Callable] = []  # each called every frame with the time so far
var _rng := RandomNumberGenerator.new()
var _centre := Vector3.ZERO
var _half := Vector2.ONE  # half the board's size, plus a margin
var _reach := 1.0
var _textures := {}  # textures made for this backdrop, by their two colours
var _sea: ShaderMaterial  # the waves, kept in step with the ships


## `shallow`: the board has things standing in the sea (islands, turtles),
## which reach down SEA_DROP.
static func make(theme: String, lo: Vector3, hi: Vector3, shallow := false) -> Scenery:
	var s := Scenery.new()
	s.shallow = shallow
	s._rng.seed = 1964
	s._centre = (lo + hi) / 2
	s._half = Vector2(hi.x - lo.x, hi.z - lo.z) / 2 + Vector2(1.6, 1.6)
	s._reach = maxf(s._half.x, s._half.y)
	match theme:
		"space":
			s._space()
		"volcano":
			s._volcano()
		"castle":
			s._castle()
		"racing":
			s._racing()
		"storm":
			s._storm()
		"market":
			s._market()
		"sky":
			s._sky_high()
		"lagoon":  # the Pirate Sea with the water still
			s.wave_scale = 0.0
			s._pirate_sea()
		_:
			s._pirate_sea()
	s._no_shadows(s)
	s.scale = Vector3.ONE * s.shrink  # about the board's centre
	s.position = s._centre * (1.0 - s.shrink) + Vector3(0, -s.drop, 0)
	# Shifted back along the view, so the ground below lines up under the
	# board as the camera sees it (the board floats DROP above it).
	s.position.z -= s.drop * s.shift_back
	return s


func _process(delta: float) -> void:
	_time += delta
	if _sea:
		_sea.set_shader_parameter("wave_time", _time)
	for a in _anims:
		a.call(_time)


## A material with a soft natural pattern between two shades, the same density
## on every surface whatever its size (`tile`: metres one copy of the pattern
## covers). `glow` makes it shine with its own colours (lava).
func textured(dark: Color, light: Color, tile := 4.0, glow := 0.0, roughness := 0.95) -> StandardMaterial3D:
	var key := "%s|%s" % [dark.to_html(), light.to_html()]
	if not _textures.has(key):
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.012
		noise.fractal_octaves = 5
		noise.seed = key.hash()
		var tex := NoiseTexture2D.new()
		tex.width = TEXTURE_SIZE
		tex.height = TEXTURE_SIZE
		tex.seamless = true
		tex.noise = noise
		var ramp := Gradient.new()
		ramp.set_color(0, dark)
		ramp.set_color(1, light)
		tex.color_ramp = ramp
		_textures[key] = tex
	var m := StandardMaterial3D.new()
	m.albedo_texture = _textures[key]
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.roughness = roughness
	if glow > 0.0:
		m.emission_enabled = true
		m.emission_texture = _textures[key]
		m.emission_energy_multiplier = glow
	return m


## Nothing in the scenery takes or casts a shadow.
func _no_shadows(node: Node) -> void:
	for child in node.get_children():
		var mi := child as MeshInstance3D
		if mi:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var m := mi.material_override as BaseMaterial3D
			if m:
				m.disable_receive_shadows = true
		_no_shadows(child)


# --- themes ---------------------------------------------------------------

## Night Market: one crowded food alley below the board, at night, running
## at an angle across the view (MARKET_ANGLE). Food stalls line both sides,
## their counters glowing with trays of food under small dark awnings, steam
## rising off some; a row of taller shopfronts along the far side carries neon
## signs, a few more hang out over the alley, and the near side stays low so
## the street shows. A crowd packs the alley. Under a deep blue-black sky and
## a dark haze; the board itself stays in soft moonlight. Repeated pieces are
## drawn in batches (_batch) so it stays light.
func _sky_high() -> void:
	sky = Color("#86c0ea")
	ambient = Color("#d8e8f8")
	ambient_energy = 0.5
	sun_color = Color("#fff6e4")
	sun_energy = 0.95
	fog = 0.002
	# A sunlit floor of cloud far below, drifting, so there is never bare sky
	# under the board, and white clouds drifting over it.
	var floor_m := textured(Color("#2e5a86"), Color("#45739e"), 6.0)  # a deep, soft blue: easy on the eye, the white clouds stand out
	_add(_slab(Vector3(_reach * 9, 0.1, _reach * 9), floor_m), _centre - Vector3(0, 10.0, 0))
	_anims.append(func(t: float): floor_m.uv1_offset = Vector3(t * 0.002, 0, 0))
	var white := textured(Color("#e6edf6"), Color("#ffffff"), 2.0)
	var soft := textured(Color("#d4dfec"), Color("#f2f6fb"), 2.0)
	_clouds(12, -9.0, -4.0, [white, soft], 0.5)
	# Small grassy rocks floating in the distance, bobbing slowly.
	var earth := textured(Color("#5a4430"), Color("#86684a"), 0.8)
	var grass := textured(Color("#4a8a3a"), Color("#6aae4e"), 1.0)
	for i in 6:
		var rock := Node3D.new()
		var size := _rng.randf_range(0.8, 1.6)
		var under := B._cyl(size, 0.1, size * 1.6, Color.WHITE)
		under.material_override = earth
		under.position.y = -size * 0.8
		rock.add_child(under)
		var top := B._cyl(size * 1.02, size * 1.02, 0.18, Color.WHITE)
		top.material_override = grass
		rock.add_child(top)
		var tree := B._cyl(0.0, size * 0.35, size * 0.9, Color.WHITE)  # a little pine
		tree.material_override = grass
		tree.position = Vector3(size * 0.3, size * 0.5, 0)
		rock.add_child(tree)
		var at := _spot(TAU * i / 6.0 + _rng.randf_range(-0.3, 0.3), _rng.randf_range(4.0, 9.0)) \
				+ Vector3(0, _rng.randf_range(-4.0, -1.0), 0)
		_add(rock, at)
		var phase := _rng.randf() * TAU
		_anims.append(func(t: float): rock.position.y = at.y + sin(t * 0.4 + phase) * 0.25)
	# Hot-air balloons drifting slowly past, at their own heights and speeds.
	var colours := [[Color("#e04a3a"), Color("#f4d04a")], [Color("#3a7ad0"), Color("#f4f4f0")], [Color("#5ab04a"), Color("#f49a3a")]]
	for i in colours.size():
		var balloon := Node3D.new()
		for k in 8:  # the envelope in coloured gores
			var gore := _ball(1.0, Color.WHITE)
			gore.material_override = B._material(colours[i][k % 2])
			gore.scale = Vector3(0.42, 1.15, 1.0)
			gore.rotation.y = PI * k / 8.0
			gore.position.y = 1.6
			balloon.add_child(gore)
		balloon.add_child(B._box(Vector3(0.45, 0.35, 0.45), Color("#7a5a3a")))  # the basket
		for c in [Vector3(-0.2, 0, -0.2), Vector3(0.2, 0, -0.2), Vector3(-0.2, 0, 0.2), Vector3(0.2, 0, 0.2)]:
			var rope := B._cyl(0.01, 0.01, 0.75, Color("#3a2a1a"))
			rope.position = c + Vector3(0, 0.55, 0)
			balloon.add_child(rope)
		_add(balloon, _centre)
		var span := _reach * 4.0
		var y := -2.0 - i * 1.5
		var z := _centre.z + (_half.y + 4.0) * (-1.0 if i % 2 == 0 else 0.4) + i
		var x0 := _rng.randf() * span
		var speed := 0.15 + i * 0.05
		_anims.append(func(t: float):
			balloon.position = Vector3(_centre.x - span / 2 + fmod(x0 + t * speed, span), y + sin(t * 0.5 + i) * 0.2, z))
	# Birds wheeling under the board in wide lazy circles.
	for i in 6:
		var bird := _seagull()
		_add(bird, _centre)
		var r := _rng.randf_range(_reach * 0.4, _reach * 1.1)
		var height := _rng.randf_range(-3.0, -1.2)
		var speed := _rng.randf_range(0.15, 0.3) * (1 if i % 2 == 0 else -1)
		var start := _rng.randf() * TAU
		var wing_l: Node3D = bird.get_meta("left")
		var wing_r: Node3D = bird.get_meta("right")
		_anims.append(func(t: float):
			var a := start + t * speed
			bird.position = _centre + Vector3(cos(a) * r, height, sin(a) * r * 0.7)
			var along := Vector3(-sin(a), 0, cos(a) * 0.7) * signf(speed)
			bird.rotation = Vector3(0, atan2(along.x, along.z), -0.3 * signf(speed))
			var w := sin(t * 6.0 + start) * 0.6 if fmod(t + start, 4.0) < 2.5 else 0.1
			wing_l.rotation.z = w
			wing_r.rotation.z = -w)


func _market() -> void:
	sky = Color("#0a0f24")
	drop = MARKET_DROP
	shift_back = 0.65  # the alley centred under the board as seen
	ambient = Color("#5a6a9a")  # moonlit blue fill: the board stays readable
	ambient_energy = 0.55
	sun_color = Color("#c8d0ff")
	sun_energy = 0.7
	fog = 0.02
	var reach := _reach * 1.6 + 6.0
	# The alley, built along its own x and turned to its angle under the board.
	var lane := Node3D.new()
	_add(lane, _centre)
	lane.rotation.y = MARKET_ANGLE
	lane.scale = Vector3.ONE * MARKET_SCALE  # big: the alley fills the view under the board
	# It all fills the whole backdrop, off the screen every way: the alley
	# runs on past both ends and rooftops pack the ground either side.
	var fill := reach / MARKET_SCALE * 1.3  # how far out it goes (before the scale)
	var half := fill  # half the alley's length
	var more := half / (_reach * 0.75)  # how much longer that is than one board's worth
	var w := MARKET_ALLEY / 2
	var parts := {}
	_part(parts, "paving", Vector3(fill * 2.6, 0.04, fill * 2.6), Vector3(0, -0.03, 0))  # tarmac under everything (just above the ground, scaled)
	# A used street, not a grid: kerbs along both sides where the stalls
	# stand, puddles catching the stall lights, litter underfoot.
	for side in [-1, 1]:
		_part(parts, "kerb", Vector3(half * 2 + 2.0, 0.06, 0.12), Vector3(0, 0.0, side * (w - 0.05)))
	for k in int(MARKET_PUDDLES * more):
		var size := Vector3(_rng.randf_range(0.3, 0.8), 0.01, _rng.randf_range(0.2, 0.45))
		_part(parts, "puddle", size, Vector3(_rng.randf_range(-half, half), -0.005, _rng.randf_range(-w * 0.7, w * 0.7)),
				Basis(Vector3.UP, _rng.randf() * PI))
	for k in int(MARKET_LITTER * more):
		var bits := ["card", "paper", "cup"]
		var bit: String = bits[_rng.randi() % bits.size()]
		var size := Vector3(0.18, 0.012, 0.14) if bit == "card" else Vector3(0.07, 0.006, 0.05) if bit == "paper" \
				else Vector3(0.04, 0.06, 0.04)
		_part(parts, bit, size, Vector3(_rng.randf_range(-half, half), -0.01 + size.y / 2,
				_rng.randf_range(-w - 0.6, w + 0.6)), Basis(Vector3.UP, _rng.randf() * TAU))
	for side in [-1, 1]:  # -1: the far side (tall shopfronts), 1: the near side (low)
		var x := -half
		while x < half:
			var sw := _rng.randf_range(0.7, 1.4)  # each stall its own width
			_food_stall(lane, Vector3(x + sw / 2, 0, side * (w + 0.35)), sw, side, parts)
			x += sw + _rng.randf_range(0.05, 0.25)
	# Shopfronts along the far side, behind its stalls, neon on their fronts.
	var x := -half - 0.5
	while x < half + 0.5:
		var bw := _rng.randf_range(1.4, 2.4)
		var h := _rng.randf_range(1.8, 2.4)  # clear of the board, scaled up
		var at := Vector3(x + bw / 2, 0, -w - 1.6)
		_part(parts, "walls", Vector3(bw - 0.05, h, 1.0), at + Vector3(0, h / 2, 0))
		for k in int(bw / 0.5):
			if _rng.randf() < 0.5:
				_part(parts, "window_lit" if _rng.randf() < 0.5 else "window_dark", Vector3(0.26, 0.28, 0.04),
						at + Vector3(-bw / 2 + 0.3 + k * 0.5, h - 0.4, 0.51))
		if _rng.randf() < 0.7:
			_part(parts, "neon%d" % (_rng.randi() % MARKET_NEON.size()), Vector3(bw * 0.5, 0.2, 0.04),
					at + Vector3(0, _rng.randf_range(1.3, h - 0.7), 0.53))
		x += bw
	# A low row of shopfronts along the near side, so the alley is walled on
	# both sides but still shows over them.
	x = -half - 0.5
	while x < half + 0.5:
		var bw := _rng.randf_range(1.4, 2.4)
		var h := _rng.randf_range(0.7, 1.1)
		_part(parts, "walls", Vector3(bw - 0.05, h, 1.0), Vector3(x + bw / 2, h / 2, w + 1.6))
		x += bw
	# Rooftops packing the ground beyond both rows, out past the screen.
	for side in [-1, 1]:
		var z := w + 2.2
		while z < fill:
			var depth := _rng.randf_range(1.5, 2.5)
			x = -half - 1.0
			while x < half + 1.0:
				var bw := _rng.randf_range(1.4, 2.6)
				var h := _rng.randf_range(1.4, 2.4) if side < 0 else _rng.randf_range(0.6, 1.2)  # low in front
				var at := Vector3(x + bw / 2, 0, side * (z + depth / 2))
				_part(parts, "roofs", Vector3(bw - 0.08, h, depth - 0.08), at + Vector3(0, h / 2, 0))
				if _rng.randf() < 0.35:  # a water tank or an air conditioner on top
					_part(parts, "cart", Vector3(0.3, 0.25, 0.3), at + Vector3(_rng.randf_range(-bw / 4, bw / 4), h + 0.12,
							_rng.randf_range(-depth / 4, depth / 4)))
				if _rng.randf() < 0.3:  # a lit window on the side facing the camera
					_part(parts, "window_lit", Vector3(0.24, 0.24, 0.04), at + Vector3(_rng.randf_range(-bw / 3, bw / 3),
							h * 0.6, depth / 2 + 0.01))
				x += bw
			z += depth
	# A few signs hung out over the alley.
	for k in int(MARKET_HANGING_SIGNS * more):
		var sx := _rng.randf_range(-half * 0.85, half * 0.85)
		_part(parts, "neon%d" % (_rng.randi() % MARKET_NEON.size()), Vector3(0.05, 0.3, 0.55),
				Vector3(sx, 1.6, -w + 0.1))
	# Strings of lights across the alley, each sagging in a slight C.
	_light_strings(half, w, parts)
	# A few roof covers, each over a short stretch of one side's stalls,
	# sloping down towards the alley: the street itself stays open.
	var covers := int(MARKET_COVERS * more)
	for k in covers:
		var cx := lerpf(-half * 0.8, half * 0.8, (k + _rng.randf_range(0.2, 0.8)) / covers)
		var length := _rng.randf_range(1.2, 1.8)
		var s := -1 if k % 2 == 0 else 1  # far side, near side, far side...
		var colour := "cover%d" % (k % MARKET_COVER_COLOURS.size())
		_part(parts, colour, Vector3(length, 0.04, 1.1), Vector3(cx, 1.5, s * (w + 0.4)),
				Basis(Vector3.RIGHT, -0.25 * s))
		for end: float in [-length / 2 + 0.05, length / 2 - 0.05]:  # its posts at the back
			_part(parts, "wire", Vector3(0.04, 1.6, 0.04), Vector3(cx + end, 0.8, s * (w + 0.9)))
	# The crowd.
	for i in int(MARKET_CROWD * more):  # as busy all along
		_alley_shopper(lane, half, w)
	var box := BoxMesh.new()
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	ball.radial_segments = 10
	ball.rings = 6
	var mats := {
		"paving": textured(Color("#2c2a32"), Color("#4a4652"), 0.9, 0.18, 0.45),  # worn, damp tarmac, faintly lit by the stalls
		"kerb": B._material(Color("#5a5660")),
		"puddle": _puddle_material(),
		"card": B._material(Color("#8a6a44")),
		"paper": B._material(Color("#c8c4b8")),
		"cup": B._material(Color("#e8e4dc")),
		"cart": B._material(Color("#8a8e96")),
		"awning": B._material(Color("#1e2a3a")),
		"table": B._material(Color("#5a4030")),
		"crate": B._material(Color("#8a6a42")),
		"glass": B._material(Color(0.85, 0.95, 1.0), 0.35),
		"grill": B._material(Color("#ff6a2a"), 1.2),  # glowing coals
		"tray": B._material(Color("#ffd890"), 0.9),  # the counters glow under their lamps
		"walls": textured(Color("#1e1e26"), Color("#2e2c34"), 0.8),
		"roofs": textured(Color("#18181e"), Color("#26242c"), 0.6),
		"window_lit": B._material(Color("#ffcf7a"), 0.8),
		"window_dark": B._material(Color("#141820")),
		"bulb": B._material(Color("#ffd890"), 1.6),
		"lantern": B._material(Color("#ff3a1a"), 1.6),
		"wire": B._material(Color("#0e0e12")),
	}
	for k in MARKET_NEON.size():
		mats["neon%d" % k] = B._material(MARKET_NEON[k], 1.2)
	for k in MARKET_FOOD.size():
		mats["food%d" % k] = B._material(MARKET_FOOD[k], 0.3)
	for k in MARKET_COVER_COLOURS.size():
		mats["cover%d" % k] = B._material((MARKET_COVER_COLOURS[k] as Color).darkened(0.2))
		mats["parasol%d" % k] = B._material((MARKET_COVER_COLOURS[k] as Color).lightened(0.1))
	for key in parts:
		var round: bool = key.begins_with("food") or key.begins_with("parasol") or key == "bulb" or key == "lantern"
		_batch(lane, ball if round else box, mats[key], parts[key])
	# A dark haze between the board and the alley.
	var haze := MeshInstance3D.new()
	var sheet := PlaneMesh.new()
	sheet.size = Vector2.ONE * reach * 8
	haze.mesh = sheet
	var haze_m := StandardMaterial3D.new()
	haze_m.albedo_color = Color(sky, MARKET_HAZE)
	haze_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	haze.material_override = haze_m
	_add(haze, _centre + Vector3(0, drop * 0.55, 0))


## Strings of lights across the alley (in its own frame, `half` its
## half-length, `w` its half-width), one every MARKET_STRING_GAP along it:
## each hangs from the shopfronts on the far side to poles on the near side
## and dips in a slight C between them (lowest in the middle), small warm
## bulbs along it and a red lantern at the bottom of the dip.
func _light_strings(half: float, w: float, parts: Dictionary) -> void:
	var reach := w + 0.9  # from just past the stalls on one side to the other
	var top := 2.0
	var x := -half + MARKET_STRING_GAP * 0.5
	while x < half:
		_part(parts, "wire", Vector3(0.03, top, 0.03), Vector3(x, top / 2, reach))  # its pole, near side
		var steps := 14
		for k in steps + 1:
			var u := -1.0 + 2.0 * k / steps  # -1 far end .. 1 near end
			var y := top - MARKET_STRING_SAG * (1.0 - u * u)
			_part(parts, "bulb", Vector3.ONE * 0.06, Vector3(x, y - 0.04, u * reach))
		_part(parts, "lantern", Vector3(0.16, 0.13, 0.16), Vector3(x, top - MARKET_STRING_SAG - 0.12, 0))
		x += MARKET_STRING_GAP


## A food stall at `at` (in the alley's own frame) on `side` of it (-1 far, 1
## near): a steel cart whose counter glows with trays of food, a small dark
## awning over it (only on the far side, so the near one never hides the
## alley), steam over some.
func _food_stall(lane: Node3D, at: Vector3, sw: float, side: int, parts: Dictionary) -> void:
	var steam := _rng.randf() < MARKET_STEAM
	var top := 0.52  # where the food sits
	match _rng.randi() % 5:
		0:  # a steel cart with a glowing counter
			_part(parts, "cart", Vector3(sw, 0.5, 0.6), at + Vector3(0, 0.25, 0))
			_part(parts, "tray", Vector3(sw * 0.9, 0.04, 0.45), at + Vector3(0, top, 0))
		1:  # a long low table, crates stacked at one end
			top = 0.4
			_part(parts, "table", Vector3(sw, 0.38, 0.5), at + Vector3(0, 0.19, 0))
			for k in _rng.randi_range(1, 3):
				_part(parts, "crate", Vector3.ONE * 0.28, at + Vector3(sw / 2 - 0.1, 0.14 + k * 0.29 - 0.29, side * 0.35))
		2:  # a tall glass display case, glowing, food on its shelves
			top = 0.75
			_part(parts, "cart", Vector3(sw, 0.45, 0.55), at + Vector3(0, 0.22, 0))
			_part(parts, "glass", Vector3(sw * 0.9, 0.5, 0.45), at + Vector3(0, 0.7, 0))
			_part(parts, "tray", Vector3(sw * 0.85, 0.03, 0.4), at + Vector3(0, 0.47, 0))
		3:  # under its own round parasol
			_part(parts, "table", Vector3(sw * 0.8, 0.45, 0.5), at + Vector3(0, 0.22, 0))
			top = 0.47
			_part(parts, "wire", Vector3(0.03, 1.25, 0.03), at + Vector3(0, 0.62, side * 0.3))
			_part(parts, "parasol%d" % (_rng.randi() % MARKET_COVER_COLOURS.size()), Vector3(sw * 1.1, 0.14, sw * 1.1),
					at + Vector3(0, 1.25, side * 0.3))
		4:  # a grill with a hood over it, always smoking
			steam = true
			_part(parts, "cart", Vector3(sw, 0.55, 0.55), at + Vector3(0, 0.27, 0))
			_part(parts, "grill", Vector3(sw * 0.85, 0.04, 0.4), at + Vector3(0, 0.57, 0))
			_part(parts, "cart", Vector3(sw * 0.9, 0.08, 0.5), at + Vector3(0, 1.1, side * 0.1))
			_part(parts, "wire", Vector3(0.03, 0.5, 0.03), at + Vector3(-sw * 0.4, 0.82, side * 0.2))
			top = 0.6
	var food := "food%d" % (_rng.randi() % MARKET_FOOD.size())
	for k in int(sw * 7):
		_part(parts, food if _rng.randf() < 0.7 else "food%d" % (_rng.randi() % MARKET_FOOD.size()),
				Vector3.ONE * 0.09, at + Vector3(_rng.randf_range(-sw * 0.4, sw * 0.4), top + 0.05,
				_rng.randf_range(-0.15, 0.15)))
	if side < 0 and _rng.randf() < 0.6:  # a small awning on the far side
		_part(parts, "awning", Vector3(sw + 0.05, 0.03, 0.8), at + Vector3(0, 1.25, -0.15),
				Basis(Vector3.RIGHT, 0.3))
	if steam:
		_steam(lane, at + Vector3(0, top + 0.1, 0))


## Someone in the crowd, wandering up and down the alley (in its own frame,
## `half` its half-length, `w` its half-width).
func _alley_shopper(lane: Node3D, half: float, w: float) -> void:
	var person := Node3D.new()
	var body := MeshInstance3D.new()
	body.mesh = _capsule(0.11, 0.48)
	body.material_override = B._material(Color.from_hsv(_rng.randf(), 0.45, _rng.randf_range(0.4, 0.85)))
	body.position.y = 0.3
	person.add_child(body)
	var head := _ball(0.085, Color("#2a2420") if _rng.randf() < 0.7 else Color("#b8906c"))  # hair, seen from above
	head.position.y = 0.64
	person.add_child(head)
	var mid := _rng.randf_range(-half * 0.9, half * 0.9)
	var span := minf(_rng.randf_range(0.5, 2.5), half - absf(mid))
	var speed := _rng.randf_range(0.05, 0.14)
	var p := _rng.randf() * TAU
	person.position = Vector3(mid, -0.08, _rng.randf_range(-w * 0.8, w * 0.8))
	lane.add_child(person)
	_anims.append(func(t: float):
		person.position.x = mid + sin(t * speed + p) * span
		person.rotation.y = PI / 2 if cos(t * speed + p) > 0.0 else -PI / 2
		person.position.y = -0.08 + absf(sin(t * 6.0 + p)) * 0.025)


## A puddle on the street: dark, glossy water with a faint warm sheen from
## the stall lights.
static func _puddle_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#14161e")
	m.roughness = 0.05
	m.metallic = 0.4
	m.emission_enabled = true
	m.emission = Color("#5a3a1a")
	m.emission_energy_multiplier = 0.5
	return m


## Steam rising off a cooking stall at `at` (in `parent`): a few soft puffs
## drifting up, swelling and fading, over and over.
func _steam(parent: Node3D, at: Vector3) -> void:
	for k in 3:
		var puff := _ball(0.12, Color.WHITE)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, 0.0)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = m
		puff.position = at
		parent.add_child(puff)
		var offset := k / 3.0
		var speed := _rng.randf_range(0.35, 0.5)
		_anims.append(func(t: float):
			var u := fposmod(t * speed + offset, 1.0)
			puff.position = at + Vector3(sin(t + k) * 0.05, u * 0.9, 0)
			puff.scale = Vector3.ONE * (0.6 + u * 1.6)
			m.albedo_color.a = 0.32 * sin(PI * u))

## Adds one piece to batch `key` of `parts`: a unit box or ball scaled to
## `size`, turned by `turn`, at `at`.
func _part(parts: Dictionary, key: String, size: Vector3, at: Vector3, turn := Basis.IDENTITY) -> void:
	if not parts.has(key):
		parts[key] = []
	parts[key].append(Transform3D(turn * Basis.from_scale(size), at))


## Draws every piece of one batch in a single go (a MultiMesh) in `parent`:
## `mesh` (a unit box or ball) in `material`, once per transform.
func _batch(parent: Node3D, mesh: Mesh, material: Material, transforms: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func _pirate_sea() -> void:
	sky = Color("#7a98ac")
	ambient = Color("#b8c8d4")
	ambient_energy = 0.42
	sun_color = Color("#fff4e0")
	sun_energy = 0.8
	fog = 0.0015
	# Deep, so the big ship's masts end just below the tiles; close under the
	# board where things on it stand in the water (islands, turtles).
	drop = SEA_DROP if shallow else SHIP_DROP
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * _reach * 9.0
	plane.subdivide_width = 140
	plane.subdivide_depth = 140
	var water := MeshInstance3D.new()
	water.mesh = plane
	var shader := Shader.new()
	shader.code = SEA_SHADER
	_sea = ShaderMaterial.new()
	_sea.shader = shader
	_sea.set_shader_parameter("wave_scale", wave_scale)
	water.material_override = _sea
	_add(water, _centre)
	# One huge ship sailing diagonally across under the board, from the far
	# left to the near right, then round again; as big as the drop lets it
	# be with its pennant still under the tiles (stretched lengthwise too).
	var size := clampf((drop - 1.4) / 2.1, 1.5, 4.5)
	var ship := _ship(Color("#e8e0cc"), Color("#151515"))
	ship.scale = Vector3(size * 1.2, size, size * 1.2)
	_add(ship, _centre)
	# Where islands or turtles stand in the water it crosses far behind the
	# board instead, clear of them.
	var course := Vector3(1, 0, 0) if shallow else Vector3(1, 0, 0.75).normalized()
	var lane := _centre - Vector3(0, 0, _half.y + 6.0) if shallow else _centre
	var reach := _reach * 2.2 + size * 3.0  # well off the screen at both ends
	var port := Node3D.new()  # where its broadsides land, either side of it
	var starboard := Node3D.new()
	add_child(port)
	add_child(starboard)
	_anims.append(func(t: float):
		var at := lane + course * (fmod(t * 1.1 + reach * 0.55, reach * 2.0) - reach)  # in view soon after the start
		var tilt := _tilt(at.x, at.z)
		ship.position = Vector3(at.x, _wave_height(at.x, at.z) * 0.7 - 0.15 * size, at.z)
		ship.rotation = Vector3(tilt.x, atan2(-course.z, course.x), tilt.y)
		var side := course.cross(Vector3.UP) * size * 3.5
		port.position = ship.position + side
		starboard.position = ship.position - side)
	_cannon_fire(ship, port, 0.0, 7.0)
	_cannon_fire(ship, starboard, 3.6, 8.0)
	if wave_scale == 0.0:  # the still lagoon: fish leaping now and then instead
		_leaping_fish()
	# Seagulls wheeling over the water, wings flapping, in wide lazy circles.
	for i in (7 if wave_scale > 0.0 else 0):
		var gull := _seagull()
		_add(gull, _centre)
		var r := _rng.randf_range(_reach * 0.4, _reach * 1.2)
		var height := _rng.randf_range(1.5, 3.6) * drop / SEA_DROP  # under the board
		var speed := _rng.randf_range(0.15, 0.3) * (1 if i % 2 == 0 else -1)
		var start := _rng.randf() * TAU
		var wing_l: Node3D = gull.get_meta("left")
		var wing_r: Node3D = gull.get_meta("right")
		var flap := _rng.randf_range(5.0, 7.0)
		_anims.append(func(t: float):
			var a := start + t * speed
			gull.position = _centre + Vector3(cos(a) * r, height + sin(t * 0.7 + start) * 0.25, sin(a) * r * 0.7)
			var along := Vector3(-sin(a), 0, cos(a) * 0.7) * signf(speed)
			gull.rotation = Vector3(0, atan2(along.x, along.z), -0.3 * signf(speed))
			var w := sin(t * flap + start) * 0.6 if fmod(t + start, 4.0) < 2.5 else 0.1  # flapping, then gliding
			wing_l.rotation.z = w
			wing_r.rotation.z = -w)
	# A shark circling round the board, its fin cutting the water.
	var fin := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.7, 0.8, 0.08)
	prism.left_to_right = 0.2
	fin.mesh = prism
	fin.material_override = textured(Color("#3a4450"), Color("#5a6470"), 0.4)
	_add(fin, _centre)
	var wake := B._box(Vector3(0.9, 0.03, 0.12), Color(0.9, 0.95, 0.97))
	_add(wake, _centre)
	_anims.append(func(t: float):
		var a := t * 0.18
		var r := _reach * 0.75
		var x := _centre.x + cos(a) * r
		var z := _centre.z + sin(a) * r * 0.7
		var y := _wave_height(x, z)
		fin.position = Vector3(x, y + 0.3, z)
		fin.rotation.y = -a
		wake.position = Vector3(x, y + 0.02, z)
		wake.rotation.y = -a)
	# Life rings bobbing on the waves.
	for i in 4:
		var ring := Node3D.new()
		for k in 8:
			var seg := B._cyl(0.11, 0.11, 0.42, Color("#e8302a") if k % 2 == 0 else Color("#f4f4f0"))
			var a := TAU * k / 8.0
			seg.position = Vector3(cos(a) * 0.45, 0, sin(a) * 0.45)
			seg.rotation = Vector3(PI / 2, -a, 0)
			ring.add_child(seg)
		_float(ring, _spot(_rng.randf() * TAU, _rng.randf_range(-3.0, 3.0)), _rng.randf() * TAU)
	if wave_scale > 0.0:  # a buoy with a light blinking on top (not on the still lagoon)
		var buoy := Node3D.new()
		var body := B._cyl(0.25, 0.4, 0.9, Color("#e8b020"))
		body.position.y = 0.3
		buoy.add_child(body)
		var light := _ball(0.1, Color.WHITE)
		var light_m := B._material(Color("#ff4030"), 2.0)
		light.material_override = light_m
		light.position.y = 0.85
		buoy.add_child(light)
		_float(buoy, _spot(0.8, 2.0), 0.0)
		_anims.append(func(t: float): light_m.emission_energy_multiplier = 2.5 if fmod(t, 2.0) < 0.3 else 0.2)
	# Rocks and floating barrels.
	var rock := textured(Color("#2a2c2e"), Color("#4c5052"), 1.2)
	for i in 6:
		var at := _spot(_rng.randf() * TAU, _rng.randf_range(3.0, 10.0))
		var lump := B._cyl(0.0, _rng.randf_range(0.6, 1.4), _rng.randf_range(1.2, 2.6), Color.WHITE)
		(lump.mesh as CylinderMesh).radial_segments = 6
		lump.material_override = rock
		lump.rotation = Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf() * TAU, _rng.randf_range(-0.2, 0.2))
		_add(lump, at + Vector3(0, 0.3, 0))
	var wood := textured(Color("#3c2a1a"), Color("#6a4a2c"), 0.4)
	for i in 5:
		var barrel := B._cyl(0.14, 0.14, 0.35, Color.WHITE)
		barrel.material_override = wood
		barrel.rotation.z = PI / 2
		_float(barrel, _spot(_rng.randf() * TAU, _rng.randf_range(0.5, 5.0)), _rng.randf() * TAU)


func _space() -> void:
	sky = Color("#04050c")
	ambient = Color("#7a80b8")
	ambient_energy = 0.5
	sun_color = Color("#f4f6ff")
	sun_energy = 0.9
	# Stars all round and below, each twinkling at its own pace.
	for i in 220:
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, -0.15), _rng.randf_range(-1, 1)).normalized()
		var star := _ball(_rng.randf_range(0.03, 0.08), Color.WHITE)
		var m := B._material(Color("#fff6e8") if i % 3 else Color("#c8dcff"), 1.4)
		star.material_override = m
		_add(star, _centre + dir * _rng.randf_range(_reach * 1.2, _reach * 3.5))
		var phase := _rng.randf() * TAU
		var speed := _rng.randf_range(0.8, 2.0)
		_anims.append(func(t: float): m.emission_energy_multiplier = 0.9 + 0.6 * sin(t * speed + phase))
	# Planets circling slowly below the board, each on its own level and
	# orbit, spaced so they never meet, each turning as it goes.
	var planets := [  # [radius, orbit, depth, speed, dark, light, ringed]
		[2.2, _reach * 1.9, -7.0, 0.05, Color("#6a3a26"), Color("#c08050"), false],
		[1.1, _reach * 1.3, -13.0, -0.07, Color("#5a1e14"), Color("#b0503a"), false],
		[1.6, _reach * 2.4, -18.0, 0.04, Color("#7a9ab0"), Color("#e0f0f8"), false],
		[2.6, _reach * 1.6, -26.0, -0.03, Color("#1a3a5a"), Color("#4a8a7a"), false],
		[0.7, _reach * 2.8, -10.0, 0.09, Color("#5a5a60"), Color("#a8a8b0"), false],
	]
	for i in planets.size():
		var p: Array = planets[i]
		var planet := _planet(Vector3.ZERO, p[0], p[4], p[5], p[6], 0.15)
		var start := TAU * i / planets.size()
		_anims.append(func(t: float):
			var a: float = start + t * p[3]
			planet.position = _centre + Vector3(cos(a) * p[1], p[2], sin(a) * p[1] * 0.7))
	# Small space rocks tumbling slowly about.
	var rock_m := textured(Color("#3a342e"), Color("#6e665c"), 0.4)
	for i in 40:
		var rock := MeshInstance3D.new()
		var lump := SphereMesh.new()
		var r := _rng.randf_range(0.06, 0.22)
		lump.radius = r
		lump.height = r * _rng.randf_range(1.2, 1.8)
		lump.radial_segments = 6
		lump.rings = 3
		rock.mesh = lump
		rock.material_override = rock_m
		var base := _centre + Vector3(_rng.randf_range(-_reach * 1.5, _reach * 1.5), _rng.randf_range(-4.0, 1.0),
				_rng.randf_range(-_reach * 1.4, _reach * 1.2))
		_add(rock, base)
		var drift := Vector3(_rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.04, 0.04), _rng.randf_range(-0.08, 0.08))
		var spin := Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * 0.6
		var span := _reach * 3.0
		_anims.append(func(t: float):
			var p := base + drift * t
			p.x = _centre.x - span / 2 + fposmod(p.x - _centre.x + span / 2, span)  # round again
			p.z = _centre.z - span / 2 + fposmod(p.z - _centre.z + span / 2, span)
			rock.position = p
			rock.rotation = spin * t)
	# Meteors streaking past below the board now and then.
	for i in 3:
		var head := _ball(0.12, Color.WHITE)
		head.material_override = B._material(Color("#ffe8c0"), 2.5)
		var trail := B._box(Vector3(0.08, 0.08, 2.4), Color.WHITE)
		var tm := B._material(Color("#ff9a50", 0.6), 1.5)
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail.material_override = tm
		var meteor := Node3D.new()
		meteor.add_child(head)
		trail.position.z = 1.2
		meteor.add_child(trail)
		_add(meteor, _centre)
		meteor.visible = false
		var period := _rng.randf_range(7.0, 12.0)
		var offset := _rng.randf() * period
		_anims.append(func(t: float):
			var cycle := floorf((t + offset) / period)
			var phase := fmod(t + offset, period)
			meteor.visible = phase < 1.6
			if not meteor.visible:
				return
			var r := RandomNumberGenerator.new()
			r.seed = int(cycle) * 7919 + i
			var from := _centre + Vector3(r.randf_range(-_reach * 2, _reach * 2), r.randf_range(-6, -2), -_reach * 2.5)
			var to := from + Vector3(r.randf_range(-_reach, _reach), r.randf_range(-6, -2), _reach * 4.5)
			meteor.position = from.lerp(to, phase / 1.6)
			meteor.look_at(meteor.position + (to - from), Vector3.UP))


func _volcano() -> void:
	sky = Color("#4a1206")  # the lava's glow on the haze, so the horizon melts into it
	ambient = Color("#c08060")
	ambient_energy = 0.32
	sun_color = Color("#ffb87a")
	sun_energy = 0.6
	fog = 0.02
	var stone := textured(Color("#231b18"), Color("#463830"), 1.0)
	# Lava under the whole stage, flowing slowly and glowing.
	var lava := textured(Color("#5a1204"), Color("#e8661a"), 5.0, 0.7, 0.6)
	_add(_slab(Vector3(_reach * 40, 0.1, _reach * 40), lava), _centre - Vector3(0, 0.6, 0))  # to every edge of the screen
	_anims.append(func(t: float):
		lava.uv1_offset = Vector3(t * 0.004, 0, t * 0.0025)
		lava.emission_energy_multiplier = 0.65 + 0.12 * sin(t * 0.7))
	# Stone pillars rising from the lava round the board.
	for k in 8:
		var at := _spot(TAU * k / 8.0 + 0.3, 1.2)
		var h := 2.2
		_add(_slab(Vector3(0.9, h + 0.6, 0.9), stone), at + Vector3(0, h / 2 - 0.6, 0))
		_add(_slab(Vector3(1.2, 0.3, 1.2), stone), at + Vector3(0, h - 0.15, 0))
	# Broken platforms of stone drifting very slowly in the lava.
	for k in 6:
		var at := _spot(_rng.randf() * TAU, _rng.randf_range(0.5, 2.0))
		var slab := _add(_slab(Vector3(_rng.randf_range(0.8, 1.6), 0.3, _rng.randf_range(0.6, 1.2)), stone), at - Vector3(0, 0.45, 0))
		slab.rotation = Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf() * TAU, _rng.randf_range(-0.08, 0.08))
		var phase := _rng.randf() * TAU
		var rest := slab.position
		_anims.append(func(t: float): slab.position = rest + Vector3(0, sin(t * 0.4 + phase) * 0.04, 0))
	# Rocky outcrops standing in the lava all over, glowing where the lava
	# meets them.
	var glow_rim := B._material(Color("#c84a10"), 0.5)
	for k in 36:  # spread over the whole sea, right up to the top of the view
		var at := _centre + Vector3(_rng.randf_range(-_reach * 1.8, _reach * 1.8), 0,
				_rng.randf_range(-_reach * 2.8, _reach * 0.9))
		var cluster := Node3D.new()
		_add(cluster, at - Vector3(0, 0.6, 0))
		for j in _rng.randi_range(2, 4):
			var h := _rng.randf_range(0.5, 2.0)
			var rock := B._cyl(_rng.randf_range(0.05, 0.25), _rng.randf_range(0.35, 0.8), h, Color.WHITE)
			(rock.mesh as CylinderMesh).radial_segments = 5
			rock.material_override = stone
			rock.position = Vector3(_rng.randf_range(-0.5, 0.5), h / 2, _rng.randf_range(-0.5, 0.5))
			rock.rotation = Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf() * TAU, _rng.randf_range(-0.25, 0.25))
			cluster.add_child(rock)
		var rim := B._cyl(0.55, 0.62, 0.05, Color.WHITE)
		rim.material_override = glow_rim
		rim.position.y = 0.06
		cluster.add_child(rim)
	_anims.append(func(t: float): glow_rim.emission_energy_multiplier = 0.45 + 0.15 * sin(t * 0.9))
	# Bubbles in the lava: each swells up slowly, pops with a ring spreading
	# out, and comes again a few seconds later.
	var bubble_m := B._material(Color("#ff7a20"), 1.2)
	for i in 26:
		var at := _centre + Vector3(_rng.randf_range(-_reach * 1.6, _reach * 1.6), -0.56,
				_rng.randf_range(-_reach * 2.4, _reach * 0.8))
		var bubble := _ball(1.0, Color.WHITE)
		bubble.material_override = bubble_m
		_add(bubble, at)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.9
		torus.outer_radius = 1.0
		ring.mesh = torus
		var ring_m := B._material(Color(1.0, 0.6, 0.2, 0.8), 1.4)
		ring_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = ring_m
		_add(ring, at)
		var size := _rng.randf_range(0.12, 0.3)
		var period := _rng.randf_range(2.5, 5.5)
		var offset := _rng.randf() * period
		_anims.append(func(t: float):
			var ph := fmod(t + offset, period) / period
			if ph < 0.8:  # swelling
				var k := ph / 0.8
				bubble.visible = true
				bubble.scale = Vector3(1, 0.7, 1) * size * k
				ring.visible = false
			else:  # popped: the ring spreads and fades
				var k := (ph - 0.8) / 0.2
				bubble.visible = false
				ring.visible = true
				ring.scale = Vector3(1, 0.3, 1) * size * (1.0 + k * 2.0)
				ring_m.albedo_color.a = 0.8 * (1.0 - k))
	# Embers drifting up from the lava and fading out, then starting again.
	for i in 30:
		var ember := _ball(_rng.randf_range(0.03, 0.06), Color.WHITE)
		var m := B._material(Color("#ffa040"), 1.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ember.material_override = m
		var base := _spot(_rng.randf() * TAU, _rng.randf_range(-3.0, 4.0)) - Vector3(0, 0.5, 0)
		_add(ember, base)
		var speed := _rng.randf_range(0.2, 0.45)
		var offset := _rng.randf() * 3.0
		var sway := _rng.randf() * TAU
		_anims.append(func(t: float):
			var k := fmod(t * speed + offset, 3.0)  # up to just under the board, then round again
			ember.position = base + Vector3(sin(t * 0.8 + sway) * 0.3, k, 0)
			m.albedo_color.a = clampf(1.0 - k / 3.0, 0.0, 1.0))


func _castle() -> void:
	sky = Color("#9fb4c4")
	shift_back = 0.65  # the courtyard centred under the board as seen
	ambient = Color("#c8d4de")
	ambient_energy = 0.38
	sun_energy = 0.8
	fog = 0.004
	var stone := textured(Color("#77706a"), Color("#a29a8e"), 1.2)
	var dark_stone := textured(Color("#5a544e"), Color("#7e766c"), 1.2)
	_ground(textured(Color("#5e5440"), Color("#7e7258"), 3.0))  # packed earth inside the walls
	frame_margin = 3.6  # room for the board once the view looks back (frame_back brings it closer)
	frame_back = 3.0  # looking further back: more of the army, less empty courtyard in front
	var hx := _half.x + 1.0
	var hz := _half.y + 1.0
	var front := hz + 9.0  # the courtyard runs on past the bottom of the screen: no front wall or moat in view
	# The moat outside the walls (behind and at the sides).
	var water := textured(Color("#2a3e48"), Color("#456470"), 2.5, 0.0, 0.2)
	_anims.append(func(t: float): water.uv1_offset = Vector3(t * 0.004, 0, 0))
	var deep := hz + front
	for side in [[Vector3(0, 0, -hz - 2.2), Vector3(hx * 2 + 7.0, 0.06, 2.4)],
			[Vector3(-hx - 2.2, 0, (front - hz) / 2), Vector3(2.4, 0.06, deep + 2.0)],
			[Vector3(hx + 2.2, 0, (front - hz) / 2), Vector3(2.4, 0.06, deep + 2.0)]]:
		_add(_slab(side[1], water), _centre + side[0] - Vector3(0, 0.08, 0))
	# Massive curtain walls with battlements: tall at the sides, low behind (so
	# the army outside the gate shows over it) and in front (out of view).
	_wall(Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), BACK_WALL, 1.0, stone)
	_wall(Vector3(-hx, 0, -hz), Vector3(-hx, 0, front), 3.0, 1.0, stone)
	_wall(Vector3(hx, 0, -hz), Vector3(hx, 0, front), 3.0, 1.0, stone)
	_wall(Vector3(-hx, 0, front), Vector3(hx, 0, front), 1.6, 0.9, stone)
	# Square towers at the corners.
	for c in [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(-hx, 0, front), Vector3(hx, 0, front)]:
		_square_tower(_centre + c, 2.2, 4.5 if c.z < 0 else 2.2, dark_stone)
	# The gatehouse in the back wall: round towers either side, a portcullis.
	var gate := _centre + Vector3(0, 0, -hz)
	for x in [-1.5, 1.5]:
		var tower := B._cyl(1.0, 1.05, 6.2, Color.WHITE)
		tower.material_override = dark_stone
		_add(tower, gate + Vector3(x, 3.1, 0.2))
		for k in 8:
			var a := TAU * k / 8.0
			_add(_slab(Vector3(0.35, 0.4, 0.35), dark_stone), gate + Vector3(x + cos(a) * 0.9, 6.4, 0.2 + sin(a) * 0.9))
	_add(B._box(Vector3(1.8, 2.6, 0.1), Color("#120e0c")), gate + Vector3(0, 1.3, 0.55))
	for k in 6:  # the portcullis
		_add(B._box(Vector3(0.05, 2.5, 0.05), Color("#3a3a3e")), gate + Vector3(-0.75 + k * 0.3, 1.3, 0.62))
	for k in 5:
		_add(B._box(Vector3(1.7, 0.05, 0.05), Color("#3a3a3e")), gate + Vector3(0, 0.3 + k * 0.5, 0.62))
	# The great keep behind, a flag on top.
	var keep := _centre + Vector3(0, 0, -hz - ARMY_DEPTH - 6.0)  # beyond the army
	_add(_slab(Vector3(6.0, 8.5, 4.5), dark_stone), keep + Vector3(0, 4.25, 0))
	_battlements(keep + Vector3(-3.0, 8.5, 2.25), keep + Vector3(3.0, 8.5, 2.25), dark_stone)
	for x in [-1.5, 0.0, 1.5]:
		for y in [3.0, 5.5]:
			_add(B._box(Vector3(0.18, 0.7, 0.05), Color("#141210")), keep + Vector3(x, y, 2.27))
	_flag(keep + Vector3(0, 8.5, 0), Color("#8e2420"))
	# Banners hanging still on the gatehouse towers.
	for x in [-1.5, 1.5]:
		var banner := Node3D.new()
		_add(banner, gate + Vector3(x, 5.6, 1.22))
		var cloth := B._box(Vector3(0.7, 2.2, 0.03), Color("#8e2420"))
		cloth.position.y = -1.1
		banner.add_child(cloth)
		var stripe := B._box(Vector3(0.16, 2.2, 0.035), Color("#c8a040"))
		stripe.position.y = -1.1
		banner.add_child(stripe)
	# Cannons along the walls, pointing out; one fires now and then.
	var cannons: Array[Node3D] = []
	for c in [[Vector3(-hx * 0.5, BACK_WALL, -hz - 0.1), PI], [Vector3(hx * 0.5, BACK_WALL, -hz - 0.1), PI],
			[Vector3(-hx - 0.1, 3.0, -hz * 0.3), -PI / 2], [Vector3(hx + 0.1, 3.0, -hz * 0.3), PI / 2],
			[Vector3(-hx - 0.1, 3.0, hz * 0.4), -PI / 2], [Vector3(hx + 0.1, 3.0, hz * 0.4), PI / 2]]:
		var cannon := _cannon()
		cannon.rotation.y = c[1]
		_add(cannon, _centre + c[0])
		cannons.append(cannon)
	_volleys(cannons, 6.0)
	# Catapults in the courtyard, under the board, each flinging now and then.
	for k in 3:
		var cat := _catapult()
		var at := _centre + Vector3((k - 1) * hx * 0.55, -0.1, -hz * 0.25 + (k % 2) * hz * 0.4)
		cat.rotation.y = PI + (k - 1) * 0.3
		_add(cat, at)
		var arm: Node3D = cat.get_meta("arm")
		var period := 7.0 + k * 1.3
		var offset := k * 2.2
		_anims.append(func(t: float):
			var ph := fmod(t + offset, period)
			if ph < 0.25:  # the throw
				arm.rotation.x = lerpf(-1.1, 0.6, ph / 0.25)
			else:  # winding back down
				arm.rotation.x = lerpf(0.6, -1.1, clampf((ph - 0.25) / (period * 0.6), 0.0, 1.0)))
	# Barrels, crates and haystacks about the courtyard.
	var wood := textured(Color("#4a3420"), Color("#6e5034"), 0.4)
	var hay := textured(Color("#a8883a"), Color("#d8b85a"), 0.3)
	for i in 24:
		var at := _centre + Vector3(_rng.randf_range(-hx + 1.0, hx - 1.0), 0, _rng.randf_range(-hz + 1.0, hz + 5.0))  # into the courtyard in front too
		match i % 3:
			0:
				var barrel := B._cyl(0.22, 0.22, 0.5, Color.WHITE)
				barrel.material_override = wood
				_add(barrel, at + Vector3(0, 0.15, 0))
			1:
				var crate := _add(_slab(Vector3(0.5, 0.5, 0.5), wood), at + Vector3(0, 0.15, 0))
				crate.rotation.y = _rng.randf() * PI
			_:
				var bale := B._cyl(0.35, 0.35, 0.6, Color.WHITE)
				bale.material_override = hay
				bale.rotation.z = PI / 2
				_add(bale, at + Vector3(0, 0.25, 0))
	# Soldiers patrolling the wall walks.
	for k in 6:
		var a: Vector3
		var b: Vector3
		var y: float
		match k % 3:
			0:
				a = Vector3(-hx + 1.5, 0, -hz)
				b = Vector3(hx - 1.5, 0, -hz)
				y = BACK_WALL
			1:
				a = Vector3(-hx, 0, -hz + 1.5)
				b = Vector3(-hx, 0, hz - 1.5)
				y = 3.0
			_:
				a = Vector3(hx, 0, -hz + 1.5)
				b = Vector3(hx, 0, hz - 1.5)
				y = 3.0
		_soldier(_centre + a + Vector3(0, y, 0), _centre + b + Vector3(0, y, 0), k)
	# An army camped outside, behind the castle at the top of the view.
	_army(hx, hz)
	# Trees beyond the moat.
	for i in 24:
		var side := -1.0 if i % 2 == 0 else 1.0
		_tree(_centre + Vector3(side * _rng.randf_range(hx + 5.0, hx + 13.0), 0,
				_rng.randf_range(-hz - 8.0, hz + 4.0)), _rng.randf_range(0.9, 1.5))


func _racing() -> void:
	sky = Color("#a9c2d4")
	shrink = 0.6  # everything smaller, more road in view
	ambient_energy = 0.38
	fog = 0.003
	_add(_slab(Vector3(_reach * 18, 0.1, _reach * 18), textured(Color("#2f5a2a"), Color("#3e6e34"), 4.0)),
			_centre - Vector3(0, 0.17, 0))  # the green baize under the set, wide enough once shrunk
	# Slot-car tracks running right across the scene, each well off the screen
	# at both ends, at three heights so they cross over one another: each a
	# run of points [position, up] the track is laid along and the cars follow.
	var far := _reach * 5.5  # how far past the board each track runs (off screen, shrunk)
	var hx := _half.x
	var hz := _half.y
	var tracks: Array = []
	# The main straight, under the board, along x on the ground.
	tracks.append(_track_path(func(u: float) -> Vector3:
		return _centre + Vector3(lerpf(-far, far, u), 0.0, -0.2)))
	# An S-bend sweeping across the front, on the ground.
	tracks.append(_track_path(func(u: float) -> Vector3:
		return _centre + Vector3(lerpf(far, -far, u), 0.0, hz * 0.85 + sin(u * TAU * 2.0) * 1.2)))
	# Two flyovers front to back, over the ground tracks.
	for x in [-hx * 0.45, hx * 0.45]:
		tracks.append(_track_path(func(u: float) -> Vector3:
			return _centre + Vector3(x + sin(u * TAU) * 0.8, 0.8, lerpf(far, -far, u))))
	# The high flyover, sweeping across over everything in big S-curves.
	tracks.append(_track_path(func(u: float) -> Vector3:
		var d := lerpf(-far, far, u)
		return _centre + Vector3(d, 1.6 + sin(u * TAU * 3.0) * 0.15, d * 0.3 + sin(u * TAU * 1.5) * hz * 0.9)))
	for track in tracks:
		_lay_track(track)
	# A haze between the board and the tracks, so they sit back softly behind
	# it, lighter and lower in contrast (the board itself is above it).
	var haze := MeshInstance3D.new()
	var sheet := PlaneMesh.new()
	sheet.size = Vector2.ONE * _reach * 30
	haze.mesh = sheet
	var haze_m := StandardMaterial3D.new()
	haze_m.albedo_color = Color(0.88, 0.92, 0.95, RACING_HAZE)
	haze_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	haze.material_override = haze_m
	_add(haze, _centre + Vector3(0, (drop - 0.5) / shrink, 0))  # just under the board
	# A start gantry over the main straight, with its lights.
	var start := _centre + Vector3(-hx * 0.75, 0, -0.2)
	for z in [-0.95, 0.95]:
		_add(B._box(Vector3(0.1, 1.5, 0.1), Color("#c8c8d0")), start + Vector3(0, 0.75, z))
	_add(B._box(Vector3(0.2, 0.3, 2.1), Color("#202028")), start + Vector3(0, 1.5, 0))
	for k in 5:
		var lamp := _ball(0.06, Color.WHITE)
		lamp.material_override = B._material(Color("#e8302a"), 1.6)
		_add(lamp, start + Vector3(0.11, 1.5, -0.6 + k * 0.3))
	for i in 8:  # the chequered line
		for j in 2:
			_add(B._box(Vector3(0.18, 0.03, 0.18), Color("#151515") if (i + j) % 2 == 0 else Color("#ecece8")),
					start + Vector3(0.09 * j - 0.04, 0.05, -0.63 + i * 0.18))
	# Formula One cars in team colours, two to a track in their own slots, each
	# at its own pace; off one end of the screen and back on at the other.
	var teams := [Color("#d8201c"), Color("#1c3ac8"), Color("#e8b020"), Color("#20a060"), Color("#ececec"),
			Color("#e86a10"), Color("#7a2ac8"), Color("#151515"), Color("#18a8c8"), Color("#c81870")]
	for i in teams.size():
		var track: Array = tracks[i % tracks.size()]
		var car := _f1_car(teams[i])
		_add(car, Vector3.ZERO)
		var lane := 0.32 if i < tracks.size() else -0.32
		var pace := _rng.randf_range(0.035, 0.07)  # of the track a second
		var offset := _rng.randf()
		_anims.append(func(t: float): _ride(car, track, fposmod(t * pace + offset, 1.0), lane))


## A track's points along `at` (u from 0 to 1 -> position), level, closely
## enough spaced for smooth climbs.
func _track_path(at: Callable) -> Array:
	var pts: Array = []
	for k in TRACK_POINTS + 1:
		pts.append([at.call(k / float(TRACK_POINTS)), Vector3.UP])
	return pts


## Carries `car` to `along` (0..1) of the way along `track`, `lane` across
## from the middle, upright on the track and pointing along it.
func _ride(car: Node3D, track: Array, along: float, lane: float) -> void:
	var f := along * (track.size() - 1)
	var i := mini(int(f), track.size() - 2)
	var k := f - i
	var a: Array = track[i]
	var b: Array = track[i + 1]
	var up: Vector3 = (a[1] as Vector3).lerp(b[1], k).normalized()
	var ahead: Vector3 = (b[0] - a[0]).normalized()
	var side := ahead.cross(up).normalized()
	car.position = (a[0] as Vector3).lerp(b[0], k) + side * lane + up * 0.06
	car.basis = Basis(ahead, up, -side)  # cars face +x


## Lays a slot-car track along `track`: grey track with two slots, red and
## white edges, and posts under it where it is lifted.
func _lay_track(track: Array) -> void:
	var surface := textured(Color("#3a3a40"), Color("#4a4a52"), 0.6, 0.0, 0.6)
	for i in track.size() - 1:
		var p0: Vector3 = track[i][0]
		var p1: Vector3 = track[i + 1][0]
		var up: Vector3 = ((track[i][1] as Vector3) + track[i + 1][1]).normalized()
		var ahead := (p1 - p0).normalized()
		var side := ahead.cross(up).normalized()
		var holder := Node3D.new()
		holder.basis = Basis(side, up, -ahead)
		_add(holder, (p0 + p1) / 2)
		var length := p0.distance_to(p1) + 0.02
		holder.add_child(_slab(Vector3(1.3, 0.06, length), surface))
		for x in [-0.32, 0.32]:  # the slots
			var slot := B._box(Vector3(0.03, 0.065, length), Color("#141416"))
			slot.position.x = x
			holder.add_child(slot)
		for x in [-0.66, 0.66]:  # the edges
			var edge := B._box(Vector3(0.06, 0.09, length), Color("#c86a64") if i % 2 == 0 else Color("#e8e6e0"))
			edge.position.x = x
			holder.add_child(edge)
		if p0.y > 0.4 and i % 4 == 0:  # posts under a raised stretch
			_add(B._box(Vector3(0.12, p0.y, 0.12), Color("#b0b0b8")), Vector3(p0.x, p0.y / 2, p0.z))


## A Formula One car `colour`, nose to +x: a slim body and nose cone, the
## cockpit and halo, wide front and rear wings, four open wheels.
func _f1_car(colour: Color) -> Node3D:
	var car := Node3D.new()
	var add := func(node: Node3D, at: Vector3) -> void:
		node.position = at
		car.add_child(node)
	add.call(B._box(Vector3(0.95, 0.09, 0.22), colour), Vector3(0, 0.1, 0))  # the body
	var nose := B._cyl(0.02, 0.07, 0.4, Color.WHITE)
	nose.material_override = B._material(colour)
	nose.rotation.z = -PI / 2
	add.call(nose, Vector3(0.62, 0.09, 0))
	for z in [-0.17, 0.17]:  # sidepods
		add.call(B._box(Vector3(0.45, 0.08, 0.12), colour.darkened(0.15)), Vector3(-0.05, 0.09, z))
	add.call(B._box(Vector3(0.18, 0.07, 0.12), Color("#141418")), Vector3(0.05, 0.17, 0))  # cockpit
	var helmet := _ball(0.045, Color("#f0d020"))
	add.call(helmet, Vector3(0.04, 0.2, 0))
	var halo := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.06
	torus.outer_radius = 0.075
	halo.mesh = torus
	halo.material_override = B._material(Color("#1a1a1e"))
	halo.scale = Vector3(1.2, 1, 1)
	add.call(halo, Vector3(0.06, 0.22, 0))
	add.call(B._box(Vector3(0.08, 0.02, 0.5), colour.darkened(0.35)), Vector3(0.82, 0.04, 0))  # front wing
	add.call(B._box(Vector3(0.1, 0.03, 0.42), colour.darkened(0.35)), Vector3(-0.5, 0.26, 0))  # rear wing
	for z in [-0.18, 0.18]:
		add.call(B._box(Vector3(0.1, 0.16, 0.02), colour.darkened(0.35)), Vector3(-0.5, 0.18, z))
	for x in [-0.36, 0.42]:
		for z in [-0.24, 0.24]:
			var wheel := B._cyl(0.1, 0.1, 0.1, Color("#141416"))
			wheel.rotation.x = PI / 2
			add.call(wheel, Vector3(x, 0.1, z))
	return car


func _storm() -> void:
	sky = Color("#2a323c")
	ambient = Color("#8e9aa8")
	ambient_energy = 0.36
	sun_color = Color("#c8d0dc")
	sun_energy = 0.45
	fog = 0.012
	# Heavy storm clouds below the board, drifting slowly.
	var dark := textured(Color("#2c3138"), Color("#56606a"), 2.0)
	var mid := textured(Color("#3c434c"), Color("#6c7680"), 2.0)
	for m in [dark, mid]:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1, 1, 1, 0.93)
	_clouds(26, -6.0, -1.0, [dark, mid], 0.35)
	# A low dark layer far below, so there is never bare sky under the board.
	var floor_m := textured(Color("#1e2228"), Color("#353c44"), 5.0)
	_add(_slab(Vector3(_reach * 9, 0.1, _reach * 9), floor_m), _centre - Vector3(0, 9.0, 0))
	_anims.append(func(t: float): floor_m.uv1_offset = Vector3(t * 0.003, 0, 0))
	# The weather turns every WEATHER_SPELL seconds: rain, then hail, then
	# snow, fading from one to the next.
	var rain_m := B._material(Color(0.78, 0.84, 0.9, 0.35))
	var hail_m := B._material(Color(0.9, 0.94, 1.0, 0.9))
	var snow_m := B._material(Color(1.0, 1.0, 1.0, 0.9))
	for m in [rain_m, hail_m, snow_m]:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var kinds := [  # [material, size, fall speed, sway, count]
		[rain_m, Vector3(0.012, 0.45, 0.012), 7.0, 0.0, 170],
		[hail_m, Vector3(0.05, 0.05, 0.05), 5.0, 0.05, 110],
		[snow_m, Vector3(0.05, 0.05, 0.05), 0.9, 0.5, 160],
	]
	for kind in kinds:
		for i in kind[4]:
			var bit := B._box(kind[1], Color.WHITE)
			bit.material_override = kind[0]
			var x := _centre.x + _rng.randf_range(-_reach * 1.6, _reach * 1.6)
			var z := _centre.z + _rng.randf_range(-_reach * 1.6, _reach * 1.2)
			var y0 := _rng.randf() * 10.0
			var phase := _rng.randf() * TAU
			_add(bit, Vector3(x, 0, z))
			var speed: float = kind[2]
			var sway: float = kind[3]
			_anims.append(func(t: float):
				bit.position = Vector3(x + sin(t * 0.8 + phase) * sway, 2.2 - fmod(y0 + t * speed, 10.0), z))
	_anims.append(func(t: float):  # which weather now, crossfading
		var spell := t / WEATHER_SPELL
		var now := int(spell) % 3
		var k := clampf((fmod(spell, 1.0) - 0.85) / 0.15, 0.0, 1.0)  # the last 15% fades to the next
		var alphas := [0.0, 0.0, 0.0]
		alphas[now] = 1.0 - k
		alphas[(now + 1) % 3] = k
		rain_m.albedo_color.a = 0.35 * alphas[0]
		hail_m.albedo_color.a = 0.9 * alphas[1]
		snow_m.albedo_color.a = 0.9 * alphas[2])
	# Lightning flickering inside the clouds now and then.
	var flash := OmniLight3D.new()
	flash.light_color = Color("#dce6ff")
	flash.omni_range = 14.0
	flash.light_energy = 0.0
	flash.shadow_enabled = false
	_add(flash, _centre)
	var period := 9.0
	var heard := [-1]  # the last flash whose thunder has been played
	_anims.append(func(t: float):
		var cycle := floorf(t / period)
		var phase := fmod(t, period)
		if phase > THUNDER_DELAY and heard[0] != int(cycle):
			heard[0] = int(cycle)
			thunder.emit()
		var r := RandomNumberGenerator.new()
		r.seed = int(cycle) * 4813
		if phase < 0.05:
			flash.position = _centre + Vector3(r.randf_range(-_reach, _reach), -3.5, r.randf_range(-_reach, _reach))
		var e := 0.0
		if phase < 0.08:
			e = 3.0
		elif phase > 0.16 and phase < 0.22:
			e = 2.0
		elif phase < 0.6:
			e = maxf(0.0, 1.2 - phase * 2.0)
		flash.light_energy = e)


# --- pieces ---------------------------------------------------------------

func _add(node: Node3D, at: Vector3) -> Node3D:
	node.position = at
	add_child(node)
	return node


## A box with material `m`.
func _slab(size: Vector3, m: Material) -> MeshInstance3D:
	var mi := B._box(size, Color.WHITE)
	if m:
		mi.material_override = m
	return mi


## A big ground plane under everything.
func _ground(m: Material) -> void:
	_add(_slab(Vector3(_reach * 9, 0.1, _reach * 9), m), _centre - Vector3(0, 0.17, 0))


## A spot outside the board, `out` beyond its edge in direction `angle`.
func _spot(angle: float, out: float) -> Vector3:
	var dir := Vector2.from_angle(angle)
	var edge := minf(_half.x / maxf(absf(dir.x), 0.01), _half.y / maxf(absf(dir.y), 0.01))
	return _centre + Vector3(dir.x, 0, dir.y) * (edge + out)


func _ball(r: float, colour: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2
	mi.mesh = mesh
	mi.material_override = B._material(colour)
	return mi


## The sea's height at x, z now (the same waves as the shader).
func _wave_height(x: float, z: float) -> float:
	var h := 0.0
	for w in WAVES:
		h += w[0] * wave_scale * sin(x * w[1] + z * w[2] + _time * w[3])
	return h


## How much the sea slopes at x, z: (pitch about x, roll about z).
func _tilt(x: float, z: float) -> Vector2:
	return Vector2((_wave_height(x, z + 0.6) - _wave_height(x, z - 0.6)) * 0.35,
			(_wave_height(x - 0.6, z) - _wave_height(x + 0.6, z)) * 0.35)


## Keeps `node` riding the waves at `at`, turned `heading` about y.
func _float(node: Node3D, at: Vector3, heading: float) -> void:
	_add(node, at)
	_anims.append(func(_t: float):
		var tilt := _tilt(at.x, at.z)
		node.position = Vector3(at.x, _wave_height(at.x, at.z) * 0.7 - 0.15 * node.scale.y, at.z)
		node.rotation = Vector3(tilt.x, heading, tilt.y))


## A three-masted pirate ship, bow to +x: a rounded wooden hull (a long
## capsule, its top cut level by the deck) with a raised stern castle,
## planking, a bowsprit, round gun ports, masts with billowing `sail` sails
## and a crow's nest, a `flag` flag at the top.
func _ship(sail: Color, flag: Color) -> Node3D:
	var ship := Node3D.new()
	var hull_m := textured(Color("#2c1d12"), Color("#54381f"), 0.35)
	var deck_m := textured(Color("#6a4a2c"), Color("#8e6a42"), 0.3)
	var trim := B._material(Color("#a8822a"))
	var add := func(node: Node3D, at: Vector3) -> Node3D:
		node.position = at
		ship.add_child(node)
		return node
	# The hull: a capsule lying along x, flattened into a boat's belly.
	var hull := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.55
	capsule.height = 3.6
	capsule.radial_segments = 24
	capsule.rings = 8
	hull.mesh = capsule
	hull.material_override = hull_m
	hull.rotation.z = PI / 2
	hull.scale = Vector3(0.8, 1, 1)  # shallower than it is wide
	add.call(hull, Vector3(0, 0.15, 0))
	# Bulwarks round the deck, following the hull's curve.
	var deck := _ball(0.5, Color.WHITE)
	deck.material_override = deck_m
	deck.scale = Vector3(3.1, 0.05, 0.92)
	add.call(deck, Vector3(0, 0.56, 0))
	for k in 24:  # the rail, a ring of posts and a band
		var a := TAU * k / 24.0
		var p := Vector3(cos(a) * 1.55, 0.66, sin(a) * 0.46)
		add.call(B._cyl(0.02, 0.02, 0.16, Color("#3a2614")), p)
	var band := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.98
	torus.outer_radius = 1.02
	band.mesh = torus
	band.material_override = trim
	band.scale = Vector3(1.55, 1, 0.47)
	add.call(band, Vector3(0, 0.73, 0))
	# The stern castle: a rounded block on the stern with gold trim and windows.
	var castle := _ball(0.5, Color.WHITE)
	castle.material_override = hull_m
	castle.scale = Vector3(0.9, 0.7, 0.95)
	add.call(castle, Vector3(-1.35, 0.75, 0))
	for z in [-0.18, 0.0, 0.18]:
		var window := _ball(0.05, Color.WHITE)
		window.material_override = B._material(Color("#ffd880"), 0.8)
		add.call(window, Vector3(-1.78, 0.8, z))
	# Round gun ports along both sides.
	for k in 6:
		for side in [-1, 1]:
			var port := B._cyl(0.06, 0.06, 0.02, Color("#0c0806"))
			port.rotation.x = PI / 2
			add.call(port, Vector3(-0.9 + k * 0.38, 0.32, side * 0.5))
	# The bowsprit, raking forward.
	var sprit := B._cyl(0.02, 0.035, 1.2, Color.WHITE)
	sprit.material_override = hull_m
	sprit.rotation.z = -1.2
	add.call(sprit, Vector3(2.15, 0.75, 0))
	# Masts, yards and billowing sails; a crow's nest on the main mast.
	for k in 3:
		var x: float = [-0.65, 0.35, 1.25][k]
		var h: float = [1.35, 1.55, 1.15][k]  # short, so a big ship stays under the board
		var mast := B._cyl(0.035, 0.05, h, Color.WHITE)
		mast.material_override = hull_m
		add.call(mast, Vector3(x, 0.56 + h / 2, 0))
		for s in 2:
			var tall := h * 0.32
			var sail_m := textured(sail.darkened(0.12), sail, 0.6)
			var cloth := _ball(0.5, Color.WHITE)  # half a flattened ball: a sail filled with wind
			cloth.material_override = sail_m
			cloth.scale = Vector3(0.22, tall, 0.95 - s * 0.18)
			add.call(cloth, Vector3(x + 0.06, 0.56 + h * (0.42 + s * 0.33), 0))
			var yard := B._cyl(0.018, 0.018, 1.0 - s * 0.18, Color.WHITE)
			yard.material_override = hull_m
			yard.rotation.x = PI / 2
			add.call(yard, Vector3(x, 0.56 + h * (0.42 + s * 0.33) + tall / 2, 0))
		if k == 1:
			add.call(B._cyl(0.12, 0.09, 0.1, Color("#3a2614")), Vector3(x, 0.56 + h * 0.97, 0))
	var pennant := Node3D.new()
	add.call(pennant, Vector3(0.38, 2.14, 0))
	var cloth := B._box(Vector3(0.4, 0.22, 0.02), flag)
	cloth.position.x = -0.2
	pennant.add_child(cloth)
	return ship


## One fish leaping out of the still water every now and then (10 to 20
## seconds apart), somewhere new round the board each time, with a splash
## where it goes in.
func _leaping_fish() -> void:
	var fish := _fish(Color("#c0c8d0"))
	fish.scale = Vector3.ONE * 2.2  # big enough to see from up here
	_add(fish, _centre)
	fish.visible = false
	var splash := _ball(0.5, Color(0.92, 0.97, 1.0))
	_add(splash, _centre)
	splash.visible = false
	var leap := 1.1  # seconds in the air
	# Kept in a dictionary: a lambda's captured locals are copies, so plain
	# variables would be back to their first values on the next frame.
	var first := _rng.randf() * TAU
	var jump := {"start": _rng.randf_range(4.0, 10.0), "at": _centre + Vector3(cos(first), 0, sin(first) * 0.8) * _reach * 0.9,
		"way": Vector3(sin(first + 1.2), 0, cos(first + 1.2)),
		"length": 3.0, "high": 1.6}
	_anims.append(func(t: float):
		var k: float = t - float(jump.start)
		if k > leap + 0.6:  # done: the next one, later and somewhere else
			jump.start = t + _rng.randf_range(10.0, 20.0)
			var a := _rng.randf() * TAU
			var r := _rng.randf_range(_reach * 0.55, _reach * 1.3)
			jump.at = _centre + Vector3(cos(a) * r, 0, sin(a) * r * 0.8)
			var turn := _rng.randf() * TAU
			jump.way = Vector3(sin(turn), 0, cos(turn))
			jump.length = _rng.randf_range(2.4, 3.6)
			jump.high = _rng.randf_range(1.2, 2.0)
			k = t - float(jump.start)
		var at: Vector3 = jump.at
		var way: Vector3 = jump.way
		var length: float = jump.length
		fish.visible = k >= 0.0 and k < leap
		if fish.visible:
			var u := k / leap
			var p := at + way * (u - 0.5) * length
			fish.position = Vector3(p.x, _wave_height(p.x, p.z) - 0.1 + sin(u * PI) * float(jump.high), p.z)
			fish.rotation = Vector3(-(1.0 - 2.0 * u) * 1.1, atan2(way.x, way.z), 0)
		var s := k - leap  # the splash, spreading as it fades after going in
		splash.visible = s >= -leap * 0.15 and s < 0.5
		if splash.visible:
			var e := at + way * length * 0.5
			var g := clampf((s + leap * 0.15) / 0.65, 0.0, 1.0)
			splash.position = Vector3(e.x, _wave_height(e.x, e.z) + 0.02, e.z)
			splash.scale = Vector3(0.4 + g * 1.4, 0.08 * (1.0 - g), 0.4 + g * 1.4))


## A fish facing +z in `colour`: a long body, a paler belly, a forked tail.
func _fish(colour: Color) -> Node3D:
	var fish := Node3D.new()
	var body := _ball(0.18, colour)
	body.scale = Vector3(0.45, 0.8, 1.6)
	fish.add_child(body)
	var belly := _ball(0.15, colour.lightened(0.45))
	belly.scale = Vector3(0.4, 0.5, 1.4)
	belly.position.y = -0.04
	fish.add_child(belly)
	for side in [-1, 1]:  # the forked tail
		var lobe := B._box(Vector3(0.02, 0.16, 0.14), colour.darkened(0.15))
		lobe.position = Vector3(0, side * 0.06, -0.33)
		lobe.rotation.x = side * 0.5
		fish.add_child(lobe)
	return fish


## A seagull flying towards +z: a white body and head, a yellow beak, and two
## grey-tipped wings on hinges (its metas "left" and "right") so they flap.
func _seagull() -> Node3D:
	var gull := Node3D.new()
	var body := _ball(0.12, Color("#f4f4f2"))
	body.scale = Vector3(0.8, 0.7, 1.6)
	gull.add_child(body)
	var head := _ball(0.07, Color("#f8f8f6"))
	head.position = Vector3(0, 0.05, 0.2)
	gull.add_child(head)
	var beak := B._cyl(0.0, 0.025, 0.08, Color("#e8b020"))
	beak.rotation.x = PI / 2
	beak.position = Vector3(0, 0.04, 0.29)
	gull.add_child(beak)
	for side in [-1, 1]:
		var hinge := Node3D.new()
		hinge.position = Vector3(side * 0.06, 0.03, 0)
		gull.add_child(hinge)
		var wing := B._box(Vector3(0.38, 0.015, 0.14), Color("#e8e8ea"))
		wing.position.x = side * 0.19
		hinge.add_child(wing)
		var tip := B._box(Vector3(0.1, 0.016, 0.12), Color("#3a3a40"))
		tip.position.x = side * 0.36
		hinge.add_child(tip)
		gull.set_meta("left" if side < 0 else "right", hinge)
	return gull


## `from` fires at `to` every `period` seconds, starting `offset` in: a flash
## at its side, a puff of smoke drifting off, a ball arcing over, a splash
## beside the target.
func _cannon_fire(from: Node3D, to: Node3D, offset: float, period: float) -> void:
	var flash := _ball(0.25, Color.WHITE)
	flash.material_override = B._material(Color("#ffd080"), 3.0)
	var smoke := _ball(0.4, Color.WHITE)
	var smoke_m := B._material(Color(0.75, 0.75, 0.72, 0.0))
	smoke_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.material_override = smoke_m
	var ball := _ball(0.07, Color("#151515"))
	var splash := B._cyl(0.12, 0.25, 1.0, Color.WHITE)
	var splash_m := B._material(Color(0.9, 0.95, 0.97, 0.8))
	splash_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splash.material_override = splash_m
	for n in [flash, smoke, ball, splash]:
		add_child(n)
		n.visible = false
	_anims.append(func(t: float):
		var phase := fmod(t + offset, period)
		var toward := (to.position - from.position)
		toward.y = 0
		var muzzle := from.position + toward.normalized() * 0.55 * from.scale.x + Vector3(0, 0.35 * from.scale.x, 0)
		var target := to.position - toward.normalized() * 1.0 * to.scale.x
		flash.visible = phase < 0.12
		flash.position = muzzle
		smoke.visible = phase < 3.0
		if smoke.visible:
			smoke.position = muzzle + Vector3(0, phase * 0.25, 0) + toward.normalized() * phase * 0.2
			smoke.scale = Vector3.ONE * (0.6 + phase * 0.8)
			smoke_m.albedo_color.a = 0.7 * (1.0 - phase / 3.0)
		ball.visible = phase < 1.2
		if ball.visible:
			var k := phase / 1.2
			ball.position = muzzle.lerp(target, k) + Vector3(0, sin(k * PI) * 2.0, 0)
		splash.visible = phase > 1.2 and phase < 2.0
		if splash.visible:
			var k := (phase - 1.2) / 0.8
			splash.position = Vector3(target.x, 0.2 + sin(k * PI) * 0.4, target.z)
			splash.scale = Vector3(1, sin(k * PI) + 0.01, 1))


## A planet `r` across between two shades, turning slowly; `ringed` gives it a
## ring.
func _planet(at: Vector3, r: float, dark: Color, light: Color, ringed: bool, spin: float) -> MeshInstance3D:
	var planet := _ball(r, Color.WHITE)
	planet.material_override = textured(dark, light, r * 0.7)
	_add(planet, at)
	if ringed:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r * 1.3
		torus.outer_radius = r * 1.65
		ring.mesh = torus
		var ring_m := textured(Color("#8a7a5a"), Color("#d0c098"), 1.0)
		ring_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_m.albedo_color = Color(1, 1, 1, 0.7)
		ring.material_override = ring_m
		ring.scale = Vector3(1, 0.03, 1)
		ring.rotation = Vector3(0.4, 0, 0.25)
		planet.add_child(ring)
	_anims.append(func(t: float): planet.rotation.y = t * spin)
	return planet


## A stone curtain wall from `a` to `b` (offsets from the board's centre),
## `height` tall and `thick` thick, with battlements along its top.
func _wall(a: Vector3, b: Vector3, height: float, thick: float, m: Material) -> void:
	var length := a.distance_to(b)
	var wall := _add(_slab(Vector3(thick, height, length), m), _centre + (a + b) / 2 + Vector3(0, height / 2 - 0.05, 0))
	wall.rotation.y = atan2(b.x - a.x, b.z - a.z)
	_battlements(_centre + a + Vector3(0, height, 0), _centre + b + Vector3(0, height, 0), m)


## Merlons along a wall top from `a` to `b`.
func _battlements(a: Vector3, b: Vector3, m: Material) -> void:
	var dir := (b - a).normalized()
	for k in int(a.distance_to(b) / 0.7):
		var merlon := _add(_slab(Vector3(0.6, 0.45, 0.4), m), a + dir * (0.35 + k * 0.7) + Vector3(0, 0.2, 0))
		merlon.rotation.y = atan2(dir.x, dir.z)


## A square tower `size` across standing on `base`, `height` tall, with
## battlements and arrow slits.
func _square_tower(base: Vector3, size: float, height: float, m: Material) -> void:
	_add(_slab(Vector3(size, height, size), m), base + Vector3(0, height / 2, 0))
	var h := size / 2
	for edge in [[Vector3(-h, 0, -h), Vector3(h, 0, -h)], [Vector3(-h, 0, h), Vector3(h, 0, h)],
			[Vector3(-h, 0, -h), Vector3(-h, 0, h)], [Vector3(h, 0, -h), Vector3(h, 0, h)]]:
		_battlements(base + edge[0] + Vector3(0, height, 0), base + edge[1] + Vector3(0, height, 0), m)
	for y in range(1, int(height / 1.6)):
		for face in [Vector3(0, 0, h + 0.01), Vector3(h + 0.01, 0, 0), Vector3(-h - 0.01, 0, 0)]:
			_add(B._box(Vector3(0.08, 0.5, 0.08), Color("#141210")), base + face + Vector3(0, y * 1.6, 0))


## A flag on a pole standing on `top`, stirring in the wind.
func _flag(top: Vector3, colour: Color) -> void:
	_add(B._box(Vector3(0.06, 1.6, 0.06), Color("#8a8a90")), top + Vector3(0, 0.8, 0))
	var flag := Node3D.new()
	_add(flag, top + Vector3(0.03, 1.35, 0))
	var cloth := B._box(Vector3(1.0, 0.6, 0.02), colour)
	cloth.position.x = 0.5
	flag.add_child(cloth)
	var phase := _rng.randf() * TAU
	_anims.append(func(t: float): flag.rotation.y = sin(t * 1.4 + phase) * 0.25)


## A wooden catapult on wheels, throwing towards -z: a frame, uprights, and
## an arm with a sling cup (its meta "arm", pivoted to swing about x).
func _catapult() -> Node3D:
	var cat := Node3D.new()
	var wood := textured(Color("#4a3420"), Color("#6e5034"), 0.4)
	for x in [-0.3, 0.3]:
		var rail := _slab(Vector3(0.1, 0.12, 1.4), wood)
		rail.position = Vector3(x, 0.2, 0)
		cat.add_child(rail)
		var post := _slab(Vector3(0.1, 0.8, 0.1), wood)
		post.position = Vector3(x, 0.6, -0.2)
		cat.add_child(post)
		for z in [-0.55, 0.55]:
			var wheel := B._cyl(0.17, 0.17, 0.06, Color.WHITE)
			wheel.material_override = wood
			wheel.rotation.z = PI / 2
			wheel.position = Vector3(x * 1.25, 0.17, z)
			cat.add_child(wheel)
	var cross := _slab(Vector3(0.7, 0.1, 0.1), wood)
	cross.position = Vector3(0, 0.95, -0.2)
	cat.add_child(cross)
	var arm := Node3D.new()
	arm.position = Vector3(0, 0.45, 0.1)
	cat.add_child(arm)
	var beam := _slab(Vector3(0.08, 0.08, 1.2), wood)
	beam.position.z = 0.5
	arm.add_child(beam)
	var cup := B._cyl(0.14, 0.08, 0.1, Color("#3a2a1a"))
	cup.position = Vector3(0, 0.05, 1.1)
	arm.add_child(cup)
	var stone := _ball(0.1, Color("#6a6660"))
	stone.position = Vector3(0, 0.14, 1.1)
	arm.add_child(stone)
	arm.rotation.x = -1.1
	cat.set_meta("arm", arm)
	return cat


## A great army drawn up outside the castle's back gate, filling the ground
## from the moat to the keep: ranks of soldiers with spears and shields in
## companies of their own colours, an aisle up the middle to the drawbridge,
## standard bearers and knights on horseback at the front, siege cannons,
## tents at the back. Standard flags stir; everyone else stands.
func _army(hx: float, hz: float) -> void:
	var companies := [Color("#2a4a8a"), Color("#4a6a2a"), Color("#6a2a6a"), Color("#8a6a1a")]
	var canvas := textured(Color("#b8ac90"), Color("#d8ccb0"), 0.6)
	var gate := _centre + Vector3(0, 0, -hz)
	# The drawbridge across the moat.
	_add(_slab(Vector3(1.6, 0.1, 2.6), textured(Color("#4a3420"), Color("#6e5034"), 0.5)), gate + Vector3(0, -0.04, -2.2))
	var front := -hz - 3.8
	var width := hx + 3.0
	var rows := 9
	var spots: Array = []  # [position, company colour]
	for row in rows:
		var z := front - row * (ARMY_DEPTH / rows)
		var x := -width
		while x <= width:
			if absf(x) > 1.0:  # leave the aisle to the gate clear
				var colour: Color = companies[int((x + width) / (width * 2.0) * companies.size()) % companies.size()]
				spots.append([_centre + Vector3(x + (row % 2) * 0.25, 0, z), colour])
			x += 0.55
	_ranks(spots)
	# At the front: standard bearers and knights on horseback either side of the aisle.
	for side in [-1, 1]:
		for k in 3:
			var at := _centre + Vector3(side * (1.6 + k * 2.4), 0, front + 1.0)
			_add(_knight(companies[k % companies.size()]), at)
			var pole := at + Vector3(side * 0.7, 0, 0)
			_add(B._cyl(0.02, 0.02, 2.4, Color("#5a3a1a")), pole + Vector3(0, 1.2, 0))
			var flag := Node3D.new()
			_add(flag, pole + Vector3(0.02, 2.15, 0))
			var cloth := B._box(Vector3(0.8, 0.5, 0.02), companies[k % companies.size()])
			cloth.position.x = 0.4
			flag.add_child(cloth)
			var phase := _rng.randf() * TAU
			_anims.append(func(t: float): flag.rotation.y = sin(t * 1.3 + phase) * 0.25)
		for k in 2:  # siege cannons aimed at the gate
			var cannon := _cannon()
			cannon.scale = Vector3.ONE * 1.5
			_add(cannon, _centre + Vector3(side * (2.6 + k * 4.0), 0, front + 0.3))
	# Tents at the back of the camp.
	for k in 9:
		var tent := B._cyl(0.0, 0.9, 1.4, Color.WHITE)
		(tent.mesh as CylinderMesh).radial_segments = 8
		tent.material_override = canvas
		var x := lerpf(-width, width, k / 8.0)
		if absf(x) < 2.5:
			continue
		_add(tent, _centre + Vector3(x, 0.7, front - ARMY_DEPTH - 0.8))


## Foot soldiers standing at `spots` ([position, tabard colour] each), facing
## the castle: drawn as one MultiMesh per body part (legs, body, arms, head,
## helmet, spear, its tip, shield), each soldier one instance coloured as it
## should be, so hundreds of them cost only a few draws.
func _ranks(spots: Array) -> void:
	const S := 1.4  # the same size as the figures elsewhere
	var skin := Color("#f1c9a5")
	var parts := [  # [mesh, offset, colour ("tabard" = the soldier's), scale]
		[_capsule(0.035, 0.2), Vector3(-0.045, 0.1, 0), Color("#2f3140"), Vector3.ONE],
		[_capsule(0.035, 0.2), Vector3(0.045, 0.1, 0), Color("#2f3140"), Vector3.ONE],
		[_capsule(0.085, 0.24), Vector3(0, 0.3, 0), "tabard", Vector3.ONE],
		[_capsule(0.028, 0.18), Vector3(-0.11, 0.31, 0), "tabard", Vector3.ONE],
		[_capsule(0.028, 0.18), Vector3(0.11, 0.31, 0), "tabard", Vector3.ONE],
		[_sphere(0.065), Vector3(0, 0.47, 0), skin, Vector3.ONE],
		[_sphere(0.088), Vector3(0, 0.545, 0), Color("#7a7a82"), Vector3(1, 0.8, 1)],
		[_rod(0.008, 0.008, 0.8), Vector3(0.14, 0.45, 0), Color("#6a4a2a"), Vector3.ONE],
		[_rod(0.0, 0.02, 0.07), Vector3(0.14, 0.88, 0), Color("#c0c0c8"), Vector3.ONE],
		[_rod(0.09, 0.09, 0.02), Vector3(-0.12, 0.32, 0.06), "shield", Vector3.ONE],
	]
	for part in parts:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = part[0]
		mm.instance_count = spots.size()
		var turn := Basis(Vector3.RIGHT, PI / 2) if part[2] is String and part[2] == "shield" else Basis.IDENTITY
		for i in spots.size():
			var at: Vector3 = spots[i][0]
			mm.set_instance_transform(i, Transform3D(turn.scaled(part[3] * S), at + part[1] * S))
			var c: Color = part[2] if part[2] is Color else (spots[i][1] as Color).lightened(0.3 if part[2] == "shield" else 0.0)
			mm.set_instance_color(i, c)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.disable_receive_shadows = true
		mmi.material_override = m
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 8
	c.rings = 2
	return c


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 10
	s.rings = 5
	return s


func _rod(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 8
	return c


## A knight on a horse, facing the castle (+z): a brown horse with legs, neck
## and head, a rider in `colour` with a helmet and lance.
func _knight(colour: Color) -> Node3D:
	var knight := Node3D.new()
	var hide := Color("#5a3a22")
	var body := _ball(0.5, hide)
	body.scale = Vector3(0.45, 0.4, 1.0)
	body.position.y = 0.75
	knight.add_child(body)
	for x in [-0.13, 0.13]:
		for z in [-0.3, 0.3]:
			var leg := B._box(Vector3(0.08, 0.6, 0.08), hide.darkened(0.2))
			leg.position = Vector3(x, 0.3, z)
			knight.add_child(leg)
	var neck := B._box(Vector3(0.14, 0.45, 0.16), hide)
	neck.position = Vector3(0, 1.05, 0.45)
	neck.rotation.x = 0.5
	knight.add_child(neck)
	var head := B._box(Vector3(0.14, 0.16, 0.34), hide)
	head.position = Vector3(0, 1.25, 0.62)
	knight.add_child(head)
	var cloth := B._box(Vector3(0.5, 0.25, 0.7), colour)  # its caparison
	cloth.position.y = 0.72
	knight.add_child(cloth)
	var rider := Character.new()
	rider.setup(colour)
	rider.scale = Vector3.ONE * 1.4
	rider.position.y = 0.8
	knight.add_child(rider)
	var helmet := _ball(0.09, Color("#9a9aa2"))
	helmet.position.y = 0.8 + 0.545 * 1.4
	knight.add_child(helmet)
	var lance := B._cyl(0.012, 0.02, 1.8, Color("#c8b890"))
	lance.position = Vector3(0.22, 1.7, 0)
	knight.add_child(lance)
	return knight


## A cannon on a wheeled carriage, its barrel pointing to +z.
func _cannon() -> Node3D:
	var cannon := Node3D.new()
	var wood := textured(Color("#3a2818"), Color("#5c4028"), 0.4)
	var carriage := _slab(Vector3(0.4, 0.2, 0.6), wood)
	carriage.position.y = 0.2
	cannon.add_child(carriage)
	for x in [-0.23, 0.23]:
		for z in [-0.18, 0.18]:
			var wheel := B._cyl(0.12, 0.12, 0.05, Color.WHITE)
			wheel.material_override = wood
			wheel.rotation.z = PI / 2
			wheel.position = Vector3(x, 0.12, z)
			cannon.add_child(wheel)
	var barrel := B._cyl(0.07, 0.1, 0.8, Color("#26262a"))
	barrel.rotation.x = PI / 2 - 0.1
	barrel.position = Vector3(0, 0.38, 0.2)
	cannon.add_child(barrel)
	return cannon


## Now and then one of `cannons` fires: a flash at its muzzle and a puff of
## smoke drifting away, roughly every `period` seconds.
func _volleys(cannons: Array[Node3D], period: float) -> void:
	var flash := _ball(0.2, Color.WHITE)
	flash.material_override = B._material(Color("#ffd080"), 3.0)
	var smoke := _ball(0.35, Color.WHITE)
	var smoke_m := B._material(Color(0.78, 0.78, 0.75, 0.0))
	smoke_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.material_override = smoke_m
	add_child(flash)
	add_child(smoke)
	_anims.append(func(t: float):
		var cycle := int(t / period)
		var phase := fmod(t, period)
		var gun: Node3D = cannons[cycle % cannons.size()]
		var muzzle := gun.position + gun.basis.z * 0.65 + Vector3(0, 0.45, 0)
		flash.visible = phase < 0.1
		flash.position = muzzle
		smoke.visible = phase < 2.5
		if smoke.visible:
			smoke.position = muzzle + gun.basis.z * phase * 0.3 + Vector3(0, phase * 0.3, 0)
			smoke.scale = Vector3.ONE * (0.5 + phase * 0.7)
			smoke_m.albedo_color.a = 0.6 * (1.0 - phase / 2.5))


## A soldier walking up and down a wall walk between `a` and `b`: a figure
## with a red tabard, a helmet and a spear.
func _soldier(a: Vector3, b: Vector3, k: int) -> void:
	var soldier := Character.new()
	soldier.setup(Color("#8e2420"))
	soldier.scale = Vector3.ONE * 1.4
	var helmet := _ball(0.088, Color("#8a8a90"))  # wholly over the cap, so they don't flicker
	helmet.scale = Vector3(1, 0.8, 1)
	helmet.position.y = 0.545
	soldier.add_child(helmet)
	var spear := B._cyl(0.008, 0.008, 0.7, Color("#6a4a2a"))
	spear.position = Vector3(0.14, 0.4, 0)
	soldier.add_child(spear)
	var tip := B._cyl(0.0, 0.02, 0.07, Color("#b8b8c0"))
	tip.position = Vector3(0.14, 0.78, 0)
	soldier.add_child(tip)
	_add(soldier, a)
	soldier.set("_walking", true)
	var length := a.distance_to(b)
	var speed := 0.35
	var offset := k * 3.0
	_anims.append(func(t: float):
		var d := fmod(t * speed + offset, length * 2.0)
		var going := d < length
		var k2 := d / length if going else 2.0 - d / length
		soldier.position = a.lerp(b, k2)
		var dir := (b - a) if going else (a - b)
		soldier.rotation.y = atan2(dir.x, dir.z))


## A tree, `size` times the usual: a pine (stacked cones) or a broadleaf (a few
## overlapping leafy crowns), its foliage stirring slightly.
func _tree(at: Vector3, size: float) -> void:
	var bark := textured(Color("#3a2a1c"), Color("#5c4430"), 0.4)
	var leaves := textured(Color("#1f4a24"), Color("#3c7038"), 1.2) if _rng.randf() < 0.6 \
			else textured(Color("#1a3a22"), Color("#2e5a34"), 1.2)
	var crown := Node3D.new()
	if _rng.randf() < 0.4:  # a pine
		_add(_slab(Vector3(0.14, 0.6, 0.14) * size, bark), at + Vector3(0, 0.25 * size, 0))
		_add(crown, at + Vector3(0, 0.45 * size, 0))
		for k in 3:
			var cone := B._cyl(0.0, (0.6 - k * 0.15) * size, 0.8 * size, Color.WHITE)
			cone.material_override = leaves
			cone.position.y = (0.35 + k * 0.4) * size
			crown.add_child(cone)
	else:  # a broadleaf
		_add(_slab(Vector3(0.16, 0.9, 0.16) * size, bark), at + Vector3(0, 0.3 * size, 0))
		_add(crown, at + Vector3(0, 1.0 * size, 0))
		for k in 3:
			var puff := _ball((0.42 - k * 0.04) * size, Color.WHITE)
			puff.material_override = leaves
			puff.position = Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.05, 0.25), _rng.randf_range(-0.2, 0.2)) * size
			crown.add_child(puff)
	var phase := _rng.randf() * TAU
	_anims.append(func(t: float): crown.rotation.z = sin(t * 0.7 + phase) * 0.015)


## `count` clouds drifting slowly across, between heights `low` and `high`,
## wrapping round when they drift too far; puffs share `materials` in turn.
func _clouds(count: int, low: float, high: float, materials: Array, speed_scale := 1.0) -> void:
	var span := _reach * 6.0
	for i in count:
		var cloud := Node3D.new()
		for k in _rng.randi_range(5, 9):
			var puff := _ball(_rng.randf_range(0.8, 1.7), Color.WHITE)
			puff.material_override = materials[k % materials.size()]
			puff.scale = Vector3(1.3, 0.6, 1)
			puff.position = Vector3(k * 0.85 - 3.0, _rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.8, 0.8))
			cloud.add_child(puff)
		var z := _centre.z + _rng.randf_range(-span / 2, span / 3)
		var y := _rng.randf_range(low, high)
		var x0 := _rng.randf_range(0, span)
		var speed := _rng.randf_range(0.1, 0.22) * speed_scale
		_add(cloud, Vector3.ZERO)
		var left := _centre.x - span / 2
		_anims.append(func(t: float):
			cloud.position = Vector3(left + fmod(x0 + t * speed, span), y, z))
