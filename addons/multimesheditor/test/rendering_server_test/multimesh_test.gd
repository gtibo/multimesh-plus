extends Node3D

const POINT_MESH = preload("res://addons/multimesheditor/test/point_mesh.obj")

func _ready() -> void:
	var m_rid : RID = RenderingServer.multimesh_create()
	var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)

	RenderingServer.instance_set_transform(i_rid, Transform3D.IDENTITY)
	
	# Populate
	
	var count : int = 200

	RenderingServer.multimesh_set_mesh(m_rid, POINT_MESH.get_rid())
	RenderingServer.multimesh_allocate_data(m_rid, count, RenderingServer.MULTIMESH_TRANSFORM_3D, true, true)
	
	for idx in count:
		var t : Transform3D = Transform3D.IDENTITY
		t.origin = Vector3((randf() - 0.5) * 5.0, (randf() - 0.5) * 5.0, (randf() - 0.5) * 5.0)
		RenderingServer.multimesh_instance_set_transform(m_rid, idx, t)
	
