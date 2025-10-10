extends BaseCollectible

@export var bomb_color: Color = Color(1, 1, 1, 1)  # White
@export var outline_color: Color = Color(1, 0, 0, 1)  # Red outline
@export var bomb_radius: float = 18.0
@export var outline_width: float = 3.0

var polygon_node: Polygon2D = null

func _ready() -> void:
	super._ready()
	add_to_group("bomb")
	_setup_visual()
	_setup_collision()

func _setup_visual() -> void:
	if visual:
		# Create white circle with red outline using Polygon2D
		var circle_polygon = Polygon2D.new()

		# Generate circle points
		var num_points = 32
		var points = PackedVector2Array()

		for i in range(num_points):
			var angle = (float(i) / num_points) * TAU
			var x = cos(angle) * bomb_radius
			var y = sin(angle) * bomb_radius
			points.append(Vector2(x, y))

		circle_polygon.polygon = points
		circle_polygon.color = bomb_color

		# Remove the ColorRect visual
		if visual:
			visual.queue_free()

		# Add circle as a child
		add_child(circle_polygon)
		polygon_node = circle_polygon

		# Create outline using Line2D
		var outline = Line2D.new()
		for point in points:
			outline.add_point(point)
		# Close the circle
		outline.add_point(points[0])

		outline.width = outline_width
		outline.default_color = outline_color
		outline.joint_mode = Line2D.LINE_JOINT_ROUND
		outline.antialiased = true

		add_child(outline)

func _setup_collision() -> void:
	# Use a circular collision shape
	var shape = CircleShape2D.new()
	shape.radius = bomb_radius
	collision_shape.shape = shape

func _on_collected() -> void:
	# Destroy obstacles in current segment and next segment
	_destroy_nearby_obstacles()

	# Play explosion sound
	AudioManager.play_sfx("orb_collect", -0.2)
	_spawn_particles()

func _destroy_nearby_obstacles() -> void:
	# Get the TunnelGenerator to find active segments
	var tunnel_generator = get_tree().get_first_node_in_group("tunnel_generator")
	if not tunnel_generator:
		print("Warning: Could not find TunnelGenerator")
		return

	# Get player position to determine which segments to clear
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var player_y = player.global_position.y

	# Find current and next segments based on player position
	var segments_to_clear: Array[BaseSegment] = []

	for segment in tunnel_generator.active_segments:
		var segment_top = segment.position.y - segment.segment_data.segment_length
		var segment_bottom = segment.position.y

		# Check if player is in this segment or if this segment is ahead
		if player_y <= segment_bottom and player_y >= segment_top:
			# Current segment
			segments_to_clear.append(segment)
		elif segment_top < player_y and segments_to_clear.size() < 2:
			# Next segment (ahead of player in negative Y direction)
			segments_to_clear.append(segment)

		# Stop after finding 2 segments (current + next)
		if segments_to_clear.size() >= 2:
			break

	# Destroy all obstacles in these segments
	var obstacles_destroyed = 0
	for segment in segments_to_clear:
		if segment.obstacles_container:
			for obstacle in segment.obstacles_container.get_children():
				if obstacle.has_method("destroy_with_effect"):
					obstacle.destroy_with_effect()
					obstacles_destroyed += 1

	print("Bomb destroyed %d obstacles across %d segments" % [obstacles_destroyed, segments_to_clear.size()])
