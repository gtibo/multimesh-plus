@tool
extends EditorPlugin

var selected_node : MmPlus3D
var data_group_list : Array[MMGroup] = []
var _memory_data_group_list : Array[MMGroup] = []

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
const BTN_THEME = preload("uid://b2b40e68ae13p")
const SPHERE_MAT = preload("uid://d3ogk53yp2yvp")

var main_tool_bar : HBoxContainer = null
var color_tool_bar : HBoxContainer = null
var color_picker : ColorPickerButton = null
var button_group : ButtonGroup = null
var preview_mesh : MeshInstance3D = null
var brush_size_box : SpinBox = null
var randomize_color_button : Button = null

func init_ui() -> void:
	main_tool_bar = HBoxContainer.new()
	color_tool_bar = HBoxContainer.new()
	main_tool_bar.hide()
	color_tool_bar.hide()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, main_tool_bar)
	var base_control = EditorInterface.get_base_control()
	button_group = ButtonGroup.new()
	# Create mode buttons
	for btn_id in btn_mode_map:
		var btn : Button = Button.new()
		btn.theme = BTN_THEME
		btn.text = btn_mode_map[btn_id].title
		btn.icon = base_control.get_theme_icon(btn_mode_map[btn_id].icon, "EditorIcons")
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
	randomize_color_button.icon = base_control.get_theme_icon("RandomNumberGenerator", "EditorIcons")
	randomize_color_button.theme = BTN_THEME
	randomize_color_button.toggle_mode = true
	randomize_color_button.tooltip_text = "Randomize Color"
	color_tool_bar.add_child(randomize_color_button)


	main_tool_bar.add_child(color_tool_bar)

func _set_current_mode(mode : MODE) -> void:
	if current_mode == mode: return
	current_mode = mode

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
	data_group_list = []
	if selected_node != null:
		_load_selected_node_data()
	main_tool_bar.visible = selected_node != null

func _load_selected_node_data() -> void:
	for data_group in selected_node.data:
		var data : Dictionary[AABB, MultiMesh] = data_group.multimesh_data_map
		var group : MMGroup = MMGroup.new()
		group.setup(data)
		data_group_list.append(group)

func _get_data_group_clone() -> Array[MMGroup]:
	var result : Array[MMGroup] = []
	for data in data_group_list:
		result.append(data.duplicate())
	return result

func _forward_3d_gui_input(viewport_camera, event):
	if current_mode == MODE.NONE: return EditorPlugin.AFTER_GUI_INPUT_PASS
	_check_paint_logic(viewport_camera, event)
	var is_left_click : bool = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed
	if !is_left_click: return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_STOP

var is_applying_action : bool = false

func _check_paint_logic(viewport_camera, event) -> void:
	var mouse_event : InputEventMouse = event as InputEventMouse
	if !mouse_event: return

	var space_state : PhysicsDirectSpaceState3D = viewport_camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		viewport_camera.global_position,
		viewport_camera.global_position + viewport_camera.project_ray_normal(event.position) * 100.0
		)
	var ray_cast_result = space_state.intersect_ray(query)
	preview_mesh.visible = ray_cast_result != {}
	if !ray_cast_result: return

	var t : Transform3D = Transform3D(_get_basis_from_normal(ray_cast_result.normal), ray_cast_result.position)

	preview_mesh.transform = t

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
			_apply_paint_mode(event, t)
		MODE.SCALE:
			_apply_scale_mode(event, t)
		MODE.COLOR:
			_apply_color_mode(t)

func _apply_paint_mode(event : InputEventMouse, t : Transform3D) -> void:
	var brush_size : float = brush_size_map[current_mode]
	if event.shift_pressed:
		# Erase
		for data_group in data_group_list:
			data_group.remove_point_in_sphere(t.origin, brush_size)
	else:
		# Paint
		for i in range(16):
			var data_group_idx : int = randi() % data_group_list.size()
			var min_space_between_instances : float = selected_node.data[data_group_idx].mesh_data.spacing
			var offset : Vector2 = _random_in_circle(brush_size)
			var target = t.translated_local(Vector3(offset.x, 0.0, offset.y))
			var overlap : bool = data_group_list.any(func(data_group : MMGroup): 
				return data_group.octree.is_point_in_sphere(target.origin, min_space_between_instances))
			if overlap: continue
			var data_group : MMGroup = data_group_list[data_group_idx]
			data_group.add_transform_to_buffer(target)

	_update_selected_node_buffers()

func _apply_scale_mode(event : InputEventMouse, t : Transform3D) -> void:
	var brush_size : float = brush_size_map[current_mode]

	for data_group in data_group_list:
		var result : Dictionary[AABB, PackedInt64Array] = data_group.octree.get_points_in_sphere(t.origin, brush_size)

		for aabb in result:
			for idx in result[aabb]:
				if event.ctrl_pressed:
					data_group.set_buffer_transform_scale(aabb, idx, 1.0)
				else:
					var point_position : Vector3 = data_group.octree.get_point_position(aabb, idx)
					var factor : float = (brush_size - point_position.distance_to(t.origin)) / brush_size
					var scale_value : float = 0.1 * factor
					data_group.increment_buffer_transform_scale(aabb, idx, -scale_value if event.shift_pressed else scale_value)

	_update_selected_node_buffers()

func _apply_color_mode(t : Transform3D) -> void:
	var brush_size : float = brush_size_map[current_mode]
	for data_group in data_group_list:
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
