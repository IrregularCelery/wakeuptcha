extends Control

@onready var container: MarginContainer = $Container
@onready var content: MarginContainer = $Container/Content

# For easier debugging/testing mobile layout
@export var force_mobile_layout: bool = false

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_window_resize)
	_update_layout()


func is_mobile_resolution() -> bool:
	if force_mobile_layout:
		return true
		
	var viewport_size: Vector2 = get_viewport_rect().size
	
	var aspect_ratio: float = float(viewport_size.x) / float(viewport_size.y)
	
	const BREAKDOWN: int = Settings.MOBILE_TABLET_BREAKPOINT
	
	return viewport_size.x <= BREAKDOWN or aspect_ratio <= 0.7 # Taller than wide


func _update_layout() -> void:
	var window_size: Vector2 = get_viewport().get_visible_rect().size
	
	if is_mobile_resolution():
		# Mobile layout: Content takes full screen, ignoring margins
		
		container.visible = false
		
		if content.get_parent() == container:
			container.remove_child(content)
			add_child(content)
			
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 0 
		content.offset_right = 0
		content.offset_top = 0
		content.offset_bottom = 0
	else:
		# Desktop layout: Portrait container in center
		
		container.visible = true
		
		if content.get_parent() != container:
			content.get_parent().remove_child(content)
			container.add_child(content)
		
		var portrait_scale = min(
			window_size.x * 0.8 / Settings.MIN_PORTRAIT_WIDTH, # 80% of window width
			window_size.y * 0.9 / Settings.MIN_PORTRAIT_HEIGHT # 90% of window height
		)
		
		var container_size = Vector2(
			Settings.MIN_PORTRAIT_WIDTH,
			Settings.MIN_PORTRAIT_HEIGHT
		) * portrait_scale
		
		container.custom_minimum_size = container_size
		container.size = container_size
		container.position = (window_size - container_size) / 2
		
		content.set_anchors_preset(PRESET_FULL_RECT)
		content.offset_left = Settings.PORTRAIT_PADDING
		content.offset_right = -Settings.PORTRAIT_PADDING
		content.offset_top = Settings.PORTRAIT_PADDING
		content.offset_bottom = -Settings.PORTRAIT_PADDING


func _on_window_resize() -> void:
	_update_layout()
