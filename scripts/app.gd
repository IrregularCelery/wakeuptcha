extends Control

@onready var container: MarginContainer = $Container

func _ready() -> void:
	get_viewport().size_changed.connect(_on_window_resize)
	update_layout()


func is_portrait() -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	var aspect_ratio: float = viewport_size.x / viewport_size.y

	return aspect_ratio <= 0.75 # Taller than wide


func update_layout() -> void:
	if is_portrait():
		# Portrait layout: Content takes full screen, ignoring margins
		container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		return

	# Landscape layout: Portrait container in center

	# For having padding on top and bottom of the container
	var multiplier: float = get_viewport_rect().size.y \
	* (1.0 - Constants.PORTRAIT_PADDING_Y * 2.0) / Constants.DESIGN_HEIGHT

	var container_size := Vector2(
		Constants.DESIGN_WIDTH,
		Constants.DESIGN_HEIGHT,
	) * multiplier

	container.custom_minimum_size = container_size
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)


# Signals

func _on_window_resize() -> void:
	update_layout()
