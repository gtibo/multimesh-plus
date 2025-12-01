@tool
class_name MmPlus3D
extends Node3D

# => moved in MMPlusData
var multimesh_RID_map : Dictionary[AABB, RID]
var visual_instance_RID_map : Dictionary[AABB, RID]
@export var multimesh_data_map : Dictionary[AABB, MultiMesh]

# => moved in MMPlusMesh
@export var mesh : BoxMesh

@export var mesh_list : Array[MMPlusMesh] : set = _set_mesh_list
@export var data : Array[MMPlusData]

func _set_mesh_list(new_list : Array[MMPlusMesh]) -> void:
	var previous_list : Array[MMPlusMesh] = mesh_list
	mesh_list = new_list


	# Item moved
	if new_list.size() == previous_list.size():
		print("moved")
		return

	# Item Added
	if new_list.size() > previous_list.size():
		print("add")
		var added_item_idx = new_list.find_custom(func(item): return item == null)
		mesh_list[added_item_idx] = MMPlusMesh.new()
		data.append(MMPlusData.new())
		return

	# Item removed
	if new_list.size() < previous_list.size():
		var removed_item_idx : int = previous_list.find_custom(func(item): return !new_list.has(item))
		print("removed : ", removed_item_idx)
		data.remove_at(removed_item_idx)
		return

func _ready() -> void:
	load_multimesh()

func load_multimesh() -> void:
	var buffer_map : Dictionary[AABB, PackedFloat32Array]
	for aabb in multimesh_data_map.keys():
		var multimesh : MultiMesh = multimesh_data_map[aabb]
		if multimesh.instance_count == 0:
			# This instance can be skipped and deleted before being loaded
			multimesh_data_map.erase(aabb)
			continue
		buffer_map[aabb] = multimesh_data_map[aabb].buffer
	_update_buffer(buffer_map)

func _add_visual_instance(aabb : AABB) -> void:
	var m_rid = RenderingServer.multimesh_create()
	var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)
	RenderingServer.instance_set_transform(i_rid, Transform3D.IDENTITY)
	RenderingServer.instance_set_custom_aabb(i_rid, aabb)
	RenderingServer.multimesh_set_mesh(m_rid, mesh.get_rid())
	RenderingServer.instance_geometry_set_visibility_range(i_rid, 0.0, 100.0, 0.0, 0.0, RenderingServer.VISIBILITY_RANGE_FADE_DISABLED)
	multimesh_RID_map[aabb] = m_rid
	visual_instance_RID_map[aabb] = i_rid

func _add_multimesh_data(aabb : AABB) -> void:
	var multimesh : MultiMesh = MultiMesh.new()
	multimesh.use_colors = true
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_data_map[aabb] = multimesh

func _update_buffer(buffer_map : Dictionary[AABB, PackedFloat32Array]):
	for aabb in buffer_map:
		var buffer : PackedFloat32Array = buffer_map[aabb]
		if !multimesh_RID_map.has(aabb):
			_add_visual_instance(aabb)
		if !multimesh_data_map.has(aabb):
			_add_multimesh_data(aabb)

		var m_rid : RID = multimesh_RID_map[aabb]
		var multimesh : MultiMesh = multimesh_data_map[aabb]

		RenderingServer.multimesh_allocate_data(m_rid, buffer.size() / 16, RenderingServer.MULTIMESH_TRANSFORM_3D, true)
		if !buffer.is_empty():
			RenderingServer.multimesh_set_buffer(m_rid, buffer)
		multimesh.instance_count = buffer.size() / 16
		multimesh.buffer = buffer

func _exit_tree() -> void:
	for data_group in data:

		for aabb in data_group.visual_instance_RID_map:
			RenderingServer.free_rid(data_group.visual_instance_RID_map[aabb])

		for aabb in data_group.multimesh_RID_map:
			RenderingServer.free_rid(data_group.multimesh_RID_map[aabb])
