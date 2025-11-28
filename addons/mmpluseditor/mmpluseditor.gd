@tool
extends EditorPlugin

var selected_node : MmPlus3D
var octree : Octree
var buffer_map : Dictionary[AABB, PackedFloat32Array] = {}

func _enable_plugin() -> void:
	# Add autoloads here.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

func _handles(object : Object) -> bool:
	return object is MmPlus3D

func _edit(object) -> void:
	var previous_selected_node : MmPlus3D = selected_node
	selected_node = object
	if selected_node:
		buffer_map = {}
		octree = Octree.new()
		_load_selected_node_data()

func _load_selected_node_data() -> void:
	var data : Dictionary[AABB, MultiMesh] = selected_node.multimesh_data_map
	
	for aabb in data:
		buffer_map[aabb] = data[aabb].buffer
		var buffer : PackedFloat32Array = data[aabb].buffer

		var points = []

		for idx in range(0, buffer.size(), 16):
			var point = Vector3(
				buffer[idx + 3],
				buffer[idx + 7],
				buffer[idx + 11]
			)
			points.append(point)

		octree.populate(aabb, points)

func _forward_3d_gui_input(viewport_camera, event) -> int:
	var mouse_event : InputEventMouse = event as InputEventMouse
	if !mouse_event: return EditorPlugin.AFTER_GUI_INPUT_PASS
	_check_paint_logic(viewport_camera, event)
	var mouse_button_event : InputEventMouseButton = event as InputEventMouseButton
	var is_left_click : bool = mouse_button_event && mouse_button_event.button_index == MOUSE_BUTTON_LEFT
	if !is_left_click: return EditorPlugin.AFTER_GUI_INPUT_PASS
	return EditorPlugin.AFTER_GUI_INPUT_STOP

func _check_paint_logic(viewport_camera, event) -> void:
	var mouse_event : InputEventMouse = event as InputEventMouse
	if !mouse_event: return
	var is_left_click : bool = event.button_mask == MOUSE_BUTTON_LEFT
	if !is_left_click: return
	
	var space_state : PhysicsDirectSpaceState3D = viewport_camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		viewport_camera.global_position,
		viewport_camera.global_position + viewport_camera.project_ray_normal(event.position) * 100.0
		)
	var ray_cast_result = space_state.intersect_ray(query)
	if !ray_cast_result: return

	var t : Transform3D = Transform3D(_get_basis_from_normal(ray_cast_result.normal), ray_cast_result.position)

	if event.shift_pressed:
		# Erase
		var result : Dictionary[AABB, PackedInt64Array] = octree.remove_points_in_sphere(t.origin, 10.0)
		for aabb in result:
			_remove_from_buffer_at_idx_list(aabb, result[aabb])
		_update_selected_node_buffers()
	else:
		for i in range(16):
			# Paint
			var offset : Vector2 = _random_in_circle(10.0)
			var target = t.translated_local(Vector3(offset.x, 0.0, offset.y))
			if octree.is_point_in_sphere(target.origin, 1.0): continue
			_add_transform_to_buffer(target)
			_update_selected_node_buffers()


func _random_in_circle(radius : float = 1.0) -> Vector2:
	var r = radius * sqrt(randf())
	var theta = randf() * TAU
	return Vector2.from_angle(theta) * r

func _add_transform_to_buffer(t : Transform3D) -> void:
	var region : AABB = octree.check_region_for_point(t.origin)

	if !buffer_map.has(region):
		buffer_map[region] = PackedFloat32Array()

	buffer_map[region].append_array(
		[t.basis.x.x, t.basis.y.x, t.basis.z.x, t.origin.x, t.basis.x.y, t.basis.y.y, t.basis.z.y, t.origin.y, t.basis.x.z, t.basis.y.z, t.basis.z.z, t.origin.z, randf(), randf(), randf(), 1.0]
		)
	var idx : int = buffer_map[region].size() / 16 - 1

	octree.add_point_in_region(region, idx, t.origin)

func _remove_from_buffer_at_idx_list(aabb : AABB, idx_list : PackedInt64Array):
	for idx in range(idx_list.size() - 1 , -1, -1):
		_remove_from_buffer_at_idx(aabb, idx_list[idx])

func _remove_from_buffer_at_idx(aabb : AABB, idx : int):
	var size : int = 16
	var idx_offset : int = size * idx
	for i in range(size - 1 + idx_offset, -1 + idx_offset, -1):
		buffer_map[aabb].remove_at(i)

func _update_selected_node_buffers() -> void:
	selected_node._update_buffer(buffer_map)

func _get_basis_from_normal(normal : Vector3) -> Basis:
	var basis = Basis.IDENTITY
	basis.y = normal
	if normal.abs() != basis.z.abs(): basis.x = -basis.z.cross(normal)
	else: basis.z = basis.x.cross(normal)
	return basis.orthonormalized()
