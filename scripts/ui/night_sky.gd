class_name NightSky
extends Control
## The Moon's nightfall over the board view: the picture fades into a deep
## blue night and stars come out and twinkle, then it all fades back to day.
## It lies over the board only, under the text (banner, turn label, corner
## map), which stays clear. play() runs it; the board's own light dims with
## it (BoardView.nightfall).

const NIGHT_TOP := Color("#060a24")
const NIGHT_LOW := Color("#1a1e52")
const STARS := 70

var _night := 0.0  # 0..1: how dark it is
var _time := 0.0
var _stars: Array[Vector3] = []  # x, y (0..1 of the view), twinkle phase


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in STARS:
		_stars.append(Vector3(rng.randf(), rng.randf_range(0.0, 0.75), rng.randf() * TAU))


## Fading to blue, then night held, then dawn, over `seconds` in all.
func play(seconds: float) -> void:
	visible = true
	_night = 0.0
	var tw := create_tween()
	tw.tween_property(self, "_night", 0.35, seconds * 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_night", 1.0, seconds * 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(seconds * 0.35)
	tw.tween_property(self, "_night", 0.0, seconds * 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): visible = false)


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# The sky: dark at the top, a little lighter low down, see-through enough
	# to still show the board in the dark.
	var bands := 24
	for i in bands:
		var k := float(i) / (bands - 1)
		var col := NIGHT_TOP.lerp(NIGHT_LOW, k)
		col.a = lerpf(0.62, 0.72, k) * _night
		draw_rect(Rect2(0, h * i / bands, w, h / bands + 1), col)
	var dark := clampf((_night - 0.4) / 0.6, 0.0, 1.0)  # stars once it is dark
	if dark <= 0.0:
		return
	for s in _stars:
		var twinkle := 0.55 + 0.45 * sin(_time * 3.0 + s.z)
		var r := 1.0 + 1.2 * fposmod(s.z, 1.0)
		draw_circle(Vector2(s.x * w, s.y * h), r, Color(1, 1, 0.9, 0.9 * dark * twinkle))
