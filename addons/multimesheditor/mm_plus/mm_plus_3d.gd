@tool
class_name MmPlus3D
extends Node3D

@export var mesh : BoxMesh
@export var multimesh_RID_map : Dictionary[AABB, RID]
const FLOWER_1 : ArrayMesh = preload("uid://d3wriijseqvdb")
const FLOWER_MAT = preload("uid://cojhtxb1xrv4a")

func _ready() -> void:
	FLOWER_1.surface_set_material(0, FLOWER_MAT)

func _add_new_rid(aabb : AABB) -> void:
	var m_rid = RenderingServer.multimesh_create()
	var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)
	RenderingServer.instance_set_transform(i_rid, Transform3D.IDENTITY)
	RenderingServer.instance_set_custom_aabb(i_rid, aabb)
	RenderingServer.multimesh_set_mesh(m_rid, FLOWER_1.get_rid())
	RenderingServer.instance_geometry_set_visibility_range(i_rid, 0.0, 100.0, 0.0, 0.0, RenderingServer.VISIBILITY_RANGE_FADE_DISABLED)

	multimesh_RID_map[aabb] = m_rid

func _update_buffer(buffer_map : Dictionary[AABB, PackedFloat32Array]):
	for aabb in buffer_map:
		var buffer : PackedFloat32Array = buffer_map[aabb]
		if !multimesh_RID_map.has(aabb):
			_add_new_rid(aabb)
		var m_rid : RID = multimesh_RID_map[aabb]

		RenderingServer.multimesh_allocate_data(m_rid, buffer.size() / 16, RenderingServer.MULTIMESH_TRANSFORM_3D, true)
		if !buffer.is_empty():
			RenderingServer.multimesh_set_buffer(m_rid, buffer)

func _save():
	pass
