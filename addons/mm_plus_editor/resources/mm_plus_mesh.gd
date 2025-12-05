@tool
class_name MMPlusMesh
extends Resource

@export var name : StringName = "" : set = _set_name
@export var mesh : Mesh : set = _set_mesh
@export var spacing : float = 0.5 : set = _set_spacing
@export_range(0.1, 10.0, 0.1, "or_greater") var base_scale : float = 1.0 : set = _set_base_scale

func _set_name(new_name : StringName) -> void:
	name = new_name

func _set_mesh(new_mesh : Mesh) -> void:
	mesh = new_mesh
	emit_changed()

func _set_spacing(new_spacing : float) -> void:
	spacing = new_spacing

func _set_base_scale(new_scale : float) -> void:
	base_scale = new_scale
