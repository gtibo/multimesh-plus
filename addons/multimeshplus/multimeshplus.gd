@tool
extends EditorPlugin

var plugin_control : HBoxContainer = HBoxContainer.new()
var selected_node : MultiMeshInstance3D

var button_group : ButtonGroup = ButtonGroup.new()

enum MODE {NONE, ADD, ERASE, SCALE, COLOR}
var current_mode : MODE = MODE.NONE

var transforms : Array[Transform3D] = []
var _last_tranforms : Array[Transform3D]
var colors : Array[Color] = []
var _last_colors : Array[Color] = []

var last_transform_operation

var threshold : float = 2.0
var scale_threshold = 4.0

var base_scale : float = 1.0
var cursor_position : Vector2 = Vector2.ZERO

var base_color : Color = Color(0.5, 0.5, 0.5)

var randomize_r : bool = false
var randomize_g : bool = false
var randomize_b : bool = false

var ignore_r : bool = false
var ignore_g : bool = false
var ignore_b : bool = false

var preview_mesh : MeshInstance3D = MeshInstance3D.new()
const SPHERE_MAT = preload("./mat/sphere_mat.tres")
const BTN_THEME = preload("./btn_theme.tres")

func _enter_tree():
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, plugin_control)
	
	var gui = EditorInterface.get_base_control()
	get_tree().root.call_deferred("add_child", preview_mesh)
	
	preview_mesh.mesh = SphereMesh.new()
	preview_mesh.material_override = SPHERE_MAT
	preview_mesh.hide()
	
	var option_btn : Button = Button.new()
	option_btn.theme = BTN_THEME
	option_btn.text = "Settings"
	option_btn.icon = gui.get_theme_icon("GuiOptionArrow", "EditorIcons")
	
	plugin_control.add_child(option_btn)
	
	var popup : PopupPanel = PopupPanel.new()
	var popup_body : VBoxContainer = VBoxContainer.new()
	popup.add_child(popup_body)
	plugin_control.add_child(popup)
	
	# Bind values
	add_float_setter(popup_body, "Base scale", base_scale,
	func(value : float):
		base_scale = value
		)
	
	add_float_setter(popup_body, "Brush threshold", threshold,
	func(value : float):
		threshold = value
		_update_threshold_side()
		)
		
	add_float_setter(popup_body, "Scale threshold", scale_threshold,
	func(value : float):
		scale_threshold = value
		_update_threshold_side()
		)
	
	option_btn.pressed.connect(func():
		popup.popup(Rect2i(option_btn.get_screen_position() + Vector2(0.0, option_btn.size.y), Vector2i.ONE))
		)
	
	# Color settings
	
	var base_color_picker : ColorPickerButton = ColorPickerButton.new()
	popup_body.add_child(base_color_picker)
	base_color_picker.custom_minimum_size.y = 32.0
	base_color_picker.color = base_color
	base_color_picker.color_changed.connect(func(picked_color : Color): base_color = picked_color)
	
	var randomize_group_title : Label = Label.new()
	popup_body.add_child(randomize_group_title)
	randomize_group_title.text = "Randomize channel"
	
	var randomize_group : HBoxContainer = HBoxContainer.new()
	popup_body.add_child(randomize_group)
	
	add_bool_setter(randomize_group, "R", func(value : bool): randomize_r = value)
	add_bool_setter(randomize_group, "G", func(value : bool): randomize_g = value)
	add_bool_setter(randomize_group, "B", func(value : bool): randomize_b = value)
	
	var ignore_group_title : Label = Label.new()
	popup_body.add_child(ignore_group_title)
	ignore_group_title.text = "Ignore channel"
	
	var ignore_group : HBoxContainer = HBoxContainer.new()
	popup_body.add_child(ignore_group)
	
	add_bool_setter(ignore_group, "R", func(value : bool): ignore_r = value)
	add_bool_setter(ignore_group, "G", func(value : bool): ignore_g = value)
	add_bool_setter(ignore_group, "B", func(value : bool): ignore_b = value)
	
	# Add modes
	var btn_types = [
		{"ID": MODE.ADD, "title": "Add", "icon": "Paint"},
		{"ID": MODE.ERASE, "title": "Erase", "icon": "Eraser"},
		{"ID": MODE.SCALE, "title": "Scale", "icon": "ToolScale"},
		{"ID": MODE.COLOR, "title": "Colorize", "icon": "Bucket"},
	]
	for type in btn_types:
		var btn : Button = Button.new()
		btn.theme = BTN_THEME
		btn.text = type.title
		btn.icon = gui.get_theme_icon(type.icon, "EditorIcons")
		btn.button_group = button_group
		btn.set_meta("ID", type.ID)
		btn.toggle_mode = true
		plugin_control.add_child(btn)
	
	button_group.pressed.connect(_on_button_group_press)
	button_group.allow_unpress = true

func add_float_setter(parent : Node, title : String, value : float, value_changed_callback : Callable):
	var float_group : HBoxContainer = HBoxContainer.new()
	parent.add_child(float_group)
	
	var label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND
	float_group.add_child(label)
	label.text = title
	
	var spin_box = SpinBox.new()
	float_group.add_child(spin_box)
	spin_box.step = 0.1
	spin_box.min_value = 0.1
	spin_box.value = value
	spin_box.value_changed.connect(value_changed_callback)
	
	
func add_bool_setter(parent : Node, title : String, toggled_callback : Callable):
	var check_box = CheckBox.new()
	check_box.size_flags_horizontal = Control.SIZE_EXPAND
	parent.add_child(check_box)
	check_box.text = title
	check_box.toggled.connect(toggled_callback)

func set_preview_scale(scale : float):
	preview_mesh.mesh.radius = scale
	preview_mesh.mesh.height = scale * 2.0

func _on_button_group_press(_pressed_button : BaseButton):
	var btn : BaseButton = button_group.get_pressed_button()
	current_mode = MODE.NONE if btn == null else btn.get_meta("ID")
	selected_node.set_meta("_edit_lock_", null if btn == null else true)
	_update_threshold_side()

func _update_threshold_side():
	match current_mode:
		MODE.ADD: set_preview_scale(threshold)
		MODE.ERASE: set_preview_scale(threshold)
		MODE.SCALE: set_preview_scale(scale_threshold)
		MODE.COLOR: set_preview_scale(scale_threshold)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, plugin_control)
	preview_mesh.queue_free()

func _forward_3d_gui_input(viewport_camera, event):
	if current_mode == MODE.NONE: return EditorPlugin.AFTER_GUI_INPUT_PASS
	_check_paint_logic(viewport_camera, event)
	var is_left_click : bool = event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed
	if !is_left_click: return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_STOP

func _check_history():
	var undo_redo = get_undo_redo()
	var color_diff = _last_colors != colors
	# Check for transforms differences
	if _last_tranforms != transforms:
		undo_redo.create_action("Edit Multimesh")
		undo_redo.add_do_property(self, "transforms", transforms.duplicate())
		undo_redo.add_undo_property(self, "transforms", _last_tranforms)
		if color_diff:
			undo_redo.add_do_property(self, "colors", colors)
			undo_redo.add_undo_property(self, "colors", _last_colors)
		undo_redo.add_do_method(self, "_update_transforms")
		undo_redo.add_undo_method(self, "_update_transforms")
		undo_redo.commit_action()
	# Check for color differences
	elif color_diff:
		undo_redo.create_action("Edit colors")
		undo_redo.add_do_property(self, "colors", colors.duplicate())
		undo_redo.add_undo_property(self, "colors", _last_colors)
		undo_redo.add_do_method(self, "_update_transforms")
		undo_redo.add_undo_method(self, "_update_transforms")
		undo_redo.commit_action()

func _check_paint_logic(viewport_camera, event):
	if !event is InputEventMouse: return
	
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_last_tranforms = transforms.duplicate()
			_last_colors = colors.duplicate()
		else:
			last_transform_operation = null
			_check_history()
	
	var space_state : PhysicsDirectSpaceState3D = viewport_camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		viewport_camera.global_position,
		viewport_camera.global_position + viewport_camera.project_ray_normal(event.position) * 100.0
		)
	var result = space_state.intersect_ray(query)
	
	preview_mesh.visible = result != {}
	
	if !result: return
	
	var t : Transform3D = Transform3D(_get_basis_from_normal(result.normal), result.position)
	preview_mesh.transform = t
	
	t = selected_node.global_transform.affine_inverse() * t
	
	if event.button_mask != MOUSE_BUTTON_LEFT: return
	
	match current_mode:
		MODE.ADD:
			if _is_inside_last_transform_threshold(t): return
			t = t.scaled_local(Vector3.ONE * base_scale)
			t = t.rotated_local(Vector3.UP, randf() * TAU)
			transforms.append(t)
			colors.append(Color(randf(), randf(), randf()))
			last_transform_operation = t
			_update_transforms()
		MODE.ERASE:
			if transforms.is_empty(): return
			if _is_inside_last_transform_threshold(t): return
			var closest_idx = _get_closest_transform_from(t, threshold)
			if closest_idx != -1:
				transforms.remove_at(closest_idx)
				colors.remove_at(closest_idx)
				last_transform_operation = t
				_update_transforms()
		MODE.SCALE:
			for idx in transforms.size():
				var dist = transforms[idx].origin.distance_to(t.origin)
				if dist > scale_threshold: continue
				var percent : float = (1.0 - clamp(dist / scale_threshold, 0.0, 1.0))
				var current_scale = transforms[idx].basis.get_scale()[0]
				if event.shift_pressed:
					current_scale -= percent * 0.025
				elif event.ctrl_pressed:
					current_scale = lerpf(current_scale, base_scale, percent * 0.025)
				else:
					current_scale += percent * 0.025
				current_scale = max(0.1, current_scale)
				transforms[idx].basis = Basis(transforms[idx].basis.get_rotation_quaternion()).scaled(Vector3.ONE * current_scale)
			_update_transforms()
		MODE.COLOR:
			for idx in transforms.size():
				var dist = transforms[idx].origin.distance_to(t.origin)
				if dist > scale_threshold: continue
				var percent : float = (1.0 - clamp(dist / scale_threshold, 0.0, 1.0))
				if !ignore_r: colors[idx].r = randf() if randomize_r else lerpf(colors[idx].r, base_color.r, percent)
				if !ignore_g: colors[idx].g = randf() if randomize_g else lerpf(colors[idx].g, base_color.g, percent)
				if !ignore_b: colors[idx].b = randf() if randomize_b else lerpf(colors[idx].b, base_color.b, percent)
			_update_transforms()

func _is_inside_last_transform_threshold(t : Transform3D) -> bool:
	if !last_transform_operation: return false
	var is_inside : bool = last_transform_operation.origin.distance_to(t.origin) < threshold
	return is_inside

func _get_closest_transform_from(from : Transform3D, radius : float = 2.0) -> int:
	var shortest_distance : float = INF
	var closest_idx : int = -1
	for idx in transforms.size():
		var transform = transforms[idx]
		var dist = transform.origin.distance_to(from.origin)
		if dist <= radius && dist < shortest_distance:
			shortest_distance = dist
			closest_idx = idx
	return closest_idx

func _handles(object : Object):
	return object is MultiMeshInstance3D

func _edit(object):
	selected_node = object
	if selected_node is MultiMeshInstance3D:
		_reset_transforms()
		
func _reset_transforms():
	var count = selected_node.multimesh.instance_count
	transforms.resize(count)
	colors.resize(count)
	for idx in count:
		transforms[idx] = selected_node.multimesh.get_instance_transform(idx)
		colors[idx] = selected_node.multimesh.get_instance_color(idx)

func _update_transforms():
	var count = transforms.size()
	selected_node.multimesh.instance_count = count
	for idx in count:
		selected_node.multimesh.set_instance_transform(idx, transforms[idx])
		selected_node.multimesh.set_instance_color(idx, colors[idx])

func _make_visible(visible):
	plugin_control.visible = visible

func _get_basis_from_normal(normal : Vector3) -> Basis:
	var basis = Basis.IDENTITY
	basis.y = normal
	if normal.abs() != basis.z.abs(): basis.x = -basis.z.cross(normal)
	else: basis.z = basis.x.cross(normal)
	return basis.orthonormalized()
