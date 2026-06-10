@tool
class_name MMPlusData
extends Resource

@export_storage var mesh_data : MMPlusMesh
# Store last used data mode to check for data mode mismatch on load
@export_storage var used_data_mode : MMDataMode.Mode = -1
@export_storage var multimesh_data_map : Dictionary[AABB, MultiMesh]
