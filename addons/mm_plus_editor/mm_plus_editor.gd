@tool
extends EditorPlugin

var selected_node : MmPlus3D
var data_group_list : Array[MMGroup] = []
var _memory_data_group_list : Array[MMGroup] = []
var is_applying_action : bool = false
var previous_target_transform : Transform3D = Transform3D.IDENTITY

var rnd : RandomNumberGenerator = RandomNumberGenerator.new()

enum MODE {NONE, PAINT, SCALE, COLOR}
var current_mode : MODE = MODE.NONE : set = _set_current_mode
const btn_mode_map : Dictionary[MODE, Dictionary] = {
	MODE.PAINT: {"title": "Paint", "icon": "Paint"},
	MODE.SCALE: {"title": "Scale", "icon": "ToolScale"},
	MODE.COLOR: {"title": "Colorize", "icon": "Bucket"},
}
var brush_size_map : Dictionary[MODE, float] = {
	MODE.PAINT: 1.0,
	MODE.SCALE: 1.0,
	MODE.COLOR: 1.0,
}
const BTN_THEME = preload("./assets/btn_theme.tres")
const SPHERE_MAT = preload("./assets/materials/sphere_mat.tres")

# Brush size scroll shortcut settings
const BRUSH_SCROLL_STEP_FINE : float = 0.2    # Step size below threshold
const BRUSH_SCROLL_STEP_MACRO : float = 0.5  # Step size above threshold
const BRUSH_SCROLL_THRESHOLD : float = 2.0    # Switch from fine to macro

# Track 'S' key for brush size shortcut (Shift + S + Scroll)
var _is_s_key_pressed : bool = false

var active_layers : Array[bool] = []

var main_tool_bar : HBoxContainer = null
var color_tool_bar : HBoxContainer = null
var color_picker : ColorPickerButton = null
var button_group : ButtonGroup = null
var preview_mesh : MeshInstance3D = null
var brush_size_box : SpinBox = null
var randomize_color_button : Button = null
var layers_popup_body : VBoxContainer = null
var collision_layer : int = 1
var grid_size_spinbox : SpinBox = null

func _set_grid_size(new_grid_size : float):
	if selected_node == null: return
	if selected_node.grid_size == new_grid_size: return
	var previous_grid_size : float = selected_node.grid_size

	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action("Set grid size")
	undo_redo.add_do_property(selected_node, "grid_size", new_grid_size)
	undo_redo.add_undo_property(selected_node, "grid_size", previous_grid_size)
	undo_redo.add_do_method(self, "_load_selected_node_data")
	undo_redo.add_undo_method(self, "_load_selected_node_data")
	undo_redo.commit_action()

func _toggle_collision_layer(toggled : bool, flag_idx : int):
	if toggled:
		# Add collision layer
		collision_layer |= 1 << (flag_idx)
	else:
		# Remove collision layer
		collision_layer &= ~( 1 << (flag_idx) )

func init_ui() -> void:
	main_tool_bar = HBoxContainer.new()
	color_tool_bar = HBoxContainer.new()
	main_tool_bar.hide()
	color_tool_bar.hide()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, main_tool_bar)
	var gui = EditorInterface.get_base_control()

	# Settings Popup
	var settings_btn : Button = Button.new()
	settings_btn.theme = BTN_THEME
	settings_btn.text = "Settings"
	settings_btn.icon = gui.get_theme_icon("GuiOptionArrow", "EditorIcons")
	main_tool_bar.add_child(settings_btn)

	var settings_popup : PopupPanel = PopupPanel.new()
	var settings_popup_body = VBoxContainer.new()
	settings_popup.add_child(settings_popup_body)
	main_tool_bar.add_child(settings_popup)

	settings_btn.pressed.connect(func():
		settings_popup.popup(Rect2i(settings_btn.get_screen_position() + Vector2(0.0, settings_btn.size.y), Vector2i.ONE))
		)

	var grid_size_label : Label = Label.new()
	grid_size_label.text = "Grid Size: "

	grid_size_spinbox = SpinBox.new()
	grid_size_spinbox.min_value = 5.0
	grid_size_spinbox.max_value = 500.0
	grid_size_spinbox.step = 1.0
	
	var update_grid_size_btn : Button = Button.new()
	update_grid_size_btn.text = "Update Grid Size"

	var grid_size_h_box : HBoxContainer = HBoxContainer.new()

	settings_popup_body.add_child(grid_size_h_box)
	grid_size_h_box.add_child(grid_size_label)
	grid_size_h_box.add_child(grid_size_spinbox)
	grid_size_h_box.add_child(update_grid_size_btn)
	
	update_grid_size_btn.pressed.connect(func():
		_set_grid_size(grid_size_spinbox.value)
		)

	# Layers popup
	var layers_btn : Button = Button.new()
	layers_btn.theme = BTN_THEME
	layers_btn.text = "Layers"
	layers_btn.icon = gui.get_theme_icon("GuiOptionArrow", "EditorIcons")
	main_tool_bar.add_child(layers_btn)

	var layers_popup : PopupPanel = PopupPanel.new()
	layers_popup_body = VBoxContainer.new()
	layers_popup.add_child(layers_popup_body)
	main_tool_bar.add_child(layers_popup)

	layers_btn.pressed.connect(func():
		layers_popup.popup(Rect2i(layers_btn.get_screen_position() + Vector2(0.0, layers_btn.size.y), Vector2i.ONE))
		)

	# Physics layer popup

	var collision_layer_btn : Button = Button.new()
	collision_layer_btn.theme = BTN_THEME
	collision_layer_btn.tooltip_text = "Collision layer"
	collision_layer_btn.icon = gui.get_theme_icon("CollisionObject3D", "EditorIcons")
	main_tool_bar.add_child(collision_layer_btn)

	var collision_layer_popup : PopupPanel = PopupPanel.new()
	var collision_layer_popup_body : GridContainer = GridContainer.new()
	collision_layer_popup_body.set("theme_override_constants/h_separation", 1)
	collision_layer_popup_body.set("theme_override_constants/v_separation", 1)
	collision_layer_popup_body.columns = 16
	collision_layer_popup.add_child(collision_layer_popup_body)
	main_tool_bar.add_child(collision_layer_popup)

	for i in 32:
		var layer_btn : Button = Button.new()
		layer_btn.text = str(i + 1)
		layer_btn.toggle_mode = true
		if i == 0: layer_btn.set_pressed(true)
		collision_layer_popup_body.add_child(layer_btn)
		layer_btn.toggled.connect(_toggle_collision_layer.bind(i))

	collision_layer_btn.pressed.connect(func():
		collision_layer_popup.popup(Rect2i(collision_layer_btn.get_screen_position() + Vector2(0.0, collision_layer_btn.size.y), Vector2i.ONE))
		)


	# Create mode buttons
	button_group = ButtonGroup.new()
	for btn_id in btn_mode_map:
		var btn : Button = Button.new()
		btn.theme = BTN_THEME
		btn.text = btn_mode_map[btn_id].title
		btn.icon = gui.get_theme_icon(btn_mode_map[btn_id].icon, "EditorIcons")
		btn.button_group = button_group
		btn.toggle_mode = true
		btn.set_meta("ID", btn_id)
		main_tool_bar.add_child(btn)
	button_group.allow_unpress = true
	button_group.pressed.connect(_on_button_group_press)
	# Create preview mesh
	preview_mesh = MeshInstance3D.new()
	get_tree().root.call_deferred("add_child", preview_mesh)
	preview_mesh.mesh = SphereMesh.new()
	preview_mesh.mesh.radial_segments = 32
	preview_mesh.mesh.rings = 16
	preview_mesh.material_override = SPHERE_MAT
	preview_mesh.hide()

	# Brush Size UI
	brush_size_box = SpinBox.new()
	main_tool_bar.add_child(brush_size_box)
	brush_size_box.suffix = "m"
	brush_size_box.min_value = 0.01
	brush_size_box.step = 0.01
	brush_size_box.value_changed.connect(_on_brush_size_value_changed)

	# Color panel
	color_picker = ColorPickerButton.new()
	color_picker.custom_minimum_size.x = 64.0
	color_tool_bar.add_child(color_picker)

	randomize_color_button = Button.new()
	randomize_color_button.icon = gui.get_theme_icon("RandomNumberGenerator", "EditorIcons")
	randomize_color_button.theme = BTN_THEME
	randomize_color_button.toggle_mode = true
	randomize_color_button.tooltip_text = "Randomize Color"
	color_tool_bar.add_child(randomize_color_button)

	main_tool_bar.add_child(color_tool_bar)


func _set_current_mode(mode : MODE) -> void:
	if current_mode == mode: return
	current_mode = mode
	_is_s_key_pressed = false  # Reset shortcut state

	if current_mode != MODE.NONE:
		brush_size_box.set_value_no_signal(brush_size_map[current_mode])
		_update_brush_preview_size()
	
	color_tool_bar.visible = current_mode == MODE.COLOR

func _update_brush_preview_size() -> void:
	var brush_size : float = brush_size_map[current_mode]
	preview_mesh.mesh.radius = brush_size
	preview_mesh.mesh.height = brush_size * 2.0

func _on_brush_size_value_changed(value : float) -> void:
	if current_mode == MODE.NONE: return
	brush_size_map[current_mode] = value
	_update_brush_preview_size()

# Check if scroll event should be consumed (Shift + S held during scroll)
func _should_consume_scroll_event(event : InputEvent) -> bool:
	if !event is InputEventMouseButton: return false
	var mouse_btn : InputEventMouseButton = event as InputEventMouseButton
	if mouse_btn.button_index != MOUSE_BUTTON_WHEEL_UP and mouse_btn.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return false
	return mouse_btn.shift_pressed and _is_s_key_pressed

# Check if brush size change should be applied (only on pressed, not released)
func _should_apply_brush_size_scroll(event : InputEvent) -> bool:
	if !_should_consume_scroll_event(event): return false
	return (event as InputEventMouseButton).pressed

# Apply brush size change from scroll wheel using fine/coarse steps
func _apply_brush_size_scroll(event : InputEventMouseButton) -> void:
	var current_size : float = brush_size_map[current_mode]
	var new_size : float
	var is_scroll_up : bool = event.button_index == MOUSE_BUTTON_WHEEL_UP

	var is_fine_range : bool = current_size < BRUSH_SCROLL_THRESHOLD or \
		(current_size == BRUSH_SCROLL_THRESHOLD and !is_scroll_up)

	if is_fine_range:
		# Fine control: small step increments
		if is_scroll_up:
			# Round up to next fine step boundary
			var steps_per_unit : float = 1.0 / BRUSH_SCROLL_STEP_FINE
			new_size = ceilf(current_size * steps_per_unit) / steps_per_unit
			if is_equal_approx(new_size, current_size):
				new_size += BRUSH_SCROLL_STEP_FINE
		else:
			new_size = current_size - BRUSH_SCROLL_STEP_FINE
	else:
		# Coarse control: large step increments
		if is_scroll_up:
			new_size = current_size + BRUSH_SCROLL_STEP_MACRO
		else:
			# Step down, snap to threshold when crossing
			new_size = current_size - BRUSH_SCROLL_STEP_MACRO
			if new_size < BRUSH_SCROLL_THRESHOLD:
				new_size = BRUSH_SCROLL_THRESHOLD

	# Enforce minimum bound from SpinBox
	new_size = maxf(new_size, brush_size_box.min_value)
	# Update via SpinBox to trigger _on_brush_size_value_changed and keep UI in sync
	brush_size_box.value = new_size

func _on_button_group_press(_pressed_button : BaseButton):
	var btn : BaseButton = button_group.get_pressed_button()
	current_mode = MODE.NONE if btn == null else btn.get_meta("ID", 0)
	selected_node.set_meta("_edit_lock_", null if btn == null else true)

func _enter_tree() -> void:
	init_ui()

func _exit_tree() -> void:
	if main_tool_bar == null: return
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, main_tool_bar)
	main_tool_bar.queue_free()
	preview_mesh.queue_free()

func _handles(object : Object) -> bool:
	return object is MmPlus3D

func _edit(object) -> void:
	var previous_selected_node : MmPlus3D = selected_node
	selected_node = object

	if selected_node && !selected_node.data_changed.is_connected(_load_selected_node_data):
		_load_selected_node_data()
		selected_node.data_changed.connect(_load_selected_node_data)
	
	if previous_selected_node && previous_selected_node.data_changed.is_connected(_load_selected_node_data):
		previous_selected_node.data_changed.disconnect(_load_selected_node_data)
	
	main_tool_bar.visible = selected_node != null

# Reinit all the plugin on selected node data change, I'm too lazy to make something better right now
func _load_selected_node_data() -> void:
	grid_size_spinbox.value = selected_node.grid_size
	data_group_list = []
	# If no mismatch between grid size
	# Feed the saved data as is
	if selected_node.grid_size == selected_node.previous_grid_size:
		for data_group in selected_node.data:
			var data : Dictionary[AABB, MultiMesh] = data_group.multimesh_data_map
			var group : MMGroup = MMGroup.new()
			group.setup(data, selected_node.grid_size)
			data_group_list.append(group)
	else:
		# If mismatch flatten all buffers into one
		# And rebuild the groups
		print("Grid size changed, re-parse all data")
		for data_group in selected_node.data:
			var flat_buffer : PackedFloat32Array = []
			var data : Dictionary[AABB, MultiMesh] = data_group.multimesh_data_map
			for multimesh in data.values():
				flat_buffer.append_array(multimesh.buffer)
			var group : MMGroup = MMGroup.new()
			group.setup_from_buffer(flat_buffer, selected_node.grid_size)
			data_group_list.append(group)
	
		selected_node.delete_all_transforms()
		_update_selected_node_buffers()
		selected_node.previous_grid_size = selected_node.grid_size

	_rebuild_layers_ui()

func _rebuild_layers_ui() -> void:
	active_layers = []
	active_layers.resize(selected_node.data.size())
	active_layers.fill(true)

	for child in layers_popup_body.get_children():
		child.queue_free()

	for mmplus_data_idx in selected_node.data.size():
		var mmplus_data : MMPlusData = selected_node.data[mmplus_data_idx]
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = mmplus_data.mesh_data.name
		checkbox.button_pressed = true
		layers_popup_body.add_child(checkbox)
		checkbox.toggled.connect(func(toggled : bool) -> void:
			active_layers[mmplus_data_idx] = toggled
			)

func _get_data_group_clone() -> Array[MMGroup]:
	var result : Array[MMGroup] = []
	for data in data_group_list:
		result.append(data.duplicate())
	return result

func _forward_3d_gui_input(viewport_camera, event):
	# Track 'S' key state for brush size shortcut
	if event is InputEventKey and event.keycode == KEY_S:
		_is_s_key_pressed = event.pressed

	if current_mode == MODE.NONE: return EditorPlugin.AFTER_GUI_INPUT_PASS

	# Brush size shortcut: Shift + S + Scroll (consume event to prevent viewport zoom)
	if _should_consume_scroll_event(event):
		if _should_apply_brush_size_scroll(event):
			_apply_brush_size_scroll(event)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	_check_paint_logic(viewport_camera, event)
	var is_left_click : bool = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed
	if !is_left_click: return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_STOP

func _check_paint_logic(viewport_camera, event) -> void:
	var mouse_event : InputEventMouse = event as InputEventMouse
	if !mouse_event: return

	var ray_cast_start : Vector3 = viewport_camera.global_position
	var ray_cast_end : Vector3 = viewport_camera.global_position + viewport_camera.project_ray_normal(event.position) * 100.0
	var ray_cast_result = _ray_cast(ray_cast_start, ray_cast_end)
	preview_mesh.visible = ray_cast_result != {}
	if !ray_cast_result: return

	var target_transform : Transform3D = Transform3D(_get_basis_from_normal(ray_cast_result.normal), ray_cast_result.position)

	preview_mesh.transform = target_transform
	target_transform = selected_node.global_transform.inverse() * target_transform

	var is_left_click : bool = event.button_mask == MOUSE_BUTTON_LEFT

	if is_applying_action != is_left_click:
		is_applying_action = is_left_click
		if is_applying_action:
			_memory_data_group_list = _get_data_group_clone()
		else:
			_add_to_history()

	if !is_left_click: return


	match current_mode:
		MODE.PAINT:
			_apply_paint_mode(event, target_transform)
		MODE.SCALE:
			_apply_scale_mode(event, target_transform)
		MODE.COLOR:
			_apply_color_mode(target_transform)
	
	previous_target_transform = target_transform

func _apply_paint_mode(event : InputEventMouse, t : Transform3D) -> void:
	var brush_size : float = brush_size_map[current_mode]
	if event.shift_pressed:
		# Erase - uses brush_size directly since grid stores base positions (without offset)
		# This creates intuitive cylinder-shaped erase behavior
		for data_group_idx in data_group_list.size():
			if active_layers[data_group_idx] == false: continue
			var data_group : MMGroup = data_group_list[data_group_idx]
			data_group.remove_point_in_sphere(t.origin, brush_size)
	else:
		# Paint
		for i in range(16):
			var weights : Array = selected_node.data.map(func(group: MMPlusData): return group.mesh_data.probability)
			var data_group_idx : int = rnd.rand_weighted(weights)
			if active_layers[data_group_idx] == false: continue
			var mesh_data : MMPlusMesh = selected_node.data[data_group_idx].mesh_data

			var circle_offset : Vector2 = _random_in_circle(brush_size)
			var target = t.translated_local(Vector3(circle_offset.x, 0.0, circle_offset.y))

			# Reproject the target onto the surface, as it is now displaced relative to the base target.
			var ray_cast_result = _ray_cast(target.origin + target.basis.y, target.origin - target.basis.y)
			if ray_cast_result == {}:
				continue

			var instance_basis : Basis = (
				_get_basis_from_normal(ray_cast_result.normal)
				if mesh_data.align_on_surface_normal
				else Basis.IDENTITY)

			target = Transform3D(instance_basis, ray_cast_result.position)

			# Check if target position is not too close to other already spawned instances.
			var min_space_between_instances : float = mesh_data.spacing
			var overlap : bool = data_group_list.any(func(data_group : MMGroup): 
				return data_group.mm_grid.is_point_in_sphere(target.origin, min_space_between_instances))
			if overlap:
				continue

			#Added offset in the transform to account for it when paiting
			var data_group : MMGroup = data_group_list[data_group_idx]
			# Capture base position BEFORE applying any transforms
			# This is the logical placement position used for spatial queries
			var base_position : Vector3 = target.origin
			var item_base_scale : float = mesh_data.base_scale
			if item_base_scale != 1.0:
				target = target.scaled_local(Vector3.ONE * item_base_scale)
			# Apply visual offset to the transform (for rendering)
			if mesh_data.offset != Vector3.ZERO:
				target = target.translated_local(mesh_data.offset)

			match mesh_data.rotation_mode:
				MMPlusMesh.RotationMode.RANDOM_Y_AXIS:
					target = target.rotated_local(Vector3.UP, randf() * TAU)
				MMPlusMesh.RotationMode.ALIGN_BRUSH_DIR:
					var tangent : Vector3 = previous_target_transform.origin.direction_to(t.origin)
					var look_at_target : Vector3 = target.origin + tangent
					if target.origin != look_at_target:
						target = target.looking_at(target.origin + tangent, target.basis.y, true)

			# Pass both: target (visual) and base_position (logical)
			data_group.add_transform_to_buffer(target, base_position)

	_update_selected_node_buffers()

func _apply_scale_mode(event : InputEventMouse, t : Transform3D) -> void:
	var brush_size : float = brush_size_map[current_mode]

	# Scale uses brush_size directly since grid stores base positions (without offset)
	for data_group_idx in data_group_list.size():
		if active_layers[data_group_idx] == false: continue
		var data_group : MMGroup = data_group_list[data_group_idx]

		# Query grid using brush_size - grid has logical positions
		var result : Dictionary[AABB, PackedInt64Array] = data_group.mm_grid.get_points_in_sphere(t.origin, brush_size)

		for aabb in result:
			for idx in result[aabb]:
				if event.ctrl_pressed:
					data_group.set_buffer_transform_scale(aabb, idx, 1.0)
				else:
					var point_position : Vector3 = data_group.mm_grid.get_point_position(aabb, idx)
					# Factor calculation uses brush_size (grid has base positions)
					var factor : float = (brush_size - point_position.distance_to(t.origin)) / brush_size
					var scale_value : float = 0.1 * factor
					data_group.increment_buffer_transform_scale(aabb, idx, -scale_value if event.shift_pressed else scale_value)

	_update_selected_node_buffers()


func _apply_color_mode(t : Transform3D) -> void:
	var brush_size : float = brush_size_map[current_mode]
	# Colorize uses brush_size directly since grid stores base positions (without offset)
	for data_group_idx in data_group_list.size():
		if active_layers[data_group_idx] == false: continue
		var data_group : MMGroup = data_group_list[data_group_idx]
		# Query uses brush_size - grid has logical positions
		data_group.set_buffer_color_in_sphere(t.origin, brush_size, color_picker.color, randomize_color_button.button_pressed)
	_update_selected_node_buffers()

func _random_in_circle(radius : float = 1.0) -> Vector2:
	var r = radius * sqrt(randf())
	var theta = randf() * TAU
	return Vector2.from_angle(theta) * r

func _add_to_history() -> void:
	var do_prop : Array[MMGroup] = _get_data_group_clone()
	var undo_prop : Array[MMGroup] = _memory_data_group_list

	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action("Update node buffers")
	undo_redo.add_do_method(self, "_update_selected_node_buffers_history", do_prop)
	undo_redo.add_undo_method(self, "_update_selected_node_buffers_history", undo_prop)
	undo_redo.add_do_property(self, "data_group_list", do_prop)
	undo_redo.add_undo_property(self, "data_group_list", undo_prop)
	undo_redo.commit_action()

func _update_selected_node_buffers() -> void:
	selected_node.update_group_buffer(data_group_list)

func _update_selected_node_buffers_history(data : Array[MMGroup]) -> void:
	selected_node.update_group_buffer(data)
	selected_node.check_missmatch(data)

func _get_basis_from_normal(normal : Vector3) -> Basis:
	var basis = Basis.IDENTITY
	basis.y = normal
	if normal.abs() != basis.z.abs(): basis.x = -basis.z.cross(normal)
	else: basis.z = basis.x.cross(normal)
	return basis.orthonormalized()

func _ray_cast(start : Vector3, end : Vector3) -> Dictionary:
	if selected_node == null: return {}
	var space_state : PhysicsDirectSpaceState3D = selected_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end, collision_layer)
	var ray_cast_result = space_state.intersect_ray(query)
	return ray_cast_result
