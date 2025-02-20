extends Node

var views := {}
var view_instances := {}
var current_view: Control = null
var current_view_name: String = ""
var animation_duration := 0.2
var is_transitioning := false
var transition_queue := []

var default_transition := "zoom"

var cache_enabled := false
var max_cached_views := 3

signal view_changed(from: String, to: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure(config: Dictionary) -> void:
	if config.has("animation_duration"):
		animation_duration = config.animation_duration

	if config.has("default_transition"):
		default_transition = config.default_transition

	if config.has("cache_enabled"):
		cache_enabled = config.cache_enabled

	if config.has("max_cached_views"):
		max_cached_views = config.max_cached_views


func preload_views(view_dict: Dictionary, auto_instantiate: bool = false) -> void:
	for view_name in view_dict:
		var view = load(view_dict[view_name])

		if view:
			views[view_name] = view

			if auto_instantiate:
				_cache_view(view_name)


func set_default_view(view_name: String) -> void:
	switch_to_view(view_name, "none")


func switch_to_view(view_name: String, transition_type: String = "") -> bool:
	if view_name == current_view_name:
		push_warning("Already in view: " + view_name)

		return false

	if is_transitioning:
		transition_queue.push_back({"name": view_name, "transition": transition_type})

		return true

	if not views.has(view_name):
		push_error("View not found: " + view_name)

		return false

	is_transitioning = true

	var old_view_name := current_view_name
	var new_view: Control

	if cache_enabled and view_instances.has(view_name):
		new_view = view_instances[view_name]
		new_view.show()
	else:
		new_view = views[view_name].instantiate()

		add_child(new_view)

		if cache_enabled:
			view_instances[view_name] = new_view

	new_view.modulate.a = 0.0

	var transition := transition_type if transition_type else default_transition

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT_IN)

	match transition:
		"none":
			_animate_none(tween, new_view)
		"fade":
			_animate_fade(tween, new_view)
		"slide":
			_animate_slide(tween, new_view)
		"scale":
			_animate_scale(tween, new_view)
		"zoom":
			_animate_zoom(tween, new_view)

	if current_view:
		var old_view = current_view

		tween.chain().tween_callback(func():
			if cache_enabled:
				old_view.hide()
				_manage_cache()
			else:
				old_view.queue_free()

			_complete_transition()
		)
	else:
		tween.chain().tween_callback(_complete_transition)

	current_view = new_view
	current_view_name = view_name

	view_changed.emit(old_view_name, view_name)

	return true


func _complete_transition() -> void:
	is_transitioning = false

	if not transition_queue.is_empty():
		var next = transition_queue.pop_front()

		switch_to_view(next.name, next.transition)


func _manage_cache() -> void:
	if view_instances.size() > max_cached_views:
		var oldest_view = view_instances.keys()[0]

		if oldest_view != current_view_name:
			view_instances[oldest_view].queue_free()
			view_instances.erase(oldest_view)


func _cache_view(view_name: String) -> void:
	if not view_instances.has(view_name):
		var instance = views[view_name].instantiate()

		view_instances[view_name] = instance
		instance.hide()

		add_child(instance)


func _animate_none(tween: Tween, new_view: Control) -> void:
	if current_view:
		tween.tween_property(current_view, "modulate:a", 0.0, 0.0)

	tween.tween_property(new_view, "modulate:a", 1.0, 0.0)


func _animate_fade(tween: Tween, new_view: Control) -> void:
	if current_view:
		tween.tween_property(current_view, "modulate:a", 0.0, animation_duration)

	tween.tween_property(new_view, "modulate:a", 1.0, animation_duration)


func _animate_slide(tween: Tween, new_view: Control) -> void:
	var offset := Vector2(0.0, 20.0)
	var current_position := new_view.position

	new_view.position += offset

	if current_view:
		tween.tween_property(current_view, "position",
			current_view.position - offset, animation_duration)
		tween.tween_property(current_view, "modulate:a", 0.0,
			animation_duration)

	tween.tween_property(new_view, "position", current_position,
		animation_duration)
	tween.tween_property(new_view, "modulate:a", 1.0, animation_duration)


func _animate_scale(tween: Tween, new_view: Control) -> void:
	new_view.pivot_offset = new_view.size / 2.0
	new_view.scale = Vector2.ZERO
	new_view.modulate.a = 1.0

	if current_view:
		current_view.pivot_offset = current_view.size / 2.0

		tween.tween_property(current_view, "scale", Vector2.ZERO,
			animation_duration)
		tween.tween_property(current_view, "modulate:a", 0.0,
			animation_duration)

	tween.tween_property(new_view, "scale", Vector2.ONE, animation_duration)
	tween.tween_property(new_view, "modulate:a", Vector2.ONE,
		animation_duration)


func _animate_zoom(tween: Tween, new_view: Control) -> void:
	new_view.pivot_offset = new_view.size / 2.0
	new_view.scale = Vector2(2.0, 2.0)
	new_view.modulate.a = 0.0

	if current_view:
		current_view.pivot_offset = current_view.size / 2.0

		tween.tween_property(current_view, "scale",
			Vector2(0.5, 0.5), animation_duration)
		tween.tween_property(current_view, "modulate:a", 0.0,
			animation_duration)

	tween.tween_property(new_view, "scale", Vector2.ONE, animation_duration)
	tween.tween_property(new_view, "modulate:a", 1.0, animation_duration)
