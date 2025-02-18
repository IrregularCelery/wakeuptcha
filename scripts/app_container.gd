extends Control

@onready var container: MarginContainer = $Container

# For easier debugging/testing portrait layout
@export var force_portrait_layout: bool = false

var last_scale: float = 1.0
var updating_scale: bool = false

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_window_resize)
	_update_layout()


func is_portrait() -> bool:
	if force_portrait_layout:
		return true
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var aspect_ratio: float = viewport_size.x / viewport_size.y
	
	return aspect_ratio <= 0.75 # Taller than widet


func _update_layout() -> void:
	var window_size: Vector2 = get_viewport().get_visible_rect().size
		
	if is_portrait():
		# Portrait layout: Content takes full screen, ignoring margins

		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.offset_left = 0 
		container.offset_right = 0
		container.offset_top = 0
		container.offset_bottom = 0
	else: 
		# Landscape layout: Portrait container in center
		
		# 90% of window height
		var container_scale: float = window_size.y * 0.9 / Settings.PORTRAIT_HEIGHT
		
		var container_size := Vector2(
			Settings.PORTRAIT_WIDTH,
			Settings.PORTRAIT_HEIGHT
		) * container_scale
		
		container.custom_minimum_size = container_size
		container.position = (window_size - container_size) / 2

		container.set_anchors_preset(Control.PRESET_CENTER)
		container.offset_left = 0 
		container.offset_right = 0
		container.offset_top = 0
		container.offset_bottom = 0


func _on_window_resize() -> void:
	_update_layout()
