@tool
extends EditorPlugin

var selected_node : MmPlus3D
var data_group_list : Array[MMGroup] = []

enum MODE {NONE, PAINT, SCALE, COLOR}
var current_mode : MODE = MODE.NONE
const btn_mode_map = {
	MODE.PAINT: {"title": "Paint", "icon": "Paint"},
	MODE.SCALE: {"title": "Scale", "icon": "ToolScale"},
	MODE.COLOR: {"title": "Colorize", "icon": "Bucket"},
}
const BTN_THEME = preload("uid://b2b40e68ae13p")

var main_tool_bar : HBoxContainer = null
var button_group : ButtonGroup = null

func init_ui() -> void:
	main_tool_bar = HBoxContainer.new()
	main_tool_bar.hide()
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
		data_group_list.append(MMGroup.new(data))
	
	#var data : Dictionary[AABB, MultiMesh] = selected_node.multimesh_data_map
	#
	#for aabb in data:
		#buffer_map[aabb] = data[aabb].buffer
		#var buffer : PackedFloat32Array = data[aabb].buffer
#
		#var points = []
#
		#for idx in range(0, buffer.size(), 16):
			#var point = Vector3(
				#buffer[idx + 3],
				#buffer[idx + 7],
				#buffer[idx + 11]
			#)
			#points.append(point)
#
		#octree.populate(aabb, points)

func _forward_3d_gui_input(viewport_camera, event):
	if current_mode == MODE.NONE: return EditorPlugin.AFTER_GUI_INPUT_PASS
	_check_paint_logic(viewport_camera, event)
	var is_left_click : bool = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed
	if !is_left_click: return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_STOP

func _check_paint_logic(viewport_camera, event) -> void:
	var mouse_event : InputEventMouse = event as InputEventMouse
	if !mouse_event: return

	var space_state : PhysicsDirectSpaceState3D = viewport_camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		viewport_camera.global_position,
		viewport_camera.global_position + viewport_camera.project_ray_normal(event.position) * 100.0
		)
	var ray_cast_result = space_state.intersect_ray(query)
	if !ray_cast_result: return

	var t : Transform3D = Transform3D(_get_basis_from_normal(ray_cast_result.normal), ray_cast_result.position)

	var is_left_click : bool = event.button_mask == MOUSE_BUTTON_LEFT
	if !is_left_click: return

	match current_mode:
		MODE.PAINT:
			_apply_paint_mode(event, t)
		#MODE.SCALE:
			#_apply_transform_mode(event, t)
		#MODE.COLOR:
			#_apply_color_mode(t)

func _apply_paint_mode(event : InputEventMouse, t : Transform3D) -> void:
	if event.shift_pressed:
		# Erase
		var erase_size : float = 2.0
		for data_group in data_group_list:
			data_group.remove_point_in_sphere(t.origin, erase_size)
	else:
		# Paint
		for i in range(16):
			var paint_size : float = 2.0
			var min_space_between_instances : float = 0.5
			var offset : Vector2 = _random_in_circle(paint_size)
			var target = t.translated_local(Vector3(offset.x, 0.0, offset.y))
			var overlap : bool = data_group_list.any(func(data_group : MMGroup): 
				return data_group.octree.is_point_in_sphere(target.origin, min_space_between_instances))
			if overlap: continue
			var data_group : MMGroup = data_group_list[randi() % data_group_list.size()]
			data_group.add_transform_to_buffer(target)

	_update_selected_node_buffers()


func _random_in_circle(radius : float = 1.0) -> Vector2:
	var r = radius * sqrt(randf())
	var theta = randf() * TAU
	return Vector2.from_angle(theta) * r

func _update_selected_node_buffers() -> void:
	selected_node.update_group_buffer(data_group_list)

func _get_basis_from_normal(normal : Vector3) -> Basis:
	var basis = Basis.IDENTITY
	basis.y = normal
	if normal.abs() != basis.z.abs(): basis.x = -basis.z.cross(normal)
	else: basis.z = basis.x.cross(normal)
	return basis.orthonormalized()
