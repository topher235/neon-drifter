class_name CosmeticPreview extends PanelContainer

## Preview display for a single trail cosmetic
## Shows animated trail preview, name, and unlock/select buttons

signal unlock_requested(cosmetic_id: String)
signal select_requested(cosmetic_id: String)

@onready var preview_line: Line2D = $MarginContainer/VBoxContainer/PreviewContainer/PreviewLine
@onready var cosmetic_name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var unlock_button: Button = $MarginContainer/VBoxContainer/UnlockButton
@onready var cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var select_button: Button = $MarginContainer/VBoxContainer/SelectButton
@onready var selected_label: Label = $MarginContainer/VBoxContainer/SelectedLabel

var cosmetic: TrailCosmetic
var cosmetic_id: String
var animation_time: float = 0.0


func _ready() -> void:
	unlock_button.pressed.connect(_on_unlock_pressed)
	select_button.pressed.connect(_on_select_pressed)


func _process(delta: float) -> void:
	if cosmetic and preview_line:
		animation_time += delta
		_update_preview_line()


func setup(p_cosmetic: TrailCosmetic, p_cosmetic_id: String) -> void:
	"""Initialize the preview with a cosmetic"""
	cosmetic = p_cosmetic
	cosmetic_id = p_cosmetic_id

	if not is_node_ready():
		await ready

	# Set name
	cosmetic_name_label.text = cosmetic.cosmetic_name

	# Update button states
	_update_button_states()

	# Setup preview line
	_setup_preview_line()


func _setup_preview_line() -> void:
	"""Setup the preview Line2D"""
	preview_line.width = 6.0
	preview_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	preview_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	preview_line.joint_mode = Line2D.LINE_JOINT_ROUND
	preview_line.antialiased = true

	# Create a wave pattern for preview
	preview_line.clear_points()
	var num_points = 30
	for i in range(num_points):
		var x = float(i) / float(num_points - 1) * 140.0 - 70.0  # -70 to 70
		var y = sin(float(i) / 5.0) * 20.0  # Wave pattern
		preview_line.add_point(Vector2(x, y))


func _update_preview_line() -> void:
	"""Update the preview line colors based on cosmetic"""
	if not cosmetic or not preview_line:
		return

	var num_points = preview_line.get_point_count()
	if num_points == 0:
		return

	# Create gradient based on cosmetic type
	if cosmetic.cosmetic_type == TrailCosmetic.CosmenticType.SOLID:
		var gradient = Gradient.new()
		var color = cosmetic.solid_color
		gradient.set_color(0, Color(color.r, color.g, color.b, 0.3))
		gradient.add_point(0.5, Color(color.r, color.g, color.b, 0.8))
		gradient.set_color(1, Color(color.r, color.g, color.b, 1.0))
		preview_line.gradient = gradient

	else:
		# For gradient/animated cosmetics
		var base_gradient = cosmetic.gradient
		if not base_gradient:
			return

		var custom_gradient = Gradient.new()
		var time_offset = 0.0

		if cosmetic.cosmetic_type == TrailCosmetic.CosmenticType.ANIMATED:
			time_offset = fmod(animation_time * cosmetic.animation_speed, 1.0)

		var num_samples = 15
		for j in range(num_samples + 1):
			var t = float(j) / float(num_samples)
			var sample_pos = t

			if cosmetic.cosmetic_type == TrailCosmetic.CosmenticType.ANIMATED:
				sample_pos = fmod(t + time_offset, 1.0)

			var color = base_gradient.sample(sample_pos)
			var alpha = lerp(0.3, 1.0, t)
			color.a = alpha

			if j == 0:
				custom_gradient.set_color(0, color)
				custom_gradient.set_offset(0, 0.0)
			elif j == num_samples:
				custom_gradient.set_color(1, color)
				custom_gradient.set_offset(1, 1.0)
			else:
				custom_gradient.add_point(t, color)

		preview_line.gradient = custom_gradient


func _update_button_states() -> void:
	"""Update button visibility based on unlock/selection state"""
	var is_unlocked = CosmeticManager.is_cosmetic_unlocked(cosmetic_id)
	var is_selected = CosmeticManager.selected_cosmetic_id == cosmetic_id

	# Non-buyable cosmetics should never show unlock button
	var can_be_purchased = cosmetic.buyable if cosmetic else true

	unlock_button.visible = not is_unlocked and can_be_purchased
	cost_label.visible = not is_unlocked and can_be_purchased
	select_button.visible = is_unlocked and not is_selected
	selected_label.visible = is_selected

	# Update cost label text
	if not is_unlocked and cosmetic and can_be_purchased:
		cost_label.text = "%d orbs" % cosmetic.orb_cost


func refresh() -> void:
	"""Refresh button states (call when cosmetics are unlocked/selected)"""
	_update_button_states()


func _on_unlock_pressed() -> void:
	unlock_requested.emit(cosmetic_id)


func _on_select_pressed() -> void:
	select_requested.emit(cosmetic_id)
