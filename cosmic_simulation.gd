extends Node2D

# Constants for the simulation
const MAX_STARS = 1000
const MAX_PLANETS = 10
const MAX_ASTEROIDS = 50
const MAX_COMETS = 5
const NEBULA_COUNT = 3
const SCREEN_SIZE = Vector2(1920, 1080)

# Base class for all celestial bodies
class CelestialBody:
	var position: Vector2
	var velocity: Vector2
	var size: float
	var color: Color

	func _init(pos: Vector2, vel: Vector2, sz: float, col: Color):
		position = pos
		velocity = vel
		size = sz
		color = col

	func update(delta: float):
		position += velocity * delta

# Star class with twinkling effect
class Star extends CelestialBody:
	var twinkle_speed: float

	func _init(pos: Vector2, sz: float, col: Color, twinkle: float):
		super(pos, Vector2.ZERO, sz, col)
		twinkle_speed = twinkle

	func update(delta: float):
		super.update(delta)
		# Create twinkling effect by modulating alpha
		color.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * twinkle_speed * 0.001)

# Planet class with orbital motion
class Planet extends CelestialBody:
	var orbit_center: Vector2
	var orbit_radius: float
	var orbit_speed: float
	var rotation_speed: float
	var angle: float

	func _init(center: Vector2, radius: float, speed: float, sz: float, col: Color, rot_speed: float):
		super(center, Vector2.ZERO, sz, col)
		orbit_center = center
		orbit_radius = radius
		orbit_speed = speed
		rotation_speed = rot_speed
		angle = randf() * 2 * PI

	func update(delta: float):
		# Update orbital position
		angle += orbit_speed * delta
		position = orbit_center + Vector2(cos(angle), sin(angle)) * orbit_radius
		# Create "breathing" effect by modulating size
		size += sin(Time.get_ticks_msec() * rotation_speed * 0.001) * 0.1

# Asteroid class with rotation
class Asteroid extends CelestialBody:
	var rotation: float
	var rotation_speed: float

	func _init(pos: Vector2, vel: Vector2, sz: float, col: Color, rot_speed: float):
		super(pos, vel, sz, col)
		rotation = randf() * 2 * PI
		rotation_speed = rot_speed

	func update(delta: float):
		super.update(delta)
		rotation += rotation_speed * delta

# Comet class with tail
class Comet extends Node2D:
	var velocity: Vector2
	var size: float
	var color: Color
	var tail_length: float
	var tail_segments: int = 10

	func _init(pos: Vector2, vel: Vector2, sz: float, col: Color, tail: float):
		position = pos
		velocity = vel
		size = sz
		color = col
		tail_length = tail

	func update(delta: float):
		position += velocity * delta
		queue_redraw()

	func _draw():
		# Draw comet head
		draw_circle(Vector2.ZERO, size, color)
		# Draw comet tail
		var segment_length = tail_length / tail_segments
		for i in range(tail_segments):
			var alpha = float(i) / tail_segments
			var color_with_alpha = color
			color_with_alpha.a *= 1.0 - alpha
			var tail_position = -velocity.normalized() * (i * segment_length)
			if i == 0:
				draw_line(tail_position, tail_position + Vector2(1, 1), color_with_alpha)
			else:
				var previous_tail_position = -velocity.normalized() * ((i - 1) * segment_length)
				draw_line(previous_tail_position, tail_position, color_with_alpha)

# Arrays to store celestial bodies
var stars = []
var planets = []
var asteroids = []
var comets = []
var nebulae = []

# Scene elements
var camera: Camera2D
var time_scale = 1.0
var player_focus: Vector2
var shader_material: ShaderMaterial
var day_night_cycle = 0.0
var photo_mode = false

func _ready():
	randomize()
	initialize_scene()
	setup_camera()
	setup_shader()
	generate_celestial_bodies()
	setup_ui()

# Initialize the scene with a dark background
func initialize_scene():
	RenderingServer.set_default_clear_color(Color(0.05, 0.05, 0.1, 1.0))

# Set up the camera
func setup_camera():
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	camera.position = SCREEN_SIZE / 2

# Update camera position based on mouse movement
func update_camera(delta):
	var target_position = get_global_mouse_position()
	camera.position = camera.position.lerp(target_position, 0.1)

# Set up a simple shader for visual effects
func setup_shader():
	var shader_code = """
	shader_type canvas_item;
	uniform float time_offset;
	void fragment() {
		vec2 uv = UV;
		uv.y += sin(uv.x * 10.0 + time_offset) * 0.1;
		COLOR = texture(TEXTURE, uv);
	}
	"""
	shader_material = ShaderMaterial.new()
	shader_material.shader = Shader.new()
	shader_material.shader.code = shader_code

# Generate all celestial bodies
func generate_celestial_bodies():
	generate_stars()
	generate_planets()
	generate_asteroids()
	generate_comets()
	generate_nebulae()

# Generate stars
func generate_stars():
	for i in range(MAX_STARS):
		var pos = Vector2(randf() * SCREEN_SIZE.x, randf() * SCREEN_SIZE.y)
		var size = randf() * 2 + 1
		var color = Color(randf(), randf(), randf(), 1.0)
		var twinkle = randf() * 5 + 1
		stars.append(Star.new(pos, size, color, twinkle))

# Generate planets
func generate_planets():
	for i in range(MAX_PLANETS):
		var center = Vector2(randf() * SCREEN_SIZE.x, randf() * SCREEN_SIZE.y)
		var radius = randf() * 200 + 50
		var speed = randf() * 0.5 + 0.1
		var size = randf() * 30 + 10
		var color = Color(randf(), randf(), randf(), 1.0)
		var rot_speed = randf() * 2 + 0.5
		planets.append(Planet.new(center, radius, speed, size, color, rot_speed))

# Generate asteroids
func generate_asteroids():
	for i in range(MAX_ASTEROIDS):
		var pos = Vector2(randf() * SCREEN_SIZE.x, randf() * SCREEN_SIZE.y)
		var vel = Vector2(randf() * 40 - 20, randf() * 40 - 20)
		var size = randf() * 5 + 2
		var color = Color(0.6, 0.6, 0.6, 1.0)
		var rot_speed = randf() * 4 - 2
		asteroids.append(Asteroid.new(pos, vel, size, color, rot_speed))

# Generate comets
func generate_comets():
	for i in range(MAX_COMETS):
		var pos = Vector2(randf() * SCREEN_SIZE.x, randf() * SCREEN_SIZE.y)
		var vel = Vector2(randf() * 200 - 100, randf() * 200 - 100)
		var size = randf() * 4 + 2
		var color = Color(0.9, 0.9, 1.0, 1.0)
		var tail = randf() * 50 + 25
		var comet = Comet.new(pos, vel, size, color, tail)
		add_child(comet)
		comets.append(comet)

# Generate nebulae
func generate_nebulae():
	for i in range(NEBULA_COUNT):
		var pos = Vector2(randf() * SCREEN_SIZE.x, randf() * SCREEN_SIZE.y)
		var size = Vector2(randf() * 300 + 200, randf() * 300 + 200)
		var color = Color(randf(), randf(), randf(), 0.3)
		nebulae.append({"position": pos, "size": size, "color": color})

# Main process function
func _process(delta):
	update_celestial_bodies(delta * time_scale)
	update_camera(delta)
	update_day_night_cycle(delta)
	queue_redraw()

# Update all celestial bodies
func update_celestial_bodies(delta):
	for star in stars:
		star.update(delta)
	for planet in planets:
		planet.update(delta)
	for asteroid in asteroids:
		asteroid.update(delta)
	for comet in comets:
		comet.update(delta)

# Update day-night cycle
func update_day_night_cycle(delta):
	day_night_cycle += delta * 0.1
	if day_night_cycle > 1:
		day_night_cycle = 0
	var background_color = Color(0.05 + 0.05 * sin(day_night_cycle * PI), 0.05, 0.1)
	RenderingServer.set_default_clear_color(background_color)

# Set up UI elements (placeholder)
func setup_ui():
	# Add UI elements like buttons, sliders, etc. here.
	pass

# Draw all celestial bodies
func _draw():
	for star in stars:
		draw_circle(star.position, star.size, star.color)
	for planet in planets:
		draw_circle(planet.position, planet.size, planet.color)
	for asteroid in asteroids:
		draw_circle(asteroid.position, asteroid.size, asteroid.color)
	for nebula in nebulae:
		draw_rect(Rect2(nebula["position"], nebula["size"]), nebula["color"])
