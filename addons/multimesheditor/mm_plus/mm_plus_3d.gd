@tool
class_name MmPlus3D
extends Node3D

const FLOWER_1 = preload("uid://d3wriijseqvdb")
const FLOWER_MAT = preload("uid://cojhtxb1xrv4a")
@export var mesh : BoxMesh
var m_rid : RID

func _ready() -> void:
	FLOWER_1.surface_set_material(0, FLOWER_MAT)
	m_rid = RenderingServer.multimesh_create()
	var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)
	RenderingServer.instance_set_transform(i_rid, Transform3D.IDENTITY)
	RenderingServer.multimesh_set_mesh(m_rid, mesh.get_rid())

func _update_buffer(buffer : PackedFloat32Array):
	RenderingServer.multimesh_allocate_data(m_rid, buffer.size() / 12, RenderingServer.MULTIMESH_TRANSFORM_3D)
	if !buffer.is_empty():
		RenderingServer.multimesh_set_buffer(m_rid, buffer)
