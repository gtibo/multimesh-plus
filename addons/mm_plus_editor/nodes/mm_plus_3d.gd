@tool
@icon("../assets/icons/mm_plus_3d_icon.svg")
class_name MmPlus3D
extends Node3D

@export var grid_size : float = 50.0
@export var previous_grid_size : float = 50.0
@export var data : Array[MMPlusData] : set = _set_data

signal data_changed

func _set_data(new_data : Array[MMPlusData]) -> void:
	var previous_data : Array[MMPlusData] = data
	data = new_data
	data_changed.emit()
	if !is_inside_tree(): return
	# Check signal on mesh data resource
	for mmplus_data in data:
		if mmplus_data == null: continue
		if mmplus_data.mesh_data == null: continue
		if !mmplus_data.mesh_data.changed.is_connected(data_changed.emit):
			mmplus_data.mesh_data.changed.connect(data_changed.emit)

	# Something was removed?
	if (previous_data.size() - data.size()) == 1:
		var idx : int = previous_data.find_custom(func(item : MMPlusData): return !data.has(item))
		var removed_data : MMPlusData = previous_data[idx]
		for aabb in removed_data.multimesh_data_map:
			var m_rid : RID = removed_data.multimesh_RID_map[aabb]
			RenderingServer.free_rid(m_rid)
			var i_rid : RID = removed_data.visual_instance_RID_map[aabb]
			RenderingServer.free_rid(i_rid)

	if previous_data != data:
		flush()
		load_multimesh()

func _ready() -> void:
	load_multimesh()
	set_notify_transform(true)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			_update_visual_instances_visibility()
		NOTIFICATION_TRANSFORM_CHANGED:
			_update_visual_instances_transform()

func _update_visual_instances_visibility() -> void:
	for data_group_idx in data.size():
		var data_group : MMPlusData = data[data_group_idx]
		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.instance_set_visible(data_group.visual_instance_RID_map[aabb], visible)


func _update_visual_instances_transform() -> void:
	for data_group_idx in data.size():
		var data_group : MMPlusData = data[data_group_idx]
		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.instance_set_transform(data_group.visual_instance_RID_map[aabb], global_transform)

func delete_all_transforms() -> void:
	for data_group_idx in data.size():
		var data_group : MMPlusData = data[data_group_idx]

		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.free_rid(data_group.visual_instance_RID_map[aabb])
		data_group.visual_instance_RID_map = {}

		for aabb in data_group.multimesh_RID_map:
			RenderingServer.free_rid(data_group.multimesh_RID_map[aabb])
		data_group.multimesh_RID_map = {}

		data_group.multimesh_data_map = {}

func load_multimesh() -> void:
	for group_idx in data.size():

		var buffer_map : Dictionary[AABB, PackedFloat32Array]

		for aabb in data[group_idx].multimesh_data_map.keys():
			var multimesh : MultiMesh = data[group_idx].multimesh_data_map[aabb]
			if multimesh.instance_count == 0:
				# This instance can be skipped and deleted before being loaded
				data[group_idx].multimesh_data_map.erase(aabb)
				continue
			buffer_map[aabb] = data[group_idx].multimesh_data_map[aabb].buffer

		_update_buffer(group_idx, buffer_map)

func _add_visual_instance(group_idx : int, aabb : AABB) -> void:
	var mesh_data : MMPlusMesh = data[group_idx].mesh_data
	var mesh : Mesh = mesh_data.mesh
	var m_rid = RenderingServer.multimesh_create()
	var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)
	RenderingServer.instance_set_transform(i_rid, global_transform)
	RenderingServer.instance_set_custom_aabb(i_rid, aabb)
	RenderingServer.multimesh_set_mesh(m_rid, mesh.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(i_rid, mesh_data.cast_shadow)
	RenderingServer.instance_geometry_set_visibility_range(i_rid, 0.0, 100.0 + grid_size / 2.0, 0.0, 0.0, RenderingServer.VISIBILITY_RANGE_FADE_DISABLED)
	RenderingServer.instance_set_visible(i_rid, visible)
	data[group_idx].multimesh_RID_map[aabb] = m_rid
	data[group_idx].visual_instance_RID_map[aabb] = i_rid

func _add_multimesh_data(group_idx : int, aabb : AABB) -> void:
	var multimesh : MultiMesh = MultiMesh.new()
	multimesh.use_colors = true
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	data[group_idx].multimesh_data_map[aabb] = multimesh

func update_group_buffer(data_group_list : Array[MMGroup]):
	for data_group_idx in data_group_list.size():
		var data_group : MMGroup = data_group_list[data_group_idx]
		var buffer_map : Dictionary[AABB, PackedFloat32Array] = data_group.buffer_map
		_update_buffer(data_group_idx, buffer_map)

func _remove_buffer(data_group_idx : int, aabb : AABB):
	var m_rid : RID = data[data_group_idx].multimesh_RID_map[aabb]
	var i_rid : RID = data[data_group_idx].visual_instance_RID_map[aabb]
	RenderingServer.free_rid(i_rid)
	RenderingServer.free_rid(m_rid)
	data[data_group_idx].visual_instance_RID_map.erase(aabb)
	data[data_group_idx].multimesh_RID_map.erase(aabb)
	data[data_group_idx].multimesh_data_map.erase(aabb)

func check_missmatch(data_group_list : Array[MMGroup]):
	for data_group_idx in data.size():
		var local_data : Dictionary[AABB, MultiMesh] = data[data_group_idx].multimesh_data_map
		var external_data : Dictionary[AABB, PackedFloat32Array] = data_group_list[data_group_idx].buffer_map
		
		for aabb in local_data:
			if !external_data.has(aabb):
				_remove_buffer(data_group_idx, aabb)

func _update_buffer(data_group_idx : int, buffer_map : Dictionary[AABB, PackedFloat32Array]) -> void:
	for aabb in buffer_map:
		var buffer : PackedFloat32Array = buffer_map[aabb]

		if !data[data_group_idx].multimesh_RID_map.has(aabb):
			_add_visual_instance(data_group_idx, aabb)
		if !data[data_group_idx].multimesh_data_map.has(aabb):
			_add_multimesh_data(data_group_idx, aabb)

		var m_rid : RID = data[data_group_idx].multimesh_RID_map[aabb]
		var multimesh : MultiMesh = data[data_group_idx].multimesh_data_map[aabb]

		RenderingServer.multimesh_allocate_data(m_rid, buffer.size() / 16, RenderingServer.MULTIMESH_TRANSFORM_3D, true)

		if !buffer.is_empty():
			RenderingServer.multimesh_set_buffer(m_rid, buffer)
			multimesh.instance_count = buffer.size() / 16
			multimesh.buffer = buffer
		else:
			_remove_buffer(data_group_idx, aabb)

func _enter_tree() -> void:
	load_multimesh()

func _exit_tree() -> void:
	flush()

func flush() -> void:
	for data_group_idx in data.size():
		for aabb in data[data_group_idx].visual_instance_RID_map:
			RenderingServer.free_rid(data[data_group_idx].visual_instance_RID_map[aabb])
		data[data_group_idx].visual_instance_RID_map = {}

		for aabb in data[data_group_idx].multimesh_RID_map:
			RenderingServer.free_rid(data[data_group_idx].multimesh_RID_map[aabb])
		data[data_group_idx].multimesh_RID_map = {}
