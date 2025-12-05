@tool
class_name MMPlusData
extends Resource

var multimesh_RID_map : Dictionary[AABB, RID] = {}
var visual_instance_RID_map : Dictionary[AABB, RID] = {}

@export var mesh_data : MMPlusMesh
@export_storage var multimesh_data_map : Dictionary[AABB, MultiMesh]
