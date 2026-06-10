@tool
@icon("../assets/icons/mm_plus_3d_icon.svg")
class_name MmPlus3D
extends Node3D

@export var data_group : MMPlusDataGroup
@export_storage var grid_size : float = 50.0
@export_storage var previous_grid_size : float = 50.0
@export_storage var visibility_range: float = 100.0

var save_path: String = "res://mmplus_save_dir/"
var rid_references: Array[MMRidRef]

signal group_buffer_resized(group_idx: int)

func _enter_tree() -> void:
	set_notify_transform(true)

	if data_group == null: return

	# Create rid array
	for _i in data_group.groups.size():
		rid_references.append(MMRidRef.new())

	load_multimesh()

	if !Engine.is_editor_hint(): return

	for group in data_group.groups:
		if group.mesh_data.changed.is_connected(_on_mesh_data_changed): continue
		group.mesh_data.changed.connect(_on_mesh_data_changed.bind(group))

func _exit_tree() -> void:
	_free_rid_references()
	if data_group == null: return
	for group in data_group.groups:
		if !group.mesh_data.changed.is_connected(_on_mesh_data_changed): continue
		group.mesh_data.changed.disconnect(_on_mesh_data_changed.bind(group))

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			_update_visual_instances_visibility()
		NOTIFICATION_TRANSFORM_CHANGED:
			_update_visual_instances_transform()

func _on_mesh_data_changed(group: MMPlusData):
	var group_idx : int = data_group.groups.find(group)
	if group_idx == -1: return

	var buffer_map : Dictionary[AABB, PackedFloat32Array]
	for aabb in group.multimesh_data_map.keys():
		buffer_map[aabb] = group.multimesh_data_map[aabb].buffer

	_update_buffer(group_idx, buffer_map)

func update_visibility_range(range: float):
	visibility_range = range

	for group_idx in rid_references.size():
		var data_group : MMRidRef = rid_references[group_idx]
		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.instance_geometry_set_visibility_range(
				data_group.visual_instance_RID_map[aabb],
				0.0,
				visibility_range + grid_size / 2.0,
				0.0,
				0.0,
				RenderingServer.VISIBILITY_RANGE_FADE_DISABLED)

func _update_visual_instances_visibility() -> void:
	for group_idx in rid_references.size():
		var data_group : MMRidRef = rid_references[group_idx]
		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.instance_set_visible(data_group.visual_instance_RID_map[aabb], visible)

func _update_visual_instances_transform() -> void:
	for group_idx in rid_references.size():
		var data_group : MMRidRef = rid_references[group_idx]
		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.instance_set_transform(data_group.visual_instance_RID_map[aabb], global_transform)

func add_mesh(plus_mesh: MMPlusMesh, at_idx: int = -1):
	var new_data_group: MMPlusData = MMPlusData.new()
	new_data_group.mesh_data = plus_mesh
	new_data_group.used_data_mode = plus_mesh.data_mode

	if at_idx == -1:
		data_group.groups.append(new_data_group)
		rid_references.append(MMRidRef.new())
	else:
		data_group.groups.insert(at_idx, new_data_group)
		rid_references.insert(at_idx, MMRidRef.new())

	_update_buffer(at_idx, {})

	plus_mesh.changed.connect(_on_mesh_data_changed.bind(new_data_group))

func remove_mesh(group_idx: int):
	var plus_mesh: MMPlusMesh = data_group.groups[group_idx].mesh_data
	plus_mesh.changed.disconnect(_on_mesh_data_changed.bind(plus_mesh))

	_delete_group_data(group_idx)
	data_group.groups.remove_at(group_idx)
	rid_references.remove_at(group_idx)

func _delete_group_data(group_idx: int) -> void:
	var group_rid_ref : MMRidRef = rid_references[group_idx]

	for aabb in group_rid_ref.visual_instance_RID_map:
		RenderingServer.free_rid(group_rid_ref.visual_instance_RID_map[aabb])
	group_rid_ref.visual_instance_RID_map = {}

	for aabb in group_rid_ref.multimesh_RID_map:
		RenderingServer.free_rid(group_rid_ref.multimesh_RID_map[aabb])
	group_rid_ref.multimesh_RID_map = {}

	data_group.groups[group_idx].multimesh_data_map = {}

func delete_all_transforms() -> void:
	for group_idx in data_group.groups.size():
		_delete_group_data(group_idx)

func load_multimesh() -> void:
	for group_idx in data_group.groups.size():

		var buffer_map : Dictionary[AABB, PackedFloat32Array]

		for aabb in data_group.groups[group_idx].multimesh_data_map.keys():
			var multimesh : MultiMesh = data_group.groups[group_idx].multimesh_data_map[aabb]
			if multimesh.instance_count == 0:
				# This instance can be skipped and deleted before being loaded
				data_group.groups[group_idx].multimesh_data_map.erase(aabb)
				continue
			buffer_map[aabb] = data_group.groups[group_idx].multimesh_data_map[aabb].buffer

		_update_buffer(group_idx, buffer_map)

func _add_visual_instance(group_idx : int, aabb : AABB) -> void:
	var mesh_data : MMPlusMesh = data_group.groups[group_idx].mesh_data
	var mesh : Mesh = mesh_data.mesh
	var m_rid = RenderingServer.multimesh_create()
	var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)
	RenderingServer.instance_set_transform(i_rid, global_transform)
	RenderingServer.multimesh_set_mesh(m_rid, mesh.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(i_rid, mesh_data.cast_shadow)
	RenderingServer.instance_geometry_set_visibility_range(i_rid, 0.0, visibility_range + grid_size / 2.0, 0.0, 0.0, RenderingServer.VISIBILITY_RANGE_FADE_DISABLED)
	RenderingServer.instance_set_visible(i_rid, visible)
	rid_references[group_idx].multimesh_RID_map[aabb] = m_rid
	rid_references[group_idx].visual_instance_RID_map[aabb] = i_rid

func _add_multimesh_data(group_idx : int, aabb : AABB, use_color: bool) -> void:
	var multimesh : MultiMesh = MultiMesh.new()
	multimesh.use_colors = use_color
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	data_group.groups[group_idx].multimesh_data_map[aabb] = multimesh

func update_group_buffer(data_group_list : Array[MMGroup]):
	for group_idx in data_group_list.size():
		var data_group : MMGroup = data_group_list[group_idx]
		var buffer_map : Dictionary[AABB, PackedFloat32Array] = data_group.buffer_map
		_update_buffer(group_idx, buffer_map)

func _remove_buffer(group_idx : int, aabb : AABB):
	var m_rid : RID = rid_references[group_idx].multimesh_RID_map[aabb]
	var i_rid : RID = rid_references[group_idx].visual_instance_RID_map[aabb]
	RenderingServer.free_rid(i_rid)
	RenderingServer.free_rid(m_rid)
	rid_references[group_idx].visual_instance_RID_map.erase(aabb)
	rid_references[group_idx].multimesh_RID_map.erase(aabb)
	data_group.groups[group_idx].multimesh_data_map.erase(aabb)

func check_missmatch(data_group_list : Array[MMGroup]):
	for group_idx in data_group.groups.size():
		var local_data : Dictionary[AABB, MultiMesh] = data_group.groups[group_idx].multimesh_data_map
		var external_data : Dictionary[AABB, PackedFloat32Array] = data_group_list[group_idx].buffer_map

		for aabb in local_data:
			if !external_data.has(aabb):
				_remove_buffer(group_idx, aabb)

func _update_buffer(group_idx : int, buffer_map : Dictionary[AABB, PackedFloat32Array]) -> void:
	if group_idx == -1: return

	var data_mode: MMDataMode.Mode = data_group.groups[group_idx].mesh_data.data_mode
	var data_size: int = MMDataMode.get_data_mode_size(data_mode)
	var previous_data_size: int = MMDataMode.get_data_mode_size(data_group.groups[group_idx].used_data_mode)
	var use_color: bool = data_mode == MMDataMode.Mode.TransformAndVertexColor
	var data_mode_mismatch = data_group.groups[group_idx].used_data_mode != data_mode

	for aabb in buffer_map:
		if !rid_references[group_idx].multimesh_RID_map.has(aabb):
			_add_visual_instance(group_idx, aabb)
		if !data_group.groups[group_idx].multimesh_data_map.has(aabb):
			_add_multimesh_data(group_idx, aabb, use_color)

		var m_rid : RID = rid_references[group_idx].multimesh_RID_map[aabb]
		var multimesh : MultiMesh = data_group.groups[group_idx].multimesh_data_map[aabb]
		var buffer : PackedFloat32Array = []

		if !data_mode_mismatch:
			buffer = buffer_map[aabb]
		else:
			buffer = _repare_buffer_size_mismatch(buffer_map[aabb], previous_data_size, data_size)
			multimesh.instance_count = 0
			multimesh.use_colors = use_color


		if !buffer.is_empty():
			RenderingServer.multimesh_allocate_data(
				m_rid,
				buffer.size() / data_size,
				RenderingServer.MULTIMESH_TRANSFORM_3D,
				use_color, false)

			RenderingServer.multimesh_set_buffer(m_rid, buffer)
			multimesh.instance_count = buffer.size() / data_size
			multimesh.buffer = buffer
		else:
			_remove_buffer(group_idx, aabb)

	if data_mode_mismatch:
		push_warning("Buffer size doesn't match mesh data mode size, buffer size was updated but some data might be lost.")
		group_buffer_resized.emit(group_idx)

	data_group.groups[group_idx].used_data_mode = data_mode

func _repare_buffer_size_mismatch(buffer : PackedFloat32Array, previous_size: int, new_size: int) -> PackedFloat32Array:
	var resized_buffer: PackedFloat32Array = []
	
	# from TransformAndVertexColor to TransformOnly
	if new_size < previous_size:
		for idx in range(0, buffer.size(), previous_size):
			for i in new_size:
				resized_buffer.append(buffer[idx + i])

	# from TransformOnly to TransformAndVertexColor
	if new_size > previous_size:
		for idx in range(0, buffer.size(), previous_size):
			var segment: PackedFloat32Array = []
			for i in previous_size:
				segment.append(buffer[idx + i])

			var missing_data: PackedFloat32Array = []
			missing_data.resize(new_size - previous_size)
			missing_data.fill(0.0)
			segment.append_array(missing_data)
			resized_buffer.append_array(segment)

	return resized_buffer

func _free_rid_references() -> void:
	for group_idx in rid_references.size():
		for aabb in rid_references[group_idx].visual_instance_RID_map:
			RenderingServer.free_rid(rid_references[group_idx].visual_instance_RID_map[aabb])
		rid_references[group_idx].visual_instance_RID_map = {}

		for aabb in rid_references[group_idx].multimesh_RID_map:
			RenderingServer.free_rid(rid_references[group_idx].multimesh_RID_map[aabb])
		rid_references[group_idx].multimesh_RID_map = {}
